import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_auth/flutter_web_auth.dart';
import 'package:nuance/providers/auth_provider.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            final result = await FlutterWebAuth.authenticate(
              url:
                  'https://many-shepherd-11.clerk.accounts.dev/oauth/authorize?response_type=code&client_id=YOUR_CLIENT_ID&redirect_uri=nuance://callback&scope=profile email',
              callbackUrlScheme: 'nuance',
            );
            final code = Uri.parse(result).queryParameters['code'];
            if (code != null) {
              ref.read(authStateProvider.notifier).login(code);
            }
          },
          child: const Text('Login with Spotify'),
        ),
      ),
    );
  }
}
