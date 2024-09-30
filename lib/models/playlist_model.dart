import 'dart:developer';

class PlaylistModel {
  final bool? collaborative; // For Spotify
  final String? description;
  final String? externalUrl;
  final String? href;
  final String? id;
  final String? imageUrl;
  final String? name;
  final String? ownerDisplayName; // For Spotify
  final String? ownerExternalUrl; // For Spotify
  final String? ownerHref; // For Spotify
  final String? ownerId; // For Spotify
  final String? ownerType; // For Spotify
  final String? ownerUri; // For Spotify
  final String? primaryColor; // For Spotify
  final bool? public; // For Spotify and Apple Music
  final String? snapshotId; // For Spotify
  final String? tracksHref; // For Spotify
  final int? totalTracks; // For Spotify
  final String? type;
  final String? uri; // For Spotify

  // New fields for Apple Music

  final bool? canEdit; // For Apple Music Library


  PlaylistModel({
    this.collaborative,
    this.description,
    this.externalUrl,
    this.href,
    this.id,
    this.imageUrl,
    this.name,
    this.ownerDisplayName,
    this.ownerExternalUrl,
    this.ownerHref,
    this.ownerId,
    this.ownerType,
    this.ownerUri,
    this.primaryColor,
    this.public,
    this.snapshotId,
    this.tracksHref,
    this.totalTracks,
    this.type,
    this.uri,
    this.canEdit,
  });

  factory PlaylistModel.fromJson(Map<String, dynamic> json) {
    log("PlaylistModel json: $json");

    return PlaylistModel(
      collaborative: json['collaborative'] ?? false,
      description: json['description'] ?? json['attributes']?['description']['standard'] ?? '',
      externalUrl: json['external_urls'] != null ? json['external_urls']['spotify'] : json['attributes']?['url'] ?? '',
      href: json['href'] ?? '',
      id: json['id'] ?? json['attributes']?['playParams']?['globalId'] ?? '',
      imageUrl: (json['images'] != null && (json['images'] as List).isNotEmpty)
          ? json['images'][0]['url']
          : json['attributes']?['artwork']?['url']?.replaceAll('{w}x{h}', '500x500') ?? '',
      name: json['name'] ?? json['attributes']?['name'] ?? '',
      ownerDisplayName: json['owner'] != null ? json['owner']['display_name'] : json['attributes']?['curatorName'] ?? '',
      ownerExternalUrl: json['owner'] != null ? json['owner']['external_urls']['spotify'] : '',
      ownerHref: json['owner'] != null ? json['owner']['href'] : '',
      ownerId: json['owner'] != null ? json['owner']['id'] : '',
      ownerType: json['owner'] != null ? json['owner']['type'] : '',
      ownerUri: json['owner'] != null ? json['owner']['uri'] : '',
      primaryColor: json['primary_color'] ?? '',
      public: json['public'] ?? json['attributes']?['isPublic'] ?? false,
      snapshotId: json['snapshot_id'] ?? '',
      tracksHref: json['tracks'] != null ? json['tracks']['href'] : '',
      totalTracks: json['tracks'] != null ? json['tracks']['total'] : 0,
      type: json['type'] ?? '',
      uri: json['uri'] ?? '',
      canEdit: json['attributes']?['canEdit'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'collaborative': collaborative,
      'description': description,
      'externalUrl': externalUrl,
      'href': href,
      'id': id,
      'imageUrl': imageUrl,
      'name': name,
      'ownerDisplayName': ownerDisplayName,
      'ownerExternalUrl': ownerExternalUrl,
      'ownerHref': ownerHref,
      'ownerId': ownerId,
      'ownerType': ownerType,
      'ownerUri': ownerUri,
      'primaryColor': primaryColor,
      'public': public,
      'snapshotId': snapshotId,
      'tracksHref': tracksHref,
      'totalTracks': totalTracks,
      'type': type,
      'uri': uri,
      'canEdit': canEdit,
    };
  }
}