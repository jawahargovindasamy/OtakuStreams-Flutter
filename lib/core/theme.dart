import 'package:flutter/material.dart';

class AppTheme {
  // Original brand colors (retained for fallback and specific visual accents)
  static const Color primaryBlue = Color(0xFF3B82F6); // Vibrant Blue
  static const Color secondaryBlue = Color(0xFF1D4ED8); // Darker Blue
  static const Color accentColor = Color(0xFF818CF8); // Indigo highlight

  // React-based Color Tokens (OkLCH mapping from src/index.css)
  static const Color reactPrimaryDark = Color(0xFFE2E8F0);   // oklch(0.929 0.013 255.508) - Light slate grey
  static const Color reactPrimaryLight = Color(0xFF131924);  // oklch(0.208 0.042 265.755) - Dark slate navy
  static const Color reactSecondaryDark = Color(0xFF1E293B); // oklch(0.279 0.041 260.031) - Medium slate grey
  static const Color reactSecondaryLight = Color(0xFFF1F5F9);// oklch(0.968 0.007 247.896) - Light slate grey

  // Dark Theme Colors
  static const Color darkBackground = Color(0xFF090D16); // oklch(0.129 0.042 264.695) - Very dark navy/slate
  static const Color darkCard = Color(0xFF131924);       // oklch(0.208 0.042 265.755) - Dark slate card background
  static const Color darkPopover = Color(0xFF131924);    // oklch(0.208 0.042 265.755) - Popover
  static const Color darkForeground = Color(0xFFF8FAFC); // oklch(0.984 0.003 247.858) - Slate foreground text
  static const Color darkMuted = Color(0xFF94A3B8);      // oklch(0.704 0.04 256.788) - Slate-400 muted text
  static const Color darkBorder = Color(0x1AFFFFFF);     // oklch(1 0 0 / 10%) - 10% white border

  // Light Theme Colors
  static const Color lightBackground = Color(0xFFFFFFFF); // oklch(1 0 0) - Absolute white
  static const Color lightCard = Color(0xFFFFFFFF);       // oklch(1 0 0) - White card background
  static const Color lightPopover = Color(0xFFFFFFFF);    // oklch(1 0 0) - White popover
  static const Color lightForeground = Color(0xFF0F172A); // oklch(0.129 0.042 264.695) - Dark slate text
  static const Color lightMuted = Color(0xFF64748B);      // oklch(0.554 0.046 257.417) - Slate-500 muted text
  static const Color lightBorder = Color(0xFFE2E8F0);     // oklch(0.929 0.013 255.508) - Slate-200 border
  static const Color lightSecondary = Color(0xFFF1F5F9);  // oklch(0.968 0.007 247.896) - Slate-100 secondary

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: reactPrimaryDark,
    scaffoldBackgroundColor: darkBackground,
    cardColor: darkCard,
    dialogTheme: const DialogThemeData(backgroundColor: darkPopover),
    colorScheme: const ColorScheme.dark(
      primary: reactPrimaryDark,
      onPrimary: reactPrimaryLight,
      secondary: reactSecondaryDark,
      onSecondary: darkForeground,
      surface: darkCard,
      error: Color(0xFFEF4444),
      onSurface: darkForeground,
      onError: Colors.white,
    ),
    dividerColor: darkBorder,
    textTheme: const TextTheme(
      displayLarge: TextStyle(color: darkForeground, fontWeight: FontWeight.bold, fontSize: 32),
      titleLarge: TextStyle(color: darkForeground, fontWeight: FontWeight.bold, fontSize: 20),
      titleMedium: TextStyle(color: darkForeground, fontWeight: FontWeight.w600, fontSize: 16),
      bodyLarge: TextStyle(color: darkForeground, fontSize: 14),
      bodyMedium: TextStyle(color: darkMuted, fontSize: 12),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: darkBackground,
      elevation: 0,
      iconTheme: IconThemeData(color: darkForeground),
      titleTextStyle: TextStyle(color: darkForeground, fontWeight: FontWeight.bold, fontSize: 18),
    ),
    buttonTheme: const ButtonThemeData(
      buttonColor: reactPrimaryDark,
      textTheme: ButtonTextTheme.primary,
    ),
    inputDecorationTheme: InputDecorationTheme(
      fillColor: darkCard,
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: darkBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: darkBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: reactPrimaryDark, width: 1.5),
      ),
      labelStyle: const TextStyle(color: darkMuted),
      hintStyle: const TextStyle(color: darkMuted),
    ),
  );

  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: reactPrimaryLight,
    scaffoldBackgroundColor: lightBackground,
    cardColor: lightCard,
    dialogTheme: const DialogThemeData(backgroundColor: lightPopover),
    colorScheme: const ColorScheme.light(
      primary: reactPrimaryLight,
      onPrimary: Colors.white,
      secondary: reactSecondaryLight,
      onSecondary: lightForeground,
      surface: lightCard,
      error: Color(0xFFEF4444),
      onSurface: lightForeground,
      onError: Colors.white,
    ),
    dividerColor: lightBorder,
    textTheme: const TextTheme(
      displayLarge: TextStyle(color: lightForeground, fontWeight: FontWeight.bold, fontSize: 32),
      titleLarge: TextStyle(color: lightForeground, fontWeight: FontWeight.bold, fontSize: 20),
      titleMedium: TextStyle(color: lightForeground, fontWeight: FontWeight.w600, fontSize: 16),
      bodyLarge: TextStyle(color: lightForeground, fontSize: 14),
      bodyMedium: TextStyle(color: lightMuted, fontSize: 12),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: lightBackground,
      elevation: 0,
      iconTheme: IconThemeData(color: lightForeground),
      titleTextStyle: TextStyle(color: lightForeground, fontWeight: FontWeight.bold, fontSize: 18),
    ),
    inputDecorationTheme: InputDecorationTheme(
      fillColor: lightSecondary,
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: lightBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: lightBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: reactPrimaryLight, width: 1.5),
      ),
      labelStyle: const TextStyle(color: lightMuted),
      hintStyle: const TextStyle(color: lightMuted),
    ),
  );
}
