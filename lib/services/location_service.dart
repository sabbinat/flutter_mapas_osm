import 'package:battery_plus/battery_plus.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  Future<Position?> getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    // Obtém o nível da bateria
    final battery = Battery();
    final batteryLevel = await battery.batteryLevel;

    // Ajusta a precisão com base no nível da bateria
    LocationAccuracy accuracy;

    if (batteryLevel > 50) {
      accuracy = LocationAccuracy.best;
    } else if (batteryLevel > 30) {
      accuracy = LocationAccuracy.high;
    } else if (batteryLevel > 20) {
      accuracy = LocationAccuracy.medium;
    } else {
      accuracy = LocationAccuracy.low;
    }


    // Retorna a posição atual com as configurações ajustadas
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: accuracy,
      timeLimit: const Duration(seconds: 10),
    );
  }
}