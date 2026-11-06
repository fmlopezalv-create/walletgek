import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  // La URL se puede inyectar en compilación:
  //   flutter build apk --dart-define=API_BASE_URL=https://tu-api.onrender.com
  // Por defecto usa el backend local (USB + adb reverse o emulador).
  static const _fromEnv = String.fromEnvironment('API_BASE_URL');
  String baseUrl = _fromEnv.isNotEmpty
      ? _fromEnv
      : 'http://127.0.0.1:3000';
  String? token;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Future<dynamic> get(String path) async {
    final res = await http.get(Uri.parse('$baseUrl$path'), headers: _headers);
    return _decode(res);
  }

  Future<dynamic> post(String path, Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _decode(res);
  }

  Future<dynamic> patch(String path, Map<String, dynamic> body) async {
    final res = await http.patch(
      Uri.parse('$baseUrl$path'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _decode(res);
  }

  Future<dynamic> delete(String path) async {
    final res = await http.delete(Uri.parse('$baseUrl$path'), headers: _headers);
    return _decode(res);
  }

  dynamic _decode(http.Response res) {
    final data = jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return data;
    }
    final message = (data is Map && data['error'] != null)
        ? data['error'].toString()
        : 'Error ${res.statusCode}';
    throw ApiException(message);
  }
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}
