import 'package:domo/data/repos/auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/user_model.dart';

class AuthController extends GetxController {
  static AuthController get instance => Get.find();

  // Controllers for registration and login
  final phoneController = TextEditingController();
  final otpController = TextEditingController();
  final fullNameController = TextEditingController();

  final RxBool isLoading = false.obs;
  final RxString userType = ''.obs;
  final RxBool isOtpSent = false.obs;
  final RxInt resendTimer = 0.obs;

  // Dependency
  final _authRepository = AuthenticationRepository.instance;

  // Normalize phone number - remove leading zero if present
String normalizePhoneNumber(String phoneNumber) {
  String normalizedNumber = phoneNumber.trim();
  
  // Remove leading zero if present
  if (normalizedNumber.startsWith('0')) {
    normalizedNumber = normalizedNumber.substring(1);
  }
  
  // Ensure there's no country code already
  if (normalizedNumber.startsWith('+233')) {
    normalizedNumber = normalizedNumber.substring(4);
  }
  
  return normalizedNumber;
}

  // Validate phone number
  String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    // Basic validation for phone number format
    // Allowing numbers starting with 0 or not, with total length 9-10 digits
    final phoneRegex = RegExp(r'^(0)?\d{9}$');
    if (!phoneRegex.hasMatch(value)) {
      return 'Enter a valid phone number (e.g., 0242209090)';
    }
    return null;
  }

  // Validate OTP
  String? validateOTP(String? value) {
    if (value == null || value.isEmpty) {
      return 'OTP is required';
    }
    if (value.length != 6) {
      return 'OTP must be 6 digits';
    }
    return null;
  }

  // Send OTP
  Future<void> sendOTP() async {
    try {
      // Validate phone number
      if (validatePhone(phoneController.text) != null) {
        Get.snackbar('Error', validatePhone(phoneController.text)!);
        return;
      }

      isLoading.value = true;

      // Normalize phone number before sending
      String normalizedNumber = normalizePhoneNumber(phoneController.text);

      // Send OTP via repository
      await _authRepository.sendOTP(normalizedNumber);
      
      isOtpSent.value = true;
      
      // Start resend timer (60 seconds)
      resendTimer.value = 60;
      startResendTimer();
      
      Get.snackbar('Success', 'OTP sent to your phone number');
    } catch (e) {
      Get.snackbar('Error', e.toString(), backgroundColor: Colors.red);
    } finally {
      isLoading.value = false;
    }
  }

  // Start countdown timer for OTP resend
  void startResendTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (resendTimer.value > 0) {
        resendTimer.value--;
        startResendTimer();
      }
    });
  }

void resetControllers() {
  // Only clear text, don't dispose
  phoneController.text = '';
  otpController.text = '';
  fullNameController.text = '';
  isOtpSent.value = false;
  userType.value = '';
}

  // Register with phone number and OTP verification
Future<void> registerUser() async {
  try {
    // Validation code remains the same...
    
    isLoading.value = true;

    // Store these values before the async operations
    final String normalizedNumber = normalizePhoneNumber(phoneController.text);
    final String fullName = fullNameController.text.trim();
    final String role = userType.value;
    final String otpCode = otpController.text.trim();
    
    // Create user model
    UserModel newUser = UserModel(
      phoneNumber: normalizedNumber,
      fullName: fullName,
      role: role,
      createdAt: DateTime.now(),
    );

    // phoneController.clear();
    // otpController.clear();
    // fullNameController.clear();
    // userType.value = '';
    // isOtpSent.value = false;
     resetControllers();

    // Now perform the Firebase operations with our captured values
    await _authRepository.verifyOTPAndRegister(otpCode, newUser);

    // Show success message
    Get.snackbar('Success', 'Account created successfully');
    
    // The auth state listener in AppRouter will handle navigation based on the user role
    
  } catch (e) {
    Get.snackbar('Error', e.toString(), backgroundColor: Colors.red);
  } finally {
    isLoading.value = false;
  }
}

  // Login with phone number and OTP
Future<void> loginUser() async {
  try {
    // Validate OTP
    if (validateOTP(otpController.text) != null) {
      Get.snackbar('Error', validateOTP(otpController.text)!);
      return;
    }

    isLoading.value = true;

    // Check if verification ID is available
    if (!isOtpSent.value) {
      Get.snackbar('Error', 'Please request OTP first', backgroundColor: Colors.red);
      isLoading.value = false;
      return;
    }

    // Normalize phone number
    String normalizedNumber = normalizePhoneNumber(phoneController.text);
    final String otpCode = otpController.text.trim();

    resetControllers();

    // Verify OTP and login
    await _authRepository.verifyOTPAndLogin(
      normalizedNumber,
      otpCode,
    );

    
    
  } catch (e) {
    if (e.toString().contains('User not found')) {
      Get.snackbar(
        'Account Not Found', 
        'No account exists with this phone number. Please register first.',
        backgroundColor: Colors.amber
      );
    } else if (e.toString().contains('invalid-verification-code')) {
      Get.snackbar(
        'Invalid OTP', 
        'The verification code you entered is incorrect. Please try again.',
        backgroundColor: Colors.red
      );
    } else {
      Get.snackbar('Login Error', e.toString(), backgroundColor: Colors.red);
    }
  } finally {
    isLoading.value = false;
  }
}

  // Sign out
  Future<void> signOut() async {
    try {
      await _authRepository.signOut();
    } catch (e) {
      Get.snackbar('Error', e.toString(), backgroundColor: Colors.red);
    }
  }

  // @override
  // void onClose() {
  //   // Dispose controllers
  //   phoneController.dispose();
  //   otpController.dispose();
  //   fullNameController.dispose();
  //   super.onClose();
  // }


}