import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuance/providers/auth_provider.dart';
import 'package:nuance/screens/auth/login_screen.dart';
import 'package:nuance/screens/home_screen.dart';

class InitialScreen extends ConsumerStatefulWidget {
  static const routeName = '/initial';

  const InitialScreen({super.key});

  @override
  _InitialScreenState createState() => _InitialScreenState();
}

class _InitialScreenState extends ConsumerState<InitialScreen> {
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final authService = ref.read(authServiceProvider);
    final sessionMap = await authService.getSessionData();

    // Only registered, authenticated account sessions auto-restore to HomeScreen
    final bool hasAuthenticatedSession = sessionMap != null &&
        sessionMap['access_token'] != null &&
        !(sessionMap['access_token'] as String).startsWith('guest_') &&
        sessionMap['user']?['id'] != 'guest_tester' &&
        sessionMap['provider'] != 'guest';

    final Widget targetScreen = hasAuthenticatedSession
        ? const HomeScreen()
        : const LoginScreen();

    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() {
        _isCompleted = true;
      });

      Future.delayed(const Duration(milliseconds: 400), () {
        if (!mounted) return;
        Navigator.of(context)
            .pushReplacement(_createFadeRoute(targetScreen));
      });
    });
  }

  Route _createFadeRoute(Widget screen) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => screen,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
          child: _isCompleted
              ? Container()
              : Image.asset(
                  'assets/whitelogo.png',
                  width: 90,
                  height: 90,
                )
                  .animate()
                  .slideY(
                    duration: 1.seconds,
                    curve: Curves.easeInOutCubic,
                    begin: 0,
                    end: -9.3,
                  )
                  .scaleX(
                    begin: 1.0,
                    end: 0.4,
                  )
                  .scaleY(
                    begin: 1.0,
                    end: 0.4,
                  )
                  .fadeOut(
                    duration: 2000.ms,
                    curve: Curves.easeOut,
                  )),
    );
  }
}
