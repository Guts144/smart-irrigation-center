/// Form validators mirroring the backend's Jakarta Validation rules
/// (RegisterRequest / LoginRequest), so users see errors before submitting.
class Validators {
  Validators._();

  static final _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  static String? email(String? value, {int maxLength = 120}) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Email is required';
    if (v.length > maxLength) return 'Email must be at most $maxLength characters';
    if (!_email.hasMatch(v)) return 'Enter a valid email address';
    return null;
  }

  static String? requiredField(String? value, {String label = 'This field'}) {
    if (value == null || value.isEmpty) return '$label is required';
    return null;
  }

  static String? fullName(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Full name is required';
    if (v.length > 100) return 'Full name must be at most 100 characters';
    return null;
  }

  static String? newPassword(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Password is required';
    if (v.length < 8) return 'Password must be at least 8 characters';
    if (v.length > 100) return 'Password must be at most 100 characters';
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) return 'Please confirm your password';
    if (value != password) return 'Passwords do not match';
    return null;
  }
}
