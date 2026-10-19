import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:nuance/services/itunes_service.dart';
import 'package:nuance/utils/constants.dart';

void main() {
  group('Backend & Music Services Health Tests', () {
    test('Live Nuance Backend is 200 OK and accessible', () async {
      final response = await http.get(Uri.parse(baseURL));
      expect(response.statusCode, equals(200));
      expect(response.body, contains('Hello, world!'));
    });

    test('Live Nuance Backend Auth Login redirects correctly', () async {
      final request = http.Request('GET', Uri.parse('$baseURL/auth/login'))..followRedirects = false;
      final client = http.Client();
      final response = await client.send(request);
      
      expect(response.statusCode, equals(302));
      final location = response.headers['location'] ?? '';
      expect(location, contains('spotify'));
      expect(location, contains('redirect_to=https%3A%2F%2Fnuance-backend.vercel.app%2Fauth%2Fcallback'));
    });

    test('iTunes Service fetches recommendations with audio streams (No login, no keys)', () async {
      final itunes = ItunesService();
      final tracks = await itunes.getRecommendations('afrobeats');

      expect(tracks, isNotEmpty);
      expect(tracks.first.title, isNotEmpty);
      expect(tracks.first.artist, isNotEmpty);
      expect(tracks.first.previewUrl, isNotEmpty);
      expect(tracks.first.previewUrl, startsWith('http'));
      expect(tracks.first.artworkUrl, startsWith('http'));
    });
  });
}
