class PlaylistModel {
  final bool? collaborative;
  final String? description;
  final String? externalUrl;
  final String? href;
  final String? id;
  final String? imageUrl;
  final String? name;
  final String? ownerDisplayName;
  final String? ownerExternalUrl;
  final String? ownerHref;
  final String? ownerId;
  final String? ownerType;
  final String? ownerUri;
  final String? primaryColor;
  final bool? public;
  final String? snapshotId;
  final String? tracksHref;
  final int? totalTracks;
  final String? type;
  final String? uri;

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
  });

  factory PlaylistModel.fromJson(Map<String, dynamic> json) {
    return PlaylistModel(
      collaborative: json['collaborative'],
      description: json['description'],
      externalUrl: json['external_urls'] != null ? json['external_urls']['spotify'] : null,
      href: json['href'],
      id: json['id'],
      imageUrl: (json['images'] != null && (json['images'] as List).isNotEmpty)
          ? json['images'][0]['url']
          : null,
      name: json['name'],
      ownerDisplayName: json['owner'] != null ? json['owner']['display_name'] : null,
      ownerExternalUrl: json['owner'] != null ? json['owner']['external_urls']['spotify'] : null,
      ownerHref: json['owner'] != null ? json['owner']['href'] : null,
      ownerId: json['owner'] != null ? json['owner']['id'] : null,
      ownerType: json['owner'] != null ? json['owner']['type'] : null,
      ownerUri: json['owner'] != null ? json['owner']['uri'] : null,
      primaryColor: json['primary_color'],
      public: json['public'],
      snapshotId: json['snapshot_id'],
      tracksHref: json['tracks'] != null ? json['tracks']['href'] : null,
      totalTracks: json['tracks'] != null ? json['tracks']['total'] : null,
      type: json['type'],
      uri: json['uri'],
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
    };
  }
}
