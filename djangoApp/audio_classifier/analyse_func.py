import os
import torch
import numpy as np
import librosa
import torch.nn.functional as F
import cv2

from audio_classifier.models.extract_feature_func import extract_cqcc_from_signal
from audio_classifier.models.load_model import test_model_GMM_BiLSTM, load_resources, load_model_weights, \
    load_audio_description, extract_mel_from_signal, preprocess_spectrogram, return_db_description
from audio_classifier.models.models_architecture import AntiSpoofingResNet


MODEL_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "models/Res_Net")
SCALER_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "models/Res_Net/mel-spect_scaler.pkl")

PRELOADED_SCALER = None
PRELOADED_MODELS = {}
_PRELOAD_DONE = False


def prepare_description(file_path, sr=None, feature_func=None):

    y, sr = librosa.load(file_path, sr=sr)
    loudness_db, loudness_level, dominant_freq, clipped_ratio, duration = return_db_description(y, sr)

    if feature_func is not None:
        features = feature_func(y, sr)
    else:
        features = extract_cqcc_from_signal(y, sr)

    confidence, result, scores, instances_preprocessed = test_model_GMM_BiLSTM(features)
    result = f"Autentyczne nagranie - pewność: {(confidence*100):.2f}%" if result == 0 else f"Zmanipulowane nagranie - pewność: {((1-confidence)*100):.2f}%"

    description = (
        f"Format: {file_path.split('.')[-1].upper()}\n"
        f"Długość: {duration:.2f} s\n"
        f"Średnia głośność: {loudness_db:.1f} dB ({loudness_level})\n"
        f"Dominująca częstotliwość: {dominant_freq:.1f} Hz\n"
        f"Przester: {'Zawiera' if clipped_ratio > 0.01 else 'Brak'}\n"
        f"Wynik detekcji: {result}"
    )

    return confidence, result, description, scores, instances_preprocessed

def get_audio_info(y, sr, final_pred=None, avg_prob_class_1=None, file_path=None):

    loudness_db, loudness_level, dominant_freq, clipped_ratio, duration = return_db_description(y, sr)

    f0, voiced_flag, voiced_probs = librosa.pyin(y, fmin=50, fmax=500)
    dominant_freq = np.nanmedian(f0)
    clipped_ratio = np.mean(np.abs(y) > 0.99)

    status = "autentyczne" if final_pred == 0 else "zmanipulowane"
    result = f"Nagranie jest {status} - pewność: {avg_prob_class_1 * 100:.2f}%"

    result = (
        f"Format: {file_path.split('.')[-1].upper()}\n"
        f"Długość: {duration:.2f} s\n"
        f"Średnia głośność: {loudness_db:.1f} dB ({loudness_level})\n"
        f"Dominująca częstotliwość: {dominant_freq:.1f} Hz\n"
        f"Przester: {'Zawiera' if clipped_ratio > 0.01 else 'Brak'}\n"
        f"Wynik detekcji: {result}"
    )

    return result


def select_model_name(model_name):
    return "best_model_1.pt" if model_name == "model_1" else "best_model_2.pt"


def load_model_and_scaler(model_name, model_folder, scaler_file, model_class, device):
    full_model_path = os.path.join(model_folder, model_name)
    scaler = load_resources(model_folder, scaler_file)
    model = load_model_weights(model_class, full_model_path, device=device)
    return scaler, model


def init_preloaded_models(model_folder=MODEL_DIR, scaler_file=SCALER_DIR, model_class=AntiSpoofingResNet):
    global PRELOADED_SCALER, PRELOADED_MODELS, _PRELOAD_DONE
    if _PRELOAD_DONE:
        return
    device = 'cuda' if torch.cuda.is_available() else 'cpu'
    PRELOADED_SCALER = load_resources(model_folder, scaler_file)
    for key in ("model_1", "model_2"):
        filename = select_model_name(key)
        full_path = os.path.join(model_folder, filename)
        try:
            PRELOADED_MODELS[key] = load_model_weights(model_class, full_path, device=device)
        except Exception:
            PRELOADED_MODELS[key] = None
    _PRELOAD_DONE = True


