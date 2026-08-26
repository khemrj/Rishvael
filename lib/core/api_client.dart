import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// DROP-IN REPLACEMENT for your existing core/api_client.dart.
///
/// Every static member your pages already use still exists and behaves the
/// same way, so login_page / signup_page / forgot_password_page /
/// reset_password_page / admin_dashboard compile without a single edit:
///
///   ApiClient.dio            ✅ same
///   ApiClient.baseUrl        ✅ same
///   ApiClient.saveToken()    ✅ same
///   ApiClient.readToken()    ✅ same
///   ApiClient.clearToken()   ✅ same
///
/// What's new underneath: configurable base URL, token caching, 401 refresh
/// with a stampede guard, background JSON decoding, and a session CancelToken.
class ApiClient {
  ApiClient._();

  /// The one instance. Static members below just forward to it — that keeps
  /// your old call sites working while giving new code something injectable.
  static final ApiClient instance = ApiClient._();

  // --------------------------------------------------------------------------
  // CONFIG
  // --------------------------------------------------------------------------

  /// Build-time override:
  ///   flutter run -d RFCRA043GZJ --dart-define=API_BASE_URL=http://192.168.1.69:8080
  ///   flutter build apk --dart-define=API_BASE_URL=https://api.rishvael.com
  ///
  /// A hardcoded LAN IP compiles fine and then dies in production — this is the
  /// one change in this file you should make before your first real build.
  static String get baseUrl {
    const fromDefine = String.fromEnvironment('API_BASE_URL');
    if (fromDefine.isNotEmpty) return fromDefine;

    // Debug fallbacks. 10.0.2.2 is the Android emulator's alias for your host.
    // Physical device on Wi-Fi still needs your LAN IP via --dart-define.
    if (kIsWeb) return 'http://localhost:8080';
    return defaultTargetPlatform == TargetPlatform.android
        ? 'http://10.0.2.2:8080'
        : 'http://localhost:8080';
  }

  static const _publicPrefix = '/api/v1/auth/';
  static const _kAccess = 'access_token';
  static const _kRefresh = 'refresh_token';

  static const _storage = FlutterSecureStorage(
    // Hardware-backed on Android; survives restarts, never iCloud-syncs on iOS.
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  // --------------------------------------------------------------------------
  // DIO
  // --------------------------------------------------------------------------

  static final Dio dio = _build();

  static Dio _build() {
    final d = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        // receiveTimeout is the gap BETWEEN bytes, not total download time.
        receiveTimeout: const Duration(seconds: 20),
        headers: {'Content-Type': 'application/json'},

        // KEPT AS YOU HAD IT — deliberately.
        // Flipping this to strict 2xx would be better design, but it would
        // break every page that currently reads `res.statusCode == 401`.
        // New code (the repository) opts into strict mode per-request instead.
        // See MIGRATION.md §3 for how to flip it later, page by page.
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    // Moves jsonDecode off the UI isolate for every response. One line, and it
    // is 90% of the "should I use isolates?" answer.
    d.transformer = BackgroundTransformer();

    d.interceptors.add(
      // Queued (not plain) so refreshes serialise instead of interleaving.
      QueuedInterceptorsWrapper(
        onRequest: (options, handler) async {
          if (!options.path.startsWith(_publicPrefix)) {
            final token = await readToken();
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          handler.next(options);
        },
        onResponse: (response, handler) async {
          // Because validateStatus allows 4xx, a 401 arrives here as a
          // "success". Catch it here rather than in onError.
          final shouldRefresh = response.statusCode == 401 &&
              !response.requestOptions.path.startsWith(_publicPrefix) &&
              response.requestOptions.extra['__retried'] != true;

          if (!shouldRefresh) return handler.next(response);

          final ok = await _refreshOnce();
          if (!ok) {
            await clearToken();
            onSessionExpired?.call();
            return handler.next(response);
          }

          try {
            final opts = response.requestOptions..extra['__retried'] = true;
            final replay = await dio.fetch<dynamic>(opts);
            return handler.resolve(replay);
          } on DioException {
            return handler.next(response);
          }
        },
        onError: (err, handler) => handler.next(err),
      ),
    );

    if (kDebugMode) {
      d.interceptors.add(
        LogInterceptor(requestBody: true, responseBody: false, error: true),
      );
    }

    return d;
  }

  // --------------------------------------------------------------------------
  // TOKENS — same signatures you already call
  // --------------------------------------------------------------------------

  /// In-memory mirror. Reading the Keychain on every single request costs
  /// 1–5ms on Android; that adds up fast on a dashboard firing four calls.
  static String? _cachedAccess;

  static Future<void> saveToken(String token) async {
    _cachedAccess = token;
    await _storage.write(key: _kAccess, value: token);
  }

  static Future<String?> readToken() async =>
      _cachedAccess ??= await _storage.read(key: _kAccess);

  static Future<void> clearToken() async {
    _cachedAccess = null;
    sessionToken.cancel('signed out');
    sessionToken = CancelToken();
    await _storage.deleteAll();
  }

  /// Call this from login alongside saveToken if your backend issues one.
  /// Safe to skip — refresh simply won't engage.
  static Future<void> saveRefreshToken(String token) =>
      _storage.write(key: _kRefresh, value: token);

  // --------------------------------------------------------------------------
  // SESSION
  // --------------------------------------------------------------------------

  /// Attach to authenticated requests. On sign-out it's cancelled and replaced,
  /// so a late response from the old session can never land in the new one.
  static CancelToken sessionToken = CancelToken();

  /// Set once in main(); fires when refresh is unrecoverable.
  static void Function()? onSessionExpired;

  /// Single-flight guard. Four dashboard calls 401 at once → ONE refresh,
  /// three awaiters. Without this a rotating-refresh backend rejects three of
  /// them and logs the user out at random. That bug takes weeks to reproduce.
  static Completer<bool>? _refreshInFlight;

  static Future<bool> _refreshOnce() {
    final pending = _refreshInFlight;
    if (pending != null) return pending.future;

    final completer = Completer<bool>();
    _refreshInFlight = completer;

    () async {
      try {
        final refresh = await _storage.read(key: _kRefresh);
        if (refresh == null) {
          completer.complete(false);
          return;
        }

        // A BARE Dio on purpose: our interceptor must not run on the refresh
        // call, or a failing refresh triggers another refresh. Forever.
        final bare = Dio(BaseOptions(baseUrl: baseUrl));
        final res = await bare.post<Map<String, dynamic>>(
          '${_publicPrefix}refresh',
          data: {'refreshToken': refresh},
        );
        final body = res.data;
        if (body == null) {
          completer.complete(false);
          return;
        }
        await saveToken(body['accessToken'] as String);
        final newRefresh = body['refreshToken'] as String?;
        if (newRefresh != null) await saveRefreshToken(newRefresh);
        completer.complete(true);
      } catch (_) {
        completer.complete(false);
      } finally {
        _refreshInFlight = null;
      }
    }();

    return completer.future;
  }

  /// Strict 2xx-only options. New code passes this per-request so Dio throws on
  /// 4xx and the repository can convert it to a typed ApiFailure — without
  /// changing the global behaviour your existing pages depend on.
  static Options get strict => Options(
        validateStatus: (s) => s != null && s >= 200 && s < 300,
      );
}
