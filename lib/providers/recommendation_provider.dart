import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuance/providers/auth_provider.dart';

import 'package:nuance/models/recommendation_model.dart';
import 'package:nuance/services/recomedation_service.dart';

final recommendationsProvider =
    FutureProvider.family<List<RecommendationModel>, String>(
        (ref, userMessage) async {
  try {
    log("RECOMMEDATIONS PROVIDER CALLED");
    final authService = ref.read(authServiceProvider);
    final sessionData = await authService.getSessionData();
    log("RECOMMEDATIONS PROVIDER CALLED:!!! $sessionData");

    if (sessionData == null) {
    log("SESSION DATA IS NULL:!!! $sessionData");
      throw Exception('User not authenticated');
    }

    final theSongs = await RecommendationsService()
        .getRecommendations(sessionData['access_token'], userMessage);

    log("THE SONGS RETURNED:!!! $theSongs");
    return theSongs;
  } catch (e) {
    log("RECOMMEDATIONS PROVIDER ERROR: $e");
    throw Exception('Failed to load recommendations');
  }
});
