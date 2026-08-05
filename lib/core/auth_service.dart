// lib/services/auth_service.dart

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/api_client.dart';

/// Result object returned from every auth operation.
/// Carries success flag, optional error message,
/// and parsed user info on successful login.
class AuthResult {
  final bool success;
  final String? error;
  final String? role;
  final String? token;
  final String? username;
  final String? email;

  const AuthResult({
    required this.success,
    this.error,
    this.role,
    this.token,
    this.username,
    this.email,
  });
}

class AuthService {
  // Single instance — no need to recreate every call
  static const _storage = FlutterSecureStorage();

  // ── SIGNUP ──────────────────────────────────────────────────
  Future<AuthResult> signup({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      final res = await ApiClient.dio.post(
        '/api/v1/auth/signup',
        data: {
          'username': username,
          'email': email,
          'password': password,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      // Spring Boot returns 201 Created on successful signup
      if (res.statusCode == 200 || res.statusCode == 201) {
        // Signup response also has nested data
        // Save token immediately so user is logged in after signup
        final wrapper = res.data as Map<String, dynamic>?;
        final data = wrapper?['data'] as Map<String, dynamic>?;

        if (data != null && data['token'] != null) {
          await _saveSession(data);
          return AuthResult(
            success: true,
            role: data['role'] as String?,
            token: data['token'] as String?,
            username: data['username'] as String?,
            email: data['email'] as String?,
          );
        }

        return const AuthResult(success: true);
      }

      return AuthResult(
        success: false,
        error: _extractError(res),
      );
    } on DioException catch (e) {
      return AuthResult(
        success: false,
        error: _networkError(e),
      );
    }
  }

  // ── LOGIN ───────────────────────────────────────────────────
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final res = await ApiClient.dio.post(
        '/api/v1/auth/login',
        data: {
          'email': email,
          'password': password,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      if (res.statusCode == 200) {
        // ── Parse the NESTED response structure ──────────────
        // Spring Boot wraps everything in ApiResponse<T>:
        // {
        //   "success": true,
        //   "message": "Login successful",
        //   "data": {               ← AuthResponse is HERE
        //     "token": "eyJ...",
        //     "role": "ROLE_CUSTOMER",
        //     "userId": 2,
        //     ...
        //   }
        // }
        final wrapper = res.data as Map<String, dynamic>?;

        // Verify server confirms success
        final serverSuccess = wrapper?['success'] as bool? ?? false;
        if (!serverSuccess) {
          return AuthResult(
            success: false,
            error: wrapper?['message'] as String? ??
                'Login failed',
          );
        }

        // Extract nested data object
        final data = wrapper?['data'] as Map<String, dynamic>?;

        if (data == null) {
          return const AuthResult(
            success: false,
            error: 'Invalid response from server',
          );
        }

        final token = data['token'] as String?;
        final role = data['role'] as String?;

        if (token == null || role == null) {
          return const AuthResult(
            success: false,
            error: 'Missing token or role in response',
          );
        }

        // ── Save session securely ────────────────────────────
        await _saveSession(data);

        return AuthResult(
          success: true,
          role: role,
          token: token,
          username: data['username'] as String?,
          email: data['email'] as String?,
        );
      }

      return AuthResult(
        success: false,
        error: _extractError(res),
      );
    } on DioException catch (e) {
      return AuthResult(
        success: false,
        error: _networkError(e),
      );
    }
  }

  // ── LOGOUT ──────────────────────────────────────────────────
  Future<void> logout() async {
    await ApiClient.clearToken();
    await _storage.delete(key: 'user_role');
    await _storage.delete(key: 'user_email');
    await _storage.delete(key: 'username');
  }

  // ── HELPERS ─────────────────────────────────────────────────

  /// Saves JWT token and user info to secure storage.
  /// Called after both successful login and signup.
  Future<void> _saveSession(Map<String, dynamic> data) async {
    final token = data['token'] as String?;
    if (token != null) {
      await ApiClient.saveToken(token);
    }
    // Store role so app can read it on next launch
    // without hitting the server again
    if (data['role'] != null) {
      await _storage.write(
        key: 'user_role',
        value: data['role'] as String,
      );
    }
    if (data['email'] != null) {
      await _storage.write(
        key: 'user_email',
        value: data['email'] as String,
      );
    }
    if (data['username'] != null) {
      await _storage.write(
        key: 'username',
        value: data['username'] as String,
      );
    }
  }

  /// Extracts the human-readable error from server response.
  /// Handles both wrapped and unwrapped error formats.
  String _extractError(Response res) {
    final data = res.data;
    if (data is Map) {
      // Try nested message first
      final message = data['message'];
      if (message != null) return message.toString();
    }
    // Fallback to status code based messages
    switch (res.statusCode) {
      case 401:
        return 'Invalid email or password';
      case 403:
        return 'Access denied';
      case 409:
        return 'Account already exists';
      case 429:
        return 'Too many attempts. Please wait a moment.';
      case 500:
        return 'Server error. Please try again later.';
      default:
        return 'Something went wrong (${res.statusCode})';
    }
  }

  /// Converts DioException into user-friendly message.
  String _networkError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.connectionError:
        return 'Cannot reach server. Check Wi-Fi and base URL.';
      case DioExceptionType.receiveTimeout:
        return 'Server is taking too long. Please retry.';
      case DioExceptionType.badResponse:
        // Server responded with error status code
        // Try to extract message from error response body
        final data = e.response?.data;
        if (data is Map && data['message'] != null) {
          return data['message'].toString();
        }
        return _extractError(e.response!);
      default:
        return e.message ?? 'Network error. Please try again.';
    }
  }
  /// Step 1 — request a reset link. Hits POST /api/v1/auth/forgot-password
Future<AuthResult> forgotPassword({required String email}) async {
  try {
    final res = await ApiClient.dio.post('/api/v1/auth/forgot-password', data: {
      'email': email,
    });
    if (res.statusCode == 200) {
      return AuthResult(success: true);
    }
    return AuthResult(success: false, error: _extractError(res));
  } on DioException catch (e) {
    return AuthResult(success: false, error: _networkError(e));
  } catch (e) {
    return AuthResult(success: false, error: 'Unexpected error: $e');
  }
}

/// Step 2 — submit token + new password. Hits POST /api/v1/auth/reset-password
Future<AuthResult> resetPassword({
  required String token,
  required String newPassword,
}) async {
  try {
    final res = await ApiClient.dio.post('/api/v1/auth/reset-password', data: {
      'token': token,
      'newPassword': newPassword,
    });
    if (res.statusCode == 200) {
      return AuthResult(success: true);
    }
    return AuthResult(success: false, error: _extractError(res));
  } on DioException catch (e) {
    return AuthResult(success: false, error: _networkError(e));
  } catch (e) {
    return AuthResult(success: false, error: 'Unexpected error: $e');
  }
}
}