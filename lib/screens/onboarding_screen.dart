import 'package:fancy_onboarding_screen/core/model/onboarding_item_model.dart';
import 'package:flutter/material.dart';
import 'package:fancy_onboarding_screen/fancy_onboarding_screen.dart';
import 'dart:math';

import 'package:nuance/utils/constants.dart';

class OnboardingScreen extends StatefulWidget {
  static const routeName = '/onboarding';
  final VoidCallback? onComplete;

  const OnboardingScreen({Key? key, this.onComplete}) : super(key: key);

  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  static const List<String> sampleImages = [
    'https://img.freepik.com/free-photo/lovely-woman-vintage-outfit-expressing-interest-outdoor-shot-glamorous-happy-girl-sunglasses_197531-11312.jpg',
    'https://img.freepik.com/free-photo/shapely-woman-vintage-dress-touching-her-glasses-outdoor-shot-interested-relaxed-girl-brown-outfit_197531-11308.jpg',
    'https://img.freepik.com/premium-photo/cheerful-lady-brown-outfit-looking-around-outdoor-portrait-fashionable-caucasian-model-with-short-wavy-hairstyle_197531-25791.jpg',
  ];

  @override
  void initState() {
    super.initState();
    _animationController =
        AnimationController(vsync: this, duration: const Duration(seconds: 4))
          ..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  List<OnBoardingItemModel> get boardingItemsList => [
        OnBoardingItemModel(
          title: 'Welcome to Nuance',
          subtitle: 'Effortlessly curate your perfect soundtrack',
          image: sampleImages[0],
          titleColor: Colors.white,
          // subtitleColor: Colors.white,
          subtitleTextStyle: subtitleTextStyle,
        ),
        OnBoardingItemModel(
          title: 'Discover music tailored for you',
          subtitle: 'Find tracks that match your mood and taste',
          image: sampleImages[1],
          titleColor: Colors.white,
          // subtitleColor: Colors.white,
          subtitleTextStyle: subtitleTextStyle,
        ),
        OnBoardingItemModel(
          title: 'Create playlists with a tap',
          subtitle: 'Effortlessly curate your perfect soundtrack',
          image: sampleImages[2],
          titleColor: Colors.white,
          // subtitleColor: Colors.white,
          subtitleTextStyle: subtitleTextStyle,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: Colors.black,
      body: Stack(
        children: [
          // _buildFallingIcons(),
          FancyOnBoardingScreen(
            backgroundColor: const Color.fromARGB(255, 0, 0, 0),
            onBoardingItems: boardingItemsList,
            onBtnTap: () => widget.onComplete!(), // Required parameter
            headingText: "Nuance",
            subHeadingText: "Let's get started",
            headingTextStyle: headingTextStyle,
            subHeadingTextStyle: subtitleTextStyle,
            buttonText: "Done",
            boardingScreenColor: Color.fromARGB(255, 20, 20, 20),
            activeIndicatorColor: Colors.grey[900],
          ),
        ],
      ),
    );
  }

  Widget _buildFallingIcons() {
    final random = Random();

    return IgnorePointer(
      child: Stack(
        children: List.generate(
          50,
          (index) {
            final leftPosition =
                random.nextDouble() * MediaQuery.of(context).size.width;
            final iconSize = 30 + random.nextDouble() * 20;
            final rotationAngle = random.nextDouble() * 2 * pi;
            final animationDuration = Duration(seconds: 3 + random.nextInt(4));
            final animation = Tween<double>(
                    begin: -100, end: MediaQuery.of(context).size.height)
                .animate(
              CurvedAnimation(
                parent: _animationController,
                curve: const Interval(
                  0.0,
                  1.0,
                  curve: Curves.linear,
                ),
              ),
            );

            return Positioned(
              left: leftPosition,
              top: -100,
              child: AnimatedBuilder(
                animation: animation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, animation.value),
                    child: Transform.rotate(
                      angle: rotationAngle,
                      child: Icon(
                        Icons.music_note,
                        size: iconSize,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

// void main() {
//   runApp(MaterialApp(
//     home: OnboardingScreen(
//       onComplete: () {
//         // Handle completion
//       },
//     ),
//   ));
// }
