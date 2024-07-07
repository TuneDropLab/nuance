import 'dart:convert';
import 'dart:developer';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:nuance/models/session_data_model.dart';
import 'package:nuance/providers/auth_provider.dart';
import 'package:nuance/screens/auth/login_screen.dart';
import 'package:nuance/services/auth_service.dart';
import 'package:nuance/theme.dart';
import 'package:nuance/utils/constants.dart';

class SessionNotifier extends AsyncNotifier<SessionData?> {
  late final AuthService authService;

  @override
  Future<SessionData?> build() async {
    authService = ref.read(authServiceProvider);
    return await _loadSession();
  }

  Future<SessionData?> _loadSession() async {
    try {
      final sessionData = await authService.getSessionData();
      // log("LOADING SESSION FROM SESSION NOTIFIER!!!: $sessionData");
      if (sessionData != null) {
        return SessionData.fromJson(sessionData);
      }
    } catch (e) {
      log("ERROR LOADING SESSION: $e");
      return Future.error(e);
    }
    return null;
  }

  Future<void> storeSessionAndSaveToState(String sessionData) async {
    state = const AsyncLoading();
    try {
      await authService.storeSessionData(sessionData);
      state = AsyncData(SessionData.fromJson(
        jsonDecode(sessionData),
      ));
    } catch (e) {
      state = AsyncError(
        e,
        StackTrace.current,
      );
    }
  }

  Future<void> logout() async {
    // Get.dialog
    Get.dialog(
        // title: "Hello",
        // content: const Text("You are logging out"),
        // confirm: MaterialButton(
        //   onPressed: () async {
        //     state = const AsyncLoading();
        //     await authService.logout();
        //     Get.offAllNamed(LoginScreen.routeName);
        //     state = const AsyncData(null);
        //   },
        //   child: const Text("OK"),
        // ),
        AlertDialog(
      backgroundColor: Colors.grey[900],
      title: const Text(
        'Sign Out',
        style: TextStyle(
          color: Colors.white,
        ),
      ),
      content: Text(
        'Are you sure you want to sign out?',
        style: subtitleTextStyle,
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Get.back();
            // globalKey.currentState!.openDrawer();
          },
          child: const Text(
            'Cancel',
          ),
        ),
        TextButton(
          onPressed: () async {
            state = const AsyncLoading();
            await authService.logout();
            Get.offAll(
              const LoginScreen(),
              transition: Transition.zoom,
            );
            state = const AsyncData(null);
          },
          child: const Text(
            'Sign Out',
          ),
        ),
      ],
    ));
  }
}

final sessionProvider =
    AsyncNotifierProvider<SessionNotifier, SessionData?>(() {
  return SessionNotifier();
});
