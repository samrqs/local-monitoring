class ClimaModel {
  final double temperatura;
  final int umidade;
  final String descricao;

  ClimaModel({
    required this.temperatura,
    required this.umidade,
    required this.descricao,
  });

  factory ClimaModel.fromJsonOpenWeather(Map<String, dynamic> json) {
    return ClimaModel(
      temperatura: json['main']['temp']?.toDouble() ?? 0.0,
      umidade: json['main']['humidity'] ?? 0,
      descricao: json['weather'][0]['description'],
    );
  }
}
