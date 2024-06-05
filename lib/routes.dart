import 'package:flutter/material.dart';
import 'package:nuance/screens/home_screen.dart';
import 'package:nuance/screens/auth/login_screen.dart';

Map<String, Widget Function(BuildContext)> routes = {
  LoginScreen.routeName: (context) => const LoginScreen(),
  HomeScreen.routeName: (context) => const HomeScreen(),
  // Define other routes here
};
