import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/theme/app_colors.dart';
import 'package:flutter_application_1/providers/AuthNotifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_application_1/pages/forgot_password_page.dart';
import '../core/auth_service.dart';
import 'customer_dashboard.dart';
import 'admin_dashboard.dart';
import 'signup_page.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(
    text: kDebugMode ? 'tt@gmail.com' : '',
  );
  final _passwordController = TextEditingController(
    text: kDebugMode ? 'Sometimes@123' : '',
  );
  final _authService = AuthService();

  bool _isLoading = false;
  bool _passwordVisible = false;
  String? _errorMessage;

  // Central Gold & Dark Palette matching RoleSelectionPage
  static const Color backgroundColor = Color(0xFF0A111E);
  static const Color cardBackgroundColor = Color(0xFF0E1729);
  static const Color goldPrimary = Color(0xFFD4AF37);
  static const Color goldDark = Color(0xFF9A7B2C);
  static const Color goldSubtle = Color(0x40C5A059);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    // Clear previous error
    setState(() => _errorMessage = null);

    // Validate form fields first
    if (!_formKey.currentState!.validate()) return;

    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    // Show loading state
    setState(() => _isLoading = true);

    try {
      final result = await _authService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Always check mounted before using context after any async operation
      if (!mounted) return;

      if (result.success) {
        final token = result.token;
        if (token != null) {
          await ref
              .read(authProvider.notifier)
              .setToken(token, userId: result.userId);
        }
        if (!mounted) return;
        // Navigate based on role
        _navigateBasedOnRole(result.role);
      } else {
        // Show server error on screen
        setState(() => _errorMessage = result.error);
      }
    } finally {
      // Always hide loading — runs even if exception thrown
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Navigates to the appropriate dashboard based on role.
  /// Uses pushAndRemoveUntil to clear navigation stack.
  void _navigateBasedOnRole(String? role) {
    final Widget destination;

    switch (role) {
      case 'ROLE_ADMIN':
        destination = const AdminDashboard();
        break;
      case 'ROLE_CUSTOMER':
      default:
        destination = const CustomerDashboard();
        break;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => destination),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Branding Bar
                    const _TopBarSection(),
                    const SizedBox(height: 32),

                    // Header Section
                    const _HeaderSection(),
                    const SizedBox(height: 32),

                    // Server Error Banner
                    if (_errorMessage != null) ...[
                      _ErrorBanner(message: _errorMessage!),
                      const SizedBox(height: 20),
                    ],

                    // Email Field
                    const _FieldLabel(label: 'Email'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      enabled: !_isLoading,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      decoration: _inputDecoration(
                        hintText: 'Enter your email',
                        prefixIcon: Icons.email_outlined,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Email is required';
                        }
                        final emailRegex = RegExp(
                          r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$',
                        );
                        if (!emailRegex.hasMatch(value.trim())) {
                          return 'Enter a valid email address';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // Password Field
                    const _FieldLabel(label: 'Password'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: !_passwordVisible,
                      textInputAction: TextInputAction.done,
                      enabled: !_isLoading,
                      onFieldSubmitted: (_) => _login(),
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      decoration: _inputDecoration(
                        hintText: 'Enter your password',
                        prefixIcon: Icons.lock_outlined,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _passwordVisible
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: Colors.white54,
                            size: 20,
                          ),
                          onPressed: () => setState(
                            () => _passwordVisible = !_passwordVisible,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Password is required';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 10),

                    // Forgot Password Link
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const ForgotPasswordPage(),
                                  ),
                                );
                              },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(
                            color: goldPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Login Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.goldDark,
                          disabledBackgroundColor: goldDark.withValues(
                            alpha: 0.2,
                          ),
                          foregroundColor: Colors.black,
                          disabledForegroundColor: Colors.white38,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.black,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
                                'Login',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Sign Up Link
                    Center(
                      child: GestureDetector(
                        onTap: _isLoading
                            ? null
                            : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const SignupPage(),
                                  ),
                                );
                              },
                        child: RichText(
                          text: const TextSpan(
                            style: TextStyle(fontSize: 14),
                            children: [
                              TextSpan(
                                text: "Don't have an account? ",
                                style: TextStyle(color: goldDark),
                              ),
                              TextSpan(
                                text: 'Sign Up',
                                style: TextStyle(
                                  color: goldPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        color: Colors.white.withValues(alpha: 0.35),
        fontSize: 14,
      ),
      prefixIcon: Icon(prefixIcon, color: goldDark, size: 20),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: cardBackgroundColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: goldSubtle, width: 1.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: goldPrimary, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.redAccent.shade100, width: 1.0),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.8),
      ),
      errorStyle: TextStyle(color: Colors.redAccent.shade100, fontSize: 12),
    );
  }
}

// ============================================================================
// MODULAR SUB-WIDGETS8
// ============================================================================

class _TopBarSection extends StatelessWidget {
  const _TopBarSection();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Diamond Logo Container
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              border: Border.all(color: _LoginPageState.goldDark, width: 1.5),
              borderRadius: BorderRadius.circular(6),
            ),
            transformAlignment: Alignment.center,
            transform: Matrix4.rotationZ(0.785398)..scale(0.75),
            child: Transform.rotate(
              angle: -0.785398,
              child: const Center(
                child: Text(
                  'R',
                  style: TextStyle(
                    color: _LoginPageState.goldPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),

          // Spacing between Logo and Brand Text
          const SizedBox(height: 16),

          // Brand Name Text
          const Text(
            'RISHVAEL',
            style: TextStyle(
              color: _LoginPageState.goldDark,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 3.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderSection extends StatelessWidget {
  const _HeaderSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Center(
          child: Text(
            'Welcome Back',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Serif',
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.15,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'Sign in to your account to continue',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.75),
            ),
          ),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Colors.white.withValues(alpha: 0.9),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2C151B),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.redAccent, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
