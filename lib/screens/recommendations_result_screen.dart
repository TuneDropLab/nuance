import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuance/providers/recommendation_provider.dart';

class RecommendationsResultScreen extends ConsumerWidget {
  static const routeName = '/recommendations-result';

  const RecommendationsResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              log("Log screen result: $recommendations");
              return ListTile(
                title: Text(recommendation.title),
                subtitle: Text(recommendation.artist),
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
}
