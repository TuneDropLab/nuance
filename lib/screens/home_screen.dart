import 'dart:developer';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
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
    final sessionData = ref.read(sessionProvider.notifier);

    log("HOME SCREEN: $sessionState");

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        actionsIconTheme: const IconThemeData(size: 40),
        title: const Text('Home Screen'),
        automaticallyImplyLeading: false,
        centerTitle: false,
        actions: [
          // IconButton(
          //   icon: const Icon(Icons.logout),
          //   tooltip: 'Logout',
          //   onPressed: () {
          //     sessionData.logout();
          //   },
          // ),
          sessionState.when(
            data: (data) {
              return CupertinoButton(
                // color: Colors.amber,
                onPressed: () {
                  sessionData.logout();
                },
                child: CachedNetworkImage(
                  imageBuilder: (context, imageProvider) => Container(
                    width: 30.0,
                    height: 100.0,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        image: imageProvider,
                        // fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  fit: BoxFit.fill,
                  height: 150,
                  imageUrl: data?.user["user_metadata"]["avatar_url"],
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                ),
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(
                color: AppTheme.textColor,
              ),
            ),
            error: (error, stack) => const CircleAvatar(),
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
