import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralized design tokens matching the reference screenshots:
/// soft off-white background, deep dark text, bright blue accent,
/// subtle grey borders, rounded/handwritten-feel font.
class AppColors {
  static const Color background = Color(0xFFFAF9F6); // soft off-white
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardGrey = Color(0xFFF2F1ED); // light grey preset cards
  static const Color textPrimary = Color(0xFF1C1C1E); // deep dark text
  static const Color textSecondary = Color(0xFF8E8E93);
  static const Color accent = Color(0xFF1E88E5); // bright blue accent
  static const Color accentSoft = Color(0xFFE3F2FD);
  static const Color border = Color(0xFFE5E3DD); // subtle grey border
  static const Color danger = Color(0xFFE53935);
  static const Color success = Color(0xFF43A047);
  static const Color lcdBackground = Color(0xFF1B2A1F); // retro LCD panel
  static const Color lcdDigitOn = Color(0xFF2EF07A);
  static const Color lcdDigitOff = Color(0xFF223B2A);
}

class AppTheme {
  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);
    final textTheme = GoogleFonts.baloo2TextTheme(base.textTheme).apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.accent,
        surface: AppColors.surface,
        error: AppColors.danger,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => Colors.white,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.accent
              : AppColors.border,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.accent,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        elevation: 8,
      ),
    );
  }

  /// Monospaced digit font used inside the retro LCD panel.
  static TextStyle lcdDigits({double size = 56, Color? color}) {
    return GoogleFonts.shareTechMono(
      fontSize: size,
      color: color ?? AppColors.lcdDigitOn,
      fontWeight: FontWeight.w500,
      letterSpacing: 2,
    );
  }
}
