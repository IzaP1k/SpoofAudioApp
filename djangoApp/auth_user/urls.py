from django.urls import path
from .views import RegisterView, UserRecordView, ChangePasswordView

app_name = 'auth'

urlpatterns = [
    path('register/', RegisterView.as_view(), name='register'),
    path('user/', UserRecordView.as_view(), name='users'),
    path('change-password/', ChangePasswordView.as_view(), name='change_password'),
]
