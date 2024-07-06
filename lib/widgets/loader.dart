import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nuance/utils/constants.dart';

class SpinningSvg extends StatefulWidget {
  final Widget svgWidget;
  final double size;
  final List<String> textList;
  final Duration animationDuration;
  final Duration fadeDuration;
  final Curve fadeCurve;

  const SpinningSvg({
    Key? key,
    required this.svgWidget,
    this.size = 40.0,
    required this.textList,
    this.animationDuration = const Duration(seconds: 2),
    this.fadeDuration = const Duration(seconds: 3),
    this.fadeCurve = Curves.linear,
  }) : super(key: key);

  @override
  _SpinningSvgState createState() => _SpinningSvgState();
}

class _SpinningSvgState extends State<SpinningSvg>
    with TickerProviderStateMixin {
  late AnimationController _spinController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  int _currentTextIndex = 0;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    )..repeat();

    _fadeController = AnimationController(
      vsync: this,
      duration: widget.fadeDuration,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: widget.fadeCurve,
    );

    _fadeController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(widget.animationDuration - widget.fadeDuration, () {
          _fadeOutText();
        });
      } else if (status == AnimationStatus.dismissed) {
        setState(() {
          _currentTextIndex = (_currentTextIndex + 1) % widget.textList.length;
          _fadeInText();
        });
      }
    });

    _fadeInText();
  }

  @override
  void dispose() {
    _spinController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _fadeInText() {
    _fadeController.forward();
  }

  void _fadeOutText() {
    _fadeController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedBuilder(
          animation: _spinController,
          builder: (context, child) {
            return SpininWidget(
                spinController: _spinController, widget: widget);
          },
        ),
        const SizedBox(height: 20.0),
        FadeTransition(
          opacity: _fadeAnimation,
          child: Text(
            widget.textList[_currentTextIndex],
            style: subtitleTextStyle.copyWith(
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

class SpininWidget extends StatelessWidget {
  const SpininWidget({
    super.key,
    required AnimationController spinController,
    required this.widget,
  }) : _spinController = spinController;

  final AnimationController _spinController;
  final SpinningSvg widget;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: _spinController.value * 2 * 3.141592653589793,
      child: widget.svgWidget,
    );
  }
}
