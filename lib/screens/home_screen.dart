import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuance/providers/session_notifier.dart';
import 'package:nuance/theme.dart';

class HomeScreen extends ConsumerWidget {
  static const routeName = '/home';

  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionState = ref.watch(sessionProvider);

    log("HOME SCREEN: $sessionState");

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Screen'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () {
              ref.read(sessionProvider.notifier).logout();
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
            // Customize the container decoration if needed
            ),
        child: Center(
          child: sessionState.when(
            data: (sessionData) {
              if (sessionData == null) {
                return const Text('No session data available.');
              }
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Text("Access Token: ${sessionData.accessToken}"),
                  const SizedBox(height: 50),
                  // You can add other session data display here

                  sessionState.when(
                    data: (sessionData) {
                      if (sessionData == null) {
                        return Text(
                            "Access Token: ${sessionData!.accessToken}");
                      }
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Access Token: ${sessionData.accessToken}"),
                          const SizedBox(height: 50),
                          // You can add other session data display here
                        ],
                      );
                    },
                    loading: () => const CircularProgressIndicator(
                      backgroundColor: Colors.amber,
                      color: AppTheme.textColor,
                    ),
                    error: (error, stack) => Text('Error: $error'),
                  ),
                ],
              );
            },
            loading: () => const CircularProgressIndicator(),
            error: (error, stack) => Text('Error: $error'),
          ),
        ),
      ),
    );
  }
}
