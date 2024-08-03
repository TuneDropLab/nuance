// not needed but we will keep it in case of future changes

import 'package:flutter/material.dart';
import 'package:nuance/screens/home_screen.dart';
import 'package:nuance/screens/auth/login_screen.dart';
import 'package:nuance/screens/initial_screen.dart';
import 'package:nuance/screens/onboarding_screen.dart';
import 'package:nuance/screens/recommendations_result_screen.dart';

Map<String, Widget Function(BuildContext)> routes = {
  LoginScreen.routeName: (context) => const LoginScreen(),
  HomeScreen.routeName: (context) => const HomeScreen(),
  InitialScreen.routeName: (context) => const InitialScreen(),
  OnboardingScreen.routeName: (context) => const OnboardingScreen(),
  RecommendationsResultScreen.routeName: (context) =>
      const RecommendationsResultScreen(),
};
