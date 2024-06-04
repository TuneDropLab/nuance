import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_auth/flutter_web_auth.dart';
import 'package:nuance/utils/constants.dart';

import 'dart:async';

import 'package:uni_links2/uni_links.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String _status = '';
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _initDeepLinkListener();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _initDeepLinkListener() {
    _sub = linkStream.listen((String? link) {
      if (link != null) {
        Uri uri = Uri.parse(link);
        String? token = uri.queryParameters['token'];
        if (token != null) {
          setState(() {
            _status = 'Logged in with token: $token';
          });
          Navigator.of(context).pushNamed("/");
          // Navigate to another screen or perform other actions
        }
      }
    }, onError: (err) {
      setState(() {
        _status = 'Failed to get deep link: $err';
      });
    });
  }

  Future<void> _authenticate() async {
    const authUrl = '$baseURL/auth/login';
    const callbackUrlScheme = "nuance";

    try {
      await FlutterWebAuth.authenticate(
        url: authUrl,
        callbackUrlScheme: callbackUrlScheme,
      );
    } on PlatformException catch (e) {
      setState(() {
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
