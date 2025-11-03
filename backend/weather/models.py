from django.db import models

class WeatherReport(models.Model):
    city = models.CharField(max_length=100)
    latitude = models.FloatField()
    longitude = models.FloatField()
    generated_at = models.DateTimeField(auto_now_add=True)
    file_path = models.CharField(max_length=300)

    class Meta:
        ordering = ["-generated_at"]

    def __str__(self):
        return f"{self.city} - {self.generated_at.strftime('%d/%m/%Y %H:%M')}"
