// lib/pages/customer_dashboard.dart
import 'package:flutter/material.dart';
import '../core/api_client.dart';
import 'login_page.dart';

class CustomerDashboard extends StatelessWidget {
  const CustomerDashboard({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trading Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ApiClient.clearToken();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                    (route) => false);
              }
            },
          ),
        ],
      ),
      body: const Center(child: Text('Customer view — trades, portfolio, etc.')),
    );
  }
}