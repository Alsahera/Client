import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // ── Ganti dengan IP/URL Laravel kamu ──────────────────────────────────────
  // Contoh XAMPP lokal dari HP Android: http://192.168.x.x/lakost/public/api
  // Contoh emulator Android:            http://10.0.2.2:8000/api
  // Contoh artisan serve lokal:         http://127.0.0.1:8000/api
  static const String baseUrl = 'http://10.0.2.2:8000/api';

  static String? _token;

  // ── Token Management ────────────────────────────────────────────────────
  static Future<void> saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  static Future<String?> getToken() async {
    if (_token != null) return _token;
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    return _token;
  }

  static Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_name');
    await prefs.remove('user_email');
  }

  // ── Headers ────────────────────────────────────────────────────────────
  static Future<Map<String, String>> _headers() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ── Auth ───────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    return jsonDecode(res.body);
  }

  static Future<void> logout() async {
    final headers = await _headers();
    await http.post(Uri.parse('$baseUrl/logout'), headers: headers);
    await clearToken();
  }

  // ── Generic GET ────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> get(String endpoint) async {
    final headers = await _headers();
    final res = await http.get(Uri.parse('$baseUrl/$endpoint'), headers: headers);
    return jsonDecode(res.body);
  }

  // ── Generic POST ───────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> post(
      String endpoint, Map<String, dynamic> body) async {
    final headers = await _headers();
    final res = await http.post(
      Uri.parse('$baseUrl/$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    );
    return jsonDecode(res.body);
  }

  // ── Generic PUT ────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> put(
      String endpoint, Map<String, dynamic> body) async {
    final headers = await _headers();
    final res = await http.put(
      Uri.parse('$baseUrl/$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    );
    return jsonDecode(res.body);
  }

  // ── Generic DELETE ─────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> delete(String endpoint) async {
    final headers = await _headers();
    final res =
        await http.delete(Uri.parse('$baseUrl/$endpoint'), headers: headers);
    return jsonDecode(res.body);
  }
}