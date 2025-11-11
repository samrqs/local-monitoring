// ignore_for_file: curly_braces_in_flow_control_structures

import 'dart:async';

import 'package:flutter/foundation.dart';
import '../../data/models/clima_model.dart';
import '../../data/models/poluicao_model.dart';
import '../../data/services/api_service.dart';
import 'package:geocoding/geocoding.dart';

class ClimaProvider extends ChangeNotifier {
  bool loading = false;
  ClimaModel? clima;
  PoluicaoModel? poluicao;
  List<PoluicaoPonto> historicoPm25 = [];

  double? ultimaLat, ultimaLon;
  String? nomeCidade;

  double? chuvaProx24h;
  double? riscoAlagamento;

Future<void> carregarClima(double lat, double lon) async {
    loading = true;
    ultimaLat = lat;
    ultimaLon = lon;
    notifyListeners();

    try {
      final climaF = ApiService.getClima(lat, lon);
      final poluF  = ApiService.getPoluicao(lat, lon);
      final histF  = ApiService.getPoluicaoHistorico(lat, lon);

      final results = await Future.wait([climaF, poluF, histF]);
      clima = results[0] as ClimaModel;
      poluicao = results[1] as PoluicaoModel;
      historicoPm25 = results[2] as List<PoluicaoPonto>;
          // ✅ Carrega cidade em paralelo (não trava UI)
    unawaited(carregarCidade(lat, lon));

    unawaited(carregarPrevisaoAlagamento(lat, lon));
    
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> carregarCidade(double lat, double lon) async {
  try {
    final placemarks = await placemarkFromCoordinates(lat, lon);

    if (placemarks.isNotEmpty) {
      final p = placemarks.first;

      final bairro = p.subLocality ?? "";
      final cidade = p.locality?.isNotEmpty == true
          ? p.locality
          : (p.subAdministrativeArea?.isNotEmpty == true ? p.subAdministrativeArea : null);
      final estado = p.administrativeArea ?? "";

      // Montagem da string final
      if (bairro.isNotEmpty && cidade != null) {
        nomeCidade = "$bairro · $cidade - $estado";
      } else if (cidade != null) {
        nomeCidade = "$cidade - $estado";
      } else {
        nomeCidade = "Região desconhecida - $estado";
      }

      notifyListeners();
    }
  } catch (e) {
    debugPrint("⚠ Erro ao obter nome da cidade: $e");
  }
}

/// Novo método para calcular risco
Future<void> carregarPrevisaoAlagamento(double lat, double lon) async {
  try {
    final prev = await ApiService.getPrecipitacaoProximas24h(lat, lon);
    chuvaProx24h = prev['chuva'];
    riscoAlagamento = calcularRiscoAlagamento(prev['chuva']!, 
    prev['umid']!.toInt(), 
    prev['nuvem']!,
    prev['press']!,
    );

    notifyListeners();
  } catch (e) {
    debugPrint("Erro previsão alagamento: $e");
  }
}

double calcularRiscoAlagamento(double chuvaMm, int umidade, double nublado, double pressao) {
  double risco = 0;
// 🌧 Peso da chuva (principal fator)
  if (chuvaMm >= 80) risco += 60;
  else if (chuvaMm >= 40) risco += 45;
  else if (chuvaMm >= 20) risco += 25;
  else if (chuvaMm >= 5)  risco += 10;

  // 💧 Umidade
  if (umidade >= 90) risco += 15;
  else if (umidade >= 75) risco += 10;
  else if (umidade >= 60) risco += 5;

  // ☁️ Nuvens
  if (nublado >= 85) risco += 10;
  else if (nublado >= 60) risco += 5;

  // 🔻 Pressão atmosférica baixa → risco de chuva
  if (pressao <= 1000) risco += 10;
  else if (pressao <= 1005) risco += 5;

  // Normaliza entre 0 e 100
  return risco.clamp(0, 100);
}

}


