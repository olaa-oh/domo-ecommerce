// import 'package:domo/bindings/auth_bindings.dart';
// import 'package:domo/features/authentication/controllers/auth_controller.dart';
// import 'package:domo/features/onboarding/views/splash_screen.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import '../../features/authentication/views/login_page.dart';
// import '../../features/authentication/views/otp.dart';
// import '../../features/authentication/views/register_page.dart';

// class AppPages {
//   static final routes = [
//     GetPage(
//       name: '/login',
//       page: () => const Login(),
//       binding: AuthBinding(),
//     ),
//     GetPage(
//       name: '/register',
//       page: () => const RegisterPage(),
//       binding: AuthBinding(),
//     ),
//     GetPage(
//       name: '/verify-otp',
//       page: () => OTPVerificationPage(),
//       binding: AuthBinding(),
//     ),
//     GetPage(
//       name: '/home',
//       page: () => SplashScreen(),
//       binding: AuthBinding(),
//       middlewares: [AuthGuard()],
//     ),
//   ];
// }

// class AuthGuard extends GetMiddleware {
//   @override
//   RouteSettings? redirect(String? route) {
//     if (Get.find<AuthController>().isAuthenticated) {
//       return null;
//     }
//     return const RouteSettings(name: '/login');
//   }
// }