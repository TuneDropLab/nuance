import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuance/providers/auth_provider.dart';
import 'package:nuance/services/recomedation_service.dart';

final spotifyHomeRecommendationsProvider =
    FutureProvider<List<dynamic>>((ref) async {
  try {
    final authService = ref.read(authServiceProvider);
    final sessionData = await authService.getSessionData();

    if (sessionData == null) {
      throw Exception('User not authenticated');
    }

    final accessToken = sessionData['access_token'];
    final recommendations = await RecommendationsService()
        .getSpotifyHomeRecommendations(accessToken);
    return recommendations;
  } catch (e) {
    throw Exception('Failed to load Spotify home recommendations');
  }
});
