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
      temperatura: (json['temperatura'] ?? 0).toDouble(),
      sensacao: (json['sensacao'] ?? 0).toDouble(),
      umidade: (json['umidade'] ?? 0).toInt(),
      vento: (json['vento'] ?? 0).toDouble(),
      pressao: (json['pressao'] ?? 0).toInt(),
      descricao: json['descricao'] ?? 'N/A',
      icone: json['icone'] ?? '',
      nascerSol: _parseTime(json['nascer_sol']),
      porSol: _parseTime(json['por_sol']),
    );
  }

    static int _parseTime(dynamic value) {
    if (value == null) return 0;

    // Se já for número (como a OpenWeather retorna), mantém.
    if (value is int) return value;

    // Se for string "HH:MM:SS", converte para timestamp de hoje
    if (value is String) {
      try {
        final parts = value.split(':');
        if (parts.length >= 2) {
          final now = DateTime.now();
          final dt = DateTime(
            now.year,
            now.month,
            now.day,
            int.parse(parts[0]),
            int.parse(parts[1]),
            parts.length == 3 ? int.parse(parts[2]) : 0,
          );
          return dt.millisecondsSinceEpoch ~/ 1000;
        }
      } catch (e) {
        print('Erro ao converter horário: $e');
      }
    }

    return 0;
  }
}
