import 'dart:developer';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuance/providers/recommendation_provider.dart';
import 'package:nuance/models/song_model.dart';

class RecommendationsResultScreen extends ConsumerStatefulWidget {
  static const routeName = '/recommendations-result';

  const RecommendationsResultScreen({super.key});

  @override
  ConsumerState<RecommendationsResultScreen> createState() =>
      _RecommendationsResultScreenState();
}

class _RecommendationsResultScreenState
    extends ConsumerState<RecommendationsResultScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  SongModel? _currentSong;

  void _togglePlay(SongModel song) async {
    if (song.previewUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No preview available for this song.')),
      );
      return;
    }

    if (_isPlaying && _currentSong?.id == song.id) {
      await _audioPlayer.pause();
      setState(() {
        _isPlaying = false;
      });
    } else {
      if (_currentSong != null) {
        await _audioPlayer.stop();
      }
      await _audioPlayer.play(UrlSource(song.previewUrl));
      setState(() {
        _isPlaying = true;
        _currentSong = song;
      });
    }
  }

  void _showArtworkOverlay(BuildContext context, String artworkUrl) {
    showDialog(
      context: context,
      builder: (context) {
        return GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Scaffold(
            backgroundColor: Colors.black54,
            body: Center(
              child: Image.network(
                artworkUrl,
                width: MediaQuery.of(context).size.width * 0.5,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final arguments = ModalRoute.of(context)!.settings.arguments as Map;
    final searchTerm = arguments['search_term'] as String;

    final recommendationsState = ref.watch(recommendationsProvider(searchTerm));

    return Scaffold(
      appBar: AppBar(
        title: Text(searchTerm),
      ),
      body: recommendationsState.when(
        data: (recommendations) {
          log("Log screen result: $recommendations");
          return ListView.builder(
            itemCount: recommendations.length,
            itemBuilder: (context, index) {
              final recommendation = recommendations[index];
              return ListTile(
                leading: GestureDetector(
                  onTap: () =>
                      _showArtworkOverlay(context, recommendation.artworkUrl),
                  child: Image.network(
                    recommendation.artworkUrl,
                    width: 50,
                    height: 50,
                  ),
                ),
                title: Text(recommendation.name),
                subtitle: Text(recommendation.artists.join(', ')),
                trailing:
                    recommendation.explicit ? const Icon(Icons.explicit) : null,
                onTap: () => _togglePlay(recommendation),
              );
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
