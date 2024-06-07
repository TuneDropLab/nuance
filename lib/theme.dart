import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF92A9BD); // Green
  static const Color secondaryColor = Color(0xFFD3DEDC); // Blue
  static const Color textColor = Color(0xFF333333); // Not fully black

  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: primaryColor,
      scaffoldBackgroundColor: Colors.white,
      textTheme: const TextTheme(
        displayLarge: TextStyle(
            color: textColor, fontSize: 24, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(
            color: textColor, fontSize: 22, fontWeight: FontWeight.bold),
        displaySmall: TextStyle(
            color: textColor, fontSize: 20, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(
            color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
        headlineSmall: TextStyle(
            color: textColor, fontSize: 16, fontWeight: FontWeight.bold),
        titleLarge: TextStyle(
            color: textColor, fontSize: 14, fontWeight: FontWeight.bold),
        bodyLarge: TextStyle(color: textColor, fontSize: 16),
        bodyMedium: TextStyle(color: textColor, fontSize: 14),
        titleMedium: TextStyle(
            color: textColor, fontSize: 14, fontWeight: FontWeight.w500),
        titleSmall: TextStyle(
            color: textColor, fontSize: 12, fontWeight: FontWeight.w500),
        bodySmall: TextStyle(color: textColor, fontSize: 12),
        labelLarge: TextStyle(
            color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
        labelSmall: TextStyle(
            color: textColor, fontSize: 10, fontWeight: FontWeight.bold),
      ),
      appBarTheme: AppBarTheme(
        color: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: textColor),
        toolbarTextStyle: const TextTheme(
          titleLarge: TextStyle(
            color: textColor,
            fontSize: 20,
          ),
        ).bodyMedium,
        titleTextStyle: const TextTheme(
          titleLarge: TextStyle(
            color: textColor,
            fontSize: 20,
          ),
        ).titleLarge,
      ),
      buttonTheme: ButtonThemeData(
        buttonColor: primaryColor,
        textTheme: ButtonTextTheme.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: primaryColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[200],
        contentPadding:
            const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide.none,
        ),
      ),
      cardTheme: CardTheme(
        color: Colors.white,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
      iconTheme: const IconThemeData(
        color: primaryColor,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
