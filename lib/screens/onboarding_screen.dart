import 'package:fancy_onboarding_screen/core/model/onboarding_item_model.dart';
import 'package:flutter/material.dart';
import 'package:fancy_onboarding_screen/fancy_onboarding_screen.dart';
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
    'https://i.ibb.co/dkcNCg9/Nuances-i-Phone-13-14-1-2.png',
    'https://i.ibb.co/f0k1mTC/Nuances-i-Phone-13-14-1-1.png',
    'https://i.ibb.co/SPGKsMQ/Nuances.png',
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
          subtitleTextStyle: subtitleTextStyle,
        ),
        OnBoardingItemModel(
          title: 'Discover music tailored for you',
          subtitle: 'Find tracks that match your mood and taste',
          image: sampleImages[1],
          titleColor: Colors.white,
          subtitleTextStyle: subtitleTextStyle,
        ),
        OnBoardingItemModel(
          title: 'Create playlists with a tap',
          subtitle: 'Effortlessly curate your perfect soundtrack',
          image: sampleImages[2],
          titleColor: Colors.white,
          subtitleTextStyle: subtitleTextStyle,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FancyOnBoardingScreen(
            backgroundColor: const Color.fromARGB(255, 0, 0, 0),
            onBoardingItems: boardingItemsList,
            onBtnTap: () => widget.onComplete!(),
            headingText: "Nuance",
            subHeadingText: "Let's get started",
            headingTextStyle: headingTextStyle,
            subHeadingTextStyle: subtitleTextStyle,
            buttonText: "Done",
            boardingScreenColor: const Color.fromARGB(255, 20, 20, 20),
            activeIndicatorColor: Colors.grey[700],
          ),
        ],
      ),
    );
  }
}
