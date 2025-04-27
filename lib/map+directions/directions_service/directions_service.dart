import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'route_bounders.dart'; // route_bounders.dart dosyasını import et
import 'route_polylines.dart'; // route_polylines.dart dosyasını import et

class DirectionsService {
  String apiKey = "AIzaSyD_xQJwsP5WZGsFYihJCK3qCzOyevmoku0";

  GoogleMapController? _googleMapController;
  final Set<Polyline> _polylines =
      {}; // Rota çizgilerini saklamak için boş bir Set

  // ------------------ (ROTA YÜKLEME FONKSİYONU) ------------------
  // Bu fonksiyon, belirtilen konumlardan rota oluşturur ve haritada gösterir.
  Future<void> loadRoute(List<LatLng> locations, String mode) async {
    if (locations.length < 2) {
      throw Exception("Rota oluşturmak için en az 2 konum gerekli.");
    }

    final String origin =
        "${locations.first.latitude},${locations.first.longitude}";
    final String destination =
        "${locations.last.latitude},${locations.last.longitude}";

    String waypoints = "";
    if (locations.length > 2) {
      waypoints =
          "&waypoints=${locations.sublist(1, locations.length - 1).map((e) => "${e.latitude},${e.longitude}").join('|')}";
    }

    final String url = "https://maps.googleapis.com/maps/api/directions/json?"
        "origin=$origin"
        "&destination=$destination"
        "&mode=$mode" // Dinamik olarak mode ekleniyor
        "$waypoints"
        "&key=$apiKey";

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if ((data["routes"] as List).isEmpty) {
        throw Exception("Rota bulunamadı.");
      }

      final polyline = data["routes"][0]["overview_polyline"]["points"];
      Set<Marker> markers = {};
      // decodePolyline fonksiyonunu route_polylines.dart'dan çağırıyoruz.
      List<LatLng> routeCoordinates =
          RoutePolylines.decodePolyline(polyline, markers);

      _polylines.clear();
      _polylines
          .addAll(await RoutePolylines.createPolylines(routeCoordinates, mode));

      LatLngBounds bounds = RouteBounders.getRouteBounds(routeCoordinates);
      _googleMapController?.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 50),
      );
    } else {
      throw Exception("Rota alınamadı, hata kodu: ${response.statusCode}");
    }
  }

  // ------------------ (HARİTA CONTROLLER'INI AYARLAMAK) ------------------
  // Bu fonksiyon, Google Map controller'ını ayarlar.
  void onMapCreated(GoogleMapController controller) {
    _googleMapController = controller;
  }
}
