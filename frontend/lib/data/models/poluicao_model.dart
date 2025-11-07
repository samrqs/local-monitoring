class PoluicaoModel {
  final int aqi;        // 1..5
  final double pm2_5;   // µg/m³
  final double pm10;    // µg/m³
  final double o3;      // µg/m³
  final double no2;     // µg/m³
  final double so2;     // µg/m³
  final double co;      // µg/m³

  PoluicaoModel({
    required this.aqi,
    required this.pm2_5,
    required this.pm10,
    required this.o3,
    required this.no2,
    required this.so2,
    required this.co,
  });

  factory PoluicaoModel.fromOpenWeather(Map<String, dynamic> json) {
    final item = json['list'][0];
    final c = item['components'];
    return PoluicaoModel(
      aqi: item['main']['aqi'] ?? 0,
      pm2_5: (c['pm2_5'] ?? 0).toDouble(),
      pm10:  (c['pm10']  ?? 0).toDouble(),
      o3:    (c['o3']    ?? 0).toDouble(),
      no2:   (c['no2']   ?? 0).toDouble(),
      so2:   (c['so2']   ?? 0).toDouble(),
      co:    (c['co']    ?? 0).toDouble(),
    );
  }
}

class PoluicaoPonto {
  final DateTime t;
  final double pm2_5;
  PoluicaoPonto(this.t, this.pm2_5);
}
