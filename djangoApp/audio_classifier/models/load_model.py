import os
import pickle
import librosa
import torch
import joblib
import pandas as pd
import numpy as np

from .models_architecture import BiLSTMClassifier

MODEL_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "GMM-BiLSTM")

def return_db_description(y, sr):

    duration = librosa.get_duration(y=y, sr=sr)
    rms = float(np.sqrt(np.mean(y ** 2)))
    loudness_db = 20 * np.log10(rms + 1e-9)
    clipped_ratio = np.mean(np.abs(y) > 0.99)

    if loudness_db > -3:
        loudness_level = "przesterowane"
    elif loudness_db > -10:
        loudness_level = "bardzo głośne"
    elif loudness_db > -20:
        loudness_level = "średnie"
    elif loudness_db > -35:
        loudness_level = "ciche"
    else:
        loudness_level = "bardzo ciche"

    try:
        f0, voiced_flag, voiced_probs = librosa.pyin(y, fmin=50, fmax=500)
        dominant_freq = np.nanmedian(f0)
    except Exception:
        dominant_freq = np.nan

    return loudness_db, loudness_level, dominant_freq, clipped_ratio, duration

def transpose_cqcc(x):
    
    arr = np.array(x)
    
    if arr.ndim == 1:
        return arr[:, np.newaxis]
    elif arr.ndim == 2:
        if arr.shape[0] < arr.shape[1]:
            return arr.T
        else:
            return arr
    else:
        return None

def filtr_nan(final_df, col_name="cqcc"):
    
    initial_len = len(final_df)
    final_df = final_df[final_df[col_name].notnull()]
    if len(final_df) < initial_len:
        raise ValueError("Pełno nulli!")
    return final_df

def prepare_data_GMM_BiLSTM(df, feature_col="cqcc", transpose_func=transpose_cqcc):
    
    df = filtr_nan(df.copy())
    df[feature_col] = df[feature_col].apply(transpose_func)
    return df

def compute_llr(features, gmm1, gmm2):
    
    ll1 = gmm1.score(features)
    ll2 = gmm2.score(features)
    return ll1 - ll2

def fused_score(model, x_tensor, features_np, gmm_genuine, gmm_df):
    device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
    model.eval()

    with torch.no_grad():
        # BiLSTM
        x_tensor_gpu = x_tensor.unsqueeze(0).to(device)
        bi_lstm_output = model(x_tensor_gpu)
        bi_lstm_prob = torch.softmax(bi_lstm_output, dim=1).detach().cpu().tolist()[0][1]


        # GMM
        gmm_llr = compute_llr(features_np, gmm_genuine, gmm_df)
        gmm_prob = 1 / (1 + np.exp(-gmm_llr))

        return 0.5 * bi_lstm_prob + 0.5 * gmm_prob

def load_bilstm_model(input_dim, model_dir=MODEL_DIR):
    
    model = BiLSTMClassifier(input_dim=input_dim)
    model_path = os.path.join(model_dir, "bilstm_model.pt")

    if not os.path.exists(model_path):
        raise FileNotFoundError(f"Nie znaleziono pliku modelu BiLSTM: {model_path}")

    model.load_state_dict(torch.load(model_path, map_location=torch.device('cpu')))

    return model


def load_gmm_models(model_dir=MODEL_DIR, ubm_model="ubm.pkl", gmm_genuine_model="gmm_genuine.pkl", gmm_df_name="gmm_df.pkl"):

    ubm_path = os.path.join(model_dir, ubm_model)
    genuine_path = os.path.join(model_dir, gmm_genuine_model)
    df_path = os.path.join(model_dir, gmm_df_name)

    for name, path in [("UBM", ubm_path), ("Genuine", genuine_path), ("DF", df_path)]:
        if not os.path.exists(path):
            raise FileNotFoundError(f"Nie znaleziono pliku modelu {name}: {path}")

    with open(ubm_path, "rb") as f:
        ubm = pickle.load(f)
    with open(genuine_path, "rb") as f:
        gmm_genuine = pickle.load(f)
    with open(df_path, "rb") as f:
        gmm_df = pickle.load(f)

    return ubm, gmm_genuine, gmm_df

