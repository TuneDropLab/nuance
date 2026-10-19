import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuance/models/history_model.dart';
import 'package:nuance/providers/auth_provider.dart';
import 'package:nuance/services/all_services.dart';

/// In-memory transient history for guest users
final guestHistoryProvider = StateProvider<List<HistoryModel>>((ref) => []);

final historyProvider = FutureProvider<List<HistoryModel>>((ref) async {
  try {
    final authService = ref.read(authServiceProvider);
    final sessionData = await authService.getSessionData();

    if (sessionData == null) {
      return ref.watch(guestHistoryProvider);
    }

    final accessToken = sessionData['access_token']?.toString() ?? '';
    final isGuest = accessToken.startsWith('guest_') ||
        sessionData['user']?['id'] == 'guest_tester' ||
        sessionData['provider'] == 'guest' ||
        sessionData['provider'] == 'itunes';

    if (isGuest) {
      // Return local transient history for guest mode
      return ref.watch(guestHistoryProvider);
    }

    // Authenticated account: fetch persistent history from backend
    final history = await AllServices().getHistory(accessToken);
    return history.reversed.toList();
  } catch (e) {
    log('historyProvider error: $e');
    // Graceful fallback to local transient history
    return ref.watch(guestHistoryProvider);
  }
});

final deleteHistoryEntryProvider =
    FutureProvider.family<void, int>((ref, historyId) async {
  try {
    // Always remove from local guest history
    ref.read(guestHistoryProvider.notifier).update(
          (list) => list.where((item) => item.id != historyId).toList(),
        );

    final authService = ref.read(authServiceProvider);
    final sessionData = await authService.getSessionData();
    if (sessionData == null) return;

    final accessToken = sessionData['access_token']?.toString() ?? '';
    final isGuest = accessToken.startsWith('guest_') ||
        sessionData['user']?['id'] == 'guest_tester' ||
        sessionData['provider'] == 'guest';

    if (isGuest) return;

    await AllServices().deleteHistory(accessToken, historyId);
  } catch (e) {
    log('deleteHistoryEntryProvider error: $e');
  }
});

final deleteAllHistoryProvider = FutureProvider<void>((ref) async {
  try {
    ref.read(guestHistoryProvider.notifier).state = [];

    final authService = ref.read(authServiceProvider);
    final sessionData = await authService.getSessionData();
    if (sessionData == null) return;

    final accessToken = sessionData['access_token']?.toString() ?? '';
    final isGuest = accessToken.startsWith('guest_') ||
        sessionData['user']?['id'] == 'guest_tester' ||
        sessionData['provider'] == 'guest';

    if (isGuest) return;

    await AllServices().deleteAllHistory(accessToken);
  } catch (e) {
    log('deleteAllHistoryProvider error: $e');
  }
});
