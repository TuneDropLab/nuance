import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:nuance/widgets/artist_chip.dart';



class SpotifyPlaylistCard extends StatelessWidget {
  final List<String> artistImages;
  final String playlistName;
  final String artistNames;
  final VoidCallback onClick;

  const SpotifyPlaylistCard({
    required this.artistImages,
    required this.playlistName,
    required this.artistNames,
    required this.onClick,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClick,
      child: Container(
        margin: const EdgeInsets.all(16),
        // padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(
            width: 2,
            style: BorderStyle.solid,
            color: Colors.transparent,
          ),
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.2),
              Colors.grey.shade600,
              Colors.grey.shade200.withOpacity(0.4),
              Colors.grey.shade400.withOpacity(0.5),
              Colors.white.withOpacity(0.6)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Container(
          // margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      spreadRadius: 6,
                      blurRadius: 15,
                      offset: const Offset(0, 9),
                    ),
                  ],
                  gradient: const LinearGradient(
                    colors: [
                      Color.fromARGB(255, 255, 204, 184),
                      Color.fromARGB(255, 255, 237, 184),
                      Color.fromARGB(255, 184, 255, 242),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                height: 90,
                child: Stack(
                  alignment: Alignment.center,
                  children: List.generate(artistImages.length, (index) {
                    return Positioned(
                      left: index * 34.0, // Adjust the overlap distance here
                      child: ArtistChip(
                        imageUrl: artistImages[index],
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                playlistName,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      overflow: TextOverflow.ellipsis,
                      fontSize: 18,
                    ),
              ),
              Row(
                children: [
                  SvgPicture.asset(
                    'assets/icon3users.svg',
                    height: 14,
                    color: Colors.white.withOpacity(0.7),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Expanded(
                    child: Text(
                      artistNames,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white.withOpacity(0.7),
                            fontWeight: FontWeight.w500,
                            overflow: TextOverflow.ellipsis,
                            fontSize: 14,
                          ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
