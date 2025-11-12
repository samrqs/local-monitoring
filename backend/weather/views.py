import os
import json
import pytz
import requests

from datetime import datetime
from django.urls import reverse
from django.http import JsonResponse, FileResponse
from django.views.decorators.csrf import csrf_exempt
from django.conf import settings

from .models import WeatherReport
from .services import (
    get_weather_data,
    get_air_pollution_data,
    get_air_pollution_history_data,
)
from .reports import generate_weather_report


@csrf_exempt
def get_weather(request):
    """Retorna dados climáticos atuais para o app Flutter"""
    if request.method != "GET":
        return JsonResponse({"error": "Use GET"}, status=405)

    lat = request.GET.get("lat")
    lon = request.GET.get("lon")

    if not lat or not lon:
        return JsonResponse({"error": "Parâmetros obrigatórios: lat e lon"}, status=400)

    try:
        data = get_weather_data(float(lat), float(lon))
        return JsonResponse(data, safe=False)
    except Exception as e:
        return JsonResponse({"error": str(e)}, status=500)


@csrf_exempt
def get_pollution(request):
    if request.method != "GET":
        return JsonResponse({"error": "Use GET"}, status=405)

    lat = request.GET.get("lat")
    lon = request.GET.get("lon")

    if not lat or not lon:
        return JsonResponse({"error": "Campos 'lat' e 'lon' são obrigatórios."}, status=400)

    data = get_air_pollution_data(float(lat), float(lon))
    if data is None:
        return JsonResponse({"error": "Não foi possível obter dados atuais."}, status=500)

    return JsonResponse({"data": data}, safe=False)


@csrf_exempt
def pollution_history(request):
    """Endpoint direto GET compatível com o Flutter ApiService"""
    if request.method != "GET":
        return JsonResponse({"error": "Use GET"}, status=405)

    lat = request.GET.get("lat")
    lon = request.GET.get("lon")
    start = request.GET.get("start")
    end = request.GET.get("end")

    if not lat or not lon:
        return JsonResponse({"error": "Parâmetros obrigatórios: lat e lon"}, status=400)

    # Se o app não enviar start/end, gera automaticamente as últimas 24h
    if not start or not end:
        now = datetime.utcnow()
        end = int(now.timestamp())
        start = int((now.timestamp()) - 86400)

    if not settings.OPENWEATHER_API_KEY:
        return JsonResponse({"error": "OPENWEATHER_API_KEY não configurada"}, status=500)

    try:
        data = get_air_pollution_history_data(float(lat), float(lon), int(start), int(end))
        if data is None:
            return JsonResponse({"error": "Nenhum dado encontrado"}, status=404)

        return JsonResponse({"list": data})
    except Exception as e:
        return JsonResponse({"error": str(e)}, status=500)


@csrf_exempt
def weather_report(request):
    if request.method != "POST":
        return JsonResponse({"error": "Use POST"}, status=405)

    try:
        body = json.loads(request.body.decode("utf-8"))
        lat = body.get("latitude") or body.get("lat")
        lon = body.get("longitude") or body.get("lon")

        if lat is None or lon is None:
            return JsonResponse({"error": "Campos 'lat' e 'lon' são obrigatórios."}, status=400)

        # 🔹 Obtem dados
        data = get_weather_data(float(lat), float(lon))
        pollution = get_air_pollution_data(lat, lon)
        data["pollution"] = pollution

        # 🔹 Gera PDF
        report_path = generate_weather_report(data)

        # 🔹 Cria no banco
        report = WeatherReport.objects.create(
            city=data["city"],
            latitude=data["latitude"],
            longitude=data["longitude"],
            file_path=report_path,
        )

        # 🔹 Cria URL completa de download
        from django.urls import reverse  # garante import local
        download_url = request.build_absolute_uri(
            reverse("download_report", args=[report.id])
        )

        return JsonResponse({
            "status": "ok",
            "city": data.get("city"),
            "download_url": download_url,
            "data": data,
        })

    except Exception as e:
        import traceback
        print(traceback.format_exc())
        return JsonResponse({"error": str(e)}, status=500)


@csrf_exempt
def list_reports(request, city):
    if request.method != "GET":
        return JsonResponse({"error": "Use GET"}, status=405)

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
            "download_url": full_url,
        })

    return JsonResponse(data, safe=False)


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
