import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:nuance/utils/constants.dart';

class CustomSnackbar {
  static final CustomSnackbar _instance = CustomSnackbar._internal();
  GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  factory CustomSnackbar() {
    return _instance;
  }

  CustomSnackbar._internal();

  void setNavigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
  }

  void show(
    String message, {
    Widget icon = const SizedBox.shrink(),
    TextStyle? textStyle,
    Duration enterDuration = const Duration(milliseconds: 500),
    Duration exitDuration = const Duration(milliseconds: 30),
    Curve enterCurve = Curves.easeOut,
    Curve exitCurve = Curves.easeInBack,
  }) {
    final overlayState = _navigatorKey.currentState?.overlay;
    OverlayEntry? overlayEntry;

    if (overlayState != null) {
      overlayEntry = OverlayEntry(
        builder: (context) => Positioned(
          bottom: 41.0,
          left: 0,
          right: 0,
          child: Material(
            color: Colors.transparent,
            child: Dismissible(
              key: UniqueKey(),
              direction: DismissDirection.down,
              onDismissed: (direction) {
                overlayEntry?.remove();
              },
              child: Animate(
                effects: [
                  SlideEffect(
                    duration: enterDuration,
                    begin: const Offset(0, 3),
                    end: const Offset(0, 0),
                    curve: enterCurve,
                  ),
                ],
                onComplete: (controller) async {
                  await Future.delayed(const Duration(seconds: 4));
                  controller.reverse();
                  controller.addStatusListener((status) {
                    if (status == AnimationStatus.dismissed) {
                      overlayEntry?.remove();
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20.0, vertical: 20.0),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade900,
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                  child: Row(
                    children: [
                      icon,
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          message,
                          style: textStyle ??
                              subtitleTextStyle.copyWith(
                                color: Colors.white,
                              ),
                        ),
                      ),
                    ],
                  ),
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
