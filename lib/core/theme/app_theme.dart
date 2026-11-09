import 'package:flutter/material.dart';

/// Material Design 3 theme configuration with high-contrast professional colors for legal app
class AppTheme {
  // Professional color palette (deep legal blues and grays with high contrast)
  static const Color primaryBlue = Color(0xFF1565C0); // Deep blue
  static const Color primaryLight = Color(0xFF5E92F3); // Light blue
  static const Color primaryDark = Color(0xFF003C8F); // Dark blue

  static const Color secondaryGray = Color(0xFF455A64); // Darker blue gray for stronger contrast
  static const Color secondaryLight = Color(0xFF819CA9);
  static const Color secondaryDark = Color(0xFF29434E);

  static const Color errorRed = Color(0xFFD32F2F);
  static const Color successGreen = Color(0xFF2E7D32);
  static const Color warningOrange = Color(0xFFEF6C00);

  // Background colors
  static const Color backgroundLight = Color(0xFFF5F7FA);
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E1E1E);

  // Text colors
  static const Color textPrimaryLight = Color(0xFF1A1A1A);
  static const Color textSecondaryLight = Color(0xFF4A5568);
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFFD1D5DB);

  /// Light theme
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: primaryBlue,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFD6E4FF),
      onPrimaryContainer: Color(0xFF002D6B),
      secondary: secondaryGray,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFE2E8F0),
      onSecondaryContainer: Color(0xFF1E293B),
      error: errorRed,
      onError: Colors.white,
      surface: surfaceLight,
      onSurface: textPrimaryLight,
    ),
    scaffoldBackgroundColor: backgroundLight,
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: true,
      backgroundColor: primaryBlue,
      foregroundColor: Colors.white,
      iconTheme: IconThemeData(color: Colors.white),
      actionsIconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: surfaceLight,
      selectedItemColor: primaryBlue,
      unselectedItemColor: Color(0xFF64748B),
      selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
      unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: Colors.white,
      unselectedLabelColor: Colors.white70,
      indicatorColor: Colors.white,
      labelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      color: surfaceLight,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      labelStyle: const TextStyle(color: textSecondaryLight),
      hintStyle: const TextStyle(color: Color(0xFF64748B)),
      prefixIconColor: primaryBlue,
      suffixIconColor: textSecondaryLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryBlue, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: errorRed, width: 1.5),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        disabledBackgroundColor: const Color(0xFFCBD5E1),
        disabledForegroundColor: const Color(0xFF64748B),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryBlue,
        side: const BorderSide(color: primaryBlue, width: 1.5),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryBlue,
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryBlue,
      foregroundColor: Colors.white,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFFE0ECFF),
      selectedColor: primaryBlue,
      checkmarkColor: Colors.white,
      secondarySelectedColor: primaryBlue,
      labelStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Color(0xFF0D3B66),
      ),
      secondaryLabelStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  );

  /// Dark theme
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: primaryLight,
      onPrimary: Colors.white,
      primaryContainer: primaryDark,
      onPrimaryContainer: Colors.white,
      secondary: secondaryLight,
      onSecondary: Colors.black,
      error: errorRed,
      onError: Colors.white,
      surface: surfaceDark,
      onSurface: textPrimaryDark,
    ),
    scaffoldBackgroundColor: backgroundDark,
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: true,
      backgroundColor: primaryDark,
      foregroundColor: Colors.white,
      iconTheme: IconThemeData(color: Colors.white),
      actionsIconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: surfaceDark,
      selectedItemColor: primaryLight,
      unselectedItemColor: textSecondaryDark,
      selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
      unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      color: surfaceDark,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF262626),
      labelStyle: const TextStyle(color: textSecondaryDark),
      hintStyle: const TextStyle(color: textSecondaryDark),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF404040), width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF404040), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryLight, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: errorRed, width: 1.5),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryLight,
        side: const BorderSide(color: primaryLight, width: 1.5),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryLight,
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryBlue,
      foregroundColor: Colors.white,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: primaryDark.withValues(alpha: 0.5),
      selectedColor: primaryBlue,
      checkmarkColor: Colors.white,
      labelStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      secondaryLabelStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  );
}
