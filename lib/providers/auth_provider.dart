import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuance/providers/secure_storage_provider.dart';
import 'package:nuance/services/auth_service.dart';



final authServiceProvider = Provider<AuthService>((ref) {
  final secureStorage = ref.read(secureStorageProvider);
  return AuthService(secureStorage);
});
