import 'package:flutter/foundation.dart';
import '../../data/models/clima_model.dart';
import '../../data/services/api_service.dart';

class ClimaProvider extends ChangeNotifier {
  bool loading = false;
  ClimaModel? clima;

  Future<void> carregarClima(double lat, double lon) async {
    loading = true;
    notifyListeners();

    clima = await ApiService.getClima(lat, lon);

    loading = false;
    notifyListeners();
  }
}
