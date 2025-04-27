// route_bounders.dart
import 'package:google_maps_flutter/google_maps_flutter.dart';

class RouteBounders {
  // ------------------ (ROTA SINIRLARINI HESAPLAMA FONKSİYONU) ------------------
  // Bu fonksiyon, rota koordinatları için harita sınırlarını hesaplar.
  static LatLngBounds getRouteBounds(List<LatLng> routeCoordinates) {
    double minLat = routeCoordinates[0].latitude;
    double maxLat = routeCoordinates[0].latitude;
    double minLng = routeCoordinates[0].longitude;
    double maxLng = routeCoordinates[0].longitude;

    for (var point in routeCoordinates) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    double paddingFactor =
        0.04; // Haritanın ne kadar yukarı kayacağını belirler
    minLat -= paddingFactor;

    return LatLngBounds(
      southwest: LatLng(minLat, minLng), // Sol alt köşe
      northeast: LatLng(maxLat, maxLng), // Sağ üst köşe
    );
  }
}
