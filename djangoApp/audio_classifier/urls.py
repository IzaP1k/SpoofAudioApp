from django.urls import path
from . import views

app_name = "upload"


urlpatterns = [
    path('file/', views.upload_file, name='upload_file'),
    path('record/', views.record_audio, name='record_audio'),
]