import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:nuance/providers/history_provider.dart';
import 'package:nuance/theme.dart';

class MyCustomDrawer extends ConsumerStatefulWidget {
  const MyCustomDrawer({
    super.key,
  });

  @override
  _MyCustomDrawerState createState() => _MyCustomDrawerState();
}

class _MyCustomDrawerState extends ConsumerState<MyCustomDrawer> {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppTheme.primaryColor,
      child: Container(
        width: Get.width * 0.8,
        color: AppTheme.primaryColor,
        child: Consumer(
          builder: (context, watch, child) {
            final historyAsyncValue = ref.watch(historyProvider);

            return historyAsyncValue.when(
              data: (history) {
                return ListView.separated(
                  separatorBuilder: (context, index) {
                    return const Divider(
                      color: AppTheme.primaryColor,
                    );
                  },
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    final historyItem = history[index];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            historyItem.searchQuery ?? '',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        SizedBox(
                          height:
                              120, // Set a fixed height for the inner ListView
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: historyItem.recommendations?.length,
                            itemBuilder: (context, recIndex) {
                              final song =
                                  historyItem.recommendations![recIndex];
                              return SizedBox(
                                width: 200, // Set a fixed width for each item
                                child: ListTile(
                                  leading: song.artworkUrl != null
                                      ? Image.network(song.artworkUrl!)
                                      : const Icon(
                                          Icons.music_note,
                                          color: AppTheme.primaryColor,
                                        ),
                                  title: Text(
                                    song.title ?? '',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  subtitle: Text(
                                    song.artist ?? '',
                                    style:
                                        const TextStyle(color: Colors.white70),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stackTrace) => Center(
                child: Text('Error: $error',
                    style: const TextStyle(color: Colors.red)),
              ),
            );
          },
        ),
      ),
    );
  }
}
