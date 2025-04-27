import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:routeappyeni/main.dart';
import 'package:routeappyeni/api_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiProvider _apiProvider = ApiProvider();

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _registerUsernameController =
      TextEditingController();
  final TextEditingController _registerPasswordController =
      TextEditingController();

  bool _keepLoggedIn = false;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    String? isLoggedIn = await _secureStorage.read(key: 'isLoggedIn');
    String? keepLoggedIn = await _secureStorage.read(key: 'keepLoggedIn');

    if (isLoggedIn == 'true' && keepLoggedIn == 'true') {
      // Eğer kullanıcı zaten giriş yapmışsa, HomeScreen'e yönlendir
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    }
  }

  Future<void> _login() async {
    String username = _usernameController.text;
    String password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Kullanıcı adı ve şifre gerekli")),
      );
      return;
    }

    try {
      var response = await http.post(
        _apiProvider.getLoginUri(), // ApiProvider'dan alınan login URI
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"username": username, "password": password}),
      );

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        String token = jsonResponse["token"];

        await _secureStorage.write(key: 'jwt_token', value: token);
        await _secureStorage.write(key: 'isLoggedIn', value: 'true');
        await _secureStorage.write(
            key: 'keepLoggedIn', value: _keepLoggedIn.toString());

        // Başarılı giriş sonrası HomeScreen'e yönlendir
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Giriş başarısız")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Bir hata oluştu, tekrar deneyin")),
      );
    }
  }

  Future<void> _register() async {
    String username = _registerUsernameController.text;
    String password = _registerPasswordController.text;

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Kullanıcı adı ve şifre gerekli")),
      );
      return;
    }

    try {
      var response = await http.post(
        _apiProvider.getRegisterUri(), // ApiProvider'dan alınan register URI
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"username": username, "password": password}),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Kullanıcı başarıyla kaydedildi.")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Kayıt başarısız")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Bir hata oluştu, tekrar deneyin")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login / Register")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: "Giriş Yap"),
                Tab(text: "Kayıt Ol"),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextField(
                        controller: _usernameController,
                        decoration:
                            const InputDecoration(labelText: "Kullanıcı Adı"),
                      ),
                      TextField(
                        controller: _passwordController,
                        decoration: const InputDecoration(labelText: "Şifre"),
                        obscureText: true,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Checkbox(
                            value: _keepLoggedIn,
                            onChanged: (bool? value) {
                              setState(() {
                                _keepLoggedIn = value!;
                              });
                            },
                          ),
                          const Text("Oturumu açık tut"),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: _login,
                        child: const Text("Giriş Yap"),
                      ),
                    ],
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Kayıt olma işlemi şu anda kullanım dışıdır.",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      )
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
