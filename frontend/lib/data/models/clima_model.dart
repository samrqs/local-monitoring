class ClimaModel {
  final double temperatura;
  final double sensacao;
  final int umidade;
  final double vento;
  final int pressao;
  final String descricao;
  final int nascerSol;
  final int porSol;
  final String icone;

  ClimaModel({
    required this.temperatura,
    required this.sensacao,
    required this.umidade,
    required this.vento,
    required this.pressao,
    required this.descricao,
    required this.nascerSol,
    required this.porSol,
    required this.icone,
  });

  factory ClimaModel.fromJsonOpenWeather(Map<String, dynamic> json) {
    return ClimaModel(
      temperatura: (json['main']['temp'] ?? 0).toDouble(),
      sensacao: (json['main']['feels_like'] ?? 0).toDouble(),
      umidade: json['main']['humidity'] ?? 0,
      vento: (json['wind']['speed'] ?? 0).toDouble(),
      pressao: json['main']['pressure'] ?? 0,
      descricao: json['weather'][0]['description'] ?? "",
      icone: json['weather'][0]['icon'] ?? "",
      nascerSol: json['sys']['sunrise'] ?? 0,
      porSol: json['sys']['sunset'] ?? 0,
    );
  }
}
