from django.db import models
from django.contrib.auth.models import User


class AnalysisRecord(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="analysis_records")

    result_text = models.TextField()
    description = models.TextField()
    model = models.TextField()
    audio_file = models.BinaryField()
    instances = models.JSONField()
    scores = models.JSONField()
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.user.username} – analysis {self.id} ({self.created_at})"

