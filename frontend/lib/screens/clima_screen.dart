// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'dart:convert';

import 'package:eco_sight/screens/providers/clima_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:weather_icons/weather_icons.dart';
import '../../data/services/location_service.dart';
import 'package:url_launcher/url_launcher.dart';


class ClimaScreen extends StatefulWidget {
  const ClimaScreen({super.key});

  @override
  State<ClimaScreen> createState() => _ClimaScreenState();
}

class _ClimaScreenState extends State<ClimaScreen> {
  bool carregado = false;

  @override
  void initState() {
    super.initState();
    _carregarAutomatico();
  }

  Future<void> _carregarAutomatico() async {
    final p = context.read<ClimaProvider>();

    // ✅ Se já tem clima carregado, não refaz a requisição
    if (p.clima != null) {
      setState(() => carregado = true);
      return;
    }

    final pos = await LocationService.getPosition();
    if (pos != null) {
      p.carregarClima(pos.latitude, pos.longitude);
    }

    setState(() => carregado = true);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ClimaProvider>();
    final c = p.clima;

    return Scaffold(
      appBar: AppBar(
      centerTitle: true,
              title: Row(
                mainAxisSize: MainAxisSize.min, // mantém centralizado
                children: [
                  const Icon(
                    Icons.cloud_outlined, // ícone de clima
                    color: Color.fromARGB(255, 56, 142, 60),
                    size: 32,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "Clima",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
      ),
      body: (!carregado || p.loading)
          ? const Center(child: CircularProgressIndicator())
          : (c == null)
              ? _erroWidget()
              : _content(p),
    );
  }

  // UI final aqui (já te mando completa após confirmar teste)
  Widget _content(ClimaProvider p) {
    final c = p.clima!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.red),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        p.nomeCidade ?? "Detectando localização...",
                        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          BoxedIcon(_mapWeatherIcon(c.icone), size: 80, color: Colors.blueGrey.shade700),
          const SizedBox(height: 12),
          Text("${c.temperatura.toStringAsFixed(1)}°C",
              style: GoogleFonts.poppins(fontSize: 48, fontWeight: FontWeight.w600)),
          Text(c.descricao.toUpperCase(),
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black54)),
          const SizedBox(height: 24),
          _infoRow("Sensação Térmica", "${c.sensacao.toStringAsFixed(1)}°C", WeatherIcons.thermometer),
          _infoRow("Vento", "${c.vento} km/h", WeatherIcons.strong_wind),
          _infoRow("Pressão", "${c.pressao} hPa", WeatherIcons.barometer),
          _infoRow("Umidade", "${c.umidade}%", WeatherIcons.humidity),
          const SizedBox(height: 20),
          _sunTimes(c.nascerSol, c.porSol),
          _buildRelatorioDivider(),
          _relatorioCard(p)
        ],
      ),
    );
  }

  Widget _infoRow(String title, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          BoxedIcon(icon, size: 28, color: Colors.green.shade700),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: GoogleFonts.poppins(fontSize: 16))),
          Text(value, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _sunTimes(int nascer, int por) {
    final s1 = DateTime.fromMillisecondsSinceEpoch(nascer * 1000).toLocal();
    final s2 = DateTime.fromMillisecondsSinceEpoch(por * 1000).toLocal();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Column(children: [
          const Icon(WeatherIcons.sunrise, size: 40, color: Colors.orange),
          Text("${s1.hour}:${s1.minute.toString().padLeft(2, '0')}", style: GoogleFonts.poppins()),
        ]),
        Column(children: [
          const Icon(WeatherIcons.sunset, size: 40, color: Colors.deepOrange),
          Text("${s2.hour}:${s2.minute.toString().padLeft(2, '0')}", style: GoogleFonts.poppins()),
        ]),
      ],
    );
  }

    Widget _relatorioCard(ClimaProvider p) {
    return Container(
      margin: const EdgeInsets.only(top: 20, bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(2, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.description, color: Color.fromARGB(255, 56, 142, 60), size: 28),
              const SizedBox(width: 8),
              Text(
                "Relatório Meteorológico",
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            "Baixe um relatório com as informações atuais do tempo, incluindo temperatura, umidade, pressão, vento e históricos.",
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.black87),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromARGB(255, 56, 142, 60),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              ),
              onPressed: () async {
                await _baixarRelatorio(p);
              },
              icon: const Icon(Icons.download, color: Colors.white),
              label: const Text(
                "Baixar Relatório",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRelatorioDivider() => const Padding(
  padding: EdgeInsets.symmetric(vertical: 8.0),
  child: Divider(thickness: 1.2),
);


Future<void> _baixarRelatorio(ClimaProvider p) async {
  try {
    final lat = p.ultimaLat;
    final lon = p.ultimaLon;

    if (lat == null || lon == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Não foi possível obter a localização atual.")),
      );
      return;
    }

    final url = Uri.parse("${dotenv.env['API_URL']}/report/weather");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"lat": p.ultimaLat, "lon": p.ultimaLon}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data["status"] == "ok") {
        final reportUrl = data["download_url"];
        if (reportUrl != null){
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
                content: Text("📄 Relatório gerado para ${data["city"]}!"),
                action: SnackBarAction(
                  label: "Baixar",
                  onPressed: () async {
                    final uri = Uri.parse(reportUrl);
                    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
                      throw Exception('Não foi possível abrir o PDF');
                    }
                  },
                ),
              ),
        );
        } else {
        throw Exception("Erro HTTP ${response.statusCode}: ${response.body}");
      }
      } else {
        throw Exception(data["error"] ?? "Erro desconhecido ao gerar relatório.");
      }
    } else {
      throw Exception("Erro HTTP ${response.statusCode}: ${response.body}");
    }
  } catch (e) {
    debugPrint("Erro ao gerar relatório: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("❌ Falha ao gerar relatório: $e")),
    );
  }
}


  IconData _mapWeatherIcon(String code) {
    switch (code) {
      case "01d": return WeatherIcons.day_sunny;
      case "01n": return WeatherIcons.night_clear;
      case "02d": return WeatherIcons.day_cloudy;
      case "02n": return WeatherIcons.night_alt_cloudy;
      case "03d":
      case "03n": return WeatherIcons.cloud;
      case "04d":
      case "04n": return WeatherIcons.cloudy;
      case "09d":
      case "09n": return WeatherIcons.rain;
      case "10d": return WeatherIcons.day_rain;
      case "10n": return WeatherIcons.night_alt_rain;
      case "11d":
      case "11n": return WeatherIcons.thunderstorm;
      case "13d":
      case "13n": return WeatherIcons.snow;
      case "50d":
      case "50n": return WeatherIcons.fog;
      default: return WeatherIcons.cloud;
    }
  }

  Widget _erroWidget() => const Center(child: Text("Não foi possível obter os dados de clima"));
}
