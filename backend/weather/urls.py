from django.urls import path
from .views import weather_report, list_reports, get_pollution, pollution_history,download_report

urlpatterns = [
    path("weather-report/", weather_report),
    path("weather-report/history/<str:city>/", list_reports),
    path("pollution/", get_pollution),
    path("pollution/history/", pollution_history, name="pollution_history"),
    path("weather-report/download/<int:report_id>/", download_report, name="download_report"),
]