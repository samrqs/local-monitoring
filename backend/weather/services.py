import requests
import pytz

from datetime import datetime

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

    weather = data.get("weather", [{}])[0]  
    tz = pytz.timezone("America/Sao_Paulo")

    sunrise = datetime.fromtimestamp(data.get("sys", {}).get("sunrise"), tz)
    sunset  = datetime.fromtimestamp(data.get("sys", {}).get("sunset"), tz)

    return {
        "latitude": lat,
        "longitude": lon,
        "city": data.get("name", "Desconhecida"),
        "temperature": data.get("main", {}).get("temp"),
        "feels_like": data.get("main", {}).get("feels_like"),
        "humidity": data.get("main", {}).get("humidity"),
        "wind_speed": data.get("wind", {}).get("speed"),
        "pressure": data.get("main", {}).get("pressure"),
        "description": weather.get("description"),
        "icon": weather.get("icon"),
        "sunrise": sunrise.strftime("%H:%M:%S"),
        "sunset": sunset.strftime("%H:%M:%S")
    }