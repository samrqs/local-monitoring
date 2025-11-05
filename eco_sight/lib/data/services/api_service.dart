import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/clima_model.dart';

class ApiService {
  static String baseUrl = dotenv.env['API_URL']!;
  static String apiKey = dotenv.env['API_KEY']!;
  static String units = dotenv.env['UNITS'] ?? "metric";
  static String lang = dotenv.env['LANG'] ?? "pt_br";

  static Future<ClimaModel> getClima(double lat, double lon) async {
    final url = Uri.parse(
      "$baseUrl/weather?lat=$lat&lon=$lon&appid=$apiKey&units=$units&lang=$lang",
    );

    final resp = await http.get(url);
    if (resp.statusCode != 200) {
      throw Exception("Erro ao obter clima: ${resp.statusCode}");
    }

    final data = jsonDecode(resp.body);
    return ClimaModel.fromJsonOpenWeather(data);
  }
}
