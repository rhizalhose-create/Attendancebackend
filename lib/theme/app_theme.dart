import 'package:flutter/material.dart';

class AppTheme {
  // Colors
  static const Color primaryColor = Color(0xFF2196F3);
  static const Color primaryLight = Color(0xFF90CAF9);
  static const Color primaryDark = Color(0xFF1976D2);
  static const Color secondaryColor = Color(0xFF03A9F4);
  static const Color accentColor = Color(0xFF00BCD4);
  
  static const Color backgroundGradientStart = Color(0xFFE3F2FD);
  static const Color backgroundGradientEnd = Color(0xFFBBDEFB);
  
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color errorColor = Color(0xFFE53935);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFF9800);
  
  // Text Styles - Reduced sizes for modern compact design
  static const TextStyle heading1 = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.bold,
    color: textPrimary,
    letterSpacing: -0.5,
  );
  
  static const TextStyle heading2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: textPrimary,
    letterSpacing: -0.3,
  );
  
  static const TextStyle heading3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );
  
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.normal,
    color: textPrimary,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.normal,
    color: textPrimary,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.normal,
    color: textSecondary,
  );
  
  static const TextStyle buttonText = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: Colors.white,
    letterSpacing: 0.5,
  );
  
  // Spacing - Reduced for compact design
  static const double spacingXS = 4.0;
  static const double spacingSM = 6.0;
  static const double spacingMD = 12.0;
  static const double spacingLG = 18.0;
  static const double spacingXL = 24.0;
  static const double spacingXXL = 32.0;
  
  // Border Radius - Slightly reduced
  static const double radiusSM = 6.0;
  static const double radiusMD = 10.0;
  static const double radiusLG = 14.0;
  static const double radiusXL = 20.0;
  
  // Shadows
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 10,
      offset: Offset(0, 4),
    ),
  ];
  
  static List<BoxShadow> elevatedShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.12),
      blurRadius: 20,
      offset: Offset(0, 8),
    ),
  ];
  
  // Gradient
  static LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [backgroundGradientStart, backgroundGradientEnd],
  );
  
  static LinearGradient buttonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryColor, primaryDark],
  );
  
  // Input Decoration
  static InputDecoration inputDecoration({
    required String label,
    IconData? prefixIcon,
    Widget? suffixIcon,
    String? hint,
    String? helperText,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      helperText: helperText,
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: primaryColor) : null,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.grey[50],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusSM),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusSM),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusSM),
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusSM),
        borderSide: BorderSide(color: errorColor),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusSM),
        borderSide: BorderSide(color: errorColor, width: 2),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: spacingMD, vertical: spacingSM),
      labelStyle: bodyMedium.copyWith(color: textSecondary),
      hintStyle: bodyMedium.copyWith(color: Colors.grey[400]),
    );
  }
  
  // Card Style
  static BoxDecoration cardDecoration = BoxDecoration(
    color: cardColor,
    borderRadius: BorderRadius.circular(radiusLG),
    boxShadow: cardShadow,
  );
  
  // Button Style
  static ButtonStyle primaryButtonStyle = ButtonStyle(
    backgroundColor: MaterialStateProperty.all(primaryColor),
    foregroundColor: MaterialStateProperty.all(Colors.white),
    padding: MaterialStateProperty.all(
      EdgeInsets.symmetric(horizontal: spacingLG, vertical: spacingSM),
    ),
    shape: MaterialStateProperty.all(
      RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusSM),
      ),
    ),
    elevation: MaterialStateProperty.all(2),
  );
  
  static ButtonStyle secondaryButtonStyle = ButtonStyle(
    backgroundColor: MaterialStateProperty.all(Colors.white),
    foregroundColor: MaterialStateProperty.all(primaryColor),
    padding: MaterialStateProperty.all(
      EdgeInsets.symmetric(horizontal: spacingLG, vertical: spacingSM),
    ),
    shape: MaterialStateProperty.all(
      RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusSM),
        side: BorderSide(color: primaryColor, width: 2),
      ),
    ),
  );
}

