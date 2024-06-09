class RecommendationModel {
  final String title;
  final String artist;

  RecommendationModel({
    required this.title,
    required this.artist,
  });

  factory RecommendationModel.fromJson(Map<String, dynamic> json) {
    return RecommendationModel(
      title: json['title'] ?? '',
      artist: json['artist'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'artist': artist,
    };
  }
}
