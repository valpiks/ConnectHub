import 'package:flutter/material.dart';

class AppColors {
  // Main Accents (Kaleidoscope Palette)
  static const Color electricBlue = Color(0xFF4361EE);
  static const Color neonPink = Color(0xFFFF3E80);
  static const Color cyberPurple = Color(0xFF9D4EDD);
  static const Color limeGreen = Color(0xFFA7F432);
  static const Color sunsetOrange = Color(0xFFFF6B35);
  static const Color aquaCyan = Color(0xFF00D2FF);
  static const Color goldYellow = Color(0xFFFFD300);
  static const Color hotMagenta = Color(0xFFFF00FF);

  // Backgrounds
  static const Color background = Color(0xFFFFFFFF);
  static const Color backgroundSecondary = Color(0xFFF8F9FF);
  static const Color backgroundTertiary = Color(0xFFF0F2FF);
  
  // Text
  static const Color text = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF4A4A6A);
  static const Color textTertiary = Color(0xFF7A7A9A);
  static const Color textInverted = Color(0xFFFFFFFF);

  // Status
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  
  // UI Elements
  static const Color border = Color(0xFFE5E7FF);
  static const Color cardHighlight = Color(0x0D4361EE); // 0.05 opacity
}

class AppGradients {
  static const LinearGradient primary = LinearGradient(
    colors: [AppColors.electricBlue, AppColors.cyberPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient energy = LinearGradient(
    colors: [AppColors.neonPink, AppColors.sunsetOrange],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient fresh = LinearGradient(
    colors: [AppColors.aquaCyan, AppColors.limeGreen],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient like = LinearGradient(
    colors: [Color(0xFF4cd964), Color(0xFF2ecc71)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient nope = LinearGradient(
    colors: [Color(0xFFff3b30), Color(0xFFff9500)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'Inter',
      colorScheme: const ColorScheme.light(
        primary: AppColors.electricBlue,
        secondary: AppColors.neonPink,
        surface: AppColors.background,
        background: AppColors.background,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.text,
        onBackground: AppColors.text,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: AppColors.text, fontWeight: FontWeight.bold, fontSize: 32),
        displayMedium: TextStyle(color: AppColors.text, fontWeight: FontWeight.bold, fontSize: 24),
        bodyLarge: TextStyle(color: AppColors.text, fontSize: 16),
        bodyMedium: TextStyle(color: AppColors.textSecondary, fontSize: 14),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.backgroundSecondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.electricBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.neonPink),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.electricBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
