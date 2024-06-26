
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:nuance/providers/auth_provider.dart';
import 'package:nuance/routes.dart';
import 'package:nuance/screens/auth/login_screen.dart';
import 'package:nuance/screens/home_screen.dart';
import 'package:nuance/screens/initial_screen.dart';
import 'package:nuance/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final container = ProviderContainer();
  final authService = container.read(authServiceProvider);
  final sessionData = await authService.getSessionData();

  runApp(
    ProviderScope(
      overrides: [
        authServiceProvider.overrideWithValue(authService),
      ],
      child: MyApp(sessionData: sessionData),
    ),
  );
}

class MyApp extends StatelessWidget {
  final Map<String, dynamic>? sessionData;

  const MyApp({super.key, this.sessionData});

  @override
  Widget build(BuildContext context) {
    return GetCupertinoApp(
      localizationsDelegates: const [
        DefaultCupertinoLocalizations.delegate,

        DefaultMaterialLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
      ],
      debugShowCheckedModeBanner: false,
      title: 'Nuance',
      initialRoute:  sessionData == null ? InitialScreen.routeName : HomeScreen.routeName,
      theme: AppTheme.lightTheme,
      routes: routes,
    );
  }
}
