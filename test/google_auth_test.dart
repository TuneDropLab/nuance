import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:nuance/models/history_model.dart';
import 'package:nuance/models/session_data_model.dart';
import 'package:nuance/screens/auth/login_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Google Sign-In Model Tests', () {
    test('SessionData correctly models Google authenticated session', () {
      final googleSession = SessionData(
        provider: 'google',
        accessToken: 'jwt_google_test_access_token',
        refreshToken: 'google_refresh_token_123',
        expiresAt: '2026-11-19T00:00:00.000Z',
        providerToken: 'google_provider_token_xyz',
        user: {
          'id': 'google_user_001',
          'email': 'alex@example.com',
          'name': 'Alex Rivera',
          'app_metadata': {'provider': 'google', 'is_guest': false},
          'user_metadata': {
            'provider_id': '10987654321',
            'full_name': 'Alex Rivera',
            'avatar_url': 'https://lh3.googleusercontent.com/a/test_avatar',
            'sub': '10987654321',
          },
        },
      );

      expect(googleSession.isGuest, isFalse);
      expect(googleSession.provider, equals('google'));
      expect(googleSession.accessToken, equals('jwt_google_test_access_token'));
      expect(googleSession.user['email'], equals('alex@example.com'));
      expect(googleSession.user['user_metadata']['full_name'], equals('Alex Rivera'));
      expect(googleSession.user['user_metadata']['avatar_url'], contains('test_avatar'));

      // Test JSON round-trip
      final jsonMap = googleSession.toJson();
      final restored = SessionData.fromJson(jsonMap);

      expect(restored.isGuest, isFalse);
      expect(restored.provider, equals('google'));
      expect(restored.accessToken, equals('jwt_google_test_access_token'));
      expect(restored.user['name'], equals('Alex Rivera'));
      expect(restored.user['user_metadata']['provider_id'], equals('10987654321'));
      // Test isExpired getter
      final expiredSession = googleSession.copyWith(
        expiresAt: (DateTime.now().millisecondsSinceEpoch - 10000).toString(),
      );
      expect(expiredSession.isExpired, isTrue);

      final validSession = googleSession.copyWith(
        expiresAt: (DateTime.now().millisecondsSinceEpoch + 10000000).toString(),
      );
      expect(validSession.isExpired, isFalse);
    });

    test('HistoryModel parses null and malformed fields gracefully', () {
      final safeModel = HistoryModel.fromJson({
        'id': '42',
        'searchQuery': 'Study Lo-Fi',
        'recommendations': null,
        'image': null,
        'createdAt': null,
      });

      expect(safeModel.id, equals(42));
      expect(safeModel.searchQuery, equals('Study Lo-Fi'));
      expect(safeModel.recommendations, isEmpty);
      expect(safeModel.imageUrl, isNull);
      expect(safeModel.createdAt, isNotNull);
    });
  });

  group('Google Sign-In UI & Cancellation Tests', () {
    testWidgets('LoginScreen displays Continue with Google button', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: GetMaterialApp(
            home: LoginScreen(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      final googleButton = find.text('Continue with Google');
      expect(googleButton, findsOneWidget);
    });

    testWidgets('Tapping Continue with Google handles web auth cancellation gracefully (CANCELED)', (WidgetTester tester) async {
      // Mock flutter_web_auth method channel to simulate user cancellation
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('flutter_web_auth'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'authenticate') {
            throw PlatformException(
              code: 'CANCELED',
              message: 'User canceled login sheet',
            );
          }
          return null;
        },
      );

      await tester.pumpWidget(
        const ProviderScope(
          child: GetMaterialApp(
            home: LoginScreen(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      final googleButton = find.text('Continue with Google');
      expect(googleButton, findsOneWidget);

      // Tap Google Sign-in button
      await tester.tap(googleButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify the screen remains interactive and did not crash
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.text('Start Exploring Music'), findsOneWidget);

      // Clean up mock handler
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('flutter_web_auth'), null);
    });

    testWidgets('Tapping Continue with Google handles web auth cancellation gracefully (CANCELLED with double L)', (WidgetTester tester) async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('flutter_web_auth'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'authenticate') {
            throw PlatformException(
              code: 'CANCELLED',
              message: 'Authentication was cancelled',
            );
          }
          return null;
        },
      );

      await tester.pumpWidget(
        const ProviderScope(
          child: GetMaterialApp(
            home: LoginScreen(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      final googleButton = find.text('Continue with Google');
      expect(googleButton, findsOneWidget);

      await tester.tap(googleButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Continue with Google'), findsOneWidget);

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('flutter_web_auth'), null);
    });
  });
}
