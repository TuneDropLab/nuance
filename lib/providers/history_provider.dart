import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuance/models/history_model.dart';
import 'package:nuance/providers/auth_provider.dart';
import 'package:nuance/services/recomedation_service.dart';

final historyProvider = FutureProvider<List<HistoryModel>>((ref) async {
  try {
    log("HISTORY PROVIDER CALLED");
    final authService = ref.read(authServiceProvider);
    final sessionData = await authService.getSessionData();
    log("HISTORY PROVIDER SESSION DATA:!!! $sessionData");

    if (sessionData == null) {
      log("SESSION DATA IS NULL:!!! $sessionData");
      throw Exception('User not authenticated');
    }

    final history =
        await RecommendationsService().getHistory(sessionData['access_token']);
    log("HISTORY RETURNED:!!! $history");
    return history.reversed.toList();
  } catch (e) {
    log("HISTORY PROVIDER ERROR: $e");
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
    await RecommendationsService()
        .deleteHistory(sessionData['access_token'], historyId);
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
    await RecommendationsService()
        .deleteAllHistory(sessionData['access_token']);
  } catch (e) {
    throw Exception('Failed to delete all history');
  }
});
