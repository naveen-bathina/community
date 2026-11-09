/// Utility functions for validation
class ValidationUtils {
  /// Validate email format
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  /// Validate phone number (basic validation)
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    final phoneRegex = RegExp(r'^\+?[1-9]\d{1,14}$');
    if (!phoneRegex.hasMatch(value.replaceAll(RegExp(r'[\s\-\(\)]'), ''))) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  /// Validate name
  static String? validateName(String? value, {int minLength = 2, int maxLength = 100}) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }
    if (value.length < minLength) {
      return 'Name must be at least $minLength characters';
    }
    if (value.length > maxLength) {
      return 'Name must not exceed $maxLength characters';
    }
    return null;
  }

  /// Validate bar number
  static String? validateBarNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Bar number is required';
    }
    if (value.length < 3) {
      return 'Enter a valid bar number';
    }
    return null;
  }

  /// Validate required field
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Validate message content
  static String? validateMessage(String? value, {int minLength = 1, int maxLength = 5000}) {
    if (value == null || value.trim().isEmpty) {
      return 'Message cannot be empty';
    }
    if (value.length > maxLength) {
      return 'Message is too long (max $maxLength characters)';
    }
    return null;
  }

  /// Validate bio
  static String? validateBio(String? value, {int minLength = 10, int maxLength = 500}) {
    if (value == null || value.isEmpty) {
      return null; // Bio is optional
    }
    if (value.length < minLength) {
      return 'Bio must be at least $minLength characters';
    }
    if (value.length > maxLength) {
      return 'Bio must not exceed $maxLength characters';
    }
    return null;
  }
}
