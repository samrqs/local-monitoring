import requests
import pytz
import time

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
    sunset = datetime.fromtimestamp(data.get("sys", {}).get("sunset"), tz)

    return {
        "latitude": lat,
        "longitude": lon,
        "city": data.get("name", "Desconhecida"),
        "temperatura": data.get("main", {}).get("temp"),
        "sensacao": data.get("main", {}).get("feels_like"),
        "umidade": data.get("main", {}).get("humidity"),
        "vento": data.get("wind", {}).get("speed"),
        "pressao": data.get("main", {}).get("pressure"),
        "descricao": weather.get("description"),
        "icone": weather.get("icon"),
        "nascer_sol": sunrise.strftime("%H:%M:%S"),
        "por_sol": sunset.strftime("%H:%M:%S"),
    }

def get_air_pollution_data(lat: float, lon: float):

    if not settings.OPENWEATHER_API_KEY:
        raise ValueError("OPENWEATHER_API_KEY não configurada no .env")

    url = (
        f"https://api.openweathermap.org/data/2.5/air_pollution"
        f"?lat={lat}&lon={lon}&appid={settings.OPENWEATHER_API_KEY}"
    )

    res = requests.get(url, timeout=10)

    if res.status_code != 200:
        return None

    res.raise_for_status()
    data = res.json()["list"][0]
    comp = data["components"]
    return {
        "aqi": data["main"]["aqi"],
        "pm2_5": comp.get("pm2_5", 0),
        "pm10": comp.get("pm10", 0),
        "o3": comp.get("o3", 0),
        "no2": comp.get("no2", 0),
        "so2": comp.get("so2", 0),
        "co": comp.get("co", 0),
    }

def get_air_pollution_history_data(lat: float, lon: float, start: int, end: int):
    """
    Busca histórico de poluição para intervalo de tempo (timestamps UNIX).
    """

    if not settings.OPENWEATHER_API_KEY:
        raise ValueError("OPENWEATHER_API_KEY não configurada no .env")

    start_ts = datetime.fromtimestamp(start)
    end_ts = datetime.fromtimestamp(end)

    url = "https://api.openweathermap.org/data/2.5/air_pollution/history"
    params = {
        "lat": lat,
        "lon": lon,
        "start": start,
        "end": end,
        "appid": settings.OPENWEATHER_API_KEY,
    }

    try:
        response = requests.get(url, params=params, timeout=10)
        
        response.raise_for_status()
        raw = response.json()

        history = []
        for item in raw.get("list", []):
            components = item.get("components", {})

            history.append({
                "dt": item.get("dt"),
                "aqi": item.get("main", {}).get("aqi", 0),
                "pm2_5": components.get("pm2_5", 0.0),
                "pm10": components.get("pm10", 0.0),
                "o3": components.get("o3", 0.0),
                "no2": components.get("no2", 0.0),
                "so2": components.get("so2", 0.0),
                "co": components.get("co", 0.0),
            })

        return history if history else None

    except Exception as e:
        print(f"[ERRO] get_air_pollution_history_data: {e}")
        return None
    
def date_to_timestamp(date_str):

    dt = datetime.strptime(date_str, "%Y-%m-%d")
    return int(time.mktime(dt.timetuple()))