import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/api_failure.dart';
import 'package:flutter_application_1/pages/admin_dashboard.dart';
import 'package:flutter_application_1/pages/business_dashboard.dart';

import '../../core/user_role.dart';
import '../customer_dashboard.dart';
import '../error_page.dart';
/// The ONLY place in the app that decides "which dashboard for which
/// role". AppBootstrap calls this once; nothing else needs to know the
/// mapping. Adding a fifth role later means editing this switch and
/// nowhere else.
class DashboardRouter extends StatelessWidget {
  const DashboardRouter({super.key, required this.role});

  final UserRole role;

 @override
Widget build(BuildContext context) {
  final Widget page = switch (role) {
    UserRole.customer => const CustomerDashboard(),
    UserRole.admin => const AdminDashboard(),
    UserRole.business => const DashboardScreen(),
    UserRole.moderator => const AdminDashboard(),
    UserRole.unknown => const ErrorPage(
        failure: UnknownFailure(
          'Your account role could not be determined. '
          'Please log in again.',
        ),
        onRetry: null,
      ),
  };

  return page;
}
}