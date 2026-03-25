import 'package:flutter/material.dart';

/// App-wide color palette and theme data (dark + light).
class AppTheme {
  // Brand colors
  static const Color primaryColor = Color(0xFF7C4DFF);      // Deep purple
  static const Color accentColor = Color(0xFFFF6D00);       // Vivid orange
  static const Color surfaceDark = Color(0xFF1A1A2E);       // Dark navy
  static const Color surfaceCard = Color(0xFF16213E);       // Card background
  static const Color surfaceElevated = Color(0xFF0F3460);   // Elevated surface
  static const Color textPrimary = Color(0xFFEEEEEE);
  static const Color textSecondary = Color(0xFF9E9E9E);

  static ThemeData darkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: primaryColor,
        secondary: accentColor,
        surface: surfaceDark,
        onSurface: textPrimary,
        onPrimary: Colors.white,
      ),
      scaffoldBackgroundColor: surfaceDark,
      cardColor: surfaceCard,
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceDark,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceCard,
        indicatorColor: primaryColor.withValues(alpha: 0.2),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(color: textSecondary, fontSize: 12),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: primaryColor,
        inactiveTrackColor: primaryColor.withValues(alpha: 0.3),
        thumbColor: accentColor,
        overlayColor: accentColor.withValues(alpha: 0.2),
      ),
      iconTheme: const IconThemeData(color: textPrimary),
      textTheme: const TextTheme(
        displayMedium: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
        titleLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: textPrimary),
        bodyMedium: TextStyle(color: textSecondary),
        bodySmall: TextStyle(color: textSecondary),
      ),
    );
  }
}
