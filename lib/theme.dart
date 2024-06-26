import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF3D9261); // Green
  static const Color secondaryColor = Color(0xFFD3DEDC); // Blue
  static const Color textColor = Color(0xFF333333); // Not fully black

  static CupertinoThemeData get lightTheme {
    return CupertinoThemeData(
      primaryColor: primaryColor,
      scaffoldBackgroundColor: CupertinoColors.white,
      textTheme: CupertinoTextThemeData(
        primaryColor: textColor,
        //   textStyle: GoogleFonts.anekBanglaTextTheme(
        //   // ThemeData.light().textTheme.copyWith(
        //   //       displayLarge: const TextStyle(
        //   //         color: textColor,
        //   //         fontSize: 20,
        //   //       ),
        //   //       displayMedium: const TextStyle(
        //   //         color: textColor,
        //   //         fontSize: 18,
        //   //       ),
        //   //     ),
        // ),
        navTitleTextStyle: GoogleFonts.anekBangla(
          textStyle: const TextStyle(
            color: textColor,
            fontSize: 20,
          ),
        ),
        navLargeTitleTextStyle: GoogleFonts.anekBangla(
          textStyle: const TextStyle(
            color: textColor,
            fontSize: 20,
          ),
        ),
        actionTextStyle: GoogleFonts.anekBangla(
          textStyle: const TextStyle(
            color: primaryColor,
            fontSize: 18,
          ),
        ),
      ),
      barBackgroundColor: CupertinoColors.white,
      primaryContrastingColor: secondaryColor,
    );
  }
}
