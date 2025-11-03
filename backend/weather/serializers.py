from rest_framework import serializers
from .models import WeatherReport

class WeatherReportSerializer(serializers.ModelSerializer):
    class Meta:
        model = WeatherReport
        fields = ["city", "latitude", "longitude", "generated_at", "file_path"]
