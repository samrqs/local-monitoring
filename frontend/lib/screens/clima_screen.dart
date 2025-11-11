import 'package:eco_sight/screens/providers/clima_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:weather_icons/weather_icons.dart';
import '../../data/services/location_service.dart';

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
                    color: Color.fromARGB(255, 22, 134, 0),
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
          Text(p.nomeCidade ?? "Localizando...",
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
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
