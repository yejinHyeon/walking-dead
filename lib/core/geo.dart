import 'dart:math';

class LatLng2 {
  final double lat, lng;
  const LatLng2(this.lat, this.lng);
}

double distanceMeters(LatLng2 a, LatLng2 b) {
  const r = 6371000.0;
  double rad(double d) => d * pi / 180;
  final dLat = rad(b.lat - a.lat), dLng = rad(b.lng - a.lng);
  final h = pow(sin(dLat / 2), 2) + cos(rad(a.lat)) * cos(rad(b.lat)) * pow(sin(dLng / 2), 2);
  return 2 * r * asin(sqrt(h));
}

/// 0 = 북, 시계 방향 (도)
double bearingDegrees(LatLng2 from, LatLng2 to) {
  double rad(double d) => d * pi / 180;
  final y = sin(rad(to.lng - from.lng)) * cos(rad(to.lat));
  final x = cos(rad(from.lat)) * sin(rad(to.lat)) - sin(rad(from.lat)) * cos(rad(to.lat)) * cos(rad(to.lng - from.lng));
  return (atan2(y, x) * 180 / pi + 360) % 360;
}

/// 8방위 인덱스: 0=N 1=NE 2=E 3=SE 4=S 5=SW 6=W 7=NW
int compassIndex(double bearing) => ((bearing / 45).round()) % 8;

String formatDistance(double m) => m < 1000 ? '${m.round()} m' : '${(m / 1000).toStringAsFixed(1)} km';

/// 소수점 첫째 자리 내림 (보유품 일수는 낙관적으로 반올림하지 않는다)
double floor1(double v) => (v * 10).floor() / 10;
