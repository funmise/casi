import 'package:flutter/material.dart';
import 'app_pallete.dart';

class AppTheme {
  static final theme = ThemeData(
    scaffoldBackgroundColor: AppPallete.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppPallete.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      foregroundColor: Colors.white,
      centerTitle: true,
    ),
    textTheme: const TextTheme(
      headlineMedium: TextStyle(
        color: AppPallete.white,
        fontWeight: FontWeight.w700,
      ),
      bodyMedium: TextStyle(color: AppPallete.white),
      titleLarge: TextStyle(color: AppPallete.white),
      bodyLarge: TextStyle(color: AppPallete.white),
    ),
    listTileTheme: const ListTileThemeData(
      textColor: Colors.white,
      iconColor: Colors.white,
      selectedColor: Colors.white,
    ),
  );
}
