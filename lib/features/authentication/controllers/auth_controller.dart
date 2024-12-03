import 'package:domo/data/repos/auth_repository.dart';
import 'package:domo/features/onboarding/views/get_started_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class AuthController extends GetxController {
  final AuthenticationRepository _authRepository =
      Get.put(AuthenticationRepository());

  bool get isLoading => _authRepository.isLoading.value;

  @override
  void onInit() {
    super.onInit();
    // Listen to auth state changes
    ever(_authRepository.firebaseUser, _handleAuthStateChange);
  }

  // Handle auth state changes
  void _handleAuthStateChange(User? user) {
    if (user == null) {
      // Navigate to login page
      Get.offAllNamed('/login');
    } else {
      // Navigate to GetStarted page
      Get.to(GetStarted());
    }
  }

  // Register new user with phone number validation
  Future<void> registerUser({
    required String name,
    required String phone,
    required String pin,
    required String role,
  }) async {
    try {
      _authRepository.isLoading.value = true;

      // Check if phone number is already registered
      final bool isPhoneRegistered =
          await _authRepository.isPhoneNumberRegistered(phone);

      if (isPhoneRegistered) {
        throw Exception(
            'This phone number is already registered. Please use a different number or sign in.');
      }

      // Create user model
      final userModel = UserModel(
        fullName: name,
        phoneNumber: phone,
        role: role,
      );

      // Send OTP
      await _authRepository.sendOTP(phone);

      // Store user model temporarily
      Get.toNamed('/verify-otp', arguments: userModel);
    } catch (e) {
      Get.snackbar(
        'Registration Error ',
        e.toString(),
        backgroundColor: Colors.red[100],
        duration: const Duration(seconds: 5),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _authRepository.isLoading.value = false;
    }
  }

  // Verify OTP with additional validation
  Future<void> verifyOTP(String otp, UserModel userModel) async {
    try {
      _authRepository.isLoading.value = true;

      // Double-check phone number uniqueness before final registration
      final bool isPhoneRegistered =
          await _authRepository.isPhoneNumberRegistered(userModel.phoneNumber);

      if (isPhoneRegistered) {
        throw Exception(
            'This phone number was registered by another user while verification was in progress.');
      }

      await _authRepository.verifyOTPAndCreateUser(otp, userModel);
      Get.offAllNamed('/login');
    } catch (e) {
      Get.snackbar(
        'Verification Error',
        e.toString(),
        backgroundColor: Colors.red[100],
        duration: const Duration(seconds: 5),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _authRepository.isLoading.value = false;
    }
  }

Future<void> signIn(String phoneNumber) async {
    try {
      _authRepository.isLoading.value = true;

      final bool isPhoneRegistered =
          await _authRepository.isPhoneNumberRegistered(phoneNumber);

      if (!isPhoneRegistered) {
        throw Exception(
            'No account found with this phone number. Please register first.');
      }

      await _authRepository.sendOTP(phoneNumber);

      Get.snackbar(
        'OTP Sent',
        'An OTP has been sent to $phoneNumber',
        backgroundColor: Colors.green[100],
        duration: const Duration(seconds: 3),
        snackPosition: SnackPosition.BOTTOM,
      );

      // Navigate to OTP verification page
      Get.toNamed('/verify-otp');
    } catch (e) {
      print('Sign In Error: $e'); // Debug print
      Get.snackbar(
        'Sign In Error',
        e.toString(),
        backgroundColor: Colors.red[100],
        duration: const Duration(seconds: 5),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _authRepository.isLoading.value = false;
    }
  }
  
  Future<void> verifyOtpSignin(String smsCode) async {
    try {
      // Ensure loading state is set
      _authRepository.isLoading.value = true;

      // Verify OTP
      await _authRepository.signInWithPhoneNumber(
          _authRepository.verificationId.value, smsCode);

      // Optionally, navigate to home or next screen
      Get.offAllNamed('/splash');
    } catch (e) {
      Get.snackbar(
        'Verification Error',
        e.toString(),
        backgroundColor: Colors.red[100],
        duration: const Duration(seconds: 5),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      // Ensure loading state is reset
      _authRepository.isLoading.value = false;
    }
  }

  Future<void> signOut() async {
    try {
      // Call the repository's sign out method
      await _authRepository.signOut();

      // Navigate to login page
      Get.offAllNamed('/login');
    } catch (e) {
      Get.snackbar(
        'Sign Out Error',
        e.toString(),
        backgroundColor: Colors.red[100],
        duration: const Duration(seconds: 5),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

}
