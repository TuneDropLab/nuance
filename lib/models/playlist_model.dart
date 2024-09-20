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

  // New fields for Apple Music
  final String? curatorName; // For Apple Music
  final String? lastModifiedDate; // For Apple Music
  final bool? isChart; // For Apple Music
  final String? playlistType; // For Apple Music
  final Description? descriptionAttributes; // For Apple Music
  final Artwork? artwork; // For Apple Music
  final PlayParams? playParams; // For Apple Music
  final String? url; // For Apple Music

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
    // New fields
    this.curatorName,
    this.lastModifiedDate,
    this.isChart,
    this.playlistType,
    this.descriptionAttributes,
    this.artwork,
    this.playParams,
    this.url,
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
      // New fields
      curatorName: json['attributes']?['curatorName'],
      lastModifiedDate: json['attributes']?['lastModifiedDate'],
      isChart: json['attributes']?['isChart'],
      playlistType: json['attributes']?['playlistType'],
      descriptionAttributes: json['attributes']?['description'] != null
          ? Description.fromJson(json['attributes']['description'])
          : null,
      artwork: json['attributes']?['artwork'] != null
          ? Artwork.fromJson(json['attributes']['artwork'])
          : null,
      playParams: json['attributes']?['playParams'] != null
          ? PlayParams.fromJson(json['attributes']['playParams'])
          : null,
      url: json['attributes']?['url'],
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
      // New fields
      'curatorName': curatorName,
      'lastModifiedDate': lastModifiedDate,
      'isChart': isChart,
      'playlistType': playlistType,
      'description': descriptionAttributes?.toJson(),
      'artwork': artwork?.toJson(),
      'playParams': playParams?.toJson(),
      'url': url,
    };
  }
}

// Define the new fields for Apple Music attributes
class Description {
  final String? standard;
  final String? short;

  Description({this.standard, this.short});

  factory Description.fromJson(Map<String, dynamic> json) {
    return Description(
      standard: json['standard'],
      short: json['short'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'standard': standard,
      'short': short,
    };
  }
}

class Artwork {
  final int? width;
  final String? url;
  final int? height;
  final String? bgColor;
  final String? textColor1;
  final String? textColor2;
  final String? textColor3;
  final String? textColor4;

  Artwork({
    this.width,
    this.url,
    this.height,
    this.bgColor,
    this.textColor1,
    this.textColor2,
    this.textColor3,
    this.textColor4,
  });

  factory Artwork.fromJson(Map<String, dynamic> json) {
    return Artwork(
      width: json['width'],
      url: json['url'],
      height: json['height'],
      bgColor: json['bgColor'],
      textColor1: json['textColor1'],
      textColor2: json['textColor2'],
      textColor3: json['textColor3'],
      textColor4: json['textColor4'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'width': width,
      'url': url,
      'height': height,
      'bgColor': bgColor,
      'textColor1': textColor1,
      'textColor2': textColor2,
      'textColor3': textColor3,
      'textColor4': textColor4,
    };
  }
}

class PlayParams {
  final String? id;
  final String? kind;
  final String? versionHash;

  PlayParams({this.id, this.kind, this.versionHash});

  factory PlayParams.fromJson(Map<String, dynamic> json) {
    return PlayParams(
      id: json['id'],
      kind: json['kind'],
      versionHash: json['versionHash'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'kind': kind,
      'versionHash': versionHash,
    };
  }
}
