/// Lightweight input validators for the demo sign-in and sign-up forms.
///
/// No real authentication happens; these only give the forms enough structure
/// to show inline error messages and to let the test suite verify the rules.
class Credentials {
  Credentials._();

  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  /// Returns an error string when [value] is not shaped like an email address,
  /// or `null` when the format is acceptable.
  static String? emailError(String value) {
    if (_emailPattern.hasMatch(value)) return null;
    return 'Enter a valid email address.';
  }

  /// Returns an error string when [value] has fewer than eight characters, or
  /// `null` when the length is acceptable.
  static String? passwordError(String value) {
    if (value.length >= 8) return null;
    return 'Password must be at least 8 characters.';
  }
}
