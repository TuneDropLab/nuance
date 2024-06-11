class PlaylistModel {
  final bool collaborative;
  final String description;
  final String externalUrl;
  final String href;
  final String id;
  final String imageUrl;
  final String name;
  final String ownerDisplayName;
  final String ownerExternalUrl;
  final String ownerHref;
  final String ownerId;
  final String ownerType;
  final String ownerUri;
  final String primaryColor;
  final bool public;
  final String snapshotId;
  final String tracksHref;
  final int totalTracks;
  final String type;
  final String uri;

  PlaylistModel({
    required this.collaborative,
    required this.description,
    required this.externalUrl,
    required this.href,
    required this.id,
    required this.imageUrl,
    required this.name,
    required this.ownerDisplayName,
    required this.ownerExternalUrl,
    required this.ownerHref,
    required this.ownerId,
    required this.ownerType,
    required this.ownerUri,
    required this.primaryColor,
    required this.public,
    required this.snapshotId,
    required this.tracksHref,
    required this.totalTracks,
    required this.type,
    required this.uri,
  });

  factory PlaylistModel.fromJson(Map<String, dynamic> json) {
    return PlaylistModel(
      collaborative: json['collaborative'],
      description: json['description'],
      externalUrl: json['external_urls']['spotify'],
      href: json['href'],
      id: json['id'],
      imageUrl: (json['images'] != null && (json['images'] as List).isNotEmpty)
          ? json['images'][0]['url']
          : '',
      name: json['name'],
      ownerDisplayName: json['owner']['display_name'],
      ownerExternalUrl: json['owner']['external_urls']['spotify'],
      ownerHref: json['owner']['href'],
      ownerId: json['owner']['id'],
      ownerType: json['owner']['type'],
      ownerUri: json['owner']['uri'],
      primaryColor: json['primary_color'] ?? '',
      public: json['public'],
      snapshotId: json['snapshot_id'],
      tracksHref: json['tracks']['href'],
      totalTracks: json['tracks']['total'],
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
