import 'package:flutter/material.dart';
import 'package:fan_carousel_image_slider/fan_carousel_image_slider.dart';
import 'package:flutter_animate/flutter_animate.dart';

class OnboardingScreen extends StatefulWidget {
  static const routeName = '/onboarding';
  final VoidCallback? onComplete;

  const OnboardingScreen({Key? key, this.onComplete}) : super(key: key);

  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentPage = 0;
  final PageController _pageController = PageController();

  static const List<String> sampleImages = [
    'https://img.freepik.com/free-photo/lovely-woman-vintage-outfit-expressing-interest-outdoor-shot-glamorous-happy-girl-sunglasses_197531-11312.jpg',
    'https://img.freepik.com/free-photo/shapely-woman-vintage-dress-touching-her-glasses-outdoor-shot-interested-relaxed-girl-brown-outfit_197531-11308.jpg',
    'https://img.freepik.com/premium-photo/cheerful-lady-brown-outfit-looking-around-outdoor-portrait-fashionable-caucasian-model-with-short-wavy-hairstyle_197531-25791.jpg',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            children: [
              _buildPage(0),
              _buildPage(1),
              _buildPage(2),
            ],
          ),
          if (_currentPage == 1) _buildFallingIcons(),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: widget.onComplete,
                  child: const Text('Skip'),
                ),
                TextButton(
                  onPressed: () {
                    if (_currentPage < 2) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      widget.onComplete?.call();
                    }
                  },
                  child: Text(_currentPage < 2 ? 'Next' : 'Get Started'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(int index) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          height: 420,
          child: FanCarouselImageSlider.sliderType1(
            imagesLink: sampleImages,
            isAssets: false,
            autoPlay: false,
            sliderHeight: 400,
            sliderWidth: MediaQuery.of(context).size.width,
            showIndicator: false,
            initalPageIndex: 0,
            turns: 200,
            sidesOpacity: 0.8,
            imageFitMode: BoxFit.cover,
            slideViewportFraction: 0.8,
            userCanDrag: false,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Onboarding Screen ${index + 1}',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            'This is some sample text for onboarding screen ${index + 1}. Replace with your actual content.',
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildFallingIcons() {
    return IgnorePointer(
      child: Stack(
        children: List.generate(
          20,
          (index) => Positioned(
            left: (index * 20.0) % MediaQuery.of(context).size.width,
            child: Icon(
              Icons.music_note,
              size: 24,
              color: Colors.blue.withOpacity(0.5),
            )
                .animate(
                  onPlay: (controller) => controller.repeat(),
                )
                .moveY(
                  begin: -100,
                  end: MediaQuery.of(context).size.height,
                  curve: Curves.easeInOut,
                  duration: Duration(seconds: 3 + index % 4),
                )
                .fadeIn(duration: const Duration(milliseconds: 500))
                .fadeOut(delay: const Duration(seconds: 2)),
          ),
        ),
      ),
    );
  }
}
