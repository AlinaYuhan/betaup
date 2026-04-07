import 'package:flutter/material.dart';

ThemeData buildAppTheme() {
  const ember = Color(0xFFFF7A18);
  const ice = Color(0xFF7BE0FF);
  const midnight = Color(0xFF09111F);
  const base = Color(0xFF0B1424);
  const surface = Color(0xFF162235);
  const panel = Color(0xFF1B2A40);
  final scheme = ColorScheme.fromSeed(
    seedColor: ember,
    brightness: Brightness.dark,
  ).copyWith(
    primary: ember,
    secondary: ice,
    surface: surface,
    surfaceContainerHighest: panel,
    error: const Color(0xFFFF7B7B),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: base,
    canvasColor: base,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: Colors.white.withValues(alpha: 0.12),
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.16)),
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
        color: Color(0xFFC6D3E4),
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        height: 1.45,
        color: Color(0xFFA7B8CF),
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: Color(0xFFF4F7FB),
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Color(0xFFB7CAE0),
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: Color(0xFF90A5C1),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.12),
      hintStyle: const TextStyle(color: Color(0xFFA5B6CC)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.20)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.20)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: ember, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Color(0xFFFF7B7B)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Color(0xFFFF7B7B)),
      ),
      labelStyle: const TextStyle(color: Color(0xFFE0E8F3)),
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
        foregroundColor: const Color(0xFFF5F8FF),
        backgroundColor: Colors.white.withValues(alpha: 0.05),
        minimumSize: const Size.fromHeight(52),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.24)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.white.withValues(alpha: 0.10),
      disabledColor: Colors.white.withValues(alpha: 0.05),
      selectedColor: ember.withValues(alpha: 0.24),
      secondarySelectedColor: ember.withValues(alpha: 0.24),
      labelStyle:
          const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
      side: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    ),
    tabBarTheme: TabBarThemeData(
      dividerColor: Colors.white.withValues(alpha: 0.10),
      indicatorColor: ember,
      indicatorSize: TabBarIndicatorSize.label,
      labelColor: Colors.white,
      unselectedLabelColor: const Color(0xFFAFBED3),
      labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
      unselectedLabelStyle:
          const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: ember,
      textColor: Colors.white,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: const Color(0xF0121D2F),
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
    snackBarTheme: SnackBarThemeData(
      backgroundColor: surface,
      contentTextStyle:
          const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      behavior: SnackBarBehavior.floating,
    ),
    dividerColor: Colors.white.withValues(alpha: 0.08),
  );
}
