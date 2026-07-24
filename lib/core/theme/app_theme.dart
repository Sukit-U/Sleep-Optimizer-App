import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const Color _primaryBlue = Color(0xFF5B8DEF);
  static const Color _accentPurple = Color(0xFF8B5CF6);
  static const Color _surfaceDark = Color(0xFF111827);
  static const Color _surfaceLight = Color(0xFFF8FAFC);

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _primaryBlue,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: _surfaceLight,
    cardTheme: const CardThemeData(
      elevation: 2,
      margin: EdgeInsets.all(8),
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
    ),
    textTheme: Typography.material2021(platform: TargetPlatform.android).black,
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _primaryBlue,
      brightness: Brightness.dark,
      secondary: _accentPurple,
    ),
    scaffoldBackgroundColor: _surfaceDark,
    cardTheme: const CardThemeData(
      elevation: 2,
      margin: EdgeInsets.all(8),
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
    ),
    textTheme: Typography.material2021(platform: TargetPlatform.android).white,
  );
}
