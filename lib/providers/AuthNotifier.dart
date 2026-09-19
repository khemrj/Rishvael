import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_client.dart';
import '../core/jwt_decoder.dart';
import '../core/user_role.dart';

enum AuthStatus { initial, authenticated, unauthenticated }

/// Session state. Carries everything a routing decision needs (status +
/// role) so no other widget has to re-decode the JWT independently —
/// decoding happens exactly once, here, whenever a token is set or loaded.
class AuthState {
  const AuthState._({
    required this.status,
    this.token,
    this.role = UserRole.unknown,
  });

  final AuthStatus status;
  final String? token;
  final UserRole role;

  factory AuthState.initial() => const AuthState._(status: AuthStatus.initial);

  factory AuthState.authenticated(String token, UserRole role) =>
      AuthState._(status: AuthStatus.authenticated, token: token, role: role);

  factory AuthState.unauthenticated() =>
      const AuthState._(status: AuthStatus.unauthenticated);
}

class AuthNotifier extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() => _restoreSession();

  /// Runs once at app start (via AsyncNotifier's build) — reads whatever
  /// token ApiClient already has cached/persisted and decides the
  /// resulting AuthState from it, including role.
  Future<AuthState> _restoreSession() async {
    try {
      final token = await ApiClient.readToken();
      if (token == null || token.isEmpty) {
        return AuthState.unauthenticated();
      }

      // A stale/expired token is intentionally still treated as
      // "authenticated" here — see the doc comment on AppBootstrap:
      // validating expiry is ApiClient's 401→refresh flow's job, not
      // this notifier's. This only decides "do we have a role to route
      // on", not "is this token still valid for API calls".
      final role = _extractRole(token);
      return AuthState.authenticated(token, role);
    } catch (_) {
      return AuthState.unauthenticated();
    }
  }

  /// Call this after a successful login/signup API response.
  Future<void> setToken(String token) async {
    await ApiClient.saveToken(token);
    final role = _extractRole(token);
    state = AsyncData(AuthState.authenticated(token, role));
  }

  /// Call this on explicit logout, or let ApiClient.onSessionExpired
  /// (wired in main.dart) call it automatically on an unrecoverable 401.
  Future<void> logout() async {
    await ApiClient.clearToken();
    state = AsyncData(AuthState.unauthenticated());
  }

  UserRole _extractRole(String token) {
    try {
      final claims = JwtDecoder.decode(token);
      // Matches your Spring Boot JwtService: claim("role", user.getRole().name())
      return UserRole.fromWireValue(claims['role'] as String?);
    } catch (_) {
      return UserRole.unknown;
    }
  }
}

final authProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);