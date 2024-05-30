import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuance/models/auth_model.dart';
import 'package:nuance/services/auth_service.dart';


final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final authStateProvider = StateNotifierProvider<AuthStateNotifier, AuthModel?>((ref) {
  return AuthStateNotifier(ref);
});

class AuthStateNotifier extends StateNotifier<AuthModel?> {
  final Ref ref;

  AuthStateNotifier(this.ref) : super(null);

  Future<void> login(String code) async {
    try {
      final authService = ref.read(authServiceProvider);
      final authModel = await authService.authenticate(code);
      state = authModel;
    } catch (e) {
      // Handle error
      state = null;
    }
  }

  void logout() {
    state = null;
  }
}
