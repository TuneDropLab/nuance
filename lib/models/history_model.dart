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
    final rawRecs = json['recommendations'];
    List<SongModel> recsList = [];
    if (rawRecs is List) {
      recsList = rawRecs
          .whereType<Map<String, dynamic>>()
          .map((x) => SongModel.fromJson(x))
          .toList();
    }

    DateTime parsedDate;
    if (json['createdAt'] != null) {
      parsedDate =
          DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    int? parsedId;
    if (json['id'] != null) {
      parsedId = json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id'].toString());
    }

    return HistoryModel(
      id: parsedId,
      searchQuery: json['searchQuery']?.toString(),
      recommendations: recsList,
      imageUrl: json['image']?.toString() ?? json['imageUrl']?.toString(),
      createdAt: parsedDate,
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
