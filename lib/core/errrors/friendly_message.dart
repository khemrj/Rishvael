import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';

import '../api_failure.dart';

/// Converts any thrown object into a message a user should read.
/// This is the only place raw error text is allowed to be translated.
String friendlyMessage(Object error) {
  if (error is ApiFailure) return error.message;

  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'The server is taking too long. Please try again.';
      case DioExceptionType.connectionError:
        return 'No connection to the server. Check your network.';
      case DioExceptionType.badResponse:
        final status = error.response?.statusCode ?? 0;
        if (status == 401) return 'Your session has expired. Please log in again.';
        if (status == 403) return 'You do not have permission to do this.';
        if (status == 404) return 'That item could not be found.';
        if (status >= 500) return 'Something went wrong on our side. Please try again.';
        return 'The request could not be completed.';
      case DioExceptionType.cancel:
        return 'The request was cancelled.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  if (error is SocketException) {
    return 'No connection to the server. Check your network.';
  }
  if (error is TimeoutException) {
    return 'The server is taking too long. Please try again.';
  }
  if (error is FormatException) {
    return 'We received data we could not read. Please try again.';
  }
  return 'Something went wrong. Please try again.';
}