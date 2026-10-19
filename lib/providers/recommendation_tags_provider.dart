import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuance/services/all_services.dart';

final recommendationTagsProvider = FutureProvider<List<String>>((ref) async {
  try {
    final discover = await AllServices().getGeminiDiscover();
    final tags = (discover['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
    if (tags.isNotEmpty) {
      return tags;
    }
  } catch (e) {
    debugPrint("Failed to load Gemini recommendation tags: $e");
  }
  return <String>[];
});
