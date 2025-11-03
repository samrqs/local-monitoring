from django.urls import path
from .views import weather_report, list_reports

urlpatterns = [
    path("weather-report/", weather_report),
    path("weather-report/history/<str:city>/", list_reports),
]