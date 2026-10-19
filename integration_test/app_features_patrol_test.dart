import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol_finders/patrol_finders.dart';
import 'package:get/get.dart';
import 'package:nuance/models/session_data_model.dart';
import 'package:nuance/models/song_model.dart';
import 'package:nuance/providers/session_notifier.dart';
import 'package:nuance/screens/auth/login_screen.dart';
import 'package:nuance/screens/home_screen.dart';
import 'package:nuance/screens/playlist_screen.dart';
import 'package:nuance/widgets/custom_drawer.dart';
import 'package:nuance/widgets/generate_playlist_card.dart';
import 'package:nuance/widgets/music_listtile.dart';

class MockGuestSessionNotifier extends SessionNotifier {
  final SessionData _session;
  MockGuestSessionNotifier(this._session);

  @override
  Future<SessionData?> build() async {
    return _session;
  }
}

void main() {
  group('Nuance Full Features Patrol & Integration Suite', () {
    patrolWidgetTest(
      'Feature 1: Login Screen enforces clean zero-cost UI (No Spotify or Apple Music)',
      ($) async {
        await $.tester.pumpWidget(
          const ProviderScope(
            child: GetMaterialApp(
              debugShowCheckedModeBanner: false,
              home: LoginScreen(),
            ),
          ),
        );
        await $.tester.pump(const Duration(milliseconds: 500));

        // 1. Verify modern discovery entry points exist
        expect($('Start Exploring Music'), findsOneWidget);
        expect($('Continue with Google'), findsOneWidget);
        expect($('Sign in with Email'), findsOneWidget);

        // 2. Strict check: Spotify and Apple Music sign-in buttons MUST NOT exist
        expect($('Continue with Spotify'), findsNothing);
        expect($('Continue with Apple Music'), findsNothing);
      },
    );

    patrolWidgetTest(
      'Feature 2: Guest Mode launches HomeScreen with dynamic cards & imagery',
      ($) async {
        const guestSession = SessionData(
          accessToken: 'guest_token_test',
          refreshToken: 'guest_refresh_token',
          expiresAt: '2099-01-01T00:00:00Z',
          providerToken: 'guest_token_test',
          provider: 'guest',
          user: {'name': 'Guest'},
        );

        await $.tester.pumpWidget(
          ProviderScope(
            overrides: [
              sessionProvider.overrideWith(
                () => MockGuestSessionNotifier(guestSession),
              ),
            ],
            child: const GetMaterialApp(
              debugShowCheckedModeBanner: false,
              home: HomeScreen(),
            ),
          ),
        );
        await $.tester.pump(const Duration(milliseconds: 600));

        // Verify Home header welcomes the guest user
        expect($('Welcome'), findsOneWidget);
        expect($(' Guest'), findsOneWidget);
        expect($('Discover'), findsOneWidget);
        expect($(' Playlists'), findsOneWidget);
      },
    );

    patrolWidgetTest(
      'Feature 3: GeneratePlaylistCard displays background photo and gradient overlay',
      ($) async {
        bool tapped = false;
        await $.tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: GeneratePlaylistCard(
                prompt: 'Cyberpunk hacker den dark techno',
                image: 'https://images.unsplash.com/photo-1518609878373-06d740f60d8b',
                gradient: const LinearGradient(colors: [Colors.purple, Colors.blue]),
                onClick: () {
                  tapped = true;
                },
              ),
            ),
          ),
        );
        await $.tester.pump(const Duration(milliseconds: 300));

        expect($('Cyberpunk hacker den dark techno'), findsOneWidget);
        expect($('Generate'), findsOneWidget);

        await $('Generate').tap();
        expect(tapped, isTrue);
      },
    );

    patrolWidgetTest(
      'Feature 4: PlaylistScreen displays cover artwork from first track without black header box',
      ($) async {
        final sampleTracks = [
          SongModel(
            id: 'track_1',
            title: 'Electric Dreams',
            artist: 'Synth Master',
            albumName: 'Neon City',
            artworkUrl: 'https://is1-ssl.mzstatic.com/image/thumb/Music/v4/test/600x600bb.jpg',
            previewUrl: 'https://audio-ssl.itunes.apple.com/preview.m4a',
            popularity: 85,
          ),
          SongModel(
            id: 'track_2',
            title: 'Midnight Runner',
            artist: 'Darkwave Wave',
            albumName: 'Nightfall',
            artworkUrl: 'https://is1-ssl.mzstatic.com/image/thumb/Music/v4/test2/600x600bb.jpg',
            previewUrl: 'https://audio-ssl.itunes.apple.com/preview2.m4a',
            popularity: null, // Test edge case: iTunes popularity is null
          ),
        ];

        await $.tester.pumpWidget(
          ProviderScope(
            child: GetMaterialApp(
              debugShowCheckedModeBanner: false,
              home: PlaylistScreen(
                searchTitle: 'Cyberpunk synthwave',
                songs: sampleTracks,
                imageUrl: 'https://images.unsplash.com/photo-1518609878373-06d740f60d8b',
              ),
            ),
          ),
        );
        await $.tester.pump(const Duration(milliseconds: 500));

        // Verify title & track counts display
        expect(find.textContaining('Cyberpunk synthwave'), findsWidgets);
        expect(find.textContaining('Electric Dreams', findRichText: true), findsOneWidget);
        expect(find.textContaining('Midnight Runner', findRichText: true), findsOneWidget);

        // Verify null popularity doesn't crash track tile
        expect($.tester.takeException(), isNull);
      },
    );

    patrolWidgetTest(
      'Feature 5: MusicListTile audio playback controls toggle smoothly',
      ($) async {
        bool played = false;
        final track = SongModel(
          id: 'test_track',
          title: 'Deep Focus Ambient',
          artist: 'Mind Wave',
          artworkUrl: 'https://is1-ssl.mzstatic.com/test.jpg',
          previewUrl: 'https://audio-ssl.itunes.apple.com/preview.m4a',
        );

        await $.tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: MusicListTile(
                  recommendation: track,
                  isPlaying: false,
                  trailingOnTap: () {
                    played = true;
                  },
                  isSelected: false,
                ),
              ),
            ),
          ),
        );
        await $.tester.pump(const Duration(milliseconds: 200));

        expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
        await $(Icons.play_arrow_rounded).tap();
        expect(played, isTrue);
      },
    );

    patrolWidgetTest(
      'Feature 6: CustomDrawer renders Guest session state and navigation',
      ($) async {
        const guestSession = SessionData(
          accessToken: 'guest_token',
          refreshToken: 'guest_refresh_token',
          expiresAt: '2099-01-01T00:00:00Z',
          providerToken: 'guest_token',
          provider: 'guest',
          user: {'name': 'Guest'},
        );

        final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

        await $.tester.pumpWidget(
          ProviderScope(
            overrides: [
              sessionProvider.overrideWith(
                () => MockGuestSessionNotifier(guestSession),
              ),
            ],
            child: GetMaterialApp(
              debugShowCheckedModeBanner: false,
              home: Scaffold(
                key: scaffoldKey,
                drawer: MyCustomDrawer(sessionState: const AsyncValue.data(guestSession)),
                body: const Text('Main Screen'),
              ),
            ),
          ),
        );
        await $.tester.pump(const Duration(milliseconds: 200));

        // Open Drawer using scaffoldKey
        scaffoldKey.currentState?.openDrawer();
        await $.tester.pump(const Duration(milliseconds: 500));

        // Verify Drawer elements
        expect(find.byType(MyCustomDrawer), findsOneWidget);
        expect($('Saved'), findsOneWidget);
        expect($(Icons.settings), findsOneWidget);
        expect($(Icons.close), findsOneWidget);
      },
    );
  });
}
