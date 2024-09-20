import 'package:nuance/models/song_model.dart';

class HistoryModel {
  final int? id;
  final String? searchQuery;
  final List<SongModel>? recommendations;
  final String? imageUrl;
  final DateTime? createdAt;

  HistoryModel({
    this.searchQuery,
    this.id,
    this.recommendations,
    this.imageUrl,
    this.createdAt,
  });

  factory HistoryModel.fromJson(Map<String, dynamic> json) {
    return HistoryModel(
      id: json['id'],
      searchQuery: json['searchQuery'],
      recommendations: List<SongModel>.from(
          json['recommendations'].map((x) => SongModel.fromJson(x))),
      imageUrl: json['image'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

class ProviderType {
  static String? _type;

  static void setType(String type) {
    _type = type;
  }

  static String? get type => _type;
}
