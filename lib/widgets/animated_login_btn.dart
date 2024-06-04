import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

class AnimatedLoginButton extends StatefulWidget {
  final VoidCallback onTap;

  const AnimatedLoginButton({Key? key, required this.onTap}) : super(key: key);

  @override
  _AnimatedLoginButtonState createState() => _AnimatedLoginButtonState();
}

class _AnimatedLoginButtonState extends State<AnimatedLoginButton> {
  late RiveAnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Initialize the controller to play the "Timeline 2" animation
    _controller = OneShotAnimation('Timeline 2', autoplay: false);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Ensure the animation plays when the widget is tapped
        if (_controller.isActive) {
          _controller.isActive = false;
        }
        _controller.isActive = true;
        widget.onTap();
      },
      child: RiveAnimation.asset(
        'assets/rive/spotify.riv',
        controllers: [_controller],
        onInit: (_) => setState(() {}),
        alignment: Alignment.center,
        fit: BoxFit
            .contain, // Adjust the fit to ensure it occupies intended space
      ),
    );
  }
}
