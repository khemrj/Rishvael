import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'api_client.dart';
import 'api_failure.dart';

/// The one place that knows the backend's envelope shape:
/// { success: bool, message: string, data: T, timestamp: string }
///
/// Every repository (Opportunity, Business, whatever comes next) calls
/// through here instead of touching Dio or the envelope directly. That means
/// there is exactly one place to fix if the envelope shape ever changes,
/// instead of N repositories all doing their own unwrapping.
class ApiService {
  const ApiService();

  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    required T Function(dynamic json) fromJson,
  }) =>
      _send<T>(
        () => ApiClient.dio.get<Map<String, dynamic>>(
          path,
          queryParameters: queryParameters,
          options: ApiClient.strict,
        ),
        fromJson: fromJson,
      );

  Future<T> post<T>(
    String path, {
    Object? data,
    required T Function(dynamic json) fromJson,
  }) =>
      _send<T>(
        () => ApiClient.dio.post<Map<String, dynamic>>(
          path,
          data: data,
          options: ApiClient.strict,
        ),
        fromJson: fromJson,
      );

  Future<T> patch<T>(
    String path, {
    Object? data,
    required T Function(dynamic json) fromJson,
  }) =>
      _send<T>(
        () => ApiClient.dio.patch<Map<String, dynamic>>(
          path,
          data: data,
          options: ApiClient.strict,
        ),
        fromJson: fromJson,
      );

  /// For endpoints that return a real payload on delete (rare, but some
  /// APIs return the deleted entity). For "204 No Content"-style deletes,
  /// use [deleteNoContent] instead.
  Future<T> delete<T>(
    String path, {
    required T Function(dynamic json) fromJson,
  }) =>
      _send<T>(
        () => ApiClient.dio.delete<Map<String, dynamic>>(path, options: ApiClient.strict),
        fromJson: fromJson,
      );

  /// For the far more common case: the server confirms success but there's
  /// nothing meaningful to parse.
  Future<void> deleteNoContent(String path) => _sendVoid(
        () => ApiClient.dio.delete<Map<String, dynamic>>(path, options: ApiClient.strict),
      );

  // --------------------------------------------------------------------------
  // INTERNALS
  // --------------------------------------------------------------------------

  Future<T> _send<T>(
    Future<Response<Map<String, dynamic>>> Function() call, {
    required T Function(dynamic json) fromJson,
  }) async {
    final data = await _unwrap(call);
    try {
      return fromJson(data);
    } catch (e, st) {
      // A malformed/unexpected shape from the backend should never crash the
      // UI or leak a raw TypeError message to the user — but it SHOULD be
      // loud in your logs, because it means the frontend model and the
      // backend DTO have drifted out of sync somewhere.
      debugPrint('ApiService: failed to parse response for $T → $e\n$st');
      throw const ParsingFailure();
    }
  }

  Future<void> _sendVoid(
    Future<Response<Map<String, dynamic>>> Function() call,
  ) async {
    await _unwrap(call);
  }

  /// Shared by [_send] and [_sendVoid]: runs the request, checks transport
  /// errors, checks the envelope's own success flag, and hands back the raw
  /// `data` payload for the caller to parse (or ignore).
  Future<dynamic> _unwrap(
    Future<Response<Map<String, dynamic>>> Function() call,
  ) async {
    try {
      final res = await call();
      final body = res.data;
      if (body == null) {
        throw const ServerFailure('Empty response from server.');
      }

      final success = body['success'] as bool? ?? false;
      if (!success) {
        throw UnknownFailure(body['message'] as String? ?? 'Request failed.');
      }

      return body['data'];
    } on DioException catch (e) {
      throw ApiFailure.from(e);
    } on ApiFailure {
      rethrow;
    } catch (e, st) {
      debugPrint('ApiService: unexpected error → $e\n$st');
      throw const UnknownFailure('Something went wrong. Please try again.');
    }
  }
}