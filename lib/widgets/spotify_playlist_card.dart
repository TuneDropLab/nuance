import 'dart:convert';
import 'dart:developer';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:nuance/widgets/artist_chip.dart';
import 'package:nuance/models/song_model.dart';
import 'package:nuance/providers/session_notifier.dart';

class SpotifyPlaylistCard extends ConsumerStatefulWidget {
  final String trackListHref;
  final String playlistName;
  final String artistNames;
  final VoidCallback onClick;

  const SpotifyPlaylistCard({
    required this.trackListHref,
    required this.playlistName,
    required this.artistNames,
    required this.onClick,
    Key? key,
  }) : super(key: key);

  @override
  _SpotifyPlaylistCardState createState() => _SpotifyPlaylistCardState();
}

class _SpotifyPlaylistCardState extends ConsumerState<SpotifyPlaylistCard> {
  List<String> artistImages = [];

  @override
  void initState() {
    super.initState();
    _fetchTrackList();
  }

  Future<void> _fetchTrackList() async {
    try {
      // final sessionState = ref.watch(sessionProvider.notifier);
      final sessionState = ref.watch(sessionProvider);

      final accessToken = sessionState.value!.accessToken;

      final response = await http.get(
        Uri.parse(widget.trackListHref),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );
      print(response);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("NO WOAHHHH $data");
        final tracks = data['items'] as List<dynamic>;

        setState(() {
          artistImages = tracks.map((track) {
            final artist = track['track']['artists'][0];
            return artist['images'][0]['url'] as String;
          }).toList();
        });
      } else {
        log('Failed to load tracks: ${response.body}');
        throw Exception('Failed to load tracks');
      }
    } catch (e) {
      log('Exception in _fetchTrackList: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
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
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.9),
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
                  SvgPicture.asset(
                    'assets/icon3users.svg',
                    height: 14,
                    color: Colors.white.withOpacity(0.7),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.artistNames,
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
