import 'package:domo/common/navigation/app_router.dart';
import 'package:domo/data/repos/auth_repository.dart';
import 'package:domo/common/styles/style.dart';
import 'package:domo/features/authentication/controllers/auth_controller.dart';
import 'package:domo/features/favorites/controller/favorite_controller.dart';
import 'package:domo/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:domo/features/services/controllers/service_controller.dart';
import 'package:geolocator/geolocator.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize local storage
  await GetStorage.init();
  Get.put(AppRouter());

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)
      .then((FirebaseApp value)  {
    print('Firebase initialized');

    Get.put(AuthenticationRepository());
    Get.put(FavoritesController());     
    Get.put(ServiceController());
    Get.put(AuthController(), permanent: true);
    // Get.put(AuthController());
    // Get.put(AuthenticationRepository());
    // Get.put(RegistrationController());
    // Get.put(UserRepository());
  });

  Future<void> checkLocationPermission() async {
  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
}



  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      initialRoute: '/splash',
      getPages: AppRouter.routes,
      debugShowCheckedModeBanner: false,
      theme: AppTheme().light,
    );
  }
}
