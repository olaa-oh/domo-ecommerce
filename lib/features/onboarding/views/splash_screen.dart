import 'package:domo/common/navigation/app_router.dart';
import 'package:domo/data/repos/auth_repository.dart';
import 'package:domo/common/styles/style.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  
  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    _handleNavigation();
  }

  void _handleNavigation() async {
    // Wait for splash screen duration
    await Future.delayed(const Duration(seconds: 3));
    
    if (mounted) {
      if (Get.find<AppRouter>().isFirstTime) {
        Get.offAllNamed('/onboarding');
      } else {
        // Check authentication and redirect
        final auth = AuthenticationRepository.instance;
        // auth.redirect();
      }
    }
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: SystemUiOverlay.values);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Center(
            child: Image(
              image: AssetImage(
                "assets/images/flashscreen.png",
              ),
              fit: BoxFit.cover,
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Text(
              "Do More",
              style: AppTheme.textTheme.headlineSmall,
            ),
          ),
        ],
      ),
    );
  }
}