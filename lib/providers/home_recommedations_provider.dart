import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuance/providers/auth_provider.dart';
import 'package:nuance/services/recomedation_service.dart';

final spotifyHomeRecommendationsProvider = FutureProvider.family<List<dynamic>, int>((ref, page) async {
  try {
    final authService = ref.read(authServiceProvider);
    final sessionData = await authService.getSessionData();

    if (sessionData == null) {
      log("SESSION DATA IS NULL: $sessionData");
      throw Exception('User not authenticated');
    }

    final accessToken = sessionData['access_token'];
    final recommendations = await RecommendationsService()
        .getSpotifyHomeRecommendations(accessToken, page, 10); // 10 is the limit
    return recommendations;
  } catch (e) {
    log("SPOTIFY HOME RECOMMENDATIONS PROVIDER ERROR: $e");
    throw Exception('Failed to load Spotify home recommendations');
  }
});
