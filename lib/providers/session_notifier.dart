import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuance/models/session_data_model.dart';
import 'package:nuance/providers/auth_provider.dart';
import 'package:nuance/services/auth_service.dart';

class SessionNotifier extends StateNotifier<SessionData?> {
  final AuthService authService;

  SessionNotifier(this.authService) : super(null) {
    _loadSession();
  }

  Future<void> _loadSession() async {
    final sessionData = await authService.getSessionData();
    if (sessionData != null) {
      state = SessionData.fromJson(sessionData);
    }
  }

  Future<void> loginWithSpotify(String sessionData) async {
    await authService.loginWithSpotify(sessionData);
    _loadSession();
  }

  Future<void> logout() async {
    await authService.logout();
    state = null;
  }
}

final sessionProvider =
    StateNotifierProvider<SessionNotifier, SessionData?>((ref) {
  final authService = ref.read(authServiceProvider);
  return SessionNotifier(authService);
});


