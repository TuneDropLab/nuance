import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF00A86B); // Green
  static const Color secondaryColor = Color(0xFF007FFF); // Blue
  static const Color backgroundColor = Color(0xFFFFFFFF); // White
  static const Color textColor = Color(0xFF333333); // Not fully black

  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
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
        labelLarge: TextStyle(
            color: backgroundColor, fontSize: 14, fontWeight: FontWeight.bold),
      ),
      appBarTheme: AppBarTheme(
        color: backgroundColor,
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
          foregroundColor: backgroundColor,
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
        color: backgroundColor,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
      iconTheme: const IconThemeData(
        color: primaryColor,
      ),
      pageTransitionsTheme: PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _MinimalistPageTransitionsBuilder(),
          TargetPlatform.iOS: _MinimalistPageTransitionsBuilder(),
        },
      ),
      colorScheme: ColorScheme.fromSwatch()
          .copyWith(
            primary: primaryColor,
            secondary: secondaryColor,
            background: backgroundColor,
            surface: backgroundColor,
          )
          .copyWith(secondary: secondaryColor)
          .copyWith(background: backgroundColor),
    );
  }
}

class _MinimalistPageTransitionsBuilder extends PageTransitionsBuilder {
  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: animation,
      child: child,
    );
  }
}
