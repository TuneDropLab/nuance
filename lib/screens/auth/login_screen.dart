import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_auth/flutter_web_auth.dart';
import 'package:nuance/utils/constants.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String _status = '';

  Future<void> _authenticate() async {
    const authUrl = '$baseURL/auth/login';
    const callbackUrlScheme = "nuance";

    try {
      final result = await FlutterWebAuth.authenticate(
        url: authUrl,
        callbackUrlScheme: callbackUrlScheme,
      );
      print("USER RESULT!!!!: $result");
      log("USER RESULT!!!!: $result");

      // Handle the redirect URI and extract user data
      // final userAccessToken =
      //     Uri.parse(result).fragment; // Use fragment instead of queryParameters
      final userAccessToken = Uri.parse(result).queryParameters['code'];
      log("USER ACCESS TOKEN: $userAccessToken");
    } on PlatformException catch (e) {
      setState(() {
        log("ERROR MESSAGE: ${e.message}");
        _status = 'Error: ${e.message}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Status: $_status'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _authenticate,
              child: const Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}
