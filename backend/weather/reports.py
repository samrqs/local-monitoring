import os
import io
import random
import pytz

import matplotlib.pyplot as plt

from datetime import datetime, timedelta

from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import cm
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, Image

from django.conf import settings

def generate_weather_report(data: dict):

    """Gera um PDF estilizado de relatório meteorológico."""

    city = data.get("city", "Desconhecida")

    tz = pytz.timezone("America/Sao_Paulo")
    now_utc = datetime.utcnow()
    now_local = now_utc.astimezone(tz)

    timestamp_display = now_local.strftime("%d/%m/%Y %H:%M")
    timestamp_filename = now_local.strftime("%Y%m%d_%H%M%S")

    safe_city = data["city"].replace(" ", "_")
    city_dir = os.path.join(settings.DATA_DIR, safe_city)
    os.makedirs(city_dir, exist_ok=True)
    filename = f"{safe_city}_{timestamp_filename}.pdf"
    filepath = os.path.join(city_dir, filename)
    os.makedirs(settings.DATA_DIR, exist_ok=True)

    doc = SimpleDocTemplate(filepath, pagesize=A4)
    elements = []
    styles = getSampleStyleSheet()

    logo_path = os.path.join(settings.BASE_DIR, "data/assets/logo.png")
    if os.path.exists(logo_path):
        logo = Image(logo_path, width=8*cm, height=8*cm)
        logo.hAlign = "CENTER"
        elements.append(logo)
    elements.append(Spacer(1, 8))

    title_style = ParagraphStyle(
        "Title",
        fontSize=20,
        alignment=1,
        textColor=colors.HexColor("#004E98"),
        spaceAfter=10,
    )
    subtitle_style = ParagraphStyle(
        "Subtitle",
        fontSize=12,
        alignment=1,
        textColor=colors.grey,
        spaceAfter=15,
    )

    elements.append(Paragraph("Relatório Ambiental Urbano", title_style))
    elements.append(Paragraph(f"Cidade: {city}", subtitle_style))

    temp_data = simulate_temperature_data(data["temperatura"], tz)
    chart_img = generate_temperature_chart(temp_data)
    chart_image = Image(chart_img, width=15*cm, height=6*cm)
    chart_image.hAlign = "CENTER"
    elements.append(chart_image)
    elements.append(Spacer(1, 20))

    table_data = [
        ["Temperatura (°C)", f"{data['temperatura']:.1f}"],
        ["Umidade (%)", f"{data['umidade']}"],
        ["Sensação (°C)", f"{data['sensacao']}"],
        ["Pressão (hPa)", f"{data['pressao']}"],
        ["Velocidade do Vento (m/s)", f"{data['vento']}"],
        ["Descrição", f"{data['descricao']}"],
        ["Nascer do Sol", f"{data['nascer_sol']}"],
        ["Por do Sol", f"{data['por_sol']}"],
        ["Latitude", f"{data['latitude']:.3f}"],
        ["Longitude", f"{data['longitude']:.3f}"],
    ]

    table = Table(table_data, colWidths=[8*cm, 8*cm])
    table.setStyle(TableStyle([
        ("BACKGROUND", (0,0), (-1,0), colors.HexColor("#004E98")),
        ("TEXTCOLOR", (0,0), (-1,0), colors.white),
        ("FONTNAME", (0,0), (-1,0), "Helvetica-Bold"),
        ("ALIGN", (0,0), (-1,-1), "CENTER"),
        ("GRID", (0,0), (-1,-1), 0.5, colors.grey),
        ("BACKGROUND", (0,1), (-1,-1), colors.whitesmoke),
    ]))
    elements.append(table)
    elements.append(Spacer(1, 20))

    pollution = data.get("pollution")
    if pollution:
        elements.append(Spacer(1, 10))

        elements.append(Paragraph("Qualidade do Ar", ParagraphStyle(
            "Header",
            fontSize=14,
            alignment=1,
            textColor=colors.HexColor("#004E98"),
            spaceAfter=8,
        )))

        air_table_data = [
            ["AQI (Índice de Qualidade do Ar)", pollution["aqi"]],
            ["PM2.5 (µg/m³)", pollution["pm2_5"]],
            ["PM10 (µg/m³)", pollution["pm10"]],
            ["Ozônio (O3)", pollution["o3"]],
            ["Dióxido de Nitrogênio (NO2)", pollution["no2"]],
            ["Dióxido de Enxofre (SO2)", pollution["so2"]],
            ["Monóxido de Carbono (CO)", pollution["co"]],
        ]

        air_table = Table(air_table_data, colWidths=[10 * cm, 6 * cm])
        air_table.setStyle(TableStyle([
            ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#004E98")),
            ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
            ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
            ("ALIGN", (0, 0), (-1, -1), "CENTER"),
            ("GRID", (0, 0), (-1, -1), 0.5, colors.grey),
            ("BACKGROUND", (0, 1), (-1, -1), colors.whitesmoke),
        ]))

        elements.append(air_table)
        elements.append(Spacer(1, 20))

    footer_style = ParagraphStyle(
        "Footer",
        fontSize=10,
        alignment=1,
        textColor=colors.grey,
    )
    elements.append(Paragraph(f"Gerado em: {timestamp_display} (horário de Brasília)", footer_style))

    doc.build(elements)
    return filepath

def simulate_temperature_data(current_temp: float, tz):

    """Gera dados simulados de temperatura nas últimas 24h com horário local."""

    base_time = datetime.utcnow().astimezone(tz)
    return [
        (base_time - timedelta(hours=i), current_temp + random.uniform(-3,3))
        for i in reversed(range(24))
    ]


def generate_temperature_chart(data_points):
    """Gera gráfico em memória e retorna o buffer para inserir no PDF."""
    times = [t.strftime("%Hh") for t, _ in data_points]
    temps = [v for _, v in data_points]

    plt.figure(figsize=(6,2.5))
    plt.plot(times, temps, marker="o", linewidth=2, color="#004E98")
    plt.title("Variação de Temperatura (últimas 24h)", fontsize=10)
    plt.xlabel("Hora")
    plt.ylabel("°C")
    plt.grid(True, linestyle="--", alpha=0.5)
    plt.xticks(rotation=45, fontsize=8)
    plt.tight_layout()

    buf = io.BytesIO()
    plt.savefig(buf, format="png", dpi=150)
    plt.close()
    buf.seek(0)
    return buf