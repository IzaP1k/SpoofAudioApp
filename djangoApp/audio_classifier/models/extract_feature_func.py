import numpy as np
import librosa
from scipy.fftpack import dct
from scipy.interpolate import interp1d

def extract_mel_spectrogram(filepath, sr=None, n_mels=64, fmax=None, mean=False):
    try:
        y, sr = librosa.load(filepath, sr=sr)
        S = librosa.feature.melspectrogram(y=y, sr=sr, n_mels=n_mels, fmax=fmax or sr / 2)
        S_db = librosa.power_to_db(S, ref=np.max)

        return np.mean(S_db, axis=1) if mean else S_db
    except Exception as e:

        print(f"[BŁĄD MEL] {filepath}: {e}")

        return None

def extract_cqcc_from_signal(y, sr, bins_per_octave=12, n_ceps=19, mean=False):
    try:

        fmin = librosa.note_to_hz('C1')
        fmax = sr / 2 - 100
        n_bins = int(np.floor(np.log2(fmax / fmin)) * bins_per_octave)

        # CQT
        cqt = librosa.cqt(y, sr=sr, n_bins=n_bins, bins_per_octave=bins_per_octave, fmin=fmin)
        cqt_mag = np.abs(cqt)
        cqt_db = librosa.amplitude_to_db(cqt_mag, ref=np.max)

        original_freqs = librosa.cqt_frequencies(n_bins=n_bins, fmin=fmin, bins_per_octave=bins_per_octave)
        lin_freqs = np.linspace(original_freqs.min(), original_freqs.max(), num=n_bins)

        interp_cqt = np.zeros_like(cqt_db)

        for t in range(cqt_db.shape[1]):
            interp_func = interp1d(original_freqs, cqt_db[:, t], kind='linear', fill_value="extrapolate")
            interp_cqt[:, t] = interp_func(lin_freqs)

        # CQCC
        log_power = np.log(np.square(interp_cqt) + 1e-12)
        cqcc_coeffs = dct(log_power, type=2, axis=0, norm='ortho')[:n_ceps, :]

        if mean:
            return np.mean(cqcc_coeffs, axis=1)
        return cqcc_coeffs

    except Exception as e:
        print(f"BŁĄD CQCC: {e}")
        return None