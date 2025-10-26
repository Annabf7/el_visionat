import 'package:flutter/material.dart';

class AppTheme {
  static const Color grisPistacho = Color(0xFFCDD1C4);
  static const Color porpraFosc = Color(0xFF2F313C);
  static const Color grisBody = Color(0xFF4D5061);
  static const Color lilaMitja = Color(0xFF8B7F9B);
  static const Color white = Color(0xFFD9D9D9);
  static const Color mostassa = Color(0xFFE8C547);
  static const Color textBlackLow = Color(0xFF5D5F71);

  static ThemeData get theme {
    return ThemeData(
      primaryColor: porpraFosc,
      scaffoldBackgroundColor: grisBody,
      colorScheme: const ColorScheme.dark(
        primary: porpraFosc,
        secondary: lilaMitja,
        surface: grisBody,
        onPrimary: grisPistacho,
        onSecondary: white,
        onSurface: grisPistacho,
        error: Colors.red,
        onError: white,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontFamily: 'Geist', color: grisPistacho),
        displayMedium: TextStyle(fontFamily: 'Geist', color: grisPistacho),
        displaySmall: TextStyle(fontFamily: 'Geist', color: grisPistacho),
        headlineMedium: TextStyle(fontFamily: 'Geist', color: grisPistacho),
        headlineSmall: TextStyle(fontFamily: 'Geist', color: grisPistacho),
        titleLarge: TextStyle(fontFamily: 'Geist', color: grisPistacho),
        bodyLarge: TextStyle(fontFamily: 'Inter', color: grisPistacho),
        bodyMedium: TextStyle(fontFamily: 'Inter', color: grisPistacho),
        titleMedium: TextStyle(fontFamily: 'Inter', color: grisPistacho),
        titleSmall: TextStyle(fontFamily: 'Inter', color: grisPistacho),
        labelLarge: TextStyle(fontFamily: 'Inter', color: grisPistacho),
        bodySmall: TextStyle(fontFamily: 'Inter', color: grisPistacho),
        labelSmall: TextStyle(fontFamily: 'Inter', color: grisPistacho),
      ),
      fontFamily: 'Inter',
    );
  }
}
