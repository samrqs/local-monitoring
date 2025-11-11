import os
import json
import pytz
import requests

from django.urls import reverse
from django.http import JsonResponse,FileResponse
from django.views.decorators.csrf import csrf_exempt
from django.conf import settings

from .models import WeatherReport
from .services import get_weather_data, get_air_pollution_data, get_air_pollution_history_data
from .reports import generate_weather_report


@csrf_exempt
def weather_report(request):
    
    if request.method != "POST":
        return JsonResponse({"error": "Método não permitido. Use POST."}, status=405)

    try:
        body = json.loads(request.body.decode("utf-8"))
        lat = body.get("lat")
        lon = body.get("lon")

        if lat is None or lon is None:
            return JsonResponse({"error": "Campos 'lat' e 'lon' são obrigatórios."}, status=400)

        data = get_weather_data(float(lat), float(lon))
        pollution = get_air_pollution_data(lat, lon)
        data["pollution"] = pollution
        report_path = generate_weather_report(data)
        report_url = f"/data/reports/{os.path.basename(report_path)}"

        WeatherReport.objects.create(
            city=data["city"],
            latitude=data["latitude"],
            longitude=data["longitude"],
            file_path=report_path
        )

        return JsonResponse({
            "city": data.get("city"),
            "report_url": report_url,
            "data": data
        })

    except json.JSONDecodeError:
        return JsonResponse({"error": "JSON inválido no corpo da requisição."}, status=400)

    except Exception as e:
        return JsonResponse({"error": str(e)}, status=500)

@csrf_exempt
def get_pollution(request):
    """
    Se receber apenas lat/lon → poluição atual
    Se receber start e end → histórico de poluição
    """
    if request.method != "POST":
        return JsonResponse({"error": "Use POST"}, status=405)

    body = json.loads(request.body)

    lat = body.get("lat")
    lon = body.get("lon")
    start = body.get("start")  # timestamp UNIX (segundos)
    end = body.get("end")      # timestamp UNIX (segundos)

    if lat is None or lon is None:
        return JsonResponse({"error": "Campos 'lat' e 'lon' são obrigatórios."}, status=400)

    if start and end:
        data = get_air_pollution_history_data(lat, lon, start, end)
        if data is None:
            return JsonResponse({"error": "Não foi possível obter histórico."}, status=500)

        return JsonResponse({"type": "history", "data": data}, safe=False)

    data = get_air_pollution_data(lat, lon)
    if data is None:
        return JsonResponse({"error": "Não foi possível obter dados atuais."}, status=500)

    return JsonResponse({"type": "current", "data": data}, safe=False)

@csrf_exempt
def list_reports(request, city):
    """
    Retorna todos os PDFs gerados para uma cidade, com link para download.
    """
    if request.method != "GET":
        return JsonResponse({"error": "Método não permitido. Use GET."}, status=405)
    
    reports = WeatherReport.objects.filter(city__iexact=city).order_by("-generated_at")
    tz = pytz.timezone("America/Sao_Paulo")

    data = []
    for r in reports:

        download_path = reverse("download_report", args=[r.id])
        full_url = request.build_absolute_uri(download_path)

        data.append({
            "id": r.id,
            "city": r.city,
            "generated_at": r.generated_at.astimezone(tz).strftime("%d/%m/%Y %H:%M"),
            "download_url": full_url
        })

    return JsonResponse(data, safe=False)

@csrf_exempt
def pollution_history(request):
    if request.method != "GET":
        return JsonResponse({"error": "Método não permitido. Use GET."}, status=405)

    lat = request.GET.get("lat")
    lon = request.GET.get("lon")
    start = request.GET.get("start")
    end = request.GET.get("end")

    if not lat or not lon or not start or not end:
        return JsonResponse({"error": "Parâmetros obrigatórios: lat, lon, start, end"}, status=400)

    url = (
        f"https://api.openweathermap.org/data/2.5/air_pollution/history"
        f"?lat={lat}&lon={lon}&start={start}&end={end}&appid={settings.OPENWEATHER_API_KEY}"
    )

    response = requests.get(url, timeout=10)

    if response.status_code != 200:
        return JsonResponse({"error": "Erro ao consultar API externa", "details": response.text}, status=500)

    data = response.json()

    formatted = []
    for item in data.get("list", []):
        c = item.get("components", {})
        formatted.append({
            "timestamp": item.get("dt"),
            "aqi": item.get("main", {}).get("aqi", 0),
            "pm2_5": c.get("pm2_5", 0),
            "pm10": c.get("pm10", 0),
            "o3": c.get("o3", 0),
            "no2": c.get("no2", 0),
            "so2": c.get("so2", 0),
            "co": c.get("co", 0),
        })

    return JsonResponse({"data": formatted}, safe=False)

@csrf_exempt
def download_report(request, report_id):
    try:
        report = WeatherReport.objects.get(id=report_id)
    except WeatherReport.DoesNotExist:
        return JsonResponse({"error": "Relatório não encontrado."}, status=404)

    filepath = report.file_path

    if not os.path.isfile(filepath):
        return JsonResponse({"error": "Arquivo não encontrado no servidor."}, status=404)

    filename = os.path.basename(filepath)
    response = FileResponse(open(filepath, "rb"), content_type="application/pdf")
    response["Content-Disposition"] = f'attachment; filename="{filename}"'
    return response