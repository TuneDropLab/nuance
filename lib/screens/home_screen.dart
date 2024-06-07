import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuance/models/session_data_model.dart';
import 'package:nuance/providers/session_notifier.dart';

class HomeScreen extends ConsumerWidget {
  static const routeName = '/home';

  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionData = ref.watch(sessionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Screen'),
      ),
      body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF6A88E5),
                Color(0xFF00B1CC),
              ],
            ),
          ),
          child: Center(
            child: _buildSessionDataWidget(sessionData!),
          )),
    );
  }

  Widget _buildSessionDataWidget(SessionData sessionData) {
    return Text(
      'Access Token: ${sessionData.accessToken}',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
      ),
    );
  }
}
