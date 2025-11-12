import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/clima_model.dart';
import '../models/poluicao_model.dart';

class ApiService {
  static String baseUrl = dotenv.env['API_URL']!;
  static String units = 'metric';
  static String lang = 'pt_br';
  static String apiKey = dotenv.env['API_KEY']!;

  static Future<ClimaModel> getClima(double lat, double lon) async {
    final url = Uri.parse('$baseUrl/weather?lat=$lat&lon=$lon');
    final r = await http.get(url);
    if (r.statusCode != 200) throw Exception('Erro clima: ${r.statusCode}');
    return ClimaModel.fromJsonOpenWeather(jsonDecode(r.body));
  }

static Future<PoluicaoModel> getPoluicao(double lat, double lon) async {
    final url = Uri.parse('$baseUrl/air?lat=$lat&lon=$lon');
    final r = await http.get(url);

    if (r.statusCode != 200) {
      throw Exception('Erro poluição: ${r.statusCode} ${r.body}');
    }

    final json = jsonDecode(r.body);
    final data = json['data'] ?? json; // suporta {"data":{}} ou direto {}

    // Adapta o JSON para o formato aceito pelo model atual
    return PoluicaoModel.fromOpenWeather({
      "list": [
        {
          "main": {"aqi": data["aqi"] ?? 0},
          "components": {
            "pm2_5": data["pm2_5"] ?? 0,
            "pm10": data["pm10"] ?? 0,
            "o3": data["o3"] ?? 0,
            "no2": data["no2"] ?? 0,
            "so2": data["so2"] ?? 0,
            "co": data["co"] ?? 0,
          }
        }
      ]
    });
  }

  /// Histórico das últimas 24h (PM2.5)
  static Future<List<PoluicaoPonto>> getPoluicaoHistorico(double lat, double lon) async {
    final now = DateTime.now().toUtc();
    final start = now.subtract(const Duration(hours: 24));
    final startTs = start.millisecondsSinceEpoch ~/ 1000;
    final endTs   = now.millisecondsSinceEpoch ~/ 1000;

    final url = Uri.parse('$baseUrl/air/history?lat=$lat&lon=$lon&start=$startTs&end=$endTs');

    final r = await http.get(url);
    if (r.statusCode != 200) throw Exception('Erro histórico: ${r.statusCode}');
    final data = jsonDecode(r.body);
    final list = (data['list'] as List?) ?? [];
    return list.map((e) {
      final dt = DateTime.fromMillisecondsSinceEpoch((e['dt'] as int) * 1000, isUtc: true).toLocal();
      final pm2 = ((e['pm2_5']) ?? 0).toDouble();
      return PoluicaoPonto(dt, pm2);
    }).toList()
      ..sort((a,b) => a.t.compareTo(b.t));
  }

  static Future<Map<String, double>> getPrecipitacaoProximas24h(double lat, double lon) async {
  final url = Uri.parse(
    'https://api.openweathermap.org/data/2.5/forecast?lat=$lat&lon=$lon&appid=$apiKey&units=$units&lang=$lang',
  );
  final r = await http.get(url);
  if (r.statusCode != 200) throw Exception('Erro forecast: ${r.statusCode}');
  final data = jsonDecode(r.body);

  final list = (data['list'] as List?) ?? [];
  double totalChuva = 0;
  double totalUmid = 0;
  double totalPress = 0;
  double totalNuvem = 0;

  int count = 0;
  for (var i = 0; i < list.length && i < 8; i++) {
    final e = list[i];
    totalChuva += (e['rain']?['3h'] ?? 0).toDouble();
    totalUmid += (e['main']?['humidity'] ?? 0).toDouble();
    totalPress += (e['main']?['pressure'] ?? 0).toDouble();
    totalNuvem += (e['clouds']?['all'] ?? 0).toDouble();
    count++;
  }
  
  return {
    'chuva': totalChuva,
    'umid': count > 0 ? totalUmid / count : 0,
    'press': count > 0 ? totalPress / count : 0,
    'nuvem': count > 0 ? totalNuvem / count : 0,
  };
}

static Future<String> gerarRelatorio(double lat, double lon) async {
    final url = Uri.parse('$baseUrl/report/weather');
    final r = await http.post(url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'lat': lat, 'lon': lon}));
    if (r.statusCode != 200) throw Exception('Erro ao gerar relatório');
    final data = jsonDecode(r.body);
    return data['report_url'];
  }

}
