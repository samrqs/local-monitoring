import os
import json

from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.conf import settings

from .services import get_weather_data
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
        report_path = generate_weather_report(data)
        report_url = f"/data/reports/{os.path.basename(report_path)}"

        return JsonResponse({
            "city": data.get("city"),
            "report_url": report_url,
            "data": data
        })

    except json.JSONDecodeError:
        return JsonResponse({"error": "JSON inválido no corpo da requisição."}, status=400)

    except Exception as e:
        return JsonResponse({"error": str(e)}, status=500)