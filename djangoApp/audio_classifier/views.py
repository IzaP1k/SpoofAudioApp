from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.core.files.storage import FileSystemStorage
from .analyse_func import get_result_ResNet
import os

def record_audio(request):
    print("Otrzymano ", request.method)

    return None

@csrf_exempt
def upload_file(request):
    if request.method == "POST":
        audio_file = request.FILES.get("file")
        model_name = request.POST.get("model")

        if not audio_file:
            return JsonResponse({"error": "Brak pliku"}, status=400)

        fs = FileSystemStorage()
        filename = fs.save(audio_file.name, audio_file)
        file_path = fs.path(filename)

        file_ext = os.path.splitext(filename)[1].lower()
        image_url = None

        confidence, result_text, description, scores, instances_preprocessed = get_result_ResNet(
            file_path, model_name=model_name
        )

        try:
            media_dir = fs.location
            for f in os.listdir(media_dir):
                fp = os.path.join(media_dir, f)
                if os.path.isfile(fp):
                    os.remove(fp)
        except:
            pass

        return JsonResponse({
            "message": "Analiza zakończona",
            "result": {
                "label": result_text,
                "confidence": confidence,
                "description": description,
                "image_url": image_url,
                "scores": scores,
                "instances_preprocessed": instances_preprocessed
            }
        })

    return JsonResponse({"error": "Tylko POST"}, status=405)
