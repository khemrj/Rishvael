import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  // ⚠️ CHANGE THIS to your PC's LAN IP (run `ipconfig` / `ifconfig`).
  // Phone and PC must be on the same Wi-Fi. Example: 192.168.1.5
  static const String baseUrl = 'http://10.84.197.231:8080';

  static final _storage = const FlutterSecureStorage();
  static const _tokenKey = 'access_token';

  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
      // Don't throw on 4xx — we handle those ourselves
      validateStatus: (status) => status != null && status < 500,
    ),
  )..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Do not attach token to public auth endpoints
          if (!options.path.startsWith('/api/v1/auth/')) {
            final token = await _storage.read(key: _tokenKey);
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          return handler.next(options);
        },
      ),
    );

  static Future<void> saveToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  static Future<String?> readToken() => _storage.read(key: _tokenKey);

  static Future<void> clearToken() => _storage.delete(key: _tokenKey);
}