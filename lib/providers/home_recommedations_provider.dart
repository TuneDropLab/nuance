import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuance/providers/auth_provider.dart';
import 'package:nuance/services/recomedation_service.dart';

final spotifyHomeRecommendationsProvider =
    FutureProvider<List<dynamic>>((ref) async {
  try {
    log("SPOTIFY HOME RECOMMENDATIONS PROVIDER CALLED");
    final authService = ref.read(authServiceProvider);
    final sessionData = await authService.getSessionData();
    log("SPOTIFY HOME RECOMMENDATIONS PROVIDER SESSION DATA: $sessionData");

    if (sessionData == null) {
      log("SESSION DATA IS NULL: $sessionData");
      throw Exception('User not authenticated');
    }

    final accessToken = sessionData['access_token'];
    final recommendations = await RecommendationsService()
        .getSpotifyHomeRecommendations(accessToken);
    log("SPOTIFY HOME RECOMMENDATIONS RETURNED: $recommendations");
    return recommendations;
  } catch (e) {
    log("SPOTIFY HOME RECOMMENDATIONS PROVIDER ERROR: $e");
    throw Exception('Failed to load Spotify home recommendations');
  }
});
