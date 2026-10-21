// ignore: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:html' as html;

Future<String?> listenForWebAuthSession(Duration timeout) async {
  final completer = Completer<String?>();
  StreamSubscription? storageSub;
  StreamSubscription? messageSub;
  Timer? timer;

  void completeWith(String? val) {
    if (!completer.isCompleted) {
      completer.complete(val);
      storageSub?.cancel();
      messageSub?.cancel();
      timer?.cancel();
    }
  }

  // 1. Check if localStorage already has an incoming session
  final existing = html.window.localStorage['flutter_web_auth_session'];
  if (existing != null && existing.contains('session=')) {
    html.window.localStorage.remove('flutter_web_auth_session');
    return existing;
  }

  // 2. Listen to storage events (across tabs/windows of same origin)
  storageSub = html.window.onStorage.listen((event) {
    if (event.key == 'flutter_web_auth_session' && event.newValue != null) {
      final val = event.newValue!;
      if (val.contains('session=') || val.contains('error=')) {
        html.window.localStorage.remove('flutter_web_auth_session');
        completeWith(val);
      }
    }
  });

  // 3. Listen to window message events
  messageSub = html.window.onMessage.listen((event) {
    try {
      final data = event.data;
      if (data is Map) {
        final authUrl = data['flutter-web-auth'] ?? data['flutter-web-auth-2'];
        if (authUrl is String && (authUrl.contains('session=') || authUrl.contains('error='))) {
          completeWith(authUrl);
        }
      }
    } catch (_) {}
  });

  // 4. Timeout safety guard
  timer = Timer(timeout, () {
    completeWith(null);
  });

  return completer.future;
}

String? getInitialWebSession() {
  try {
    final search = html.window.location.search;
    if (search != null && search.isNotEmpty) {
      final uri = Uri.parse(html.window.location.href);
      final session = uri.queryParameters['session'];
      if (session != null && session.isNotEmpty) {
        // Clear query parameters from address bar to keep clean URL
        html.window.history.replaceState({}, '', html.window.location.pathname);
        return session;
      }
    }
  } catch (_) {}
  return null;
}

void clearWebAuthStorage() {
  try {
    html.window.localStorage.remove('flutter_web_auth_session');
    html.window.localStorage.remove('flutter_web_auth_timestamp');
  } catch (_) {}
}
