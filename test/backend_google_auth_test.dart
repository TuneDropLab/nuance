import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:nuance/models/song_model.dart';
import 'package:nuance/services/all_services.dart';
import 'package:nuance/utils/constants.dart';

void main() {
  group('Live Backend Google Auth & History Persistence Integration Tests', () {
    test('Live Backend /auth/google endpoints respond correctly', () async {
      // 1. Check GET /auth/google renders the Google sign-in page
      final response = await http.get(Uri.parse('$baseURL/auth/google'));
      expect(response.statusCode, equals(200));
      expect(response.body, contains('Google'));

      // 2. Check POST /auth/google/complete upserts user and returns valid session
      final testEmail =
          'nuance_flutter_test_${DateTime.now().millisecondsSinceEpoch}@example.com';
      final testProviderId =
          'google_test_${DateTime.now().millisecondsSinceEpoch}';
      final completeResponse = await http.post(
        Uri.parse('$baseURL/auth/google/complete'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': testEmail,
          'name': 'Flutter Test User',
          'avatarUrl': 'https://ui-avatars.com/api/?name=Flutter+Test',
          'providerId': testProviderId,
        }),
      );

      expect(completeResponse.statusCode, equals(200));
      final completeData = jsonDecode(completeResponse.body);
      expect(completeData['session'], isNotNull);
      expect(completeData['session']['provider'], equals('google'));
      expect(completeData['session']['access_token'], isNotEmpty);
      expect(completeData['session']['user']['email'], equals(testEmail));
      expect(completeData['session']['user']['user_metadata']['full_name'],
          equals('Flutter Test User'));

      final token = completeData['session']['access_token'] as String;

      // 3. Check history persistence with authenticated Google token
      final services = AllServices();
      final testSongs = [
        SongModel(
          title: 'Testing Star',
          artist: 'Flutter Band',
          previewUrl: 'https://example.com/audio.mp3',
          artworkUrl: 'https://example.com/art.jpg',
          albumName: 'Nuance Suite',
          durationMs: 180000,
        ),
      ];

      final saved = await services.saveHistory(
        token,
        'relaxing evening study beats',
        'https://example.com/art.jpg',
        testSongs,
      );
      expect(saved, isTrue);

      // 4. Retrieve saved history from backend
      final history = await services.getHistory(token);
      expect(history, isNotEmpty);
      expect(history.first.searchQuery, equals('relaxing evening study beats'));
      expect(history.first.recommendations, isNotEmpty);
      expect(history.first.recommendations!.first.title, equals('Testing Star'));

      // 5. Test Token Refresh
      final refreshResult = await services.refreshToken(
        testProviderId,
        currentToken: token,
      );
      expect(refreshResult, isNotNull);
      expect(refreshResult!['tokens'], isNotNull);
      expect(refreshResult['tokens']['accessToken'], isNotEmpty);

      // 6. Test Case-insensitive login
      final upperResponse = await http.post(
        Uri.parse('$baseURL/auth/google/complete'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': testEmail.toUpperCase(),
          'name': 'Flutter Test Upper',
          'providerId': testProviderId,
        }),
      );
      expect(upperResponse.statusCode, equals(200));
      final upperData = jsonDecode(upperResponse.body);
      expect(upperData['session']['user']['email'], equals(testEmail.toLowerCase()));

      // 7. Test Delete History Entry
      final promptId = history.first.id;
      if (promptId != null) {
        await services.deleteHistory(token, promptId);
        final historyAfterDel = await services.getHistory(token);
        expect(
          historyAfterDel.any((h) => h.id == promptId),
          isFalse,
        );
      }
    });
  });
}
