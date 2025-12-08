enum PasswordStrength { veryWeak, weak, medium, strong, veryStrong }

class PasswordUtils {
  // Returns a score 0..4 and a PasswordStrength enum
  static PasswordStrength estimate(String password) {
    if (password.isEmpty) return PasswordStrength.veryWeak;
    int score = 0;
    if (password.length >= 8) score++; // length
    if (RegExp(r'[A-Z]').hasMatch(password)) score++; // upper
    if (RegExp(r'[0-9]').hasMatch(password)) score++; // digit
    if (RegExp(r'[!@#\$%\^&\*(),.?":{}|<>]').hasMatch(password)) score++; // symbol

    // Map score to strength
    switch (score) {
      case 0:
      case 1:
        return PasswordStrength.weak;
      case 2:
        return PasswordStrength.medium;
      case 3:
        return PasswordStrength.strong;
      case 4:
        return PasswordStrength.veryStrong;
      default:
        return PasswordStrength.veryWeak;
    }
  }

  static String label(PasswordStrength s) {
    switch (s) {
      case PasswordStrength.veryWeak:
        return 'Very Weak';
      case PasswordStrength.weak:
        return 'Weak';
      case PasswordStrength.medium:
        return 'Medium';
      case PasswordStrength.strong:
        return 'Strong';
      case PasswordStrength.veryStrong:
        return 'Very Strong';
    }
  }
}
