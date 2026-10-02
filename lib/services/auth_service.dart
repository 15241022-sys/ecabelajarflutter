import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String baseUrl = AppConfig.baseUrl;
  static const Map<String, String> headers = AppConfig.headers;

  // Login: cari user berdasarkan email & password di tabel "users"
  Future<Map<String, dynamic>?> login(String email, String password) async {
    final response =
        await http.get(Uri.parse("$baseUrl/users"), headers: headers);

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);

      final user = data.firstWhere(
        (u) => u["email"] == email && u["password"] == password,
        orElse: () => null,
      );

      if (user != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("userId", user["id"].toString());
        await prefs.setString("nama", user["nama"]);
        await prefs.setString("role", user["role"]); // "admin" / "member"
        return user;
      }
    }
    return null; // login gagal
  }

  // Register akun baru (role default: member)
  Future<bool> register(String nama, String email, String password) async {
    final response = await http.post(
      Uri.parse("$baseUrl/users"),
      headers: headers,
      body: jsonEncode({
        "nama": nama,
        "email": email,
        "password": password,
        "role": "member",
      }),
    );
    return response.statusCode == 201;
  }

  // Ambil role user yang sedang login (dipakai untuk routing)
  Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("role");
  }

  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("userId");
  }

  // Logout: hapus semua data session
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
