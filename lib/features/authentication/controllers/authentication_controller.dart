// import 'package:domo/data/repos/auth_repository.dart';
// import 'package:get/get.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:domo/features/authentication/models/user_model.dart';
// import 'package:domo/features/authentication/views/otp.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// class AuthController extends GetxController {
//   final Rx<User?> user = Rx<User?>(null);
//   final RxBool isLoading = false.obs;

//   final _authRepository = Get.put(AuthenticationRepository());

//   // Register user method
  
  
//   Future<void> registerUser({
//     required String name, 
//     required String phone, 
//     required String pin,
//     required String role,
//   }) async {
//     try {
//       // Set loading to true
//       isLoading.value = true;

//       // Create user model
//       final userModel = UserModel(
//         fullName: name,
//         phoneNumber: phone,
//         role: role,
//         createdAt: DateTime.now(),
//       );

//       // Send OTP
//       await _authRepository.sendOTP(phone);

//       // Navigate to OTP verification page
//       Get.to(() => OTPVerificationPage(), arguments: userModel);
//     } catch (e) {
//       // Handle any registration errors
//       Get.snackbar('Error', 'Registration failed: $e');
//     } finally {
//       // Set loading to false
//       isLoading.value = false;
//     }
//   }

//   // Verify OTP method
//   Future<void> verifyOTP(String otp, UserModel userModel) async {
//     try {
//       // Set loading to true
//       isLoading.value = true;

//       // Verify OTP and create user
//       await _authRepository.verifyOTPAndCreateUser(
//         otp: otp, 
//         userModel: userModel
//       );

//       // Navigate based on user role
//       if (userModel.role == 'artisan') {
//         Get.offAllNamed('/artisan/navBar');
//       } else {
//         Get.offAllNamed('/customer/navBar');
//       }
//     } catch (e) {
//       // Handle OTP verification errors
//       Get.snackbar('Error', 'OTP verification failed: $e');
//     } finally {
//       // Set loading to false
//       isLoading.value = false;
//     }
//   }

//   // Sign out method
//   Future<void> signOut() async {
//     try {
//       isLoading.value = true;
//       await _authRepository.signOut();
//     } catch (e) {
//       Get.snackbar('Error', 'Sign out failed: $e');
//     } finally {
//       isLoading.value = false;
//     }
//   }

// // signIn with phonenumber
//   Future<void> signInWithPhoneNumber(String phoneNumber) async {
//     try {
//       await _authRepository.sendOTP(phoneNumber);
//     } catch (e) {
//       Get.snackbar('Error', 'Sign in failed: $e');
//     }
//   }

//   // Verify OTP method
//   Future<void> verifyOTPAndSignIn(String otp, UserModel userModel) async {
//     try {
//       // Set loading to true
//       isLoading.value = true;

//       // Verify OTP and create user
//       await _authRepository.verifyOTPAndCreateUser(
//         otp: otp, 
//         userModel: userModel
//       );

//       // Navigate based on user role
//       if (userModel.role == 'artisan') {
//         Get.offAllNamed('/artisan/navBar');
//       } else {
//         Get.offAllNamed('/customer/navBar');
//       }
//     } catch (e) {
//       // Handle OTP verification errors
//       Get.snackbar('Error', 'OTP verification failed: $e');
//     } finally {
//       // Set loading to false
//       isLoading.value = false;
//     }
//   }


  
// }