from django.urls import path
from .views import RegisterView, UserRecordView

app_name = 'auth'

urlpatterns = [
    path('register/', RegisterView.as_view(), name='register'),
    path('user/', UserRecordView.as_view(), name='users'),
]
