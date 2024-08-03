import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuance/models/song_model.dart';
import 'package:nuance/providers/auth_provider.dart';
import 'package:nuance/services/recomedation_service.dart';

final recommendationsProvider =
    FutureProvider.family<List<SongModel>, String>((ref, userMessage) async {
  try {
    final authService = ref.read(authServiceProvider);
    final sessionData = await authService.getSessionData();

    if (sessionData == null) {
      throw Exception('User not authenticated');
    }

    final theSongs = await RecommendationsService()
        .getRecommendations(sessionData['access_token'], userMessage);

    return theSongs;
  } catch (e) {
    throw Exception('Failed to load recommendations');
  }
});
