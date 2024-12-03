// onboarding screen
import 'package:domo/features/onboarding/views/onboardingPage.dart';
import 'package:domo/features/onboarding/models/Onboarding_strings.dart';
import 'package:domo/features/onboarding/models/onboarding_model.dart';
import 'package:domo/common/styles/style.dart';
import 'package:domo/features/onboarding/views/get_started_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:liquid_swipe/liquid_swipe.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final controller = LiquidController();

  int currentPage = 0;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final pages = [
      OnBoardingPage(
        model: OnboardingModel(
            title: OnboardingStrings.title1,
            description: OnboardingStrings.description1,
            image: OnboardingStrings.onboard1,
            color: AppTheme.caption,
            textColor: AppTheme.darkBackground,
            onboardingCounter: OnboardingStrings.onboardingCounter,
            height: size.height),
      ),
      OnBoardingPage(
        model: OnboardingModel(
            title: OnboardingStrings.title2,
            description: OnboardingStrings.description2,
            image: OnboardingStrings.onboard2,
            color: AppTheme.darkText,
            textColor: AppTheme.darkBackground,
            onboardingCounter: OnboardingStrings.onboardingCounter2,
            height: size.height),
      ),
      OnBoardingPage(
        model: OnboardingModel(
            title: OnboardingStrings.title3,
            description: OnboardingStrings.description3,
            image: OnboardingStrings.onboard3,
            color: const Color.fromARGB(255, 115, 136, 192),
            textColor: AppTheme.darkBackground,
            onboardingCounter: OnboardingStrings.onboardingCounter3,
            height: size.height),
      ),
      PageView(
        children: [
          Container(
            height: size.height,
            decoration: const BoxDecoration(color: AppTheme.border),
          )
        ],
      ),
    ];

    return Scaffold(
      body: Stack(
        children: [
          LiquidSwipe(
            slideIconWidget: const Icon(Icons.arrow_back_ios),
            enableSideReveal: true,
            pages: pages,
            liquidController: controller,
            onPageChangeCallback: OnPageChangeCallback,
          ),
          // Positioned(
          //   top: 50,
          //   right: 20,
          //   child: TextButton(
          //     onPressed: () {
          //       Navigator.pushReplacement(
          //         context,
          //         MaterialPageRoute(
          //           builder: (context) => const GetStarted(),
          //         ),
          //       );
          //     },
          //     child: const Text(
          //       "Skip",
          //       style: TextStyle(color: AppTheme.darkBackground),
          //     ),
          //   ),
          // ),
          Positioned(
              top: 70,
              left: size.width / 2 - 35,
              child: AnimatedSmoothIndicator(
                  activeIndex: controller.currentPage,
                  count: 3,
                  effect: const WormEffect(
                    dotWidth: 15,
                    dotHeight: 7,
                    activeDotColor: Colors.white,
                    dotColor: Color.fromARGB(255, 70, 79, 97),
                  )))
        ],
      ),
    );
  }

  OnPageChangeCallback(int activePageIndex) {
    setState(() {
      currentPage = activePageIndex;
    });

    if (currentPage == 2) {
      Future.delayed(const Duration(seconds: 2), () {
        Get.toNamed('/get-started');
      }
      );
    }
  }
}
