import 'dart:convert';
import 'dart:developer';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:nuance/models/session_data_model.dart';
import 'package:nuance/providers/auth_provider.dart';
import 'package:nuance/screens/auth/login_screen.dart';
import 'package:nuance/services/auth_service.dart';
import 'package:nuance/theme.dart';

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
        CupertinoAlertDialog(
      title: const Text(
        "Sign Out",
        style: TextStyle(
          // wordSpacing: 2,
          letterSpacing: 0.5,
          fontSize: 18,
        ),
      ),
      content: const Text(
        "Confirm Sign Out",
        style: TextStyle(
          letterSpacing: 0.5,
          color: CupertinoColors.darkBackgroundGray,
          fontSize: 14,
        ),
        selectionColor: CupertinoColors.systemGrey4,
      ),
      actions: <Widget>[
        CupertinoDialogAction(
          isDefaultAction: true,
          child: const Text(
            "Yes",
            style: TextStyle(
              color: AppTheme.textColor,
              fontSize: 20,
            ),
          ),
          onPressed: () async {
            state = const AsyncLoading();
            await authService.logout();
            Get.offAllNamed(
              LoginScreen.routeName,
            );
            state = const AsyncData(null);
          },
        ),
        CupertinoDialogAction(
          child: const Text(
            "No",
            style: TextStyle(
              color: AppTheme.textColor,
              fontSize: 20,
            ),
          ),
          onPressed: () async {
            Get.back();
          },
        )
      ],
    ));
  }
}

final sessionProvider =
    AsyncNotifierProvider<SessionNotifier, SessionData?>(() {
  return SessionNotifier();
});
