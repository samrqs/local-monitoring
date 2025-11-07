import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/clima_model.dart';
import '../models/poluicao_model.dart';

class ApiService {
  static String baseUrl = dotenv.env['API_URL']!;
  static String apiKey  = dotenv.env['API_KEY']!;
  static String units   = dotenv.env['UNITS'] ?? 'metric';
  static String lang    = dotenv.env['LANG']  ?? 'pt_br';

  static Future<ClimaModel> getClima(double lat, double lon) async {
    final url = Uri.parse(
      '$baseUrl/weather?lat=$lat&lon=$lon&appid=$apiKey&units=$units&lang=$lang',
    );
    final r = await http.get(url);
    if (r.statusCode != 200) throw Exception('Erro clima: ${r.statusCode}');
    return ClimaModel.fromJsonOpenWeather(jsonDecode(r.body));
  }

  static Future<PoluicaoModel> getPoluicao(double lat, double lon) async {
    final url = Uri.parse(
      '$baseUrl/air_pollution?lat=$lat&lon=$lon&appid=$apiKey',
    );
    final r = await http.get(url);
    if (r.statusCode != 200) throw Exception('Erro poluição: ${r.statusCode}');
    return PoluicaoModel.fromOpenWeather(jsonDecode(r.body));
  }

  /// Histórico das últimas 24h (PM2.5)
  static Future<List<PoluicaoPonto>> getPoluicaoHistorico(double lat, double lon) async {
    final now = DateTime.now().toUtc();
    final start = now.subtract(const Duration(hours: 24));
    final startTs = start.millisecondsSinceEpoch ~/ 1000;
    final endTs   = now.millisecondsSinceEpoch ~/ 1000;

    final url = Uri.parse(
      '$baseUrl/air_pollution/history?lat=$lat&lon=$lon&start=$startTs&end=$endTs&appid=$apiKey',
    );

    final r = await http.get(url);
    if (r.statusCode != 200) throw Exception('Erro histórico: ${r.statusCode}');
    final data = jsonDecode(r.body);
    final list = (data['list'] as List?) ?? [];
    return list.map((e) {
      final dt = DateTime.fromMillisecondsSinceEpoch((e['dt'] as int) * 1000, isUtc: true).toLocal();
      final pm2 = ((e['components']?['pm2_5']) ?? 0).toDouble();
      return PoluicaoPonto(dt, pm2);
    }).toList()
      ..sort((a,b) => a.t.compareTo(b.t));
  }
}
