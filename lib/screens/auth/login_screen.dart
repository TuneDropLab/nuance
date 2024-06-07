import 'dart:developer';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_auth/flutter_web_auth.dart';
import 'package:get/get.dart';
import 'package:nuance/providers/auth_provider.dart';
import 'package:nuance/screens/home_screen.dart';
import 'package:nuance/utils/constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoginScreen extends ConsumerStatefulWidget {
  static const routeName = '/';
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  late String _status;

  Future<void> _authenticate() async {
    const authUrl = '$baseURL/auth/login';
    const callbackUrlScheme = "nuance";

    try {
      final result = await FlutterWebAuth.authenticate(
        url: authUrl,
        callbackUrlScheme: callbackUrlScheme,
      );
      _status = "Alright";
      print("USER RESULT!!!!: $result");
      log("USER RESULT!!!!: $result");
      log("Authentication Result: $result");

      final uri = Uri.parse(result);
      final sessionData = uri.queryParameters['session'];

      log("Session data: $sessionData");

      if (sessionData != null) {
        final authService = ref.read(authServiceProvider);
        await authService.loginWithSpotify(sessionData);

        await Get.to(
          () => const HomeScreen(),
          transition: Transition.zoom,
        );
      }

      // Navigate to the next screen or update UI state
    } on PlatformException catch (e) {
      setState(() {
        log("ERROR MESSAGE: ${e.message}");
        _status = 'Error: ${e.message}';
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _status = "Untouched";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: const Text('Login'),
      // ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Status: $_status'),
            const SizedBox(height: 16),
            CupertinoButton.filled(
              onPressed: _authenticate,
              child: const Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}
