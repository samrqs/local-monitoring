// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:eco_sight/screens/providers/clima_provider.dart';
import 'package:eco_sight/screens/providers/mapa_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../data/services/location_service.dart';

class MapaScreen extends StatefulWidget {
  const MapaScreen({super.key});
  @override
  State<MapaScreen> createState() => _MapaScreenState();
}

class _MapaScreenState extends State<MapaScreen> {
  final MapController _map = MapController();
  bool _menuAberto = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final pos = await LocationService.getPosition();
    final mapaProv = context.read<MapaProvider>();
    final climaProv = context.read<ClimaProvider>();
    final center = LatLng(
      pos?.latitude ?? -23.55,
      pos?.longitude ?? -46.63,
    );
    await mapaProv.init(center, climaProv);

    // Carrega poluição via ClimaProvider (uma vez)

    await climaProv.carregarClima(center.latitude, center.longitude);

    _map.move(center, 11);
  }

  @override
  Widget build(BuildContext context) {
    final clima = context.watch<ClimaProvider>();
    final mapa = context.watch<MapaProvider>();

    final lat = clima.ultimaLat;
    final lon = clima.ultimaLon;

    final center = mapa.centroAtual ?? const LatLng(-23.55, -46.63);

    return Scaffold(
      appBar: AppBar(
              centerTitle: true,
              title: Row(
                mainAxisSize: MainAxisSize.min, // mantém centralizado
                children: [
                  const Icon(
                    Icons.map_outlined, // ícone de clima
                    color: Color.fromARGB(255, 22, 134, 0),     // cor do sol ☀️
                    size: 32,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "Mapa Ambiental",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _map,
            options: MapOptions(
              initialCenter: center,
              initialZoom: 11,
              maxZoom: 18,
              minZoom: 3,
            ),
            children: [
              TileLayer(
                urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                userAgentPackageName: "com.example.eco_sight",
              ),

              // 📍 marcador da posição do usuário
              if (lat != null && lon != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(lat, lon),
                      width: 42,
                      height: 42,
                      child: const Icon(Icons.my_location, color: Colors.blue, size: 32),
                    ),
                  ],
                ),

              // 🟢 camada: Poluição (círculo PM2.5) — usa ClimaProvider
              if (mapa.modo == ModoMapa.poluicao &&
                  clima.poluicao != null &&
                  lat != null &&
                  lon != null)
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: LatLng(lat, lon),
                      useRadiusInMeter: true,
                      radius: 8000, // 8 km
                      color: _corPM25(clima.poluicao!.pm2_5).withOpacity(0.38),
                      borderStrokeWidth: 0,
                    ),
                  ],
                ),

              if (mapa.modo == ModoMapa.alagamento && mapa.pontosAlagamento.isNotEmpty)
                MarkerLayer(
                  markers: mapa.pontosAlagamento.map((p) {
                    return Marker(
                      point: LatLng(p.lat, p.lon),
                      width: 28,
                      height: 28,
                      child: Icon(
                        Icons.water_drop,
                        color: _corRisco(p.risco),
                        size: 26,
                      ),
                    );
                  }).toList(),
                ),

            ],
          ),

          Positioned(
            bottom: 20,
            left: 16,
            child: _buildLegendaCard(mapa),
          ),

          if (mapa.loading)
            const Positioned(
              top: 0, left: 0, right: 0,
              child: LinearProgressIndicator(minHeight: 3),
            ),

          // 🔄 recarregar + centralizar
          Positioned(
            bottom: 20,
            right: 16,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'center',
                  onPressed: () {
                    final c = mapa.centroAtual ?? center;
                    _map.move(c, 12);
                  },
                  child: const Icon(Icons.center_focus_strong),
                ),
                const SizedBox(height: 10),
                FloatingActionButton.small(
                  heroTag: 'reload',
                  onPressed: () => mapa.recarregar(clima),
                  child: const Icon(Icons.refresh),
                ),
                const SizedBox(height: 10),

                // 🛰 menu flutuante de camadas
                if (_menuAberto) ...[
                  const SizedBox(height: 6),
                  FloatingActionButton.extended(
                    heroTag: 'modo_poluicao',
                    onPressed: () async {
                      setState(() => _menuAberto = false);
                      await mapa.setModo(ModoMapa.poluicao, clima);
                    },
                    icon: const Icon(Icons.cloud),
                    label: const Text('Poluição'),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton.extended(
                    heroTag: 'modo_alag',
                    onPressed: () async {
                      setState(() => _menuAberto = false);
                      await mapa.setModo(ModoMapa.alagamento, clima);
                    },
                    icon: const Icon(Icons.water),
                    label: const Text('Alagamento'),
                  ),
                  const SizedBox(height: 8),
                ],

                FloatingActionButton(
                  heroTag: 'menu',
                  onPressed: () => setState(() => _menuAberto = !_menuAberto),
                  child: Icon(_menuAberto ? Icons.close : Icons.layers),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

Widget _buildLegendaCard(MapaProvider mapa) {
  // Controlador reativo para abrir/fechar a legenda
  final ValueNotifier<bool> abertoNotifier = ValueNotifier(false);

  return ValueListenableBuilder<bool>(
    valueListenable: abertoNotifier,
    builder: (context, aberto, _) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card visível se aberto = true
          if (aberto)
            Container(
              padding: const EdgeInsets.all(12),
              width: 220,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(2, 3)),
                ],
              ),
              child: mapa.modo == ModoMapa.poluicao
                  ? _legendaPoluicao()
                  : _legendaAlagamento(),
            ),

          const SizedBox(height: 6),

          // Botão de info
          FloatingActionButton.small(
            heroTag: 'info',
            backgroundColor: Colors.white,
            onPressed: () => abertoNotifier.value = !abertoNotifier.value,
            child: Icon(
              aberto ? Icons.close : Icons.info_outline,
              color: Colors.blueGrey.shade700,
            ),
          ),
        ],
      );
    },
  );
}

  Widget _legendaPoluicao() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text("Qualidade do Ar", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      const SizedBox(height: 8),
      _linhaLegenda(Colors.green, "Excelente"),
      _linhaLegenda(Colors.yellow, "Moderada"),
      _linhaLegenda(Colors.orange, "Ruim"),
      _linhaLegenda(Colors.red, "Perigosa"),
      _linhaLegenda(Colors.purple, "Tóxica"),
    ],
  );
}

  Widget _legendaAlagamento() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Risco de Alagamento", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 8),
        _linhaLegenda(Colors.green, "Sem riscos"),
        _linhaLegenda(Colors.yellow, "Atenção"),
        _linhaLegenda(Colors.orange, "Alto risco"),
        _linhaLegenda(Colors.red, "Crítico"),
      ],
    );
  }

  Widget _linhaLegenda(Color cor, String texto) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: cor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(texto, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
  // Escala PM2.5 em µg/m³ → cor
  Color _corPM25(double? pm) {
    if (pm == null) return Colors.grey;
    if (pm < 12) return Colors.green;        // Excelente
    if (pm < 35) return const Color.fromARGB(255, 165, 154, 54); // Moderada
    if (pm < 55) return Colors.orange;       // Ruim
    if (pm < 150) return Colors.red;         // Perigosa
    return Colors.purple;                    // Tóxica
  }

  Color _corRisco(double risco) {
    if (risco < 20) {
      return Colors.green.withOpacity(0.9);
    } else if (risco < 50) {
      return Colors.yellow.withOpacity(0.9);
    } else if (risco < 75) {
      return Colors.orange.withOpacity(0.9);
    } else {
      return Colors.red.withOpacity(0.9);
    }
  }


}