def load_and_resample_audio(file_path, target_sr):
    y, sr, description = load_audio_description(file_path=file_path)
    if sr != target_sr:
        y = librosa.resample(y, orig_sr=sr, target_sr=target_sr)
        sr = target_sr
    return y, sr, description


def split_into_segments(y, sr):
    chunk_samples = 2 * sr
    total_samples = len(y)
    if total_samples < chunk_samples:
        n_repeats = int(np.ceil(chunk_samples / total_samples))
        y_repeated = np.tile(y, n_repeats)[:chunk_samples]
        return [y_repeated]
    segments = []
    for i in range(0, total_samples - chunk_samples + 1, chunk_samples):
        segments.append(y[i: i + chunk_samples])
    if total_samples % chunk_samples != 0:
        last_seg = y[-chunk_samples:]
        segments.append(last_seg)
    return segments


def process_segments(segments, sr, scaler, target_width):
    processed_tensors = []
    instances_preprocessed = []
    for segment in segments:
        raw_spect = extract_mel_from_signal(segment, sr, n_mels=64)
        if raw_spect is None:
            continue
        if raw_spect.shape[1] != target_width:
            raw_spect = cv2.resize(raw_spect, (target_width, 64), interpolation=cv2.INTER_LINEAR)
        try:
            tensor = preprocess_spectrogram(raw_spect, scaler)
            processed_tensors.append(tensor)
            instances_preprocessed.append(tensor.detach().cpu().numpy().tolist())
        except ValueError:
            continue
    return processed_tensors, instances_preprocessed


def evaluate_model(model, processed_tensors):
    batch_input = torch.stack(processed_tensors).squeeze(1)
    with torch.no_grad():
        outputs = model(batch_input)
        probs = F.softmax(outputs, dim=1)
        confidences = probs.cpu().numpy()
    return confidences


def classify(confidences):

    probs_class_1 = confidences[:, 1]
    avg_prob_class_1 = float(np.mean(probs_class_1))
    final_pred = 1 if avg_prob_class_1 >= 0.65 else 0
    scores = probs_class_1.tolist()
    status = "zmanipulowane" if final_pred == 1 else "autentyczne"
    avg_prob = avg_prob_class_1 if final_pred == 1 else 1 - avg_prob_class_1

    if avg_prob < 0.65:
        confidence = "mała"
    elif avg_prob < 0.75:
        confidence = "średnia"
    else:
        confidence = "duża"
    result = f"Nagranie jest {status} – pewność: {confidence}"

    return final_pred, avg_prob, result, scores


def get_result_ResNet(file_path, model_name, model_folder=MODEL_DIR, scaler_file=SCALER_DIR,
                      model_class=AntiSpoofingResNet, target_sr=1600, target_width=63):

    device = 'cuda' if torch.cuda.is_available() else 'cpu'
    init_preloaded_models(model_folder=model_folder, scaler_file=scaler_file, model_class=model_class)
    scaler = PRELOADED_SCALER
    model = PRELOADED_MODELS.get(model_name)
    if scaler is None or model is None:
        model_file = select_model_name(model_name)
        scaler, model = load_model_and_scaler(model_file, model_folder, scaler_file, model_class, device)

    if scaler is None:
        return None

    y, sr, description = load_and_resample_audio(file_path, target_sr)

    segments = split_into_segments(y, sr)
    processed_tensors, instances_preprocessed = process_segments(segments, sr, scaler, target_width)

    if not processed_tensors:
        return 0.0, "Błąd: Nie udało się przetworzyć żadnego fragmentu", description, [], []

    confidences = evaluate_model(model, processed_tensors)
    final_pred, avg_prob, result, scores = classify(confidences)

    description = get_audio_info(y, sr, final_pred, avg_prob, file_path)

    return avg_prob, result, description, scores, instances_preprocessed


