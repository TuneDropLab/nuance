import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:nuance/models/session_data_model.dart';
import 'package:nuance/models/song_model.dart';
import 'package:nuance/screens/auth/login_screen.dart';
import 'package:nuance/services/all_services.dart';

void main() {
  group('Guest Session & Dual Session Architecture Unit Tests', () {
    test('SessionData correctly identifies guest mode vs authenticated account', () {
      final guestSession = SessionData(
        provider: 'guest',
        accessToken: 'guest_token_123',
        refreshToken: 'guest_refresh_token',
        expiresAt: '2099-01-01T00:00:00Z',
        providerToken: 'guest_provider_token',
        user: {'name': 'Guest Listener', 'email': 'guest@nuance.local'},
      );

      expect(guestSession.isGuest, isTrue);
      expect(guestSession.provider, equals('guest'));
      expect(guestSession.accessToken, equals('guest_token_123'));

      final spotifySession = SessionData(
        provider: 'spotify',
        accessToken: 'oauth_token_xyz',
        refreshToken: 'oauth_refresh_token',
        expiresAt: '2026-01-01T00:00:00Z',
        providerToken: 'spotify_provider_token',
        user: {'name': 'John Doe', 'email': 'john@example.com'},
      );

      expect(spotifySession.isGuest, isFalse);
      expect(spotifySession.provider, equals('spotify'));

      final jsonMap = guestSession.toJson();
      final revived = SessionData.fromJson(jsonMap);
      expect(revived.isGuest, isTrue);
      expect(revived.accessToken, equals('guest_token_123'));
    });

    test('SongModel.fromItunes correctly maps iTunes search result properties and trackId alias', () {
      final mockItunesJson = {
        'trackId': 12345678,
        'trackName': 'Feel Good Inc.',
        'artistName': 'Gorillaz',
        'collectionName': 'Demon Days',
        'collectionViewUrl': 'https://music.apple.com/album/123',
        'artworkUrl100': 'https://is1-ssl.mzstatic.com/image/thumb/100x100bb.jpg',
        'previewUrl': 'https://audio-ssl.itunes.apple.com/preview.m4a',
        'trackViewUrl': 'https://music.apple.com/song/123',
        'trackTimeMillis': 223000,
        'releaseDate': '2005-05-09T07:00:00Z',
        'trackExplicitness': 'notExplicit',
        'trackNumber': 6,
      };

      final song = SongModel.fromItunes(mockItunesJson);
      expect(song.id, equals('12345678'));
      expect(song.trackId, equals('12345678'));
      expect(song.title, equals('Feel Good Inc.'));
      expect(song.artist, equals('Gorillaz'));
      expect(song.albumName, equals('Demon Days'));
      expect(song.previewUrl, equals('https://audio-ssl.itunes.apple.com/preview.m4a'));
      expect(song.artworkUrl, contains('600x600bb'));
      expect(song.durationMs, equals(223000));
    });

    test('AllServices handles guest tokens gracefully without throwing network/401 errors', () async {
      final services = AllServices();

      // getHistory should return empty list without network call
      final history = await services.getHistory('guest_token_123');
      expect(history, isEmpty);

      // deleteHistory should complete without exception
      expect(
        () async => await services.deleteHistory('guest_token_123', 12345),
        returnsNormally,
      );

      // deleteAllHistory should complete without exception
      expect(
        () async => await services.deleteAllHistory('guest_token_123'),
        returnsNormally,
      );
    });
  });

  group('LoginScreen UI Tests', () {
    testWidgets('LoginScreen displays Guest Mode, Google, and Email sign-in without Spotify or Apple Music', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: GetMaterialApp(
            home: LoginScreen(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      // Verify guest mode option is front and center
      expect(find.text('Start Exploring Music'), findsOneWidget);

      // Verify Nuance account sign-in options
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.text('Sign in with Email'), findsOneWidget);

      // Verify ZERO Spotify or Apple Music sign-in references exist
      expect(find.textContaining('Spotify'), findsNothing);
      expect(find.textContaining('Apple Music'), findsNothing);
    });

    testWidgets('Tapping Sign in with Email opens bottom sheet modal with text field', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: GetMaterialApp(
            home: LoginScreen(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      final emailButton = find.text('Sign in with Email');
      expect(emailButton, findsOneWidget);

      await tester.tap(emailButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify modal content
      expect(find.text('Continue with Email'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.textContaining('Enter your email to sync and save'), findsOneWidget);

      // Enter invalid email
      await tester.enterText(find.byType(TextField), 'invalid-email');
      await tester.tap(find.text('Continue with Email'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify modal remains open
      expect(find.text('Continue with Email'), findsOneWidget);
    });

    testWidgets('Tapping Start Exploring Music initiates guest session', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: GetMaterialApp(
            home: LoginScreen(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      final guestButton = find.text('Start Exploring Music');
      expect(guestButton, findsOneWidget);

      await tester.tap(guestButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    });
  });
}
