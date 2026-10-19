import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:nuance/models/song_model.dart';

class ItunesService {
  static const String _searchEndpoint = 'https://itunes.apple.com/search';

  /// Search songs on iTunes using a keyword, mood, or artist query.
  /// No API keys, no cards, no authentication required.
  Future<List<SongModel>> searchTracks(String query, {int limit = 20}) async {
    try {
      final sanitized = query.trim().replaceAll(RegExp(r'\s+'), '+');
      final uri = Uri.parse('$_searchEndpoint?term=$sanitized&entity=song&limit=$limit');
      log("ItunesService: Fetching tracks from $uri");

      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> results = data['results'] ?? [];
        log("ItunesService: Found ${results.length} results for '$query'");

        final songs = results
            .map((item) => SongModel.fromItunes(item as Map<String, dynamic>))
            .where((song) => (song.previewUrl?.isNotEmpty ?? false))
            .toList();

        return songs;
      } else {
        log("ItunesService error: HTTP ${response.statusCode}");
      }
    } catch (e) {
      log("ItunesService exception: $e");
    }
    return [];
  }

  /// Get recommendations from a user prompt using iTunes catalog.
  Future<List<SongModel>> getRecommendations(String prompt) async {
    final cleanPrompt = prompt.trim();
    if (cleanPrompt.isEmpty) {
      return searchTracks("top hits", limit: 15);
    }

    // Try direct search first
    var tracks = await searchTracks(cleanPrompt, limit: 15);
    if (tracks.isNotEmpty) {
      return tracks;
    }

    // Fallback: extract primary mood/genre keywords
    final keywords = cleanPrompt
        .split(RegExp(r'[,.\s]+'))
        .where((w) => w.length > 2)
        .take(3)
        .join(' ');

    return searchTracks(keywords.isNotEmpty ? keywords : "trending", limit: 15);
  }
}
