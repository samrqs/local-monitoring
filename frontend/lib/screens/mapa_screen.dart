import 'package:eco_sight/screens/providers/clima_provider.dart';
import 'package:eco_sight/screens/providers/mapa_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
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
    final center = LatLng(
      pos?.latitude ?? -23.55,
      pos?.longitude ?? -46.63,
    );
    await mapaProv.init(center);

    // Carrega poluição via ClimaProvider (uma vez)
    final climaProv = context.read<ClimaProvider>();
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
        title: const Text('Mapa Ambiental'),
        centerTitle: true,
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
                      radius: 12000, // 12 km
                      color: _corPM25(clima.poluicao!.pm2_5).withOpacity(0.38),
                      borderStrokeWidth: 0,
                    ),
                  ],
                ),

              // 🌊 camada: Alagamentos (polígonos)
              if (mapa.modo == ModoMapa.alagamento && mapa.alagamentos.isNotEmpty)
                PolygonLayer(
                  polygons: mapa.alagamentos.map((a) {
                    return Polygon(
                      points: a.poligono,
                      color: Colors.blueAccent.withOpacity(0.25),
                      borderColor: Colors.blueAccent,
                      borderStrokeWidth: 2,
                      label: a.titulo,
                    );
                  }).toList(),
                ),

              // 🔥 camada: Queimadas (INPE)
              if (mapa.modo == ModoMapa.queimadas && mapa.focos.isNotEmpty)
                MarkerLayer(
                  markers: mapa.focos.map((f) {
                    return Marker(
                      point: LatLng(f.lat, f.lon),
                      width: 28,
                      height: 28,
                      child: const Icon(Icons.local_fire_department, color: Colors.red, size: 26),
                    );
                  }).toList(),
                ),
            ],
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
                  onPressed: () => mapa.recarregar(),
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
                      await mapa.setModo(ModoMapa.poluicao);
                    },
                    icon: const Icon(Icons.cloud),
                    label: const Text('Poluição'),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton.extended(
                    heroTag: 'modo_alag',
                    onPressed: () async {
                      setState(() => _menuAberto = false);
                      await mapa.setModo(ModoMapa.alagamento);
                    },
                    icon: const Icon(Icons.water),
                    label: const Text('Alagamento'),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton.extended(
                    heroTag: 'modo_fogo',
                    onPressed: () async {
                      setState(() => _menuAberto = false);
                      await mapa.setModo(ModoMapa.queimadas);
                    },
                    icon: const Icon(Icons.local_fire_department),
                    label: const Text('Queimadas'),
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

  // Escala PM2.5 em µg/m³ → cor
  Color _corPM25(double? pm) {
    if (pm == null) return Colors.grey;
    if (pm < 12) return Colors.green;        // Excelente
    if (pm < 35) return Colors.yellow;       // Moderada
    if (pm < 55) return Colors.orange;       // Ruim
    if (pm < 150) return Colors.red;         // Perigosa
    return Colors.purple;                    // Tóxica
  }
}
