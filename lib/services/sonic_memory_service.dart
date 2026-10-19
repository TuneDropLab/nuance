import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SonicMemoryService {
  static final SonicMemoryService _instance = SonicMemoryService._internal();
  factory SonicMemoryService() => _instance;
  SonicMemoryService._internal();

  static const String _kRecentArtistsKey = 'nuance_sonic_recent_artists';
  static const String _kRecentGenresKey = 'nuance_sonic_recent_genres';
  static const String _kRecentPromptsKey = 'nuance_sonic_recent_prompts';

  Future<void> recordPlayedTrack({required String artist, String? genre}) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Update artists
      final trimmedArtist = artist.trim();
      if (trimmedArtist.isNotEmpty) {
        List<String> artists = prefs.getStringList(_kRecentArtistsKey) ?? [];
        artists.remove(trimmedArtist);
        artists.insert(0, trimmedArtist);
        if (artists.length > 12) {
          artists = artists.sublist(0, 12);
        }
        await prefs.setStringList(_kRecentArtistsKey, artists);
      }

      // Update genres
      if (genre != null && genre.trim().isNotEmpty) {
        final trimmedGenre = genre.trim();
        List<String> genres = prefs.getStringList(_kRecentGenresKey) ?? [];
        genres.remove(trimmedGenre);
        genres.insert(0, trimmedGenre);
        if (genres.length > 8) {
          genres = genres.sublist(0, 8);
        }
        await prefs.setStringList(_kRecentGenresKey, genres);
      }
    } catch (e) {
      debugPrint('Error recording played track in SonicMemoryService: $e');
    }
  }

  Future<void> recordPrompt(String prompt) async {
    try {
      final trimmed = prompt.trim();
      if (trimmed.isEmpty) return;
      final prefs = await SharedPreferences.getInstance();
      List<String> prompts = prefs.getStringList(_kRecentPromptsKey) ?? [];
      prompts.remove(trimmed);
      prompts.insert(0, trimmed);
      if (prompts.length > 10) {
        prompts = prompts.sublist(0, 10);
      }
      await prefs.setStringList(_kRecentPromptsKey, prompts);
    } catch (e) {
      debugPrint('Error recording prompt in SonicMemoryService: $e');
    }
  }

  Future<List<String>> getRecentArtists() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_kRecentArtistsKey) ?? [];
    } catch (e) {
      return [];
    }
  }

  Future<List<String>> getRecentGenres() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_kRecentGenresKey) ?? [];
    } catch (e) {
      return [];
    }
  }

  Future<List<String>> getRecentPrompts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_kRecentPromptsKey) ?? [];
    } catch (e) {
      return [];
    }
  }
}
