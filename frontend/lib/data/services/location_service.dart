import 'package:geolocator/geolocator.dart';

class LocationService {
  static Future<Position?> getPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null; // GPS desativado
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }

    if (permission == LocationPermission.deniedForever) {
      return null; // Permissão permanentemente negada
    }

    return await Geolocator.getCurrentPosition();
  }
}
