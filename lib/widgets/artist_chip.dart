import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class ArtistChip extends StatelessWidget {
  final String imageUrl;
  final double borderWidth;

  const ArtistChip({
    required this.imageUrl,
    this.borderWidth = 2.0,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 30,
      backgroundColor: Colors.white.withOpacity(0.3),
      child: CircleAvatar(
        radius: 30 - borderWidth,
        backgroundImage: CachedNetworkImageProvider(imageUrl),
        backgroundColor: Colors.transparent,
      ),
    );
  }
}