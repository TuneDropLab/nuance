import 'package:flutter/material.dart';

const baseURL = "http://localhost:3000";

// RGB Colors
const Color kUiGreen = Color(0xFF3D9261);
const Color secondaryColor = Color.fromRGBO(76, 175, 80, 1); // Green
const Color accentColor = Color.fromRGBO(255, 193, 7, 1); // Amber

// Linear Gradients
const LinearGradient gradient1 = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [
    Color.fromRGBO(255, 87, 34, 1), // Deep Orange
    Color.fromRGBO(233, 30, 99, 1), // Pink
  ],
);

const LinearGradient gradient2 = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [
    Color.fromRGBO(156, 39, 176, 1), // Purple
    Color.fromRGBO(3, 169, 244, 1), // Light Blue
  ],
);

final List<LinearGradient> gradients = [
  const LinearGradient(
    colors: [
      Color(0xFF0088FF),
      Color(0xFF007CE8),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  ),
  const LinearGradient(
    colors: [
      Color(0xFFFFA726),
      Color(0xFFFF7043),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  ),
  const LinearGradient(
    colors: [
      Color(0xFFAB47BC),
      Color(0xFF8E24AA),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  ),
  const LinearGradient(
    colors: [
      Color.fromARGB(255, 188, 71, 71),
      Color.fromARGB(255, 170, 36, 36),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  ),
  const LinearGradient(
    colors: [
      Color.fromARGB(255, 71, 188, 108),
      Color.fromARGB(255, 31, 141, 58),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  ),
];

final subtitleTextStyle = TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.w500,
  letterSpacing: -0.8,
  wordSpacing: -0.9,
  color: Colors.grey.shade500,
);
const headingTextStyle = TextStyle(
  fontSize: 20,
  fontWeight: FontWeight.w500,
  color: Colors.white,
);

// final GlobalKey<ScaffoldState> globalKey = GlobalKey(); 
T identity<T>(T t) => t;

extension DurationInt on int {
  Duration get hours => Duration(hours: this);
  Duration get minutes => Duration(minutes: this);
  Duration get seconds => Duration(seconds: this);
  Duration get millis => Duration(milliseconds: this);
  Duration get days => Duration(days: this);
  Iterable<int> get times => Iterable.generate(this, identity);
}
