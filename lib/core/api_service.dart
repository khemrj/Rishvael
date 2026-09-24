import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'api_client.dart';
import 'api_failure.dart';

typedef JsonDecoder<T> = T Function(Object? json);

/// Application HTTP boundary.
///
/// Responsibilities:
/// - Execute HTTP requests through Dio.
/// - Interpret the backend ApiResponse envelope.
/// - Convert Dio/network failures into ApiFailure.
/// - Decode payloads into application models.
///
/// Repositories should never need to know about Dio or the
/// backend response envelope.
final class ApiService {
  final Dio _dio;
  final Options _options;

  ApiService({
    Dio? dio,
    Options? options,
  })  : _dio = dio ?? ApiClient.dio,
        _options = options ?? ApiClient.strict;

  // --------------------------------------------------------------------------
  // GET
  // --------------------------------------------------------------------------

  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    required JsonDecoder<T> fromJson,
  }) {
    return _send<T>(
      () => _dio.get<Map<String, dynamic>>(
        path,
        queryParameters: queryParameters,
        options: _options,
      ),
      fromJson: fromJson,
    );
  }

  // --------------------------------------------------------------------------
  // POST
  // --------------------------------------------------------------------------

  Future<T> post<T>(
    String path, {
    Object? data,
    required JsonDecoder<T> fromJson,
  }) {
    return _send<T>(
      () => _dio.post<Map<String, dynamic>>(
        path,
        data: data,
        options: _options,
      ),
      fromJson: fromJson,
    );
  }

  // --------------------------------------------------------------------------
  // PUT
  // --------------------------------------------------------------------------

  Future<T> put<T>(
    String path, {
    Object? data,
    required JsonDecoder<T> fromJson,
  }) {
    return _send<T>(
      () => _dio.put<Map<String, dynamic>>(
        path,
        data: data,
        options: _options,
      ),
      fromJson: fromJson,
    );
  }

  // --------------------------------------------------------------------------
  // PATCH
  // --------------------------------------------------------------------------

  Future<T> patch<T>(
    String path, {
    Object? data,
    required JsonDecoder<T> fromJson,
  }) {
    return _send<T>(
      () => _dio.patch<Map<String, dynamic>>(
        path,
        data: data,
        options: _options,
      ),
      fromJson: fromJson,
    );
  }

  // --------------------------------------------------------------------------
  // DELETE WITH RESPONSE
  // --------------------------------------------------------------------------

  Future<T> delete<T>(
    String path, {
    Object? data,
    required JsonDecoder<T> fromJson,
  }) {
    return _send<T>(
      () => _dio.delete<Map<String, dynamic>>(
        path,
        data: data,
        options: _options,
      ),
      fromJson: fromJson,
    );
  }

  // --------------------------------------------------------------------------
  // DELETE NO CONTENT
  // --------------------------------------------------------------------------

  Future<void> deleteNoContent(
    String path, {
    Object? data,
  }) async {
    try {
      final response = await _dio.delete<Map<String, dynamic>>(
        path,
        data: data,
        options: _options,
      );

      // 204 is a valid success response without a body.
      if (response.statusCode == 204 ||
          response.data == null) {
        return;
      }

      _validateEnvelope(response.data);
    } on DioException catch (e) {
      throw ApiFailure.from(e);
    } on ApiFailure {
      rethrow;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint(
          'ApiService: unexpected DELETE error '
          '→ $e\n$st',
        );
      }

      throw const UnknownFailure(
        'Something went wrong. Please try again.',
      );
    }
  }

  // --------------------------------------------------------------------------
  // SHARED SEND
  // --------------------------------------------------------------------------

  Future<T> _send<T>(
    Future<Response<Map<String, dynamic>>> Function() call, {
    required JsonDecoder<T> fromJson,
  }) async {
    final payload = await _unwrap(call);

    try {
      return fromJson(payload);
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint(
          'ApiService: failed to parse response for $T '
          '→ $e\n$st',
        );
      }

      throw const ParsingFailure();
    }
  }

  // --------------------------------------------------------------------------
  // ENVELOPE
  // --------------------------------------------------------------------------

  Future<Object?> _unwrap(
    Future<Response<Map<String, dynamic>>> Function() call,
  ) async {
    try {
      final response = await call();

      if (kDebugMode) {
        debugPrint('ApiService response: ${response.data}');
      }

      final body = response.data;

      if (body == null) {
        throw const ServerFailure(
          'Empty response from server.',
        );
      }

      _validateEnvelope(body);

      return body['data'];
    } on DioException catch (e) {
      throw ApiFailure.from(e);
    } on ApiFailure {
      rethrow;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint(
          'ApiService: unexpected error → $e\n$st',
        );
      }

      throw const UnknownFailure(
        'Something went wrong. Please try again.',
      );
    }
  }

  void _validateEnvelope(
    Map<String, dynamic>? body,
  ) {
    if (body == null) {
      throw const ServerFailure(
        'Empty response from server.',
      );
    }

    if (body['success'] != true) {
      final message =
          body['message'] is String
              ? body['message'] as String
              : 'Request failed.';

      throw UnknownFailure(message);
    }
  }
}