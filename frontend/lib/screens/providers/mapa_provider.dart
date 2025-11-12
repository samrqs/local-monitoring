import 'package:eco_sight/data/services/api_service.dart';
import 'package:eco_sight/screens/providers/clima_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

enum ModoMapa { poluicao, alagamento }

class PontoAlagamento {
  final double lat;
  final double lon;
  final double risco;

  PontoAlagamento(this.lat, this.lon, this.risco);
}

class MapaProvider extends ChangeNotifier {
  ClimaProvider climaProv = ClimaProvider();
  bool loading = false;
  ModoMapa modo = ModoMapa.poluicao;

  LatLng? centroAtual;

  // Dados das camadas
  List<PontoAlagamento> pontosAlagamento  = [];

  Future<void> init(LatLng center, ClimaProvider climaProv) async {
    centroAtual = center;
    notifyListeners();
    await carregarCamadaAtual(climaProv);
  }

  Future<void> setModo(ModoMapa m, ClimaProvider climaProv) async {
    if (modo == m) return;
    modo = m;
    notifyListeners();
    await carregarCamadaAtual(climaProv);
  }

  Future<void> recarregar(ClimaProvider climaProv) => carregarCamadaAtual(climaProv);

  Future<void> carregarCamadaAtual(ClimaProvider climaProv) async {
    switch (modo) {
      case ModoMapa.poluicao:
        // Poluição usa ClimaProvider; nada a buscar aqui.
        return;
      case ModoMapa.alagamento:
        return gerarPontosAlagamento(centroAtual!.latitude, centroAtual!.longitude, climaProv);
    }
  }

  Future<void> gerarPontosAlagamento(double lat, double lon, ClimaProvider climaProv) async {
  pontosAlagamento.clear();
  loading = true;
  notifyListeners();

  try {
      for (var i = -1; i <= 1; i++) {
        for (var j = -1; j <= 1; j++) {
          final novoLat = lat + (i * 0.01); // ~5km
          final novoLon = lon + (j * 0.01);

          // 🔹 Busca previsão detalhada (chuva, umidade, pressão, nuvens)
          final prev = await ApiService.getPrecipitacaoProximas24h(novoLat, novoLon);

          // 🔹 Calcula o risco com base no método do ClimaProvider
          final risco = climaProv.calcularRiscoAlagamento(
            prev['chuva'] ?? 0,
            prev['umid']!.toInt(),
            prev['nuvem'] ?? 0,
            prev['press'] ?? 0,
          );

          pontosAlagamento.add(PontoAlagamento(novoLat, novoLon, risco));
        }
      }
    } catch (e) {
      debugPrint("⚠️ Erro ao gerar pontos de alagamento: $e");
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
