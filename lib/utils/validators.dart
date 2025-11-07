/// Form Validation Utilities for PrevailMart
/// Provides common validation functions for forms

class Validators {
  /// Email validation regex pattern (RFC 5322 compliant)
  static final RegExp _emailRegex = RegExp(
    r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$",
  );

  /// Phone number validation regex (international format)
  static final RegExp _phoneRegex = RegExp(
    r'^\+?[1-9]\d{1,14}$',
  );

  /// Password strength regex (at least 8 characters)
  static final RegExp _passwordRegex = RegExp(
    r'^.{8,}$',
  );

  /// Strong password regex (8+ chars, uppercase, lowercase, number, special char)
  static final RegExp _strongPasswordRegex = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$',
  );

  /// Validate email address
  /// Returns null if valid, error message if invalid
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }

    final trimmedValue = value.trim();

    if (trimmedValue.isEmpty) {
      return 'Email is required';
    }

    if (!_emailRegex.hasMatch(trimmedValue)) {
      return 'Please enter a valid email address';
    }

    // Additional checks for common mistakes
    if (trimmedValue.endsWith('.')) {
      return 'Email cannot end with a dot';
    }

    if (trimmedValue.contains('..')) {
      return 'Email cannot contain consecutive dots';
    }

    if (!trimmedValue.contains('@')) {
      return 'Email must contain @ symbol';
    }

    final parts = trimmedValue.split('@');
    if (parts.length != 2) {
      return 'Email must contain exactly one @ symbol';
    }

    if (parts[1].isEmpty || !parts[1].contains('.')) {
      return 'Email domain must contain a dot';
    }

    return null; // Valid email
  }

  /// Validate password
  /// Returns null if valid, error message if invalid
  static String? validatePassword(String? value, {bool requireStrong = false}) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }

    if (requireStrong && !_strongPasswordRegex.hasMatch(value)) {
      return 'Password must contain uppercase, lowercase, number, and special character';
    }

    return null; // Valid password
  }

  /// Validate required field
  /// Returns null if valid, error message if invalid
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Validate phone number
  /// Returns null if valid, error message if invalid
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }

    final cleaned = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    if (cleaned.length < 10) {
      return 'Phone number must be at least 10 digits';
    }

    if (!RegExp(r'^[\d\+]+$').hasMatch(cleaned)) {
      return 'Phone number can only contain digits and +';
    }

    return null; // Valid phone
  }

  /// Validate name (no numbers or special characters except spaces, hyphens, apostrophes)
  /// Returns null if valid, error message if invalid
  static String? validateName(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }

    final trimmedValue = value.trim();

    if (trimmedValue.length < 2) {
      return '$fieldName must be at least 2 characters';
    }

    if (!RegExp(r"^[a-zA-Z\s\-']+$").hasMatch(trimmedValue)) {
      return '$fieldName can only contain letters, spaces, hyphens, and apostrophes';
    }

    return null;
  }

  /// Validate minimum length
  /// Returns null if valid, error message if invalid
  static String? validateMinLength(String? value, int minLength, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }

    if (value.length < minLength) {
      return '$fieldName must be at least $minLength characters';
    }

    return null;
  }

  /// Validate maximum length
  /// Returns null if valid, error message if invalid
  static String? validateMaxLength(String? value, int maxLength, String fieldName) {
    if (value == null) {
      return null;
    }

    if (value.length > maxLength) {
      return '$fieldName must not exceed $maxLength characters';
    }

    return null;
  }

  /// Validate number
  /// Returns null if valid, error message if invalid
  static String? validateNumber(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }

    if (double.tryParse(value) == null) {
      return '$fieldName must be a valid number';
    }

    return null;
  }

  /// Validate positive number
  /// Returns null if valid, error message if invalid
  static String? validatePositiveNumber(String? value, String fieldName) {
    final numberError = validateNumber(value, fieldName);
    if (numberError != null) return numberError;

    if (double.parse(value!) <= 0) {
      return '$fieldName must be greater than 0';
    }

    return null;
  }

  /// Validate matching fields (e.g., password confirmation)
  /// Returns null if valid, error message if invalid
  static String? validateMatch(String? value, String? matchValue, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }

    if (value != matchValue) {
      return '${fieldName}s do not match';
    }

    return null;
  }

  /// Validate URL
  /// Returns null if valid, error message if invalid
  static String? validateUrl(String? value, {bool required = false}) {
    if (!required && (value == null || value.isEmpty)) {
      return null;
    }

    if (required && (value == null || value.isEmpty)) {
      return 'URL is required';
    }

    try {
      final uri = Uri.parse(value!);
      if (!uri.hasScheme || !uri.hasAuthority) {
        return 'Please enter a valid URL';
      }
    } catch (e) {
      return 'Please enter a valid URL';
    }

    return null;
  }

  /// Check if email is valid (boolean)
  static bool isValidEmail(String? value) {
    return validateEmail(value) == null;
  }

  /// Check if phone is valid (boolean)
  static bool isValidPhone(String? value) {
    return validatePhone(value) == null;
  }

  /// Check if password is valid (boolean)
  static bool isValidPassword(String? value, {bool requireStrong = false}) {
    return validatePassword(value, requireStrong: requireStrong) == null;
  }
}
