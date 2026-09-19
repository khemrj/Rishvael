
import 'dart:convert';

/// Minimal, dependency-free JWT payload decoder.
///
/// Deliberately does NOT verify the signature — verification is the
/// server's job (it already happened when the token was issued and on
/// every subsequent request via ApiClient's Authorization header). This
/// decoder exists ONLY to read claims already trusted by the fact that
/// ApiClient successfully stored the token after a real login/refresh
/// response. Never use this to make a security decision — only to read
/// display/routing data (role, email, expiry) already implied by
/// possessing the token.
abstract final class JwtDecoder {
  static Map<String, dynamic> decode(String token) {
    final parts = token.split('.');
    if (parts.length != 3) {
      throw const FormatException('Invalid JWT: expected 3 segments');
    }

    final payload = _base64UrlDecode(parts[1]);
    return jsonDecode(payload) as Map<String, dynamic>;
  }

  static String _base64UrlDecode(String segment) {
    // JWT base64url omits padding; base64.normalize restores it before
    // Dart's decoder (which requires correctly padded input) touches it.
    final normalized = base64.normalize(segment);
    return utf8.decode(base64Url.decode(normalized));
  }

  static DateTime? expiryOf(String token) {
    final exp = decode(token)['exp'];
    if (exp is! int) return null;
    return DateTime.fromMillisecondsSinceEpoch(exp * 1000);
  }

  static bool isExpired(String token) {
    final expiry = expiryOf(token);
    if (expiry == null) return false; // no exp claim → treat as non-expiring
    return DateTime.now().isAfter(expiry);
  }
}