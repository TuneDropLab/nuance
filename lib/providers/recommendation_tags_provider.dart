import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuance/providers/auth_provider.dart';
import 'package:nuance/services/recomedation_service.dart';

final recommendationTagsProvider = FutureProvider<List<String>>((ref) async {
  try {
    log("RECOMMENDATION TAGS PROVIDER CALLED");
    final authService = ref.read(authServiceProvider);
    final sessionData = await authService.getSessionData();
    log("RECOMMENDATION TAGS PROVIDER SESSION DATA: $sessionData");

    if (sessionData == null) {
      log("SESSION DATA IS NULL: $sessionData");
      throw Exception('User not authenticated');
    }

    final accessToken = sessionData['access_token'];
    final tags =
        await RecommendationsService().getTags(accessToken);
    log("RECOMMENDATION TAGS RETURNED: $tags");
    return tags;
  } catch (e) {
    log("RECOMMENDATION TAGS PROVIDER ERROR: $e");
    throw Exception('Failed to generate recommendation tags');
  }
});
