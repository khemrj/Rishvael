// lib/core/deep_link_handler.dart
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import '../pages/reset_password_page.dart';

class DeepLinkHandler {
  final AppLinks _appLinks = AppLinks();
  final GlobalKey<NavigatorState> navigatorKey;

  DeepLinkHandler(this.navigatorKey);

  Future<void> init() async {
    // App launched cold by tapping the link
    final initial = await _appLinks.getInitialLink();
    if (initial != null) _handle(initial);

    // App already open when link tapped
    _appLinks.uriLinkStream.listen(_handle);
  }

  void _handle(Uri uri) {
    // Matches rishvael://reset-password?token=XXXX
    if (uri.host == 'reset-password' || uri.path.contains('reset-password')) {
      final token = uri.queryParameters['token'];
      if (token != null && token.isNotEmpty) {
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => ResetPasswordPage(token: token), // token pre-filled!
          ),
        );
      }
    }
  }
}