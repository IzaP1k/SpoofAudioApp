from django.db import models
import random
import numpy as np
import librosa

def prepare_description(filename, file_path):

    y, sr = librosa.load(file_path, sr=None)

    duration = librosa.get_duration(y=y, sr=sr)
    mean_val = float(np.mean(y))
    min_val = float(np.min(y))
    max_val = float(np.max(y))
    rms = float(np.sqrt(np.mean(y ** 2)))

    description = (f"Plik: {filename}, Format: {filename.split('.')[-1].upper()}, Szczegóły: długość {duration}, "
                   f"średnia {mean_val}, minimalnie {min_val}, maksymalnie {max_val}, średnia moc sygnału {rms}")

    return description

def handle_model():

    result_text = random.choice(['Nagranie autentyczne', 'Nagranie spreparowany'])
    confidence = random.uniform(0, 1)

    return result_text, confidence
