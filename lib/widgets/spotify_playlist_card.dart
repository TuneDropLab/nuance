import 'dart:convert';
import 'dart:developer';
import 'dart:math' as math;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:nuance/utils/constants.dart';
import 'package:nuance/widgets/animated_box.dart';
import 'package:nuance/widgets/artist_chip.dart';
import 'package:nuance/models/song_model.dart';
import 'package:nuance/providers/session_notifier.dart';
import 'package:nuance/widgets/custom_snackbar.dart';
import 'package:shimmer/shimmer.dart';
import 'package:mesh_gradient/mesh_gradient.dart';

class SpotifyPlaylistCard extends ConsumerStatefulWidget {
  final String trackListHref;
  final String playlistName;
  final String playlistId;
  final String artistNames;
  final VoidCallback onClick;

  const SpotifyPlaylistCard({
    required this.trackListHref,
    required this.playlistName,
    required this.playlistId,
    required this.artistNames,
    required this.onClick,
    Key? key,
  }) : super(key: key);

  @override
  _SpotifyPlaylistCardState createState() => _SpotifyPlaylistCardState();
}

class _SpotifyPlaylistCardState extends ConsumerState<SpotifyPlaylistCard> {
  List<String> artistImages = [];
  late final AnimatedMeshGradientController _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller = AnimatedMeshGradientController();
    _fetchArtistsImages(playlistId: widget.playlistId);
  }

  Future<void> _fetchArtistsImages({required String playlistId}) async {
    try {
      final sessionState = ref.watch(sessionProvider);
      final accessToken = sessionState.value?.accessToken ?? '';

      final List<String> images = [];

      final artistResponse = await http.post(
        Uri.parse('$baseURL/spotify/artists-images'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'playlistId': playlistId}),
      );

      if (artistResponse.statusCode == 200) {
        final artistData =
            jsonDecode(artistResponse.body) as Map<String, dynamic>;
        final List<dynamic> artistImagesData = artistData['artistImages'];
        for (final artistImage in artistImagesData) {
          images.add(artistImage);
        }
      } else {
        log('Failed to load artist images: ${artistResponse.body}');
        throw Exception('Failed to load artist images');
      }

      if (mounted) {
        setState(() {
          artistImages = images;
        });
      }
    } catch (e) {
      log('Exception in _fetchArtistsImages: $e');

      throw Exception('Failed to load artist images');
    }
  }

  @override
  Widget build(BuildContext context) {
    final gradientOptions = [
      AnimatedMeshGradientOptions(
        amplitude: 0,
        grain: 1.0,
        frequency: 10,
        speed: 8,
      ),
      AnimatedMeshGradientOptions(
        amplitude: 20,
        grain: 0.0,
        frequency: 1,
        speed: 5,
      ),
      // Add more options if needed
    ];

    AnimatedMeshGradientOptions getRandomGradientOptions() {
      final random = math.Random();
      return gradientOptions[random.nextInt(gradientOptions.length)];
    }

    const pastelColors = [
      Color.fromARGB(255, 164, 136, 126),
      Color.fromARGB(255, 239, 212, 130),
      Color.fromARGB(255, 151, 253, 234),
      Color.fromARGB(255, 147, 192, 237),
      Color.fromARGB(255, 145, 145, 248),
      Color.fromARGB(255, 254, 197, 254),
      Color.fromARGB(255, 204, 255, 204),
      Color.fromARGB(255, 255, 229, 204),
    ];

    List<Color> getRandomPastelColors() {
      final random = math.Random();
      final colors = <Color>[];

      while (colors.length < 4) {
        final color = pastelColors[random.nextInt(pastelColors.length)];
        if (!colors.contains(color)) {
          colors.add(color);
        }
      }

      return colors;
    }

    return GestureDetector(
      onTap: widget.onClick,
      child: Container(
        height: 210,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
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
              const Color.fromARGB(38, 255, 255, 255).withOpacity(0.2),
              const Color.fromARGB(50, 255, 255, 255),
              const Color.fromARGB(255, 95, 95, 95).withOpacity(0.4),
              const Color.fromARGB(255, 76, 76, 76).withOpacity(0.6),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          decoration: BoxDecoration(
            color: const Color(0xff292929),
            borderRadius: BorderRadius.circular(23),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedBox(
                width: double.maxFinite,
                height: 90,
                child: AnimatedMeshGradient(
                  colors: getRandomPastelColors(),
                  options: getRandomGradientOptions(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    // decoration: BoxDecoration(
                    //   color: Colors.grey[800],
                    //   borderRadius: BorderRadius.circular(10),
                    //   boxShadow: [
                    //     BoxShadow(
                    //       color: Colors.black.withOpacity(0.9),
                    //       spreadRadius: 6,
                    //       blurRadius: 15,
                    //       offset: const Offset(0, 9),
                    //     ),
                    //   ],
                    // ),
                    height: 90,
                    child: artistImages.isEmpty
                        ? Shimmer.fromColors(
                            baseColor: const Color.fromARGB(69, 0, 0, 0),
                            highlightColor: const Color.fromARGB(121, 0, 0, 0),
                            child: Stack(
                              alignment: Alignment.center,
                              children: List.generate(7, (index) {
                                return Positioned(
                                    left: index *
                                        34.0, // Adjust the overlap distance here
                                    child: const CircleAvatar(
                                      radius: 30,
                                      child: CircleAvatar(
                                        radius: 28.0,
                                        backgroundColor:
                                            Color.fromARGB(85, 0, 0, 0),
                                      ),
                                    ));
                              }),
                            ),
                          )
                        : Center(
                            child: Stack(
                              alignment: Alignment.center,
                              children: List.generate(
                                artistImages.length,
                                (index) {
                                  return Positioned(
                                    left: index *
                                        34.0, // Adjust the overlap distance here
                                    child: ArtistChip(
                                      imageUrl: artistImages[index],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                  ),
                ),
              ),
              // AnimatedMeshGradient(
              //   colors: const [
              //     Color.fromARGB(255, 255, 204, 184),
              //     Color.fromARGB(255, 255, 237, 184),
              //     // Color.fromARGB(255, 184, 255, 242),
              //     Color.fromARGB(255, 7, 52, 98),
              //   ],
              //   options: AnimatedMeshGradientOptions(
              //     amplitude: 30,
              //     grain: 0.4,
              //     frequency: 5,
              //     speed: 2,
              //   ),
              //   child: Container(
              //     height: 90,
              //   ),
              //   // controller: _controller,
              //   // child: Container(
              //   //   padding:
              //   //       const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              //   //   // decoration: BoxDecoration(
              //   //   //   color: Colors.grey[800],
              //   //   //   borderRadius: BorderRadius.circular(10),
              //   //   //   boxShadow: [
              //   //   //     BoxShadow(
              //   //   //       color: Colors.black.withOpacity(0.9),
              //   //   //       spreadRadius: 6,
              //   //   //       blurRadius: 15,
              //   //   //       offset: const Offset(0, 9),
              //   //   //     ),
              //   //   //   ],
              //   //   // ),
              //   //   height: 90,
              //   //   child: artistImages.isEmpty
              //   //       ? Shimmer.fromColors(
              //   //           baseColor: Colors.grey[700]!,
              //   //           highlightColor: Colors.grey[500]!,
              //   //           child: Stack(
              //   //             alignment: Alignment.center,
              //   //             children: List.generate(7, (index) {
              //   //               return Positioned(
              //   //                   left: index *
              //   //                       34.0, // Adjust the overlap distance here
              //   //                   child: const CircleAvatar(
              //   //                     radius: 30,
              //   //                     child: CircleAvatar(
              //   //                       radius: 28.0,
              //   //                       backgroundColor:
              //   //                           Color.fromARGB(255, 95, 94, 94),
              //   //                     ),
              //   //                   ));
              //   //             }),
              //   //           ),
              //   //         )
              //   //       : const Center(
              //   //           // child: Stack(
              //   //           //   alignment: Alignment.center,
              //   //           //   children: List.generate(
              //   //           //     artistImages.length,
              //   //           //     (index) {
              //   //           //       return Positioned(
              //   //           //         left: index *
              //   //           //             34.0, // Adjust the overlap distance here
              //   //           //         child: ArtistChip(
              //   //           //           imageUrl: artistImages[index],
              //   //           //         ),
              //   //           //       );
              //   //           //     },
              //   //           //   ),
              //   //           // ),
              //   //           ),
              //   // ),
              // ),
              const SizedBox(height: 20),
              Text(
                widget.playlistName,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      overflow: TextOverflow.ellipsis,
                      fontSize: 18,
                    ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.artistNames,
                      maxLines: 1,
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

class SpotifyPlaylistShadow extends StatelessWidget {
  const SpotifyPlaylistShadow({super.key});

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}

@override
Widget build(BuildContext context) {
  return Container(
    height: 210,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(25),
      border: Border.all(
        width: 2,
        style: BorderStyle.solid,
        color: Colors.transparent,
      ),
    ),
  );
}
