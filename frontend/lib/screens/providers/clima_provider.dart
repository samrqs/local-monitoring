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

}


