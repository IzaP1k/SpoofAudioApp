import base64
import io
import os
import torch
import torch.nn as nn
import joblib
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt


def generate_human_friendly_explanation(mask, method_name):
    mask_energy = np.abs(mask)
    if mask_energy.size == 0: return "Brak danych do analizy."

    H, W = mask_energy.shape
    total_energy = np.sum(mask_energy) + 1e-9

    one_third = W // 3
    time_regions = {
        "początku nagrania": mask_energy[:, :one_third],
        "środku nagrania": mask_energy[:, one_third:2 * one_third],
        "końcu nagrania": mask_energy[:, 2 * one_third:]
    }

    time_sums = {k: np.sum(v) for k, v in time_regions.items()}
    best_time = max(time_sums, key=time_sums.get)
    best_time_pct = (time_sums[best_time] / total_energy) * 100

    band_h = H // 3
    freq_regions = {
        "niskich tonach": (mask_energy[:band_h, :],
                        "nasłuchiwał tła, buczenia mikrofonu lub głębi głosu"),
        "średnich tonach": (mask_energy[band_h:2 * band_h, :],
                         "skupił się na brzmieniu głosu i wymawianych słowach"),
        "wysokich tonach": (mask_energy[2 * band_h:, :],
                         "szukał cyfrowych artefaktów, szumów lub 'syczenia' (typowe dla deepfake)")
    }

    freq_sums = {k: np.sum(v[0]) for k, v in freq_regions.items()}
    best_freq = max(freq_sums, key=freq_sums.get)
    best_freq_pct = (freq_sums[best_freq] / total_energy) * 100
    freq_desc = freq_regions[best_freq][1]

    if method_name == "Occlusion":
        intro = "Test zasłaniania (Mapa cieplna nr 3) wykazał, że usunięcie tego fragmentu najbardziej zmienia decyzję"
        action_verb = "najważniejsze były"
    else:
        intro = "Analiza uwagi sieci (Mapa cieplna 2) pokazuje, gdzie model analizował"
        action_verb = "skupił wzrok na"

    return (f"{intro}. "
            f"Model w {best_time_pct:.0f}% oparł werdykt na {best_time}. "
            f"W aspekcie częstotliwości {action_verb} paśmie {best_freq} (w {best_freq_pct:.0f}% całej analizy), "
            f"co oznacza, że model {freq_desc}. \n")


def plot_xai_to_base64(original_img, gradcam_mask, occ_mask, title_info):
    fig, axes = plt.subplots(1, 3, figsize=(18, 5))
    plt.suptitle(title_info, fontsize=14, fontweight='bold')

    axes[0].imshow(original_img, origin='lower', aspect='auto', cmap='gray')
    axes[0].set_title("Spektrogram Wejściowy")
    axes[0].axis('off')

    axes[1].imshow(original_img, origin='lower', aspect='auto', cmap='gray', alpha=1.0)
    gradcam_mask = np.maximum(gradcam_mask, 0)
    im2 = axes[1].imshow(gradcam_mask, origin='lower', aspect='auto', cmap='jet', alpha=0.5)
    axes[1].set_title("Grad-CAM++ (Skupienie sieci)")
    axes[1].axis('off')
    fig.colorbar(im2, ax=axes[1], fraction=0.046, pad=0.04)

    axes[2].imshow(original_img, origin='lower', aspect='auto', cmap='gray', alpha=1.0)
    limit = np.percentile(np.abs(occ_mask), 99.5) if np.max(np.abs(occ_mask)) > 0 else 1
    im3 = axes[2].imshow(occ_mask, origin='lower', aspect='auto', cmap='seismic', vmin=-limit, vmax=limit, alpha=0.7)
    axes[2].set_title("Occlusion (Kluczowe cechy)")
    axes[2].axis('off')
    fig.colorbar(im3, ax=axes[2], fraction=0.046, pad=0.04)

    plt.tight_layout()
    buffer = io.BytesIO()
    plt.savefig(buffer, format='png', bbox_inches='tight')
    plt.close(fig)
    buffer.seek(0)

    img_str = base64.b64encode(buffer.read()).decode('utf-8')

    return img_str