from django.contrib import admin
from django.urls import path, include
from rest_framework.authtoken import views as drf_views
from django.conf import settings
from django.conf.urls.static import static

urlpatterns = [
    path('admin/', admin.site.urls),
    path('auth/', include('auth_user.urls', namespace='auth')),
    path('api-token-auth/', drf_views.obtain_auth_token, name='api-token-auth'),
    path('upload/', include('audio_classifier.urls', namespace='upload')),
    path("xai/", include("xai.urls")),
    path("analysis/", include("manage_database.urls")),



] + static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
