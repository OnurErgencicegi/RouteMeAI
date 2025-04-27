import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:routeappyeni/map+directions/directions_service/route_polylines.dart';
import 'package:routeappyeni/route_lister.dart';
import 'package:routeappyeni/map+directions/directions_service/route_bounders.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import 'directions_service/directions_service.dart';
import 'package:routeappyeni/api_provider.dart';
import 'slider.dart';

class MapScreen extends StatefulWidget {
  final int? routeId;

  const MapScreen({Key? key, this.routeId}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final ApiProvider _apiProvider = ApiProvider();

  final Set<Polyline> _polylines = {};
  final Set<Marker> _markers = {};
  bool _isRouteVisible = false;
  List<Map<String, dynamic>> _orderedCoords = [];
  List<LatLng> routeCoordinates = [];
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  GoogleMapController? _googleMapController;
  final DirectionsService _directionsService = DirectionsService();
  bool _isWalking = true;
  bool _isPinsLoaded = false;

  static bool _cachedPinsLoaded = false;
  static Set<Marker> _cachedMarkers = {};

  bool _isSliderVisible = false;
  Map<String, dynamic>? _selectedLocation;

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
    if (widget.routeId != null) {
      _loadRoute();
    } else {
      _fetchCoords();
    }
  }

  Future<void> _checkLocationPermission() async {
    var status = await Permission.location.request();
    if (!status.isGranted) {
      debugPrint("Konum izni reddedildi.");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text("Konum izni verilmedi. Uygulama düzgün çalışmayabilir."),
        ),
      );
    }
  }

  Future<void> _fetchCoords() async {
    if (_isPinsLoaded) return;

    if (_cachedPinsLoaded) {
      setState(() {
        _markers.addAll(_cachedMarkers);
        _isPinsLoaded = true;
      });
      return;
    }

    try {
      final token =
          await _apiProvider.getToken(); 
      final uri = _apiProvider.getFetchCoordsUri(
          cityId: 1); 

      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data.containsKey('coordinates')) {
          List<Map<String, dynamic>> locations =
              List<Map<String, dynamic>>.from(data['coordinates']);

          for (var loc in locations) {
            debugPrint(
                "Location: ${loc['name']}, Latitude: ${loc['latitude']}, Longitude: ${loc['longitude']}");
          }

          final newMarkers = _createMarkers(locations);

          setState(() {
            _markers.addAll(newMarkers);
            _isPinsLoaded = true;
          });

          _cachedMarkers = newMarkers;
          _cachedPinsLoaded = true;
        } else {
          debugPrint("Geçerli 'coordinates' verisi bulunamadı.");
        }
      } else {
        debugPrint(
            "Koordinatlar alınamadı. Status Code: ${response.statusCode}");
      }
    } catch (e, stackTrace) {
      debugPrint("Koordinatlar yüklenirken hata oluştu: $e");
      debugPrint("Stack Trace: $stackTrace");
    }
  }

  Set<Marker> _createMarkers(List<Map<String, dynamic>> locations) {
    return locations.map((loc) {
      return Marker(
        markerId:
            MarkerId('${loc['name']}_${loc['latitude']}_${loc['longitude']}'),
        position: LatLng(loc['latitude'], loc['longitude']),
        onTap: () {
          debugPrint('Marker tıklandı: ${loc['name']}');
          setState(() {
            _selectedLocation = loc;
            _updateSlider(loc);
          });
        },
        infoWindow: InfoWindow.noText,
      );
    }).toSet();
  }

  void _updateSlider(Map<String, dynamic> selectedLocation) {
    setState(() {
      _selectedLocation = null;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _selectedLocation = selectedLocation;
        _isSliderVisible = true;
      });
    });
  }

  void _toggleSliderVisibility() {
    setState(() {
      _isSliderVisible = !_isSliderVisible;
    });
  }

  void _hideRoute() {
    setState(() {
      _isRouteVisible = false;
      _orderedCoords.clear();
      _polylines.clear();
      _markers.clear();
      _fetchCoords();
    });
  }

  Future<void> _loadRoute() async {
    if (widget.routeId == null) return;

    try {
      final apiProvider = ApiProvider(); // Singleton instance

      // Token'ı al
      String token = await apiProvider.getToken();

      // URI oluştur
      Uri uri = apiProvider.getPlayRouteUri(routeId: widget.routeId!);

      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<Map<String, dynamic>> orderedCoords =
            List<Map<String, dynamic>>.from(data['ordered_coords']);

        orderedCoords.sort((a, b) => a['order'].compareTo(b['order']));
        List<LatLng> newRouteCoordinates = orderedCoords
            .map((coord) => LatLng(coord['latitude'], coord['longitude']))
            .toList();

        final newPolylines = await RoutePolylines.createPolylines(
            newRouteCoordinates, _isWalking ? "walking" : "driving");

        final newMarkers =
            RoutePolylines.createMarkers(newRouteCoordinates, orderedCoords);

        setState(() {
          _polylines.clear();
          _markers.clear();
          _polylines.addAll(newPolylines);
          _markers.addAll(newMarkers);
          _orderedCoords = orderedCoords;
          routeCoordinates = newRouteCoordinates;
          _isRouteVisible = true;
        });

        if (_googleMapController != null) {
          LatLngBounds bounds =
              RouteBounders.getRouteBounds(newRouteCoordinates);
          _googleMapController
              ?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
        }
      } else {
        debugPrint("Rota verisi alınamadı. Status: ${response.statusCode}");
      }
    } catch (e, stackTrace) {
      debugPrint("Rota yüklenirken hata oluştu: $e");
      debugPrint("Stack Trace: $stackTrace");
    }
  }

  Future<void> _toggleTravelMode() async {
    setState(() {
      _isWalking = !_isWalking;
    });

    if (_isRouteVisible && _orderedCoords.isNotEmpty) {
      _loadRoute();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rota Görüntüle'),
        actions: [
          if (_isRouteVisible)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _isRouteVisible = false;
                  _polylines.clear();
                  _markers.clear();
                });
              },
            ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 0),
              child: GoogleMap(
                initialCameraPosition: const CameraPosition(
                  target: LatLng(41.0110, 28.9924),
                  zoom: 12,
                ),
                polylines: _polylines,
                markers: _markers,
                onMapCreated: (GoogleMapController controller) {
                  _googleMapController = controller;
                },
              ),
            ),
          ),
          Positioned(
            top: 10,
            left: 10,
            child: ToggleButtons(
              isSelected: [_isWalking, !_isWalking],
              onPressed: (int index) {
                _toggleTravelMode();
              },
              children: const [
                Text("Yaya"),
                Text("Araç"),
              ],
            ),
          ),
          if (_isRouteVisible)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black26, blurRadius: 5, spreadRadius: 2)
                  ],
                ),
                child: RouteLister(
                  orderedCoords: _orderedCoords,
                  scrollController: null,
                ),
              ),
            ),
          if (_isSliderVisible && _selectedLocation != null)
            Positioned(
              bottom: 0,
              left: MediaQuery.of(context).size.width * 0.07,
              top: 10,
              right: 0,
              child: SliderWidget(
                isOpen: _isSliderVisible,
                title: _selectedLocation?['name'] ?? "Test Başlık",
                activities: ["aktivite1", "aktivite2"],
                onClose: () {
                  setState(() {
                    _isSliderVisible = false;
                    _selectedLocation = null;
                  });
                },
                description:
                    _selectedLocation?['description'] ?? "Test description",
                imageUrl:
                    _selectedLocation!['imageUrl'] ?? 'lib/assets/yerebatan.jpg',
              ),
            ),
        ],
      ),
    );
  }
}
