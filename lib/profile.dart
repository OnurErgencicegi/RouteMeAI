import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'map+directions/map.dart'; // Harita ekranına yönlendirme için
import 'api_provider.dart'; // ApiProvider'ı buraya dahil ediyoruz

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiProvider _apiProvider = ApiProvider(); // ApiProvider örneği
  String _userName = 'Loading...';
  bool _isLoading = true;
  List<Map<String, dynamic>> _routes = [];

  Future<void> _fetchProfileData() async {
    try {
      final profileData = await _apiProvider
          .getUserProfile(); // ApiProvider'dan profil verisini alıyoruz

      if (profileData != null) {
        setState(() {
          _userName = profileData['user_name'];
          _routes = List<Map<String, dynamic>>.from(profileData['routes']);
        });
      } else {
        setState(() {
          _userName = 'Error loading profile';
        });
      }
    } catch (e) {
      setState(() {
        _userName = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("User Profile")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Center(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    const Icon(Icons.account_circle, size: 100),
                    const SizedBox(height: 20),
                    Text(
                      'User Name: $_userName',
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Routes:",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: MediaQuery.of(context).size.width * 0.8,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.deepPurple, width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        separatorBuilder: (context, index) => const Divider(),
                        itemCount: _routes.length,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () {
                              
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MapScreen(
                                    routeId: _routes[index]['route_id'],
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: Colors.deepPurple, width: 2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                leading: const Icon(Icons.route),
                                title: Text(_routes[index]['route_name']),
                                trailing: const Icon(
                                  Icons.play_arrow,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
