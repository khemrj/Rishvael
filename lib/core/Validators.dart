class validators {
  static String? username(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Username is required';
    if (v.length < 3 || v.length > 20) return 'Username must be 3–20 characters';
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(v)) {
      return 'Only letters, numbers and underscore allowed';
    }
    return null;
  }

  static String? email(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Email is required';
    final pattern = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');
    if (!pattern.hasMatch(v)) return 'Enter a valid email';
    return null;
  }

  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Password is required';
    if (v.length < 8) return 'At least 8 characters';
    if (!RegExp(r'[A-Z]').hasMatch(v)) return 'Include an uppercase letter';
    if (!RegExp(r'[a-z]').hasMatch(v)) return 'Include a lowercase letter';
    if (!RegExp(r'\d').hasMatch(v)) return 'Include a number';
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if ((value ?? '').isEmpty) return 'Confirm your password';
    if (value != original) return 'Passwords do not match';
    return null;
  }
}