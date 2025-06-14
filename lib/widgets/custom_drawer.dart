import 'package:animated_hint_textfield/animated_hint_textfield.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:nuance/models/history_model.dart';
import 'package:nuance/models/session_data_model.dart';
import 'package:nuance/providers/history_provider.dart';
import 'package:nuance/screens/playlist_screen.dart';
import 'package:nuance/screens/settings_page.dart';
import 'package:nuance/services/all_services.dart';
import 'package:nuance/utils/constants.dart';
import 'package:nuance/widgets/custom_dialog.dart';
import 'package:nuance/widgets/general_button.dart';
import 'package:nuance/widgets/loader.dart';

class MyCustomDrawer extends ConsumerStatefulWidget {
  final AsyncValue<SessionData?> sessionState;
  const MyCustomDrawer({
    required this.sessionState,
    super.key,
  });

  @override
  _MyCustomDrawerState createState() => _MyCustomDrawerState();
}

class _MyCustomDrawerState extends ConsumerState<MyCustomDrawer> {
  final TextEditingController _searchController = TextEditingController();
  List<HistoryModel> _localHistory = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadHistory(); // Load history when dependencies change
  }

  void _loadHistory() {
    _localHistory = []; // Clear local history
    ref.read(historyProvider); // Trigger the provider to load data
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: Get.width,
      backgroundColor: const Color.fromARGB(255, 14, 14, 14),
      child: SafeArea(
        child: SizedBox(
          height: Get.height,
          width: Get.width,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 15,
            ),
            child: Stack(
              children: [
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.only(
                        top: 15,
                        bottom: 15,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Saved',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium!
                                .copyWith(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                          ),
                          const SizedBox(
                            width: 20,
                          ),
                          // Search bar
                          Expanded(
                            child: AnimatedTextField(
                              animationDuration: const Duration(seconds: 2),
                              maxLines: 1,
                              onTapOutside: (event) {
                                FocusManager.instance.primaryFocus?.unfocus();
                              },
                              controller: _searchController,
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.search),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(25),
                                  ),
                                  borderSide: BorderSide.none,
                                ),
                                fillColor: Color.fromARGB(98, 34, 34, 34),
                                filled: true,
                                contentPadding: EdgeInsets.all(12),
                              ),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                              hintTextStyle: Theme.of(context)
                                  .textTheme
                                  .titleMedium!
                                  .copyWith(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                              onSubmitted: (value) {
                                setState(() {});
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    // History List
                    Expanded(
                      child: Consumer(
                        builder: (context, watch, child) {
                          final historyAsyncValue = ref.watch(historyProvider);
                          return historyAsyncValue.when(
                            data: (history) {
                              _localHistory =
                                  history; // Update local history here
                              if (history.isEmpty) {
                                return Center(
                                  child: Text(
                                    'Save your first playlist to see history',
                                    style: subtitleTextStyle.copyWith(
                                      color: Colors.white,
                                    ),
                                  ),
                                );
                              }

                              return ValueListenableBuilder<TextEditingValue>(
                                valueListenable: _searchController,
                                builder: (context, value, __) {
                                  final filteredHistory = _filterHistoryByQuery(
                                      _localHistory, value.text);

                                  if (filteredHistory.isEmpty) {
                                    return Center(
                                      child: Text(
                                        'No results found',
                                        style: subtitleTextStyle.copyWith(
                                          color: Colors.white,
                                        ),
                                      ),
                                    );
                                  }
                                  return ListView.separated(
                                    padding: const EdgeInsets.only(
                                      bottom: 120,
                                    ),
                                    separatorBuilder: (context, index) {
                                      return const Divider(
                                        color: Colors.transparent,
                                      );
                                    },
                                    itemCount: filteredHistory.length,
                                    itemBuilder: (context, index) {
                                      final historyItem =
                                          filteredHistory[index];
                                      return ListTile(
                                        title: Text(
                                          historyItem.searchQuery ?? '',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                        subtitle: Text(
                                          _formatRelativeTime(
                                            historyItem.createdAt ??
                                                DateTime.now(),
                                          ),
                                          style: subtitleTextStyle,
                                        ),
                                        leading: historyItem.recommendations
                                                    ?.isNotEmpty ??
                                                false
                                            ? SizedBox(
                                                height: 50,
                                                width: 50,
                                                child: ArtworkSwitcher(
                                                  artworks: historyItem
                                                      .recommendations!
                                                      .map((song) =>
                                                          song.artworkUrl ?? "")
                                                      .toList(),
                                                ),
                                              )
                                            : const Icon(
                                                Icons.square,
                                                color: Colors.white,
                                              ),
                                        contentPadding: EdgeInsets.zero,
                                        onTap: () {
                                          Get.to(
                                            () => PlaylistScreen(
                                              searchTitle:
                                                  historyItem.searchQuery,
                                              sessionState: widget.sessionState,
                                              songs:
                                                  historyItem.recommendations!,
                                              imageUrl: historyItem.imageUrl,
                                            ),
                                          );
                                        },
                                        trailing: IconButton(
                                          icon: const Icon(
                                            CupertinoIcons.delete,
                                            size: 16,
                                            color: Colors.white,
                                          ),
                                          onPressed: () {
                                            _deleteHistoryItem(historyItem);
                                          },
                                        ),
                                      );
                                    },
                                  );
                                },
                              );
                            },
                            loading: () => Center(
                              child: SpinningSvg(
                                svgWidget: Image.asset(
                                  'assets/hdlogo.png',
                                  height: 40,
                                ),
                                textList: const [
                                  'Loading your history ...',
                                  'Just a moment ...',
                                  'Almost done ...',
                                ],
                              ),
                            ),
                            error: (error, stackTrace) => Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'Error loading history',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                  GeneralButton(
                                    onPressed: _loadHistory,
                                    text: "Retry",
                                    backgroundColor: Colors.grey,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    color: const Color.fromARGB(255, 14, 14, 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.settings,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            Get.to(const SettingsScreen());
                          },
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<HistoryModel> _filterHistoryByQuery(
      List<HistoryModel> history, String query) {
    if (query.isEmpty) return history;
    return history.where((item) {
      return item.searchQuery?.toLowerCase().contains(query.toLowerCase()) ??
          false;
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

  void _deleteHistoryItem(HistoryModel historyItem) {
    Get.dialog(
      ConfirmDialog(
        heading: "Delete ${historyItem.searchQuery}?",
        subtitle: "Are you sure you want to delete this item?",
        confirmText: "Delete",
        onConfirm: () {
          Get.back();
          setState(() {
            _localHistory.remove(historyItem);
          });

          AllServices().deleteHistory(
            widget.sessionState.value?.accessToken ?? "",
            historyItem.id ?? 0,
          );
          _loadHistory();
        },
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(25)),
      height: 45,
      width: 45,
      child: AnimatedSwitcher(
        duration: const Duration(seconds: 3),
        child: widget.artworks.isNotEmpty &&
                widget.artworks[_currentIndex]!.isNotEmpty &&
                widget.artworks[_currentIndex] != null
            ? CachedNetworkImage(
                imageBuilder: (context, imageProvider) {
                  return Container(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: imageProvider,
                      ),
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  );
                },
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
