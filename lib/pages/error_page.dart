import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/api_failure.dart';
// Import your api_failure.dart here

class ErrorPage extends StatelessWidget {
  final ApiFailure failure;
  final VoidCallback? onRetry;

  const ErrorPage({
    super.key,
    required this.failure,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    // Determine icon and theme based on the sealed class subtype
    final (icon, color) = _getFailureDecoration(failure);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 64, color: color),
                const SizedBox(height: 24),
                Text(
                  _getFailureTitle(failure),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  failure.message, // Uses your human-readable failure message
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                
                // Uses your ApiFailureX extension property!
                if (failure.isRetryable && onRetry != null)
                  ElevatedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try Again'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getFailureTitle(ApiFailure failure) {
    return switch (failure) {
      NetworkFailure() => 'Connection Error',
      TimeoutFailure() => 'Request Timed Out',
      UnauthorizedFailure() => 'Session Expired',
      ForbiddenFailure() => 'Access Denied',
      NotFoundFailure() => 'Not Found',
      ServerFailure() => 'Server Unavailable',
      _ => 'Something Went Wrong',
    };
  }

  (IconData, Color) _getFailureDecoration(ApiFailure failure) {
    return switch (failure) {
      NetworkFailure() || TimeoutFailure() => (Icons.wifi_off_rounded, Colors.orange),
      UnauthorizedFailure() || ForbiddenFailure() => (Icons.lock_outline_rounded, Colors.red),
      ServerFailure() => (Icons.dns_rounded, Colors.red),
      _ => (Icons.error_outline_rounded, Colors.redAccent),
    };
  }
}