from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from django.http import JsonResponse
import base64
import logging
from rest_framework.response import Response

from .models import AnalysisRecord
from datetime import datetime

logger = logging.getLogger(__name__)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def save_analysis(request):
    print("przed try")
    try:

        data = request.data

        result_text = data.get("result_text")
        description = data.get("description")
        audio_base64 = data.get("audio_bytes")
        instances = data.get("instances")
        scores = data.get("scores")
        model = data.get("model")
        delete_oldest = data.get("delete_oldest", False)  # nowy parametr z frontu

        if not all([result_text, description, audio_base64, instances, scores]):
            return JsonResponse({"error": "Missing fields"}, status=400)

        user_records = AnalysisRecord.objects.filter(user=request.user).order_by('created_at')
        existing_count = user_records.count()

        # 🔹 limit 4 analiz
        if existing_count >= 4:
            if delete_oldest:
                # usuń najstarszy rekord
                oldest = user_records.first()
                oldest.delete()
            else:
                # poinformuj front o limicie
                return JsonResponse({
                    "error": "limit_reached",
                    "message": "Masz już 4 zapisane analizy. Czy chcesz usunąć najstarszą?"
                }, status=400)

        audio_bytes = base64.b64decode(audio_base64)
        print("Przed save")
        record = AnalysisRecord.objects.create(
            user=request.user,
            result_text=result_text,
            description=description,
            audio_file=audio_bytes,
            instances=instances,
            scores=scores,
            model=model
        )

        return JsonResponse({"status": "ok", "id": record.id})

    except Exception as e:
        print(e)
        return JsonResponse({"error": str(e)}, status=500)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def get_analysis(request):
    try:
        user = request.user

        records = AnalysisRecord.objects.filter(user=user).order_by('-created_at')
        data = [
            {
                "result_text": record.result_text,
                "description": record.description,
                "audio_file": base64.b64encode(record.audio_file).decode('utf-8'),
                "instances": record.instances,
                "scores": record.scores,
                "model": record.model,
                "created_at": record.created_at.strftime("%d.%m.%Y %H:%M"),

            }
            for record in records
        ]

        return JsonResponse({"status": "ok", "records": data})
    except Exception as e:
        print(e)
        return JsonResponse({"error": str(e)}, status=500)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def delete_analysis(request):
    data = request.data
    description = data.get('description')

    if not description:
        return Response({'error': 'Brak description'}, status=400)

    try:
        user = request.user

        # Szukamy rekordu w tabeli AnalysisRecord
        analyses = AnalysisRecord.objects.filter(user=user, description=description)

        if analyses.exists():
            count = analyses.count()
            analyses.delete()  # <- usuwa rekordy
            logger.info(f'Usunięto {count} rekord(y) dla użytkownika {user.username}')
            return Response({'message': f'Usunięto {count} rekord(y) z historii!'}, status=200)
        else:
            return Response({'message': 'Nie znaleziono rekordu.'}, status=404)

    except Exception as e:
        logger.error(f'Błąd w delete_analysis: {e}')
        return Response({'error': 'Wystąpił błąd serwera.'}, status=500)

