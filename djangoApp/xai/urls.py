from django.urls import path
from . import views

urlpatterns = [
    path("analyse_xai/", views.analyse_xai, name="analyse_xai"),
]