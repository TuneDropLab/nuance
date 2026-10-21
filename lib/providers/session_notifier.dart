import 'dart:convert';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_auth/flutter_web_auth.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:nuance/models/session_data_model.dart';
import 'package:nuance/providers/auth_provider.dart';
import 'package:nuance/providers/history_provider.dart';
import 'package:nuance/screens/auth/login_screen.dart';
import 'package:nuance/services/auth_service.dart';
import 'package:nuance/services/all_services.dart';
import 'package:nuance/utils/constants.dart';
import 'package:nuance/widgets/custom_dialog.dart';
import 'package:nuance/utils/web_auth_bridge.dart';

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
        final session = SessionData.fromJson(sessionData);
        if (!session.isGuest && session.isExpired) {
          log('Google/Account session expired, auto-refreshing token...');
          final refreshed = await refreshSession();
          if (refreshed && state.value != null) {
            return state.value;
          }
        }
        return session;
      }
    } catch (e) {
      log('_loadSession error: $e');
      return Future.error(e);
    }
    return null;
  }

  void setSession(SessionData session) {
    state = AsyncData(session);
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

  Future<void> startGuestSession() async {
    state = const AsyncLoading();
    try {
      final guestSession = {
        'access_token': 'guest_token_123',
        'refresh_token': 'guest_refresh_token_123',
        'provider_token': 'guest_provider_token_123',
        'expires_at': DateTime.now().millisecondsSinceEpoch + 86400000,
        'provider': 'guest',
        'user': {
          'id': 'guest_tester',
          'name': 'Guest Listener',
          'email': 'guest@nuance.app',
          'app_metadata': {'provider': 'guest', 'is_guest': true},
          'user_metadata': {'full_name': 'Guest Listener'},
        }
      };
      await authService.storeSessionData(jsonEncode(guestSession));
      state = AsyncData(SessionData.fromJson(guestSession));
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<bool> signInWithGoogle() async {
    final previousSession = state.value;
    state = const AsyncLoading();
    try {
      final String authUrl;
      final String callbackScheme;

      if (kIsWeb) {
        final origin = Uri.base.origin;
        final callbackUrl = '$origin/auth.html';
        authUrl = '$baseURL/auth/google?redirect_uri=${Uri.encodeComponent(callbackUrl)}';
        callbackScheme = Uri.base.scheme.isNotEmpty ? Uri.base.scheme : 'https';
      } else {
        authUrl = '$baseURL/auth/google?redirect_uri=nuance://auth/callback';
        callbackScheme = 'nuance';
      }

      log('Opening Google Sign-In sheet: $authUrl');
      final String result;
      if (kIsWeb) {
        clearWebAuthStorage();
        final webAuthFuture = FlutterWebAuth.authenticate(
          url: authUrl,
          callbackUrlScheme: callbackScheme,
        );
        final storageFuture = listenForWebAuthSession(const Duration(seconds: 120));

        final outcome = await Future.any<String?>([
          webAuthFuture.then<String?>((v) => v).catchError((_) => null),
          storageFuture,
        ]);

        if (outcome == null || outcome.isEmpty) {
          log('Google Sign-In sheet dismissed or timed out');
          state = AsyncData(previousSession);
          return false;
        }
        result = outcome;
      } else {
        result = await FlutterWebAuth.authenticate(
          url: authUrl,
          callbackUrlScheme: callbackScheme,
        );
      }

      final uri = Uri.parse(result);
      if (uri.path.contains('cancel') ||
          uri.queryParameters['error'] != null) {
        log('Google Sign-In was cancelled or error: ${uri.queryParameters['error']}');
        state = AsyncData(previousSession);
        return false;
      }

      final sessionParam = uri.queryParameters['session'];
      if (sessionParam == null || sessionParam.isEmpty) {
        throw Exception('No session data returned from Google authentication');
      }

      final sessionJson = jsonDecode(sessionParam) as Map<String, dynamic>;
      sessionJson['provider'] = 'google';
      if (sessionJson['user'] is Map<String, dynamic>) {
        final userMap = sessionJson['user'] as Map<String, dynamic>;
        userMap['app_metadata'] = {
          ...(userMap['app_metadata'] as Map<String, dynamic>? ?? {}),
          'provider': 'google',
          'is_guest': false,
        };
      }

      final sessionDataString = jsonEncode(sessionJson);
      await authService.storeSessionData(sessionDataString);

      final newSession = SessionData.fromJson(sessionJson);
      state = AsyncData(newSession);

      ref.invalidate(historyProvider);
      return true;
    } on PlatformException catch (e) {
      log('PlatformException during Google Sign-In: ${e.code} - ${e.message}');
      if (e.code == 'CANCELED' ||
          e.code == 'CANCELLED' ||
          (e.message?.toLowerCase().contains('cancel') ?? false)) {
        log('Google Sign-In sheet dismissed by user');
        state = AsyncData(previousSession);
        return false;
      }
      state = AsyncData(previousSession);
      rethrow;
    } catch (e) {
      log('Google Sign-In error: $e');
      state = AsyncData(previousSession);
      rethrow;
    }
  }

  Future<bool> refreshSession() async {
    try {
      final sessionData = await authService.getSessionData();
      if (sessionData == null) return false;

      final userMap = sessionData['user'] as Map<String, dynamic>?;
      final providerId = userMap?['user_metadata']?['provider_id'] ??
          userMap?['user_metadata']?['sub'] ??
          userMap?['id'] ??
          '';
      final currentToken = sessionData['access_token']?.toString() ?? '';

      final refreshResult = await allServices.refreshToken(
        providerId.toString(),
        currentToken: currentToken,
      );

      if (refreshResult != null && refreshResult['tokens'] != null) {
        final tokens = refreshResult['tokens'] as Map<String, dynamic>;
        int expiryMs = 0;
        final rawExpires = tokens['expiresAt'];
        if (rawExpires != null) {
          final parsed = int.tryParse(rawExpires.toString());
          if (parsed != null) {
            expiryMs = parsed < 10000000000 ? parsed * 1000 : parsed;
          } else {
            expiryMs = DateTime.tryParse(rawExpires.toString())
                    ?.millisecondsSinceEpoch ??
                0;
          }
        }

        final updatedSessionJson = {
          ...sessionData,
          'access_token': tokens['accessToken'],
          'refresh_token': tokens['refreshToken'],
          'expires_at': expiryMs,
        };
        await authService.storeSessionData(jsonEncode(updatedSessionJson));
        state = AsyncData(SessionData.fromJson(updatedSessionJson));
        log('Successfully refreshed Google session token');
        return true;
      }
      return false;
    } catch (e) {
      log('refreshSession error: $e');
      return false;
    }
  }

  Future<void> signInWithGoogleDirect({
    required String email,
    String? name,
    String? avatarUrl,
    String? providerId,
  }) async {
    state = const AsyncLoading();
    try {
      final effectiveName =
          name ?? (email.contains('@') ? email.split('@')[0] : 'Google User');
      final effectiveAvatar = avatarUrl ??
          'https://ui-avatars.com/api/?name=${Uri.encodeComponent(effectiveName)}&background=4285F4&color=fff';

      final response = await http
          .post(
            Uri.parse('$baseURL/auth/google/complete'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': email.trim(),
              'name': effectiveName,
              'avatarUrl': effectiveAvatar,
              'providerId': providerId ?? 'google_${email.hashCode.abs()}',
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final sessionMap = data['session'] as Map<String, dynamic>;
        await authService.storeSessionData(jsonEncode(sessionMap));
        state = AsyncData(SessionData.fromJson(sessionMap));
        ref.invalidate(historyProvider);
      } else {
        throw Exception(
            'Failed to sign in with Google: status ${response.statusCode}');
      }
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> signInWithEmail(String email, {String? name}) async {
    state = const AsyncLoading();
    try {
      final trimmedEmail = email.trim();
      final displayName = (name != null && name.trim().isNotEmpty)
          ? name.trim()
          : (trimmedEmail.contains('@') ? trimmedEmail.split('@').first : 'Nuance Member');
      final emailSession = {
        'access_token': 'nuance_email_${DateTime.now().millisecondsSinceEpoch}',
        'refresh_token': 'nuance_refresh_${DateTime.now().millisecondsSinceEpoch}',
        'provider_token': 'email_token',
        'expires_at': DateTime.now().millisecondsSinceEpoch + (86400000 * 30),
        'provider': 'email',
        'user': {
          'id': 'email_user_${trimmedEmail.hashCode.abs()}',
          'name': displayName,
          'email': trimmedEmail,
          'app_metadata': {'provider': 'email', 'is_guest': false},
          'user_metadata': {'full_name': displayName},
        }
      };
      await authService.storeSessionData(jsonEncode(emailSession));
      state = AsyncData(SessionData.fromJson(emailSession));
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> updateUserName(String name) async {
    state = const AsyncLoading();
    try {
      if (state.value?.isGuest == true) {
        final current = state.value!;
        final updatedUser = {
          ...current.user,
          'name': name,
          'user_metadata': {
            ...(current.user['user_metadata'] as Map<String, dynamic>? ?? {}),
            'full_name': name,
          }
        };
        final updatedSession = current.copyWith(user: updatedUser);
        state = AsyncData(updatedSession);
        return;
      }

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
        confirmText: "Sign out",
        onConfirm: () async {
          state = const AsyncLoading();
          await authService.logout();
          ref.read(guestHistoryProvider.notifier).state = [];
          ref.invalidate(historyProvider);
          Get.offAll(
            () => const LoginScreen(),
            transition: Transition.fade,
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
