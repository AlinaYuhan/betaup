import 'package:flutter/material.dart';

ThemeData buildAppTheme() {
  const ember = Color(0xFFFF7A18);
  const ice = Color(0xFF7BE0FF);
  const midnight = Color(0xFF09111F);
  final scheme = ColorScheme.fromSeed(
    seedColor: ember,
    brightness: Brightness.dark,
  ).copyWith(
    primary: ember,
    secondary: ice,
    surface: const Color(0xFF111C2E),
    error: const Color(0xFFFF7B7B),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: Colors.transparent,
    canvasColor: Colors.transparent,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: Colors.white.withValues(alpha: 0.07),
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
      ),
    ),
    textTheme: const TextTheme(
      displaySmall: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.1,
        color: Colors.white,
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.6,
        color: Colors.white,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        height: 1.5,
        color: Color(0xFFE5EDF9),
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        height: 1.5,
        color: Color(0xFFB7C5D8),
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.06),
      hintStyle: const TextStyle(color: Color(0xFF8A9BB4)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: ember),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Color(0xFFFF7B7B)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Color(0xFFFF7B7B)),
      ),
      labelStyle: const TextStyle(color: Color(0xFFD5DEEC)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: ember,
        foregroundColor: midnight,
        minimumSize: const Size.fromHeight(56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.16)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.white.withValues(alpha: 0.06),
      disabledColor: Colors.white.withValues(alpha: 0.03),
      selectedColor: ember.withValues(alpha: 0.18),
      secondarySelectedColor: ember.withValues(alpha: 0.18),
      labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
      side: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: const Color(0xCC0C1628),
      indicatorColor: ember.withValues(alpha: 0.22),
      labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>(
        (states) => TextStyle(
          color: states.contains(WidgetState.selected)
              ? Colors.white
              : const Color(0xFF93A6C2),
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    ),
    dividerColor: Colors.white.withValues(alpha: 0.08),
  );
}
