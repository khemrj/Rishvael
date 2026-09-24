import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// One closed family of errors the UI is allowed to see.
///
/// `sealed` = the compiler knows every subtype lives in THIS file.
/// That is what makes `switch` exhaus8tive: forget a case and you get a
/// compile error, not a 3am crash. Never let a raw `DioException` reach a
/// widget — widgets should never know what HTTP is.
sealed class ApiFailure implements Exception {
  const ApiFailure(this.message);

  /// Already human-readable. Never show `e.toString()` to a user.
  final String message;

  @override
  String toString() => '$runtimeType($message)';

  /// The single funnel: every raw error becomes a typed failure here.
  static ApiFailure from(Object error) {
    if (error is ApiFailure) return error;
    if (error is! DioException) {
      if (kDebugMode) debugPrint('ApiFailure.from: unexpected error → $error');
      return const UnknownFailure('Something unexpected happened.');
    }
    // ...unchanged switch below

    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout => const TimeoutFailure(),
      DioExceptionType.cancel => const CancelledFailure(),
      DioExceptionType.connectionError ||
      DioExceptionType.unknown => const NetworkFailure(),
      DioExceptionType.badCertificate => const NetworkFailure(
        'Could not verify a secure connection.',
      ),
      DioExceptionType.badResponse => _fromStatus(error.response),
      // TODO: Handle this case.
      DioExceptionType.transformTimeout => throw UnimplementedError(),
    };
  }

  static ApiFailure _fromStatus(Response<dynamic>? res) {
    final code = res?.statusCode ?? 0;
    // Backend contract (GlobalExceptionHandler.handleValidationErrors):
    // { "success": false, "message": "Validation failed",
    //   "fieldErrors": { "field": "reason" } }
    // Field is literally named "fieldErrors", not "errors".
    final body = res?.data is Map<String, dynamic>
        ? res!.data as Map<String, dynamic>
        : const <String, dynamic>{};
    final serverMessage = body['message'] as String?;

    return switch (code) {
      401 => const UnauthorizedFailure(),
      403 => const ForbiddenFailure(),
      404 => const NotFoundFailure(),
      409 => ConflictFailure(serverMessage ?? 'That already exists.'),
      422 || 400 => ValidationFailure(
        serverMessage ?? 'Please check the highlighted fields.',
        fieldErrors: switch (body['fieldErrors']) {
          final Map<String, dynamic> m => m.map((k, v) => MapEntry(k, '$v')),
          _ => const {},
        },
      ),
      429 => const RateLimitedFailure(),
      >= 500 => ServerFailure(serverMessage ?? 'Something broke on our side.'),
      _ => UnknownFailure(serverMessage ?? 'Unexpected response ($code).'),
    };
  }
}

// `final class` = nobody outside can extend it. Locks the hierarchy shut.
final class NetworkFailure extends ApiFailure {
  const NetworkFailure([super.message = 'You appear to be offline.']);
}

final class TimeoutFailure extends ApiFailure {
  const TimeoutFailure([super.message = 'The server took too long to reply.']);
}

final class UnauthorizedFailure extends ApiFailure {
  const UnauthorizedFailure([super.message = 'Your session has expired.']);
}

final class ForbiddenFailure extends ApiFailure {
  const ForbiddenFailure([super.message = 'You do not have access to this.']);
}

final class NotFoundFailure extends ApiFailure {
  const NotFoundFailure([super.message = 'We could not find that.']);
}

final class ConflictFailure extends ApiFailure {
  const ConflictFailure(super.message);
}

final class RateLimitedFailure extends ApiFailure {
  const RateLimitedFailure([
    super.message = 'Too many attempts. Wait a moment.',
  ]);
}

final class ServerFailure extends ApiFailure {
  const ServerFailure([super.message = 'Something broke on our side.']);
}

final class ParsingFailure extends ApiFailure {
  const ParsingFailure([
    super.message = 'We had trouble reading the server response.',
  ]);
}

/// Not an error the user caused — a request we deliberately aborted.
/// Swallow this one silently in the UI.
final class CancelledFailure extends ApiFailure {
  const CancelledFailure([super.message = 'Request cancelled.']);
}

final class ValidationFailure extends ApiFailure {
  const ValidationFailure(super.message, {this.fieldErrors = const {}});

  /// Maps directly onto `TextFormField.errorText` — field name → reason.
  final Map<String, String> fieldErrors;
}

final class UnknownFailure extends ApiFailure {
  const UnknownFailure(super.message);
}

/// Extension = add behaviour to a type you don't own (or don't want to bloat).
/// Zero runtime cost; resolved at compile time.
extension ApiFailureX on ApiFailure {
  /// Retrying a 403 is pointless. Retrying a timeout is not.
  bool get isRetryable => switch (this) {
    NetworkFailure() || TimeoutFailure() || ServerFailure() => true,
    _ => false,
  };

  /// Signal to nuke the token and bounce to login.
  bool get requiresReauth => this is UnauthorizedFailure;
}
