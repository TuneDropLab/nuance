import 'package:nuance/models/song_model.dart';

class HistoryModel {
  final int? id;
  final String? searchQuery;
  final List<SongModel>? recommendations;
  final DateTime? createdAt;

  HistoryModel({
    this.searchQuery,
    this.id,
    this.recommendations,
    this.createdAt,
  });

  factory HistoryModel.fromJson(Map<String, dynamic> json) {
    return HistoryModel(
      id: json['id'],
      searchQuery: json['searchQuery'],
      recommendations: List<SongModel>.from(
          json['recommendations'].map((x) => SongModel.fromJson(x))),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
