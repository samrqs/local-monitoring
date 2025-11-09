import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

enum ModoMapa { poluicao, alagamento, queimadas }

class FocoQueimada {
  final double lat;
  final double lon;
  final DateTime dataHora;
  final String? estado;

  FocoQueimada({
    required this.lat,
    required this.lon,
    required this.dataHora,
    this.estado,
  });
}

class AreaAlagamento {
  final List<LatLng> poligono;
  final String? titulo;

  AreaAlagamento({required this.poligono, this.titulo});
}

class MapaProvider extends ChangeNotifier {
  bool loading = false;
  ModoMapa modo = ModoMapa.poluicao;

  LatLng? centroAtual;

  // Dados das camadas
  List<FocoQueimada> focos = [];
  List<AreaAlagamento> alagamentos = [];

  Future<void> init(LatLng center) async {
    centroAtual = center;
    notifyListeners();
    await carregarCamadaAtual();
  }

  Future<void> setModo(ModoMapa m) async {
    if (modo == m) return;
    modo = m;
    notifyListeners();
    await carregarCamadaAtual();
  }

  Future<void> recarregar() => carregarCamadaAtual();

  Future<void> carregarCamadaAtual() async {
    switch (modo) {
      case ModoMapa.poluicao:
        // Poluição usa ClimaProvider; nada a buscar aqui.
        return;
      case ModoMapa.queimadas:
        return carregarQueimadasBR();
      case ModoMapa.alagamento:
        return carregarAlagamentosBR();
    }
  }

  /// 🔥 INPE – focos de queimadas BR, últimas 24h
  Future<void> carregarQueimadasBR() async {
    loading = true;
    notifyListeners();
    try {
      // API pública INPE (sem chave). Dias=1 → últimas 24h.
      final url = Uri.parse(
        'https://queimadas.dgi.inpe.br/api/focos?pais=BR&dias=1',
      );
      final r = await http.get(url);
      if (r.statusCode != 200) {
        throw Exception('INPE error: ${r.statusCode}');
      }
      final data = jsonDecode(r.body);
      if (data is List) {
        focos = data.map<FocoQueimada>((e) {
          final lat = (e['latitude'] as num).toDouble();
          final lon = (e['longitude'] as num).toDouble();
          final uf = (e['estado'] ?? '') as String?;
          // pode vir 'datahora_gmt' ou similar; tratamos genericamente
          final ts = (e['datahora'] ??
                  e['datahora_gmt'] ??
                  e['horario'] ??
                  '') as String;
          DateTime dt;
          try {
            dt = DateTime.tryParse(ts)?.toLocal() ?? DateTime.now();
          } catch (_) {
            dt = DateTime.now();
          }
          return FocoQueimada(lat: lat, lon: lon, dataHora: dt, estado: uf);
        }).toList();
      } else {
        focos = [];
      }
    } catch (e) {
      debugPrint('Erro ao carregar focos INPE: $e');
      focos = [];
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  /// 🌊 INMET/Defesa Civil – áreas de alerta/risco de chuva/inundação (GeoJSON ou lista)
  /// Implementação robusta dependerá do endpoint adotado; aqui deixo um fetch genérico com fallback.
  Future<void> carregarAlagamentosBR() async {
    loading = true;
    notifyListeners();
    try {
      // EXEMPLO de fonte (ajuste para a que você adotar):
      // final url = Uri.parse('https://seu-endpoint-geojson/avisos_inmet.geojson');
      // final r = await http.get(url);
      // if (r.statusCode != 200) throw Exception('Alagamentos error: ${r.statusCode}');
      // final geo = jsonDecode(r.body);
      // Parse GeoJSON → AreaAlagamento(poligono: [...])

      // Fallback: se não tiver endpoint ainda, cria uma área exemplo perto do centro
      if (centroAtual != null) {
        final c = centroAtual!;
        alagamentos = [
          AreaAlagamento(
            titulo: 'Área de risco (exemplo)',
            poligono: [
              LatLng(c.latitude + 0.06, c.longitude - 0.06),
              LatLng(c.latitude + 0.06, c.longitude + 0.06),
              LatLng(c.latitude - 0.06, c.longitude + 0.06),
              LatLng(c.latitude - 0.06, c.longitude - 0.06),
            ],
          ),
        ];
      } else {
        alagamentos = [];
      }
    } catch (e) {
      debugPrint('Erro ao carregar alagamentos: $e');
      alagamentos = [];
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
