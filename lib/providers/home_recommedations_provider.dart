import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuance/providers/auth_provider.dart';
import 'package:nuance/services/all_services.dart';

final spotifyHomeRecommendationsProvider =
    FutureProvider<List<dynamic>>((ref) async {
  try {
    final authService = ref.read(authServiceProvider);
    final sessionData = await authService.getSessionData();

    

    if (sessionData == null) {
      throw Exception('User not authenticated');
    }

    final accessToken = sessionData['access_token'];
    final providerType = sessionData['user']['app_metadata']['provider'];
    final recommendations =
        await AllServices().getSpotifyHomeRecommendations(accessToken, providerType);
    return recommendations;
  } catch (e) {
    throw Exception('Failed to load Spotify home recommendations');
  }
});
