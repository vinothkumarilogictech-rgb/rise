import 'dart:convert';
import 'dart:io' show Platform, SocketException;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiClient {
  static String? _customBaseUrl;

  /// Allows dynamically configuring a custom API base URL
  /// (e.g. for physical devices connecting to a PC LAN IP like http://192.168.1.50:8000/api)
  static void setCustomBaseUrl(String? url) {
    _customBaseUrl = url?.trim();
  }

  /// Platform-specific default base URL:
  /// - Flutter Web (local development): http://127.0.0.1:8000/api
  /// - Android Emulator: http://10.0.2.2:8000/api
  /// - Physical device / fallback: http://127.0.0.1:8000/api
  static String get platformDefaultBaseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8000/api';
    }
    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:8000/api';
      }
    } catch (_) {}
    return 'http://127.0.0.1:8000/api';
  }

  /// Configurable API base URL:
  /// 1. Runtime override if configured via [setCustomBaseUrl]
  /// 2. Dart define `--dart-define=API_BASE_URL=...`
  ///    (intelligently adapts 10.0.2.2 -> 127.0.0.1 if emulator IP was passed to a Web build)
  /// 3. Platform-specific default URL
  static String get baseUrl {
    if (_customBaseUrl != null && _customBaseUrl!.isNotEmpty) {
      return _customBaseUrl!;
    }
    const envUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (envUrl.isNotEmpty) {
      if (kIsWeb && envUrl.contains('10.0.2.2')) {
        return envUrl.replaceAll('10.0.2.2', '127.0.0.1');
      }
      return envUrl;
    }
    return platformDefaultBaseUrl;
  }

  /// Safely constructs a URI guaranteeing that `/api` is appended exactly once,
  /// whether the base URL has `/api` or not, and whether endpoint has `/api` or not.
  static Uri buildUri(String endpoint) {
    var base = baseUrl.trim();
    while (base.endsWith('/')) {
      base = base.substring(0, base.length - 1);
    }
    var ep = endpoint.trim();
    if (!ep.startsWith('/')) {
      ep = '/$ep';
    }

    // Ensure /api is appended exactly once
    if (base.endsWith('/api')) {
      if (ep.startsWith('/api/')) {
        ep = ep.substring(4);
      } else if (ep == '/api') {
        ep = '';
      }
    } else {
      if (!ep.startsWith('/api/') && ep != '/api') {
        ep = '/api$ep';
      }
    }

    return Uri.parse('$base$ep');
  }

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  String? _cachedToken;

  Future<String?> getToken() async {
    if (_cachedToken != null) return _cachedToken;
    try {
      _cachedToken = await _secureStorage.read(key: 'auth_token');
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      _cachedToken = prefs.getString('auth_token');
    }
    return _cachedToken;
  }

  Future<void> setToken(String token) async {
    _cachedToken = token;
    try {
      await _secureStorage.write(key: 'auth_token', value: token);
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<void> clearToken() async {
    _cachedToken = null;
    try {
      await _secureStorage.delete(key: 'auth_token');
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  Map<String, String> _headers(String? token) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<dynamic> get(String endpoint) async {
    final token = await getToken();
    final uri = buildUri(endpoint);
    try {
      final response = await http
          .get(uri, headers: _headers(token))
          .timeout(const Duration(seconds: 15));
      return _processResponse(response);
    } on SocketException {
      throw ApiException('Cannot reach RISE server. Please check your connection or start the local backend.');
    } on http.ClientException {
      throw ApiException('Cannot connect to RISE backend at $baseUrl. Please verify the server is running.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString());
    }
  }

  Future<dynamic> post(String endpoint, {Map<String, dynamic>? body}) async {
    final token = await getToken();
    final uri = buildUri(endpoint);
    try {
      final response = await http
          .post(
            uri,
            headers: _headers(token),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 25));
      return _processResponse(response);
    } on SocketException {
      throw ApiException('Cannot reach RISE server. Please verify backend is running.');
    } on http.ClientException {
      throw ApiException('Cannot connect to RISE backend at $baseUrl. Please verify the server is running.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString());
    }
  }

  Future<dynamic> patch(String endpoint, {Map<String, dynamic>? body}) async {
    final token = await getToken();
    final uri = buildUri(endpoint);
    try {
      final response = await http
          .patch(
            uri,
            headers: _headers(token),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 15));
      return _processResponse(response);
    } on SocketException {
      throw ApiException('Cannot reach RISE server. Please verify backend is running.');
    } on http.ClientException {
      throw ApiException('Cannot connect to RISE backend at $baseUrl. Please verify the server is running.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString());
    }
  }

  Future<dynamic> delete(String endpoint) async {
    final token = await getToken();
    final uri = buildUri(endpoint);
    try {
      final response = await http
          .delete(uri, headers: _headers(token))
          .timeout(const Duration(seconds: 15));
      return _processResponse(response);
    } on SocketException {
      throw ApiException('Cannot reach RISE server. Please verify backend is running.');
    } on http.ClientException {
      throw ApiException('Cannot connect to RISE backend at $baseUrl. Please verify the server is running.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString());
    }
  }

  dynamic _processResponse(http.Response response) {
    if (response.statusCode == 204) {
      return null;
    }
    final bodyString = response.body.isNotEmpty ? response.body : '{}';
    dynamic bodyJson;
    try {
      bodyJson = jsonDecode(bodyString);
    } catch (_) {
      bodyJson = {'detail': bodyString};
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return bodyJson;
    } else {
      final message = bodyJson is Map && bodyJson.containsKey('detail')
          ? bodyJson['detail'].toString()
          : 'Request failed with status ${response.statusCode}';
      throw ApiException(message, statusCode: response.statusCode);
    }
  }
}
