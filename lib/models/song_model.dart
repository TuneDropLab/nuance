import 'dart:developer';

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
    log("SONG MODEL JSON: $json");
    return SongModel(
      id: json['id']?.toString() ??
          json['songId']?.toString() ??
          json['playParams']?['id']?.toString() ??
          "",

      title: json['title'] ??
          json['name'] ??
          json['attributes']?['name'] ??
          json['trackName'] ??
          "",

      artist: json['artist'] ??
          (json['artists'] != null && (json['artists'] as List).isNotEmpty
              ? json['artists'][0]['name']
              : json['attributes']?['artistName']) ??
          json['artistName'] ??
          "",

      albumName: json['attributes']?['albumName'] ??
          json['albumName'] ??
          json['album']?['name'] ??
          "",

      albumType: json['attributes']?['albumType'] ??
          json['albumType'] ??
          json['album']?['type'] ??
          "",

      albumUrl: json['attributes']?['albumUrl'] ??
          json['albumUrl'] ??
          json['album']?['external_urls']?['spotify'] ??
          json['url'] ??
          "",

      artworkUrl: json['attributes']?['artworkUrl'] ??
          (json['album']?['images'] != null &&
                  (json['album']?['images'] as List).isNotEmpty
              ? json['album']['images'][0]['url']
              : json['attributes']?['artwork']?['url']
                  ?.replaceAll('{w}x{h}', '300x300') ??
              json['artwork']?['url']
                  ?.replaceAll('{w}x{h}', '300x300')) ??
          "",

      releaseDate: json['attributes']?['releaseDate'] ??
          json['releaseDate'] ??
          json['album']?['release_date'] ??
          "",

      totalTracks: json['attributes']?['totalTracks'] ??
          json['totalTracks'] ??
          json['album']?['total_tracks'] ??
          0,

      discNumber: json['attributes']?['discNumber'] ??
          json['discNumber'] ??
          json['disc_number'] ??
          json['discNumber'] ??
          0,

      durationMs: json['attributes']?['durationMs'] ??
          json['durationMs'] ??
          json['duration_ms'] ??
          json['durationInMillis'] ??
           0,

      explicit: json['explicit'] ??
          json['is_explicit'] ??
          json['contentRating'] == 'explicit' ??
          false,

      isrc: json['isrc'] ?? json['external_ids']?['isrc'] ?? "",

      trackNumber: json['trackNumber'] ?? json['track_number'] ?? 0,

      popularity: json['popularity'] ?? 0,

      trackUrl: json['trackUrl'] ??
          json['external_urls']?['spotify'] ??
          json['url'] ?? json['attributes']['url'] ??
          "",

      previewUrl: json['previewUrl'] ??
          json['preview_url'] ??
          (json['attributes']?['previews'] != null &&
                  (json['attributes']?['previews'] as List).isNotEmpty
              ? json['attributes']['previews'][0]['url']
              : null) ??
          "",

      albumUri: json['albumUri'] ?? json['album']?['uri'] ?? "",

      artistUri: json['artistUri'] is String
          ? json['artistUri']
          : (json['artists'] != null &&
                      (json['artists'] as List).isNotEmpty &&
                      json['artists'][0]['uri'] is String
                  ? json['artists'][0]['uri']
                  : null) ??
              "",

      trackUri: json['trackUri'] ?? json['uri'] ?? "",

      promptId: json['promptId'] ?? 0,

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
