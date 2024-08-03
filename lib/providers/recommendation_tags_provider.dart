import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuance/providers/auth_provider.dart';
import 'package:nuance/services/all_services.dart';

final recommendationTagsProvider = FutureProvider<List<String>>((ref) async {
  try {
    final authService = ref.read(authServiceProvider);
    final sessionData = await authService.getSessionData();

    if (sessionData == null) {
      throw Exception('User not authenticated');
    }

    final accessToken = sessionData['access_token'];
    final tags = await AllServices().getTags(accessToken);
    return tags;
  } catch (e) {
    throw Exception('Failed to generate recommendation tags');
  }
});
