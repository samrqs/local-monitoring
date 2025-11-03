from django.urls import path
from .views import weather_report

urlpatterns = [
    path("weather-report/", weather_report),
]