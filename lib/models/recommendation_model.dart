class RecommendationModel {
  // final String id;
  final String title;
  final String artist;
  // final String album;
  // final String artworkUrl;

  RecommendationModel({
    // required this.id,
    required this.title,
    required this.artist,
    // required this.album,
    // required this.artworkUrl,
  });

  factory RecommendationModel.fromJson(Map<String, dynamic> json) {
    return RecommendationModel(
      // id: json['id'],
      title: json['title'],
      artist: json['artist'],
      // album: json['album'],
      // artworkUrl: json['artworkUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      // 'id': id,
      'title': title,
      'artist': artist,
      // 'album': album,
      // 'artworkUrl': artworkUrl,
    };
  }
}
