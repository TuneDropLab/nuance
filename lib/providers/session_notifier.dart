import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:nuance/models/session_data_model.dart';
import 'package:nuance/providers/auth_provider.dart';
import 'package:nuance/screens/auth/login_screen.dart';
import 'package:nuance/services/auth_service.dart';
import 'package:nuance/services/all_services.dart';
import 'package:nuance/widgets/custom_dialog.dart';

class SessionNotifier extends AsyncNotifier<SessionData?> {
  late final AuthService authService;
  late final AllServices allServices;

  @override
  Future<SessionData?> build() async {
    authService = ref.read(authServiceProvider);
    allServices = AllServices();
    return await _loadSession();
  }

  Future<SessionData?> _loadSession() async {
    try {
      final sessionData = await authService.getSessionData();
      if (sessionData != null) {
        return SessionData.fromJson(sessionData);
      }
    } catch (e) {
      return Future.error(e);
    }
    return null;
  }

  Future<void> storeSessionAndSaveToState({
    required String sessionData,
    required String name,
    required String email,
    Map<String, String>? musicKitData,
  }) async {
    state = const AsyncLoading();
    try {
      final sessionJson = jsonDecode(sessionData) as Map<String, dynamic>;
      final updatedUser = {
        ...sessionJson['user'] as Map<String, dynamic>,
        'name': name,
        'email': email,
        // 'provider': provider
      };

      final updatedSessionJson = {
        ...sessionJson,
        'user': updatedUser,
      };

      final updatedSessionData = jsonEncode(updatedSessionJson);

      await authService.storeSessionData(updatedSessionData);

      state = AsyncData(SessionData.fromJson(updatedSessionJson));
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> updateUserName(String name) async {
    state = const AsyncLoading();
    try {
      final Map<String, dynamic>? sessionJson =
          await authService.getSessionData();
      if (sessionJson != null) {
        final accessToken = sessionJson['access_token'] as String;
        final response = await allServices.updateUserProfile(accessToken, name);
        final userMetadata =
            sessionJson['user']['user_metadata'] as Map<String, dynamic>;
        final updatedUserMetadata = {
          ...userMetadata,
          'full_name': response['user']['name'],
        };

        final updatedUser = {
          ...sessionJson['user'] as Map<String, dynamic>,
          'user_metadata': updatedUserMetadata,
        };

        final updatedSessionJson = {
          ...sessionJson,
          'user': updatedUser,
        };

        final updatedSessionData = jsonEncode(updatedSessionJson);
        await authService.storeSessionData(updatedSessionData);

        state = AsyncData(SessionData.fromJson(updatedSessionJson));
      }
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> logout() async {
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
