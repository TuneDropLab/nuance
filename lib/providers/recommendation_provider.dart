import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuance/providers/auth_provider.dart';

import 'package:nuance/models/recommendation_model.dart';
import 'package:nuance/services/recomedation_service.dart';

final recommendationsProvider = FutureProvider.family<List<RecommendationModel>, String>((ref, userMessage) async {
  final authService = ref.read(authServiceProvider);
  final sessionData = await authService.getSessionData();

  if (sessionData == null) {
    throw Exception('User not authenticated');
  }

  return await RecommendationsService().getRecommendations(sessionData['access_token'], userMessage);
});
