import 'dart:developer';

class SongModel {
  final String id;
  final String name;
  final List<String> artists;
  final String albumName;
  final String albumType;
  final List<String> availableMarkets;
  final String albumUrl;
  final String artworkUrl;
  final String releaseDate;
  final int totalTracks;
  final int discNumber;
  final int durationMs;
  final bool explicit;
  final String isrc;
  final bool isLocal;
  final int trackNumber;
  final int popularity;
  final String trackUrl;
  final String previewUrl;

  SongModel({
    required this.id,
    required this.name,
    required this.artists,
    required this.albumName,
    required this.albumType,
    required this.availableMarkets,
    required this.albumUrl,
    required this.artworkUrl,
    required this.releaseDate,
    required this.totalTracks,
    required this.discNumber,
    required this.durationMs,
    required this.explicit,
    required this.isrc,
    required this.isLocal,
    required this.trackNumber,
    required this.popularity,
    required this.trackUrl,
    required this.previewUrl,
  });

  factory SongModel.fromJson(Map<String, dynamic> json) {
    log("json DATA: $json");
    return SongModel(
      id: json['id'],
      name: json['name'],
      artists: (json['artists'] as List)
          .map((artist) => artist['name'] as String)
          .toList(),
      albumName: json['album']['name'],
      albumType: json['album']['album_type'],
      availableMarkets: (json['available_markets'] as List)
          .map((market) => market as String)
          .toList(),
      albumUrl: json['album']['external_urls']['spotify'],
      artworkUrl: (json['album']['images'] != null &&
              (json['album']['images'] as List).isNotEmpty)
          ? json['album']['images'][0]['url']
          : '',
      releaseDate: json['album']['release_date'],
      totalTracks: json['album']['total_tracks'],
      discNumber: json['disc_number'],
      durationMs: json['duration_ms'],
      explicit: json['explicit'],
      isrc: json['external_ids']['isrc'],
      isLocal: json['is_local'],
      trackNumber: json['track_number'],
      popularity: json['popularity'],
      trackUrl: json['external_urls']['spotify'],
      previewUrl: json['preview_url'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'artists': artists,
      'albumName': albumName,
      'albumType': albumType,
      'availableMarkets': availableMarkets,
      'albumUrl': albumUrl,
      'artworkUrl': artworkUrl,
      'releaseDate': releaseDate,
      'totalTracks': totalTracks,
      'discNumber': discNumber,
      'durationMs': durationMs,
      'explicit': explicit,
      'isrc': isrc,
      'isLocal': isLocal,
      'trackNumber': trackNumber,
      'popularity': popularity,
      'trackUrl': trackUrl,
      'previewUrl': previewUrl,
    };
  }
}
