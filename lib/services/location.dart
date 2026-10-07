import 'package:geolocator/geolocator.dart';

import '../core/geo.dart';

/// GPS 위치. 인터넷 없이 작동하며, 위치는 메모리에만 두고 어디에도 보내지 않는다.
class LocationService {
  static LatLng2? last;

  static Future<LatLng2?> current() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return last;
      var p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied) p = await Geolocator.requestPermission();
      if (p == LocationPermission.denied || p == LocationPermission.deniedForever) return last;
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 20)),
      );
      return last = LatLng2(pos.latitude, pos.longitude);
    } catch (_) {
      return last;
    }
  }
}
