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

  /// Resolve a list of Gemini recommendation titles & artists into playable iTunes preview tracks
  Future<List<SongModel>> resolveRecommendations(
      List<dynamic> recommendations) async {
    final List<SongModel> resolved = [];
    final Set<String> seenIds = {};

    for (final item in recommendations) {
      String? title;
      String? artist;
      if (item is Map) {
        title = item['title']?.toString();
        artist = item['artist']?.toString();
      } else {
        try {
          title = item.title?.toString();
          artist = item.artist?.toString();
        } catch (_) {}
      }

      if (title == null || title.isEmpty) continue;
      final term = artist != null && artist.isNotEmpty
          ? "$title $artist"
          : title;

      final results = await searchTracks(term, limit: 3);
      for (final song in results) {
        final id = song.trackId ?? "${song.title}_${song.artist}";
        if (!seenIds.contains(id) && (song.previewUrl?.isNotEmpty ?? false)) {
          seenIds.add(id);
          resolved.add(song);
          break; // Got best match for this recommendation
        }
      }

      if (resolved.length >= 20) break;
    }

    return resolved;
  }

  /// Generate more recommendations based on existing songs or search prompt
  Future<List<SongModel>> getMoreRecommendations({
    String? prompt,
    List<SongModel>? currentSongs,
    int limit = 15,
  }) async {
    final Set<String> existingIds = (currentSongs ?? [])
        .map((s) => s.trackId ?? "${s.title}_${s.artist}".toLowerCase())
        .toSet();

    final List<SongModel> moreTracks = [];

    // 1. If we have seed songs, search by seed artists/titles
    if (currentSongs != null && currentSongs.isNotEmpty) {
      final sampleSeeds = List<SongModel>.from(currentSongs)..shuffle();
      for (final seed in sampleSeeds.take(3)) {
        final query = seed.artist ?? seed.title ?? "";
        if (query.isNotEmpty) {
          final tracks = await searchTracks(query, limit: 10);
          for (final t in tracks) {
            final id = t.trackId ?? "${t.title}_${t.artist}".toLowerCase();
            if (!existingIds.contains(id)) {
              existingIds.add(id);
              moreTracks.add(t);
              if (moreTracks.length >= limit) return moreTracks;
            }
          }
        }
      }
    }

    // 2. If not enough, search based on prompt
    if (moreTracks.length < limit && prompt != null && prompt.isNotEmpty) {
      final promptTracks = await searchTracks(prompt, limit: 20);
      for (final t in promptTracks) {
        final id = t.trackId ?? "${t.title}_${t.artist}".toLowerCase();
        if (!existingIds.contains(id)) {
          existingIds.add(id);
          moreTracks.add(t);
          if (moreTracks.length >= limit) return moreTracks;
        }
      }
    }

    // 3. Fallback to trending
    if (moreTracks.isEmpty) {
      return searchTracks("top hits", limit: limit);
    }

    return moreTracks;
  }
}
