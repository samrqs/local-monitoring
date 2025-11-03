import requests
from django.conf import settings

def get_weather_data(lat: float, lon: float):

    if not settings.OPENWEATHER_API_KEY:
        raise ValueError("OPENWEATHER_API_KEY não configurada no .env")

    url = (
        f"https://api.openweathermap.org/data/2.5/weather?"
        f"lat={lat}&lon={lon}&appid={settings.OPENWEATHER_API_KEY}&units=metric&lang=pt_br"
    )

    res = requests.get(url, timeout=10)
    res.raise_for_status()
    data = res.json()

    return {
        "latitude": lat,
        "longitude": lon,
        "city": data.get("name", "Desconhecida"),
        "temperature": data["main"]["temp"],
        "humidity": data["main"]["humidity"],
        "pressure": data["main"]["pressure"],
        "wind_speed": data["wind"]["speed"],
        "weather": data["weather"][0]["description"].capitalize(),
        "air_quality_index": estimate_air_quality(data["main"]["humidity"], data["wind"]["speed"])
    }


def estimate_air_quality(humidity, wind_speed):
    
    if humidity > 80:
        return "Alta"
    elif wind_speed < 1:
        return "Moderada"
    else:
        return "Baixa"
