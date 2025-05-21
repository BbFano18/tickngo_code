import 'package:flutter/material.dart';

class AppTheme {
  // Définition des couleurs principales
  static const Color primaryColor = Color(0xFF7F56D9); // Violet
  static const Color primaryLightColor = Color(0xFFF4EBFF); // Violet clair
  static const Color textColor = Colors.black;

  // Définition des styles de texte
  static final TextStyle headingStyle = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: primaryColor,
  );

  static final TextStyle bodyTextStyle = TextStyle(
    fontSize: 16,
    color: textColor,
  );

  // Thème global pour l'application
  static ThemeData themeData = ThemeData(
    primaryColor: primaryColor,
    scaffoldBackgroundColor: Colors.white,
    textTheme: TextTheme(
      displayLarge: headingStyle,
      bodyLarge: bodyTextStyle,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
  );
}