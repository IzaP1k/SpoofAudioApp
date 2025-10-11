from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.core.files.storage import FileSystemStorage
from .analyse_func import prepare_description, handle_model
from pydub import AudioSegment
import os

import random

def record_audio(request):
    print("Otrzymano ", request.method)

    return None

@csrf_exempt
def upload_file(request):
    if request.method == "POST":
        audio_file = request.FILES.get("file")

        if not audio_file:
            print("Brak pliku w żądaniu!")
            return JsonResponse({"error": "Brak pliku"}, status=400)

        fs = FileSystemStorage()
        filename = fs.save(audio_file.name, audio_file)
        file_path = fs.path(filename)

        print(f"Otrzymano plik: {filename}")

        file_ext = os.path.splitext(filename)[1].lower()

        if file_ext == ".m4a":
            try:
                wav_filename = filename.replace(".m4a", ".wav")
                wav_path = fs.path(wav_filename)

                print("Konwersja pliku .m4a → .wav...")
                sound = AudioSegment.from_file(file_path, format="m4a")
                sound.export(wav_path, format="wav")

                file_path = wav_path
                filename = wav_filename
                print(f"Konwersja zakończona: {wav_filename}")
            except Exception as e:
                print(f"Błąd podczas konwersji: {e}")
                return JsonResponse({"error": "Nie udało się przekonwertować pliku .m4a"}, status=500)

        image_url = None

        result_text, confidence = handle_model()

        description = prepare_description(filename, file_path)

        return JsonResponse({
            "message": "Analiza zakończona",
            "file_url": fs.url(filename),
            "result": {
                "label": result_text,
                "confidence": confidence,
                "description": description,
                "image_url": image_url,
            }
        })

    return JsonResponse({"error": "Tylko POST"}, status=405)