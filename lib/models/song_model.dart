class SongModel {
  final int? id;
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
      id: json['id'],
      title: json['title'],
      artist: json['artist'],
      albumName: json['albumName'],
      albumType: json['albumType'],
      albumUrl: json['albumUrl'],
      artworkUrl: json['artworkUrl'],
      releaseDate: json['releaseDate'],
      totalTracks: json['totalTracks'],
      discNumber: json['discNumber'],
      durationMs: json['durationMs'],
      explicit: json['explicit'],
      isrc: json['isrc'],
      trackNumber: json['trackNumber'],
      popularity: json['popularity'],
      trackUrl: json['trackUrl'],
      previewUrl: json['previewUrl'],
      albumUri: json['albumUri'],
      artistUri: json['artistUri'],
      trackUri: json['trackUri'],
      promptId: json['promptId'],
      createdAt: DateTime.parse(json['createdAt']),
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
