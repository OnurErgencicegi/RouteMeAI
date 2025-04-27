import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'login.dart'; // Login sayfası için import et
import 'api_provider.dart'; // ApiProvider import et

class ApiService {
  // ApiProvider'dan baseUrl'i alıyoruz
  final String baseUrl = ApiProvider().baseUrl;
  final storage =
      const FlutterSecureStorage(); // Flutter Secure Storage kullanıyoruz

  // API'den rota verisi almak için olan fonksiyon
  Future<Map<String, dynamic>> fetchRoute(
      Map<String, dynamic> requestBody) async {
    const String url = "/calculate_route"; // API uç noktası

    try {
      final response = await http.post(
        Uri.parse('$baseUrl$url'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body); // JSON yanıtını döndür
      } else {
        throw Exception('API isteği başarısız: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception("Bir hata oluştu: $e");
    }
  }

  // Flutter'da Secure Storage kullanarak token saklama ve alma
  Future<String?> _getToken() async {
    return await storage.read(key: "token");
  }

  Future<void> _redirectToLogin(BuildContext context) async {
    await storage.delete(key: "token"); // Token'ı güvenli bir şekilde sil
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  // Refresh Token kullanarak yeni Access Token almak
  Future<String?> _refreshToken() async {
    String? refreshToken = await storage.read(key: 'refresh_token');
    if (refreshToken == null) return null;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/refresh'),
        body: jsonEncode({'refresh_token': refreshToken}),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        await storage.write(key: 'token', value: data['access_token']);
        return data['access_token'];
      }
    } catch (e) {
      print("Refresh Token Hatası: $e");
    }
    return null;
  }

  // Auth kontrolü ve API'ye istek atan fonksiyon
  Future<Map<String, dynamic>?> postRequest(
      String endpoint, Map<String, dynamic> body, BuildContext context) async {
    String url = "$baseUrl$endpoint";
    String? token = await _getToken();

    // Token geçerli değilse, refresh token kullanarak yenile
    if (token == null || _isTokenExpired(token)) {
      token = await _refreshToken();
    }

    if (token == null) {
      _redirectToLogin(context); // Giriş yapmak için yönlendir
      return null;
    }

    Map<String, String> headers = {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };

    try {
      final response = await http.post(Uri.parse(url),
          headers: headers, body: jsonEncode(body));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        _redirectToLogin(context); // Yetkisiz giriş varsa login ekranına dön
      }
      return null;
    } catch (e) {
      print("API Hatası: $e");
      return null;
    }
  }

  // Token'ın süresi dolmuş mu kontrol et
  bool _isTokenExpired(String token) {
    var decodedToken = jsonDecode(
        utf8.decode(base64.decode(base64.normalize(token.split('.')[1]))));
    int expiry = decodedToken['exp'];
    DateTime expiryDate = DateTime.fromMillisecondsSinceEpoch(expiry * 1000);
    return DateTime.now().isAfter(expiryDate);
  }

  // Rota hesaplama isteği (Token kontrolü ve auth işlemi ile)
  Future<Map<String, dynamic>?> calculateRoute(
      double latitude,
      double longitude,
      int locationCount,
      int cityId,
      BuildContext context) async {
    return await postRequest(
      "/calculate_route",
      {
        "latitude": latitude,
        "longitude": longitude,
        "location_count": locationCount,
        "city_id": cityId,
      },
      context,
    );
  }
}
