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
import 'package:nuance/widgets/custom_dialog.dart';

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
      log("LOADING SESSION FROM SESSION NOTIFIER!!!ml: $sessionData");
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
      ConfirmDialog(
        heading: 'Sign out',
        subtitle: "Are you sure you want to sign out?",
        confirmText: "Okay",
        onConfirm: () {
          state = const AsyncLoading();
          authService.logout();
          Get.offAll(
            const LoginScreen(),
            transition: Transition.zoom,
          );
          state = const AsyncData(null);
        },
      ),
    );
  }
}

final sessionProvider =
    AsyncNotifierProvider<SessionNotifier, SessionData?>(() {
  return SessionNotifier();
});
