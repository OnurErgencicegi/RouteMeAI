import 'dart:convert';
import 'dart:math' as Math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class RoutePolylines {
  // Google Directions API'den detaylı rota (adım adım) almak için yardımcı fonksiyon.
  static Future<List<LatLng>> _getDetailedRoute(
      String mode, List<Map<String, dynamic>> orderedCoords) async {
    // Koordinatları 'coord_order' parametresine göre sıralıyoruz
    orderedCoords.sort((a, b) {
      // null kontrolü ekliyoruz
      if (a['order'] == null || b['order'] == null) {
        return throw Exception(
            "coordorderlar veya biri null"); // null değeri karşılaştırma yapmadan geç
      }
      return a['order'].compareTo(b['order']);
    });

    List<LatLng> routeCoordinates = orderedCoords.map((coord) {
      return LatLng(coord['latitude'], coord['longitude']);
    }).toList();

    String apiKey = "MY_APİ_KEY"; // API keyinizi buraya ekleyin

    String avoid = "";
    if (mode == "driving") {
      avoid = "&avoid=ferries";
    } else if (mode == "walking") {
      avoid = "&avoid=highways,tolls,ferries";
    }

    // URL'yi dinamik olarak oluşturuyoruz
    StringBuffer originDestination = StringBuffer();

    for (int i = 0; i < routeCoordinates.length - 1; i++) {
      String origin =
          "${routeCoordinates[i].latitude},${routeCoordinates[i].longitude}";
      String destination =
          "${routeCoordinates[i + 1].latitude},${routeCoordinates[i + 1].longitude}";

      if (i > 0) {
        originDestination
            .write("|"); // Eğer ilk konum değilse, ayırıcı ekleriz.
      }

      originDestination.write("$origin|$destination");
    }

    String routeQuery = originDestination.toString();

    String url =
        "https://maps.googleapis.com/maps/api/directions/json?origin=${routeCoordinates.first.latitude},${routeCoordinates.first.longitude}&destination=${routeCoordinates.last.latitude},${routeCoordinates.last.longitude}&mode=$mode&key=$apiKey$avoid&waypoints=$routeQuery";

    final response =
        await http.get(Uri.parse(url)).timeout(Duration(seconds: 30));

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);

      if ((jsonData["routes"] as List).isNotEmpty) {
        List<List<LatLng>> allRoutes = [];
        for (var route in jsonData["routes"]) {
          List<LatLng> routeCoords = [];
          final legs = route["legs"];
          for (var leg in legs) {
            final steps = leg["steps"];
            for (var step in steps) {
              List<LatLng> stepCoords =
                  decodePolyline(step["polyline"]["points"], {});
              if (routeCoords.isNotEmpty &&
                  stepCoords.isNotEmpty &&
                  routeCoords.last == stepCoords.first) {
                stepCoords.removeAt(0);
              }
              routeCoords.addAll(stepCoords);
            }
          }
          allRoutes.add(routeCoords);
        }

        // En iyi rotayı seçiyoruz
        int bestRouteIndex = _chooseBestRoute(allRoutes);
        return allRoutes[bestRouteIndex];
      } else {
        throw Exception("Belirtilen mod için uygun rota bulunamadı.");
      }
    } else {
      throw Exception(
          "Google Directions API isteği başarısız: ${response.statusCode}");
    }
  }

  // En iyi rotayı seçen fonksiyon
  static int _chooseBestRoute(List<List<LatLng>> allRoutes) {
    int bestIndex = 0;
    int minDistance = 99;
    debugPrint("Tüm rotaların uzunluklarını hesaplamaya başlıyor...");

    for (int i = 0; i < allRoutes.length; i++) {
      int distance = 0;
      for (int j = 0; j < allRoutes[i].length - 1; j++) {
        distance += _calculateDistance(allRoutes[i][j], allRoutes[i][j + 1]);
      }
      debugPrint("Rota $i için toplam mesafe: $distance");
      if (distance < minDistance) {
        minDistance = distance;
        bestIndex = i;
      }
    }

    debugPrint("En kısa mesafe: $minDistance, en iyi rota indexi: $bestIndex");
    return bestIndex;
  }

  // İki nokta arasındaki mesafeyi hesaplayan fonksiyon
  static int _calculateDistance(LatLng start, LatLng end) {
    const int radius = 6371; // Dünya'nın yarıçapı (km cinsinden)
    double dLat = _toRadians(end.latitude - start.latitude);
    double dLng = _toRadians(end.longitude - start.longitude);
    double a = (Math.sin(dLat / 2) * Math.sin(dLat / 2)) +
        (Math.cos(_toRadians(start.latitude)) *
            Math.cos(_toRadians(end.latitude)) *
            Math.sin(dLng / 2) *
            Math.sin(dLng / 2));
    double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return (radius * c).toInt(); // Mesafeyi kilometre olarak döndürür
  }

  // Dereceyi radiana çeviren yardımcı fonksiyon
  static double _toRadians(double degree) {
    return degree * (Math.pi / 180);
  }

  // Google Directions API'den dönen sıkıştırılmış polyline string'ini LatLng listesine çeviren fonksiyon
  static List<LatLng> decodePolyline(String encoded, Set<Marker> markers) {
    List<LatLng> polylineCoords = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;
    debugPrint("Polyline decode işlemi başladı. Toplam karakter sayısı: $len");

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      LatLng newLatLng = LatLng(lat / 1E5, lng / 1E5);
      polylineCoords.add(newLatLng);

      // Marker eklemek isterseniz, aşağıdaki satırı aktif edebilirsiniz.
      markers.add(Marker(
        markerId: MarkerId(newLatLng.toString()),
        position: newLatLng,
        infoWindow: InfoWindow(),
      ));
    }

    debugPrint(
        "Polyline decode işlemi tamamlandı. Toplam koordinat sayısı: ${polylineCoords.length}");
    return polylineCoords;
  }

  // createPolylines fonksiyonu
  static Future<Set<Polyline>> createPolylines(
      List<LatLng> routeCoordinates, String mode) async {
    List<LatLng> finalCoordinates = routeCoordinates;
    debugPrint(
        "createPolylines: Başlangıçta rota koordinat sayısı: ${finalCoordinates.length}");

    // API isteği ile detaylı rota alınması: adım adım koordinatlar
    if (mode == "walking" || mode == "driving") {
      try {
        // routeCoordinates'ı orderedCoords formatına dönüştürme
        List<Map<String, dynamic>> orderedCoords =
            routeCoordinates.map((coord) {
          return {
            'order': routeCoordinates.indexOf(coord), // Koordinat sırası
            'latitude': coord.latitude,
            'longitude': coord.longitude,
            'coord_id': routeCoordinates.indexOf(coord), // ID olarak sıralama
            'name': 'Location ${routeCoordinates.indexOf(coord)}', // Örnek isim
          };
        }).toList();

        finalCoordinates = await _getDetailedRoute(mode, orderedCoords);
        debugPrint(
            "Detaylı rota alındı. Koordinat sayısı: ${finalCoordinates.length}");
      } catch (e) {
        debugPrint("Detaylı rota alınamadı: $e");
        // Hata durumunda fallback olarak doğrudan verilen koordinatlar kullanılabilir.
      }
    }

    // Rota modu için farklı renk seçimi:
    Color polylineColor = mode == "walking"
        ? Colors.green
        : Colors.blue; // Yaya: yeşil, araç: mavi
    debugPrint("createPolylines: Kullanılan renk: $polylineColor");

    return {
      Polyline(
        polylineId: const PolylineId('route'),
        color: polylineColor,
        width: 5,
        points: finalCoordinates,
      ),
    };
  }

  // Rota üzerindeki koordinatlar için Marker oluşturan fonksiyon
  static List<Marker> createMarkers(
      List<LatLng> routeCoordinates, List<Map<String, dynamic>> orderedCoords) {
    debugPrint(
        "createMarkers: Marker oluşturuluyor. Toplam koordinat sayısı: ${routeCoordinates.length}");
    return List.generate(routeCoordinates.length, (index) {
      final coord = orderedCoords[index];
      return Marker(
        markerId: MarkerId(coord['coord_id'].toString()),
        position: routeCoordinates[index],
        infoWindow: InfoWindow(
          title: coord['name'],
        ),
      );
    });
  }
}
