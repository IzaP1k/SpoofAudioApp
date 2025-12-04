import json
import os
import torch
import traceback
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from audio_classifier.models.models_architecture import AntiSpoofingResNet
from audio_classifier.models.load_model import load_model_weights
from xai.xai_func import run_xai_analysis

current_path = os.path.abspath(__file__)
xai_dir = os.path.dirname(current_path)
base_app_dir = os.path.dirname(xai_dir)
MODEL_DIR = os.path.join(base_app_dir, "audio_classifier", "models", "Res_Net")

@csrf_exempt
def analyse_xai(request):
    if request.method != 'POST':
        return JsonResponse({"error": "Only POST method allowed"}, status=405)

    try:
        data = json.loads(request.body)
        instances = data.get("listInstances_preprocessed", [])
        scores = data.get("listScores", [])
        model_name = data.get("model", "best_model_1.pt")

        if model_name == "model_1":
            model_name = "best_model_1.pt"
        else:
            model_name = "best_model_2.pt"

        device = 'cuda' if torch.cuda.is_available() else 'cpu'
        full_model_path = os.path.join(MODEL_DIR, model_name)
        model = load_model_weights(AntiSpoofingResNet, full_model_path, device=device)
        results = run_xai_analysis(model, instances, scores, device)

        return JsonResponse(results)

    except Exception as e:

        traceback.print_exc()
        return JsonResponse({"error": str(e)}, status=500)
