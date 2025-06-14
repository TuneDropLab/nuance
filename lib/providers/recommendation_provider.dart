import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuance/models/song_model.dart';
import 'package:nuance/providers/auth_provider.dart';
import 'package:nuance/services/all_services.dart';

final recommendationsProvider =
    FutureProvider.family<List<SongModel>, String>((ref, userMessage) async {
  try {
    final authService = ref.read(authServiceProvider);
    final sessionData = await authService.getSessionData();

    if (sessionData == null) {
      throw Exception('User not authenticated');
    }

    final accessToken = sessionData['access_token'];
    final providerType = sessionData['user']['app_metadata']['provider'];

    final theSongs = await AllServices()
        .getRecommendations(accessToken, userMessage, providerType);

    return theSongs;
  } catch (e) {
    throw Exception('Failed to load recommendations');
  }
});
