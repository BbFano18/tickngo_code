import 'package:flutter/material.dart';

class AppTheme {
  // Définition des couleurs principales
  static const Color primaryColor = Color(0xFFD88F73);
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
        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
  );
}