import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:nuance/models/session_data_model.dart';
import 'package:nuance/providers/auth_provider.dart';
import 'package:nuance/screens/auth/login_screen.dart';
import 'package:nuance/services/auth_service.dart';

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
      log("LOADING SESSION FROM SESSION NOTIFIER!!!: $sessionData");
      if (sessionData != null) {
        return SessionData.fromJson(sessionData);
      }
    } catch (e) {
      log("ERROR LOADING SESSION: $e");
      return Future.error(e);
    }
    return null;
  }

  Future<void> loginWithSpotify(String sessionData) async {
    state = const AsyncLoading();
    try {
      await authService.loginWithSpotify(sessionData);
      state = AsyncData(SessionData.fromJson(jsonDecode(sessionData)));
    } catch (e) {
      state = AsyncError(
        e,
        StackTrace.current,
      );
    }
  }

  Future<void> logout() async {
    // Get.dialog
    Get.defaultDialog(
      title: "Hello",
      content: const Text("You are logging out"),
      confirm: MaterialButton(
        onPressed: () async {
          state = const AsyncLoading();
          await authService.logout();
          Get.offAllNamed(LoginScreen.routeName);
          state = const AsyncData(null);
        },
        child: const Text("OK"),
      ),
    );
  }
}

final sessionProvider =
    AsyncNotifierProvider<SessionNotifier, SessionData?>(() {
  return SessionNotifier();
});
