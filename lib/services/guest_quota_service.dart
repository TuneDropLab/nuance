import 'package:shared_preferences/shared_preferences.dart';

class GuestQuotaService {
  static final GuestQuotaService _instance = GuestQuotaService._internal();
  factory GuestQuotaService() => _instance;
  GuestQuotaService._internal();

  static const int kMaxGuestGenerations = 3;
  static const String _kGuestGenerationsUsedKey = 'nuance_guest_generations_used';

  Future<int> getRemainingGenerations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final used = prefs.getInt(_kGuestGenerationsUsedKey) ?? 0;
      final remaining = kMaxGuestGenerations - used;
      return remaining < 0 ? 0 : remaining;
    } catch (e) {
      return kMaxGuestGenerations;
    }
  }

  Future<bool> hasRemainingGenerations() async {
    final remaining = await getRemainingGenerations();
    return remaining > 0;
  }

  Future<int> consumeGeneration() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = prefs.getInt(_kGuestGenerationsUsedKey) ?? 0;
      final next = current + 1;
      await prefs.setInt(_kGuestGenerationsUsedKey, next);
      final remaining = kMaxGuestGenerations - next;
      return remaining < 0 ? 0 : remaining;
    } catch (e) {
      return 0;
    }
  }

  Future<void> resetQuota() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kGuestGenerationsUsedKey);
  }
}
