class SongModel {
  final String? id;
  final String? title;
  final String? artist;
  final String? albumName;
  final String? albumType;
  final String? albumUrl;
  final String? artworkUrl;
  final String? releaseDate;
  final int? totalTracks;
  final int? discNumber;
  final int? durationMs;
  final bool? explicit;
  final String? isrc;
  final int? trackNumber;
  final int? popularity;
  final String? trackUrl;
  final String? previewUrl;
  final String? albumUri;
  final String? artistUri;
  final String? trackUri;
  final int? promptId;
  final DateTime? createdAt;

  SongModel({
    this.id,
    this.title,
    this.artist,
    this.albumName,
    this.albumType,
    this.albumUrl,
    this.artworkUrl,
    this.releaseDate,
    this.totalTracks,
    this.discNumber,
    this.durationMs,
    this.explicit,
    this.isrc,
    this.trackNumber,
    this.popularity,
    this.trackUrl,
    this.previewUrl,
    this.albumUri,
    this.artistUri,
    this.trackUri,
    this.promptId,
    this.createdAt,
  });

  factory SongModel.fromJson(Map<String, dynamic> json) {
    return SongModel(
      id: (json['id'] ??
              (json['songId'] is int
                  ? int.tryParse(json['songId'])
                  : json['songId']))
          .toString(),
      title: json['title'] ?? json['name'],
      artist: json['artist'] ??
          (json['artists'] != null && (json['artists'] as List).isNotEmpty
              ? json['artists'][0]['name']
              : null),
      albumName: json['albumName'] ?? json['album']['name'],
      albumType: json['albumType'] ?? json['album']['type'],
      albumUrl: json['albumUrl'] ?? json['album']['external_urls']['spotify'],
      artworkUrl: json['artworkUrl'] ??
          (json['album']['images'] != null &&
                  (json['album']['images'] as List).isNotEmpty
              ? json['album']['images'][0]['url']
              : null),
      releaseDate: json['releaseDate'] ?? json['album']['release_date'],
      totalTracks: json['totalTracks'] ?? json['album']['total_tracks'],
      discNumber: json['discNumber'] ?? json['disc_number'],
      durationMs: json['durationMs'] ?? json['duration_ms'],
      explicit: json['explicit'] ?? json['is_explicit'],
      isrc: json['isrc'] ?? json['external_ids']['isrc'],
      trackNumber: json['trackNumber'] ?? json['track_number'],
      popularity: json['popularity'] ?? json['popularity'],
      trackUrl: json['trackUrl'] ?? json['external_urls']['spotify'],
      previewUrl: json['previewUrl'] ?? json['preview_url'],
      albumUri: json['albumUri'] ?? json['album']['uri'],
      artistUri: json['artistUri'] is String
          ? json['artistUri']
          : (json['artists'] != null &&
                  (json['artists'] as List).isNotEmpty &&
                  json['artists'][0]['uri'] is String
              ? json['artists'][0]['uri']
              : null),
      trackUri: json['trackUri'] ?? json['uri'],
      promptId: json['promptId'],
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'albumName': albumName,
      'albumType': albumType,
      'albumUrl': albumUrl,
      'artworkUrl': artworkUrl,
      'releaseDate': releaseDate,
      'totalTracks': totalTracks,
      'discNumber': discNumber,
      'durationMs': durationMs,
      'explicit': explicit,
      'isrc': isrc,
      'trackNumber': trackNumber,
      'popularity': popularity,
      'trackUrl': trackUrl,
      'previewUrl': previewUrl,
      'albumUri': albumUri,
      'artistUri': artistUri,
      'trackUri': trackUri,
      'promptId': promptId,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
