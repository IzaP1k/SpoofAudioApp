from django.urls import path
from . import views

urlpatterns = [
    path("save/", views.save_analysis),
    path("delete/", views.delete_analysis),
    path("get/", views.get_analysis),
]
