import 'package:domo/common/widgets/nav/artisan_navigation.dart';
import 'package:domo/common/widgets/nav/customer_navigation.dart';
import 'package:domo/features/bookings/controller/booking_controller.dart';
import 'package:domo/features/home/views/search_drawer.dart';
import 'package:domo/data/repos/shop_repository.dart';
import 'package:domo/features/bookings/views/appointments.dart';
import 'package:domo/features/authentication/views/login_page.dart';
import 'package:domo/features/authentication/views/register_page.dart';
import 'package:domo/features/bookings/views/booking_per_service.dart';
import 'package:domo/features/bookings/views/bookings.dart';
import 'package:domo/features/services/controllers/service_controller.dart';
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
import 'package:domo/features/favorites/views/service_history.dart';
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
  
  // Flag to prevent multiple navigation attempts
  final RxBool isNavigating = false.obs;

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
      
      // Make sure this stream is correctly updating the user observable
      user.bindStream(_auth.authStateChanges());
      
      // Update userId when user changes
      ever(user, (currentUser) {
        userId.value = currentUser?.uid; 
        print('User updated: ${currentUser?.uid}');
      });

      isLoading.value = false;
    } catch (e) {
      print('Error initializing Firebase: $e');
      isLoading.value = false;
      Get.offAllNamed('/error');
    }
  }

  // Check if it's first time launching the app
  bool get isFirstTime => _storage.read(FIRST_TIME_KEY) ?? true;

  // Mark first time as complete
  Future<void> markFirstTimeDone() async {
    await _storage.write(FIRST_TIME_KEY, false);
  }

  // Improved method to fetch user role with retry logic
  Future<String?> _fetchUserRole(String uid) async {
    try {
      // First attempt
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data()?['role'] != null) {
        String role = doc.data()?['role'];
        userRole.value = role;
        return role;
      }
      
      // If role not found, wait briefly and retry (handles race condition)
      await Future.delayed(Duration(milliseconds: 500));
      
      // Second attempt
      final retryDoc = await _firestore.collection('users').doc(uid).get();
      if (retryDoc.exists && retryDoc.data()?['role'] != null) {
        String role = retryDoc.data()?['role'];
        userRole.value = role;
        return role;
      }
      
      // If still not found after retry
      print('No role found for user $uid after retry');
      userRole.value = null;
      return null;
    } catch (e) {
      print('Error fetching user role: $e');
      userRole.value = null;
      return null;
    }
  }

// In app_router.dart, _handleAuthStateChange method
Future<void> _handleAuthStateChange(User? currentUser) async {
  if (isNavigating.value) {
    print('Navigation already in progress, ignoring auth state change');
    return;
  }
  
  try {
    isNavigating.value = true;
    isLoading.value = true;
    print('Auth state changed. User: ${currentUser?.uid}');

    if (currentUser == null) {
      print('User is null, navigating to splash');
      Get.offAllNamed('/splash');
    } else {
      // Add more detailed logging
      print('User authenticated. Fetching user role from Firestore...');
      
      // Fetch user role with logging
      String? role;
      for (int i = 0; i < 3; i++) {
        print('Attempt ${i+1} to fetch user role');
        final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
        
        if (userDoc.exists) {
          print('User document found: ${userDoc.id}');
          if (userDoc.data()?['role'] != null) {
            role = userDoc.data()?['role'];
            userRole.value = role;
            print('User role set to: $role');
            break;
          } else {
            print('Role field missing in user document');
          }
        } else {
          print('User document not found');
        }
        
        print('Waiting before retry...');
        await Future.delayed(Duration(milliseconds: 500));
      }
      
      print('Final user role determination: $role');

      if (role == 'artisan') {
        print('User is artisan, checking shop');
        final shopRepository = ShopRepository();
        final existingShop = await shopRepository.getShopByArtisanId(currentUser.uid);

        if (existingShop == null || existingShop.id.isEmpty) {
          print('No shop found, navigating to shop onboarding');
          Get.offAllNamed('/shop-onboarding');
        } else {
          print('Shop found, navigating to artisan dashboard');
          Get.offAllNamed('/artisan/navBar');
          print('Navigation to artisan dashboard completed');
        }
      } else if (role == 'customer') {
        print('User is customer, navigating to customer dashboard');
        Get.offAllNamed('/customer/navBar');
        print('Navigation to customer dashboard completed');
      } else {
        print('User role unknown or null ($role), not navigating');
      }
    }
  } catch (e) {
    print('Error in auth state change handler: $e');
  } finally {
    isLoading.value = false;
    // Reset navigation flag immediately
    isNavigating.value = false;
    print('Auth state handling completed, navigation flag reset');
  }
}
  static final routes = [
    // Splash and onboarding
    GetPage(name: '/splash', page: () => const SplashScreen()),
    GetPage(name: '/onboarding', page: () => const OnboardingScreen()),
    GetPage(name: '/get-started', page: () => const GetStarted()),

    // Authentication
    GetPage(name: '/login', page: () =>  Login()),
    GetPage(name: '/register', page: () =>  RegisterPage()),
    // GetPage(name: '/verify-otp', page: () => OTPVerificationPage()),

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
    // search page 
    GetPage(name: '/search', page: () => const SearchPage()),
    // service history page
      GetPage(
      name: '/service-history',
      page: () => const ServiceHistoryPage(),
      binding: BindingsBuilder(() {
        Get.lazyPut<BookingsController>(() => BookingsController());
        Get.lazyPut<ServiceController>(() => ServiceController());
      }),
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

// Rest of the classes remain unchanged
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