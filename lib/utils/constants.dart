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
