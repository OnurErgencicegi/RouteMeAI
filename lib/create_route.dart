import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/cupertino.dart';

import 'api_provider.dart';

class CreateRouteScreen extends StatefulWidget {
  const CreateRouteScreen({super.key});

  @override
  State<CreateRouteScreen> createState() => _CreateRouteScreenState();
}

class _CreateRouteScreenState extends State<CreateRouteScreen> {
  static const _initialCameraPosition = CameraPosition(
    target: LatLng(41.008212, 28.978412), // İstanbul
    zoom: 11.5,
  );

  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  List<LatLng> _routePoints = [];
  String? _responseTime;
  String _travelMode = 'walking';
  final String baseUrl = ApiProvider().baseUrl;
  int _selectedInputMethod = 3;

  final TextEditingController _locationCountController =
      TextEditingController(text: '8');
  final TextEditingController _latitudeController =
      TextEditingController(text: '41.0383');
  final TextEditingController _longitudeController =
      TextEditingController(text: '28.9750');

  bool _isButtonDisabled = false;

  // Haritaya tıklanınca çalışacak fonksiyon
  void _handleMapTap(LatLng tappedPoint) {
    setState(() {
      _markers.clear();
      _markers.add(
        Marker(
          markerId: const MarkerId('selected-location'),
          position: tappedPoint,
          infoWindow: const InfoWindow(title: "Seçilen Konum"),
        ),
      );
      _latitudeController.text = tappedPoint.latitude.toString();
      _longitudeController.text = tappedPoint.longitude.toString();
    });
  }

  Future<void> _sendRequestToApi() async {
    setState(() {
      _isButtonDisabled = true;
    });

    const FlutterSecureStorage secureStorage = FlutterSecureStorage();
    String? token = await secureStorage.read(key: 'jwt_token');

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No token found!")),
      );
      setState(() {
        _isButtonDisabled = false;
      });
      return;
    }

    final Map<String, dynamic> requestBody = {
      "latitude": double.tryParse(_latitudeController.text) ?? 0.0,
      "longitude": double.tryParse(_longitudeController.text) ?? 0.0,
      "location_count": int.tryParse(_locationCountController.text) ?? 0,
      "mode": _travelMode,
    };

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/calculate_route'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData.containsKey("route")) {
          List<dynamic> routeData = responseData["route"];

          List<LatLng> coordinates = [];
          for (var point in routeData) {
            coordinates.add(LatLng(point["lat"], point["lng"]));
          }

          setState(() {
            _markers.clear();
            _routePoints = coordinates;

            for (var i = 0; i < coordinates.length; i++) {
              _markers.add(
                Marker(
                  markerId: MarkerId("point_$i"),
                  position: coordinates[i],
                  infoWindow: InfoWindow(title: "Durak ${i + 1}"),
                ),
              );
            }

            final currentTime = DateTime.now();
            _responseTime =
                "${currentTime.hour}:${currentTime.minute}:${currentTime.second}";
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Rota başarıyla oluşturuldu!")),
          );
        } else {
          throw Exception("API'den geçerli rota verisi alınamadı.");
        }
      } else {
        throw Exception("API'den geçerli yanıt alınamadı.");
      }
    } catch (e) {
      print("Hata: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Bir hata oluştu. Lütfen tekrar deneyin.")),
      );
    } finally {
      setState(() {
        _isButtonDisabled = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Route"),
      ),
      body: Column(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.30,
            child: GoogleMap(
              initialCameraPosition: _initialCameraPosition,
              markers: _markers,
              onTap: _selectedInputMethod == 1 ? _handleMapTap : null,
              onMapCreated: (controller) => _mapController = controller,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: CupertinoSegmentedControl<int>(
              children: const {
                0: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('Adres Gir'),
                ),
                1: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('Haritadan Seç'),
                ),
                2: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('Mevcut Konum'),
                ),
                3: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('Coord(Devtest)'),
                ),
              },
              groupValue: _selectedInputMethod,
              onValueChanged: (int value) {
                setState(() {
                  _selectedInputMethod = value;
                });
              },
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    if (_selectedInputMethod == 0) ...[
                      TextField(
                        decoration: const InputDecoration(
                          labelText: 'Adres giriniz (ör: Taksim Meydanı)',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {},
                      ),
                    ],
                    if (_selectedInputMethod == 1) ...[
                      const Text(
                        "Haritadan bir noktaya dokunun.",
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                    if (_selectedInputMethod == 2) ...[
                      const Text(
                        "Mevcut konum kullanılacak.",
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                    if (_selectedInputMethod == 3) ...[
                      const SizedBox(height: 16),
                      TextField(
                        controller: _latitudeController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Enlem (Latitude)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _longitudeController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Boylam (Longitude)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    TextField(
                      controller: _locationCountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Kaç konum gezilecek? (0-20)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _travelMode = 'walking';
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _travelMode == 'walking'
                                ? Colors.blue
                                : Colors.grey,
                          ),
                          child: const Text('Walk'),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _travelMode = 'car';
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _travelMode == 'car'
                                ? Colors.blue
                                : Colors.grey,
                          ),
                          child: const Text('Car'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _isButtonDisabled ? null : _sendRequestToApi,
                      child: _isButtonDisabled
                          ? const CircularProgressIndicator()
                          : const Text('Rota Al'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
