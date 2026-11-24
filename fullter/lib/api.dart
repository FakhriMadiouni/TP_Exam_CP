import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}

class Api {
  // Téléphone en USB : 127.0.0.1 (après : adb reverse tcp:8081 tcp:8081)
  // Émulateur Android : 10.0.2.2  |  téléphone en Wi-Fi : adresse IP du PC (ipconfig)
  static const String host = '127.0.0.1';
  static const int port = 8081;
  static const String base = 'http://$host:$port/api';
  static const Duration _timeout = Duration(seconds: 10);

  static dynamic _decode(http.Response r) {
    final text = utf8.decode(r.bodyBytes);
    if (r.statusCode >= 400) {
      String msg = 'Erreur HTTP ${r.statusCode}';
      try {
        final j = jsonDecode(text);
        if (j is Map && j['message'] is String && (j['message'] as String).isNotEmpty) {
          msg = j['message'] as String;
        }
      } catch (_) {}
      throw ApiException(msg);
    }
    if (text.isEmpty) return null;
    return jsonDecode(text);
  }

  static String errorText(Object e) {
    if (e is ApiException) return e.message;
    return 'Connexion impossible au serveur (le backend est-il démarré ?)';
  }

  static Future<List<dynamic>> getList(String path) async {
    final r = await http.get(Uri.parse('$base$path')).timeout(_timeout);
    return _decode(r) as List<dynamic>;
  }

  static Future<Map<String, dynamic>> getMap(String path) async {
    final r = await http.get(Uri.parse('$base$path')).timeout(_timeout);
    return _decode(r) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final r = await http
        .post(
          Uri.parse('$base$path'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(_timeout);
    return _decode(r) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> put(
    String path, [
    Map<String, dynamic>? body,
  ]) async {
    final r = await http
        .put(
          Uri.parse('$base$path'),
          headers: {'Content-Type': 'application/json'},
          body: body == null ? null : jsonEncode(body),
        )
        .timeout(_timeout);
    return _decode(r) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> delete(String path) async {
    final r = await http.delete(Uri.parse('$base$path')).timeout(_timeout);
    return _decode(r) as Map<String, dynamic>;
  }
}
