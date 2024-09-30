import 'dart:developer';

class ApplePlaylistModel {
  final String? id;
  final String? name;
  final String? description;
  final String? imageUrl;
  final String? ownerName;
  final String? playlistUrl;
  final int? totalTracks;
  final DateTime? dateAdded;
  final bool? canEdit;

  ApplePlaylistModel({
    this.id,
    this.name,
    this.description,
    this.imageUrl,
    this.ownerName,
    this.playlistUrl,
    this.totalTracks,
    this.dateAdded,
    this.canEdit
  });

  factory ApplePlaylistModel.fromJson(Map<String, dynamic> json) {
    log("PLAYLIST MODEL JSON: $json");
      // Apple Music
      return ApplePlaylistModel(
        id: json['id'],
        name: json['attributes']?['name'],
        description: json['attributes']?['description']?['standard'],
        imageUrl: json['attributes']?['artwork']?['url']?.replaceAll('{w}x{h}', '500x500'),
        ownerName: null,
        playlistUrl: json['attributes']?['playParams']?['id'],
        totalTracks: null,
        dateAdded: json['attributes']?['dateAdded'] != null
            ? DateTime.parse(json['attributes']?['dateAdded'])
            : null,
        canEdit: json['attributes']?['canEdit']
      );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'ownerName': ownerName,
      'playlistUrl': playlistUrl,
      'totalTracks': totalTracks,
      'dateAdded': dateAdded?.toIso8601String(),
      'canEdit': canEdit
    };
  }
}
