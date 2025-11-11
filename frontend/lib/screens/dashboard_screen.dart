// ignore_for_file: deprecated_member_use

import 'package:eco_sight/screens/providers/clima_provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../data/services/location_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DateTime? ultimaAtualizacao;
  bool atualizando = false; // controla ícone animado

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ClimaProvider>();
    final c = p.clima;
    final q = p.poluicao;

    return Scaffold(
        appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min, // centraliza o conteúdo do Row
          children: [
            ClipOval(
              child: Image.asset(
                'assets/logo.png',
                height: 46,
                width: 46,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Eco Sight',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: p.loading && !atualizando
            ? _loadingSkeleton()
            : (c == null)
                ? _emptyState()
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _topBar(context, p),
                        const SizedBox(height: 16),

                        // linha 1: clima resumido
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: _cardMetric("Temperatura", "${c.temperatura.toStringAsFixed(1)}°C", Icons.thermostat, Colors.orange)),
                            const SizedBox(width: 12),
                            Expanded(child: _cardMetric("Umidade", "${c.umidade}%", Icons.water_drop, Colors.blue)),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // linha 2: AQI + PM2.5
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: _cardMetric("Qualidade do Ar (AQI)", _aqiText(q?.aqi), Icons.air, _aqiColor(q?.aqi))),
                            const SizedBox(width: 12),
                            Expanded(child: _cardMetric("Partículas Finas - PM2.5", "${q?.pm2_5.toStringAsFixed(1) ?? '—'} µg/m³", Icons.blur_on, Colors.deepPurple)),
                          ],
                        ),

                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(child: _cardMetric("Poeira - PM10", "${q?.pm10.toStringAsFixed(1) ?? '—'} µg/m³", Icons.blur_circular, Colors.teal)),
                            const SizedBox(width: 12),
                            Expanded(child: _cardMetric("Ozônio (poluente)", "${q?.o3.toStringAsFixed(1) ?? '—'} µg/m³", Icons.cloud, Colors.indigo)),
                          ],
                        ),

                        const SizedBox(height: 12),

                        if (p.riscoAlagamento != null)
                        Row(
                          children: [
                            Expanded(child: _cardMetric(
                          "Risco de Alagamento",
                          "${_textoRisco(p.riscoAlagamento!)} (${p.riscoAlagamento!.toStringAsFixed(0)}%)",
                          Icons.water_drop,
                          _corRisco(p.riscoAlagamento!))),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        _buildGuiaQualidadeAr(),

                        const SizedBox(height: 20),
                        _cardChart("PM2.5 (pó invisível) últimas 24h", p.historicoPm25),

                      ],
                    ),
                  ),
      ),
    );
  }

  /// ✅ Topo com cidade + botão atualizar + data
Widget _topBar(BuildContext context, ClimaProvider p) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(
            child: Row(
              children: [
                const Icon(Icons.location_on, color: Colors.red),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    p.nomeCidade ?? "Detectando localização...",
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          _refreshButton(p),
        ],
      ),
      const SizedBox(height: 6),
      Text(
        ultimaAtualizacao != null
            ? "Última atualização: ${ultimaAtualizacao!.hour.toString().padLeft(2, '0')}:${ultimaAtualizacao!.minute.toString().padLeft(2, '0')}"
            : "Carregamento inicial automático",
        style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54),
      ),
    ],
  );
}

