import 'package:domo/common/widgets/nav/artisan_navigation.dart';
import 'package:domo/common/widgets/nav/customer_navigation.dart';
import 'package:domo/data/repos/shop_repository.dart';
import 'package:domo/features/bookings/views/appointments.dart';
import 'package:domo/features/authentication/views/login_page.dart';
import 'package:domo/features/authentication/views/otp.dart';
import 'package:domo/features/authentication/views/register_page.dart';
import 'package:domo/features/bookings/views/booking_per_service.dart';
import 'package:domo/features/bookings/views/bookings.dart';
import 'package:domo/features/services/views/artisan_dashboard.dart';
import 'package:domo/features/personalisation/views/artisan_homepage.dart';
import 'package:domo/features/home/views/customer_homepage.dart';
import 'package:domo/features/inbox/views/inbox_page.dart';
import 'package:domo/features/onboarding/views/get_started_page.dart';
import 'package:domo/features/onboarding/views/onboarding_screen.dart';
import 'package:domo/features/onboarding/views/splash_screen.dart';
import 'package:domo/features/personalisation/views/you_page.dart';
import 'package:domo/features/services/views/artisan_service_details.dart';
import 'package:domo/features/services/views/service_details_page.dart';
import 'package:domo/features/services/models/service_model.dart';
import 'package:domo/features/shop/controller/shop_details_controller.dart';
import 'package:domo/features/shop/model/shop_model.dart';
import 'package:domo/features/shop/views/shop_details.dart';
import 'package:domo/features/shop/views/shop_onboarding.dart';
import 'package:domo/features/shop/views/themes_view.dart';
import 'package:domo/features/favorites/views/favorite.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AppRouter extends GetxController {
  static const String FIRST_TIME_KEY = 'is_first_time';
  final _storage = GetStorage();
  late final FirebaseAuth _auth;
  late final FirebaseFirestore _firestore;

  // Observable values
  final Rx<bool> isLoading = true.obs;
  final Rx<User?> user = Rx<User?>(null);
  final Rx<String?> userRole = Rx<String?>(null);
  final Rx<String?> userId = Rx<String?>(null);

  @override
  Future<void> onInit() async {
    super.onInit();
    try {
      // Initialize Firebase first
      await Firebase.initializeApp();

      // Only initialize Firebase services after Firebase is initialized
      _auth = FirebaseAuth.instance;
      _firestore = FirebaseFirestore.instance;

      // Set up auth state listener
      ever(user, _handleAuthStateChange);
      user.bindStream(_auth.authStateChanges());
      ever(user, (currentUser) {
        userId.value = currentUser?.uid; // Automatically update userId
      });

      isLoading.value = false;
    } catch (e) {
      print('Error initializing Firebase: $e');
      isLoading.value = false;
      // Handle initialization error (maybe show an error screen)
      Get.offAllNamed('/error');
    }
  }

  // Check if it's first time launching the app
  bool get isFirstTime => _storage.read(FIRST_TIME_KEY) ?? true;

  // Mark first time as complete
  Future<void> markFirstTimeDone() async {
    await _storage.write(FIRST_TIME_KEY, false);
  }

  // Fetch user role from Firestore
  Future<void> _fetchUserRole(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        userRole.value = doc.data()?['role'];
      }
    } catch (e) {
      print('Error fetching user role: $e');
      userRole.value = null;
    }
  }

  // Future<void> _handleAuthStateChange(User? currentUser) async {
  //   try {
  //     isLoading.value = true;

  //     if (currentUser == null) {
  //       // Existing logic for unauthenticated users
  //     } else {
  //       // User is authenticated - fetch role and route accordingly
  //       await _fetchUserRole(currentUser.uid);

  //       if (userRole.value == 'artisan') {
  //         // Check if shop exists before routing
  //         final shopRepository = ShopRepository();
  //         final existingShop =
  //             await shopRepository.getShopByArtisanId(currentUser.uid);

  //         print('Artisan User ID: ${currentUser.uid}');
  //         print('Existing Shop: $existingShop');
  //         print('Existing Shop ID: ${existingShop?.id}');

  //         if (existingShop == null || existingShop.id.isEmpty) {
  //           // Redirect to shop onboarding if no shop exists or shop ID is empty
  //           Get.offAllNamed('/shop-onboarding');
  //         } else {
  //           Get.offAllNamed('/artisan/navBar');
  //         }
  //       } else {
  //         // Default to customer view
  //         Get.offAllNamed('/customer/navBar');
  //       }
  //     }
  //   } finally {
  //     isLoading.value = false;
  //   }
  // }


  Future<void> _handleAuthStateChange(User? currentUser) async {
    try {
      isLoading.value = true;

      if (currentUser == null) {
        // User is not authenticated - go to login
        Get.offAllNamed('/login');
      } else {
        // User is authenticated - fetch role and route accordingly
        await _fetchUserRole(currentUser.uid);

        if (userRole.value == 'artisan') {
          // Check if shop exists before routing
          final shopRepository = ShopRepository();
          final existingShop =
              await shopRepository.getShopByArtisanId(currentUser.uid);

          print('Artisan User ID: ${currentUser.uid}');
          print('Existing Shop: $existingShop');
          print('Existing Shop ID: ${existingShop?.id}');

          if (existingShop == null || existingShop.id.isEmpty) {
            // Redirect to shop onboarding if no shop exists or shop ID is empty
            Get.offAllNamed('/shop-onboarding');
          } else {
            Get.offAllNamed('/artisan/navBar');
          }
        } else {
          // Default to customer view
          Get.offAllNamed('/customer/navBar');
        }
      }
    } finally {
      isLoading.value = false;
    }
  }

  // Define app routes
  static final routes = [
    // Splash and onboarding
    GetPage(name: '/splash', page: () => const SplashScreen()),
    GetPage(name: '/onboarding', page: () => const OnboardingScreen()),
    GetPage(name: '/get-started', page: () => const GetStarted()),

    // Authentication
    GetPage(name: '/login', page: () => const Login()),
    GetPage(name: '/register', page: () => const RegisterPage()),
    GetPage(name: '/verify-otp', page: () => OTPVerificationPage()),

    // comomon routes
    GetPage(name: '/you', page: () => const UserProfilePage()),
    GetPage(name: '/inbox', page: () => const InboxBox()),

    // Artisan routes
    GetPage(
        name: '/artisan/dashboard',
        page: () {
          final String shopId = Get.arguments as String;
          return ArtisanDashboard(shopId: shopId);
        }),
    GetPage(name: '/artisan/navBar', page: () => const ArtisanMainScreen()),
    GetPage(name: '/artisan/home', page: () => const ArtisanHomepage()),
    GetPage(
      name: '/appointments',
      page: () {
        final String shopId = Get.arguments['shopId'] as String;
        final String shopName = Get.arguments['shopName'] as String;
        return AppointmentPage(shopId: shopId, shopName: shopName);
      },
    ),
    GetPage(
      name: '/shop-onboarding',
      page: () => const ShopOnboardingScreen(),
      // Optional: Add middleware to ensure only artisans can access
      middlewares: [ArtisanOnlyMiddleware()],
    ),
    GetPage(
      name: '/artisan-services',
      page: () {
        final ServicesModel service = Get.arguments as ServicesModel;
        return ArtisanServiceDetails(service: service);
      },
    ),
    GetPage(
      name: '/artisan/bookings',
      page: () {
        final String serviceId = Get.arguments['serviceId'] as String;
        final String serviceName = Get.arguments['serviceName'] as String;
        return BookingPerService(
            serviceId: serviceId, serviceName: serviceName);
      },
    ),

    // Customer routes
    GetPage(name: '/customer/home', page: () => const CustomerHomepage()),
    GetPage(name: '/customer/navBar', page: () => const CustomerMainScreen()),

    GetPage(name: '/customer/wishlist', page: () => const Wishlist()),
    GetPage(name: '/themes', page: () => const ThemesPage()),
    GetPage(
      name: '/service-details',
      page: () {
        final ServicesModel service = Get.arguments as ServicesModel;
        return ServiceDetailsPage(service: service);
      },
    ),
    // bookings page
    GetPage(name: '/bookings', page: () => const BookingsPage()),
    GetPage(
      name: '/customer/shop-details',
      page: () {
        final arguments = Get.arguments;
        if (arguments is Map && arguments['shopId'] != null) {
          return FutureBuilder<ShopModel?>(
            future: Get.find<ShopDetailsController>().fetchShopDetailsById(arguments['shopId']),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                if (snapshot.hasData) {
                  return ShopDetailsPage(shopDetails: snapshot.data!);
                }
                return const Scaffold(body: Center(child: Text('Shop not found')));
              }
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            },
          );
        }
        return const Scaffold(body: Center(child: Text('Invalid shop data')));
      },
    ),
  ];
}

// Wrapper widget to handle loading state and initial routing
class AppRouterWrapper extends StatelessWidget {
  final Widget child;

  const AppRouterWrapper({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final router = Get.put(AppRouter());

    return Obx(() {
      if (router.isLoading.value) {
        return const MaterialApp(
          home: Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          ),
        );
      }
      return child;
    });
  }
}

class ArtisanOnlyMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final AppRouter router = Get.find();

    // If user is not an artisan, redirect to appropriate screen
    if (router.userRole.value != 'artisan') {
      return const RouteSettings(name: '/customer/home');
    }
    return null;
  }
}
