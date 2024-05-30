import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuance/providers/auth_provider.dart';
import 'package:nuance/services/spotify_api_services.dart';

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

final recommendationProvider = FutureProvider<List<dynamic>>((ref) async {
  final authModel = ref.watch(authStateProvider);
  if (authModel == null) {
    throw Exception('Not authenticated');
  }
  final apiService = ref.read(apiServiceProvider);
  return apiService.fetchRecommendations(authModel.accessToken);
});
