
import 'package:flutter/material.dart';
import 'login_page.dart'; // Import your initial target page

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // Theme palette matching your Rishvael dark/gold design
  static const Color backgroundColor = Color(0xFF0A111E);
  static const Color goldPrimary = Color(0xFFD4AF37);
  static const Color goldDark = Color(0xFF9A7B2C);

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Simulate initialization delay (e.g. checking auth tokens, fetching config)
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Navigate to Login or Dashboard and remove Splash from backstack
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Diamond Logo Emblem
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                border: Border.all(color: goldDark, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              transformAlignment: Alignment.center,
              transform: Matrix4.rotationZ(0.785398)..scale(0.75),
              child: Transform.rotate(
                angle: -0.785398,
                child: const Center(
                  child: Text(
                    'R',
                    style: TextStyle(
                      color: goldPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Brand Title
            const Text(
              'RISHVAEL',
              style: TextStyle(
                color: goldDark,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 4.0,
              ),
            ),

            const SizedBox(height: 48),

            // Gold Loading Indicator
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: goldPrimary,
                strokeWidth: 2.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}