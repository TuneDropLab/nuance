import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:nuance/models/history_model.dart';
import 'package:nuance/models/session_data_model.dart';
import 'package:nuance/providers/history_provider.dart';
import 'package:nuance/screens/recommendations_result_screen.dart';
import 'package:nuance/theme.dart';

class MyCustomDrawer extends ConsumerStatefulWidget {
  // sessionState
  final AsyncValue<SessionData?> sessionState;
  const MyCustomDrawer({
    required this.sessionState,
    super.key,
  });

  @override
  _MyCustomDrawerState createState() => _MyCustomDrawerState();
}

class _MyCustomDrawerState extends ConsumerState<MyCustomDrawer> {
  String? _selectedArtist;
  Map<String, int> _artists = {};

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black87,
      child: SafeArea(
        child: Container(
          height: Get.height,
          width: Get.width * 0.9,
          color: Colors.transparent,
          child: Column(
            children: [
              // Heading and Search Bar
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'History',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    // Search bar
                    SizedBox(
                      width: 200,
                      height: 40,
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search',
                          hintStyle: const TextStyle(color: Colors.white70),
                          filled: true,
                          fillColor: Colors.white10,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Colors.white70,
                          ),
                        ),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              // Dynamic Artist Chips
              Container(
                height: 50,
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Consumer(
                  builder: (context, watch, child) {
                    final historyAsyncValue = ref.watch(historyProvider);
                    return historyAsyncValue.when(
                      data: (history) {
                        // Generate artists
                        _artists = _generateArtists(history);
                        return ListView(
                          scrollDirection: Axis.horizontal,
                          children: _artists.keys.map((artist) {
                            return AnimatedOpacity(
                              opacity: _selectedArtist == null ||
                                      _selectedArtist == artist
                                  ? 1.0
                                  : 0.2,
                              duration: const Duration(milliseconds: 500),
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4.0),
                                child: ChoiceChip(
                                  label: Text('$artist (${_artists[artist]})'),
                                  selected: _selectedArtist == artist,
                                  onSelected: (bool selected) {
                                    setState(() {
                                      _selectedArtist =
                                          selected ? artist : null;
                                    });
                                  },
                                  selectedColor: Colors.blue,
                                  backgroundColor: Colors.white10,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20.0),
                                  ),
                                  labelStyle: TextStyle(
                                    color: _selectedArtist == artist
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      },
                      loading: () => const Center(
                        child: CupertinoActivityIndicator(),
                      ),
                      error: (error, stackTrace) => Center(
                        child: Text(
                          'Error: $error',
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    );
                  },
                ),
              ),
              // History List
              Expanded(
                child: Consumer(
                  builder: (context, watch, child) {
                    final historyAsyncValue = ref.watch(historyProvider);

                    return historyAsyncValue.when(
                      data: (history) {
                        final filteredHistory =
                            _filterHistoryByArtist(history, _selectedArtist);
                        return ListView.separated(
                          separatorBuilder: (context, index) {
                            return const Divider(
                              color: Colors.transparent,
                            );
                          },
                          itemCount: filteredHistory.length,
                          itemBuilder: (context, index) {
                            final historyItem = filteredHistory[index];
                            return ListTile(
                              title: Text(
                                historyItem.searchQuery ?? '',
                                style: const TextStyle(color: Colors.white),
                              ),
                              subtitle: Text(
                                _formatRelativeTime(
                                    historyItem.createdAt ?? DateTime.now()),
                                style: const TextStyle(color: Colors.white70),
                              ),
                              leading:
                                  historyItem.recommendations?.isNotEmpty ??
                                          false
                                      ? ArtworkSwitcher(
                                          artworks: historyItem.recommendations!
                                              .map((song) => song.artworkUrl)
                                              .toList(),
                                        )
                                      : const Icon(
                                          Icons.square,
                                          color: Colors.white,
                                        ),
                              onTap: () {
                                // setState(() {
                                //   // Trigger the change of artwork
                                // });
                                Get.to(RecommendationsResultScreen(
                                  searchQuery: historyItem.searchQuery,
                                  sessionState: widget.sessionState,
                                  songs: historyItem.recommendations!,
                                ));
                              },
                            );
                          },
                        );
                      },
                      loading: () => const Center(
                        child: CupertinoActivityIndicator(),
                      ),
                      error: (error, stackTrace) => Center(
                        child: Text(
                          'Error: $error',
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, int> _generateArtists(List<HistoryModel> history) {
    final artistMap = <String, int>{};
    for (var item in history) {
      if (item.recommendations != null) {
        for (var song in item.recommendations!) {
          if (song.artistUri != null && song.artistUri!.isNotEmpty) {
            var artists = song.artist!.split(', ');
            for (var artist in artists) {
              if (artistMap.containsKey(artist)) {
                artistMap[artist] = artistMap[artist]! + 1;
              } else {
                artistMap[artist] = 1;
              }
            }
          }
        }
      }
    }
    return artistMap..entries.toList();
  }

  List<HistoryModel> _filterHistoryByArtist(
      List<HistoryModel> history, String? artist) {
    if (artist == null) return history;
    return history.where((item) {
      if (item.recommendations != null) {
        return item.recommendations!
            .any((song) => song.artist!.contains(artist));
      }
      return false;
    }).toList();
  }

  String _formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      final seconds = difference.inSeconds;
      return '$seconds ${seconds == 1 ? 'second' : 'seconds'} ago';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '$minutes ${minutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days ${days == 1 ? 'day' : 'days'} ago';
    } else if (difference.inDays < 30) {
      final weeks = difference.inDays ~/ 7;
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else if (difference.inDays < 365) {
      final months = difference.inDays ~/ 30;
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      final years = difference.inDays ~/ 365;
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    }
  }
}

class ArtworkSwitcher extends StatefulWidget {
  final List<String?> artworks;

  const ArtworkSwitcher({super.key, required this.artworks});

  @override
  _ArtworkSwitcherState createState() => _ArtworkSwitcherState();
}

class _ArtworkSwitcherState extends State<ArtworkSwitcher> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _startArtworkSwitcher();
  }

  void _startArtworkSwitcher() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          if (widget.artworks.isNotEmpty) {
            _currentIndex = (_currentIndex + 1) % widget.artworks.length;
          }
        });
        _startArtworkSwitcher();
      }
    });
  }

  // random list of colors

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 45,
      width: 45,
      child: AnimatedSwitcher(
        duration: const Duration(seconds: 1),
        child:
            widget.artworks.isNotEmpty && widget.artworks[_currentIndex] != null
                ? CachedNetworkImage(
                    // height: 45,
                    // width: 45,
                    imageUrl: widget.artworks[_currentIndex]!,
                    key: ValueKey<int>(_currentIndex),
                    placeholder: (context, url) {
                      return const Center(
                        child: CupertinoActivityIndicator(),
                      );
                    },
                    errorWidget: (context, url, error) {
                      return const Icon(
                        Icons.error,
                        color: Colors.white,
                      );
                    },
                  )
                : Container(
                    // height: 45,
                    // width: 45,
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.square,
                      color: Colors.white,
                    ),
                  ),
      ),
    );
  }
}