Widget _refreshButton(ClimaProvider p) {
  return InkWell(
    onTap: atualizando ? null : () async {
      setState(() => atualizando = true);
      final pos = await LocationService.getPosition();
      if (pos != null) await p.carregarClima(pos.latitude, pos.longitude);
      setState(() {
        ultimaAtualizacao = DateTime.now();
        atualizando = false;
      });
    },
    child: SizedBox(
      width: 28,
      height: 28,
      child: atualizando
          ? const Padding(
              padding: EdgeInsets.all(4),
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : AnimatedRotation(
              duration: const Duration(milliseconds: 700),
              turns: atualizando ? 1 : 0,
              child: const Icon(Icons.refresh, size: 24, color: Colors.green),
            ),
    ),
  );
}

  // === RESTO DO SEU CÓDIGO MANTIDO IGUAL ===

  Widget _emptyState() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        SizedBox(height: 60),
        Text(
          "Nenhum dado carregado.",
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );

  Widget _loadingSkeleton() => Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Column(
          children: [
            Row(children: [
              Expanded(child: Container(height: 100, color: Colors.grey)),
              const SizedBox(width: 12),
              Expanded(child: Container(height: 100, color: Colors.grey)),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: Container(height: 100, color: Colors.grey)),
              const SizedBox(width: 12),
              Expanded(child: Container(height: 100, color: Colors.grey)),
            ]),
            const SizedBox(height: 20),
            Container(height: 220, color: Colors.grey),
          ],
        ),
      );

  Widget _cardMetric(String title, String value, IconData icon, Color color) {
    return Container(
      height: 120,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color.withOpacity(0.85), color]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: color.withOpacity(0.25), blurRadius: 10, offset: const Offset(2,4))],
      ),
      child: Row(
        children: [
          Icon(icon, size: 36, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(value, style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardChart(String title, List historico) {
    final spots = <FlSpot>[];
    for (var i = 0; i < historico.length; i++) {
      spots.add(FlSpot(i.toDouble(), historico[i].pm2_5));
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(2,4))]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(historico.isEmpty ? "Sem dados de PM2.5 nas últimas 24h"
                                 : "Pontos: ${historico.length} • unidade: µg/m³",
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54)),
        ],
      ),
    );
  }

  Widget _buildGuiaQualidadeAr() {
  return Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Colors.black12),
      boxShadow: const [
        BoxShadow(
          color: Colors.black12,
          blurRadius: 6,
          offset: Offset(2, 4),
        )
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(Icons.info_outline, color: Colors.blue, size: 20),
            SizedBox(width: 8),
            Text(
              "Guia de Qualidade do Ar (OMS)",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _linhaPoluente("PM2.5", "< 15 µg/m³", "Ideal para saúde",Colors.deepPurple),
        _linhaPoluente("PM10", "< 45 µg/m³", "Limite recomendado",Colors.teal),
        _linhaPoluente("Ozônio (O₃)", "< 100 µg/m³", "Acima disso irrita pulmões",Colors.indigo),
      ],
    ),
  );
}

  Widget _linhaPoluente(String nome, String valor, String nota, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              nome,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: color, // título colorido
              ),
            ),
          ),
          Text(
            valor,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color, // valor colorido
            ),
          ),
          const SizedBox(width: 8),
          Text(
            "• $nota",
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8), // texto auxiliar ligeiramente mais claro
            ),
          ),
        ],
      ),
    );
  }

  String _aqiText(int? aqi) {
    if (aqi == null) return "—";
    return {1:"1 (Bom)",2:"2 (Moderado)",3:"3 (Ruim)",4:"4 (Muito ruim)",5:"5 (Perigoso)"}[aqi]!;
  }
  Color _aqiColor(int? aqi) {
    if (aqi == null) return Colors.grey;
    return {1:Colors.green,2:const Color.fromARGB(255, 165, 154, 54),3:Colors.orange,4:Colors.red,5:Colors.purple}[aqi]!;
  }
  Color _corRisco(double risco) {
  if (risco < 20) return Colors.green;
  if (risco < 50) return const Color.fromARGB(255, 165, 154, 54);
  if (risco < 75) return Colors.orange;
  return Colors.red;
}

  String _textoRisco(double risco) {
    if (risco < 20) {
      return "Sem risco";
    } else if (risco < 50) {
      return "Atenção";
    } else if (risco < 75) {
      return "Alto risco";
    } else {
      return "Crítico";
    }
  }


}