def test_model_GMM_BiLSTM(
        instance_cqcc,  # (19, okna)
        model_dir=MODEL_DIR,
        label_col="label",
        feature_col="cqcc",
        transpose_func=None,
        scaler_file="scaler.pkl",
        frame_len_sec=2,
        frame_step_sec=2):

    try:
        if transpose_func is None:
            transpose_func = lambda x: x.T

        scaler_path = os.path.join(model_dir, scaler_file)
        if not os.path.exists(scaler_path):
            raise FileNotFoundError(f"Brak pliku skalera: {scaler_path}")
        scaler = joblib.load(scaler_path)

        input_dim = instance_cqcc.shape[0]

        if input_dim != 19:
            raise ValueError(f"Niepoprawna liczba cech: {input_dim}, oczekiwano 19")

        bilstm_model = load_bilstm_model(input_dim=input_dim, model_dir=model_dir)
        _, gmm_genuine, gmm_df = load_gmm_models(model_dir=model_dir)

        total_frames = instance_cqcc.shape[1]
        frames_per_segment = int(frame_len_sec * (total_frames / frame_len_sec))
        step_frames = int(frame_step_sec * (total_frames / frame_step_sec))

        if total_frames < frames_per_segment:
            raise ValueError("Nagranie krótsze niż 2 sekundy!")

        segments = []
        start = 0
        while start < total_frames:
            end = start + frames_per_segment
            seg = instance_cqcc[:, start:end]
            if seg.shape[1] < frames_per_segment:
                seg = instance_cqcc[:, -frames_per_segment:]
            segments.append(seg)
            start += step_frames
            if end >= total_frames:
                break

        scores = []
        instances_preprocessed = []
        for seg in segments:
            df = pd.DataFrame({feature_col: [seg], label_col: [0]})
            df = prepare_data_GMM_BiLSTM(df, feature_col=feature_col, transpose_func=transpose_func)
            df[feature_col] = df[feature_col].apply(lambda x: scaler.transform(x))

            instance_preprocessed = df[feature_col].iloc[0]
            seg_tensor = torch.tensor(instance_preprocessed, dtype=torch.float32)

            score = fused_score(bilstm_model, seg_tensor, instance_preprocessed, gmm_genuine, gmm_df)
            instances_preprocessed.append(instance_preprocessed)
            scores.append(score)

        scores = np.array(scores)
        pred_class = int(np.round(np.median(scores)))
        confidence = float(np.mean([1 - s if pred_class == 1 else s for s in scores]))

        scores_list = scores.tolist()
        instances_serializable = [inst.tolist() if isinstance(inst, np.ndarray) else inst for inst in
                                  instances_preprocessed]

        return confidence, pred_class, scores_list, instances_serializable

    except Exception as e:
        raise e

"""
ResNet
"""


def preprocess_spectrogram(spectrogram_raw, scaler):
    x = spectrogram_raw.numpy() if isinstance(spectrogram_raw, torch.Tensor) else spectrogram_raw
    x_scaled = scaler.transform(x)

    if x_scaled.ndim == 1:
        x_scaled = x_scaled[np.newaxis, :, np.newaxis]
    elif x_scaled.ndim == 2:
        x_scaled = x_scaled[np.newaxis, :, :]

    input_tensor = torch.tensor(x_scaled, dtype=torch.float32).unsqueeze(0)
    input_tensor.requires_grad = True

    return input_tensor

def load_resources(model_folder, scaler_filename):
    path = os.path.join(model_folder, scaler_filename)
    try:
        return joblib.load(path)
    except FileNotFoundError:
        return None

def load_model_weights(model_class, weight_path, device='cpu'):
    model = model_class(num_classes=2)
    model.load_state_dict(torch.load(weight_path, map_location=device))
    model.to(device)
    model.eval()
    return model

def load_audio_description(file_path, sr=16000):
    y, sr = librosa.load(file_path, sr=sr)

    
    loudness_db, loudness_level, dominant_freq, clipped_ratio, duration = return_db_description(y, sr)

    description = {"duration": duration,
                   "dominant_freq": dominant_freq,
                   "loudness_level": loudness_level,
                   "clipped_ratio": clipped_ratio}

    return y, sr, description


def extract_mel_from_signal(y, sr, n_mels=64, fmax=None, mean=False):

    try:

        S = librosa.feature.melspectrogram(y=y, sr=sr, n_mels=n_mels, fmax=fmax or sr / 2)
        S_db = librosa.power_to_db(S, ref=np.max)

        if mean:
            return np.mean(S_db, axis=1)
        return S_db

    except Exception as e:

        return None


