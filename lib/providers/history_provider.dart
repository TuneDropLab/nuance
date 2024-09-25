import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuance/models/history_model.dart';
import 'package:nuance/providers/auth_provider.dart';
import 'package:nuance/services/all_services.dart';

final historyProvider = FutureProvider<List<HistoryModel>>((ref) async {
  try {
    final authService = ref.read(authServiceProvider);
    final sessionData = await authService.getSessionData();

    if (sessionData == null) {
      throw Exception('User not authenticated');
    }

    final history = await AllServices().getHistory(sessionData['access_token']);
    return history.reversed.toList();
  } catch (e) {
    throw Exception('Failed to load history');
  }
});

final deleteHistoryEntryProvider =
    FutureProvider.family<void, int>((ref, historyId) async {
  try {
    final authService = ref.read(authServiceProvider);
    final sessionData = await authService.getSessionData();
    if (sessionData == null) {
      throw Exception('User not authenticated');
    }
    final accessToken = sessionData['access_token'];
    // final providerType = sessionData['user']['app_metadata']['provider'];
    await AllServices().deleteHistory(accessToken, historyId);
  } catch (e) {
    throw Exception('Failed to delete history entry');
  }
});

final deleteAllHistoryProvider = FutureProvider<void>((ref) async {
  try {
    final authService = ref.read(authServiceProvider);
    final sessionData = await authService.getSessionData();
    if (sessionData == null) {
      throw Exception('User not authenticated');
    }
    await AllServices().deleteAllHistory(sessionData['access_token']);
  } catch (e) {
    throw Exception('Failed to delete all history');
  }
});
