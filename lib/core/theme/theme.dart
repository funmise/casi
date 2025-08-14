import 'package:flutter/material.dart';
import 'app_pallete.dart';

class AppTheme {
  static final theme = ThemeData(
    scaffoldBackgroundColor: AppPallete.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppPallete.background,
      elevation: 0,
    ),
    textTheme: const TextTheme(
      headlineMedium: TextStyle(
        color: AppPallete.white,
        fontWeight: FontWeight.w700,
      ),
      bodyMedium: TextStyle(color: AppPallete.white),
    ),
  );
}
