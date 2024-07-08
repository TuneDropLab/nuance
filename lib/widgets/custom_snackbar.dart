import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class CustomSnackbar {
  static final CustomSnackbar _instance = CustomSnackbar._internal();
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  factory CustomSnackbar() {
    return _instance;
  }

  CustomSnackbar._internal();

  void setNavigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey.currentState?.overlay?.dispose();
    _navigatorKey.currentState?.overlay?.insert(
      OverlayEntry(builder: (_) => Container()),
    );
  }

  void show(String message, {TextStyle? textStyle}) {
    final overlayState = _navigatorKey.currentState?.overlay;
    OverlayEntry? overlayEntry; // Declare overlayEntry here

    if (overlayState != null) {
      overlayEntry = OverlayEntry(
        builder: (context) => Positioned(
          bottom: 50.0,
          left: 15.0,
          right: 15.0,
          child: Material(
            color: Colors.transparent,
            child: Animate(
              effects: [
                SlideEffect(
                  duration: 300.ms,
                  begin: const Offset(0, 1),
                  end: const Offset(0, 0),
                ),
                FadeEffect(
                  duration: 300.ms,
                  begin: 0,
                  end: 1,
                )
              ],
              onComplete: (controller) async {
                await Future.delayed(const Duration(seconds: 3));
                controller.reverse();
                await Future.delayed(const Duration(milliseconds: 300));
                overlayEntry?.remove();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24.0, vertical: 12.0),
                decoration: BoxDecoration(
                  color: Colors.grey.shade900,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  message,
                  style: textStyle ??
                      const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ),
        ),
      );

      overlayState.insert(overlayEntry);
    }
  }

  GlobalKey<NavigatorState> get navigatorKey => _navigatorKey;
}
