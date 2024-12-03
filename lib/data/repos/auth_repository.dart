import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:domo/features/authentication/models/user_model.dart';
import 'package:domo/features/authentication/views/login_page.dart';
import 'package:domo/features/onboarding/views/onboarding_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class AuthenticationRepository extends GetxController {
  static AuthenticationRepository get instance => Get.find();

  // Dependencies
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GetStorage _storage = GetStorage();

  // Constants
  static const String VERIFICATION_ID_KEY = 'verification_id';

  // Observables
  final Rx<User?> firebaseUser = Rx<User?>(null);
  final RxBool isLoading = false.obs;
  final RxString verificationId = ''.obs;

  // Stream of authentication state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current user
  User? get currentUser => _auth.currentUser;

  @override
  void onInit() {
    super.onInit();
    firebaseUser.bindStream(authStateChanges);
  }

  // Normalize phone number
  String normalizePhoneNumber(String phoneNumber) {
    // Remove any whitespace or special characters
    String cleaned = phoneNumber.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // Ensure it starts with +
    if (!cleaned.startsWith('+')) {
      // Add country code if not present (adjust as needed)
      if (cleaned.startsWith('0')) {
        cleaned = '+233${cleaned.substring(1)}';
      } else if (!cleaned.startsWith('233')) {
        cleaned = '+233$cleaned';
      } else {
        cleaned = '+$cleaned';
      }
    }

    return cleaned;
  }

  // Check if phone number is already registered
  // Future<bool> isPhoneNumberRegistered(String phoneNumber) async {
  //   try {
  //     String normalizedPhone = normalizePhoneNumber(phoneNumber);

  //     final QuerySnapshot result = await _firestore
  //         .collection('users')
  //         .where('phoneNumber', isEqualTo: normalizedPhone)
  //         .limit(1)
  //         .get();

  //     return result.docs.isNotEmpty;
  //   } catch (e) {
  //     throw Exception('Error checking phone number: $e');
  //   }
  // }

  Future<bool> isPhoneNumberRegistered(String phoneNumber) async {
    try {
      String normalizedPhone = normalizePhoneNumber(phoneNumber);

      print('Checking Registration for: $normalizedPhone'); // Debug print

      final QuerySnapshot result = await _firestore
          .collection('users')
          .where('phoneNumber', isEqualTo: normalizedPhone)
          .limit(1)
          .get();

      print(
          'Registration Check Result: ${result.docs.isNotEmpty}'); // Debug print

      return result.docs.isNotEmpty;
    } catch (e) {
      print('Phone Number Registration Check Error: $e'); // Debug print
      throw Exception('Error checking phone number: $e');
    }
  }

  // Send OTP
  Future<void> sendOTP(String phoneNumber) async {
    try {
      String normalizedPhone = normalizePhoneNumber(phoneNumber);

      await _auth.verifyPhoneNumber(
        phoneNumber: normalizedPhone,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          throw _handleAuthException(e);
        },
        codeSent: (String verificationId, int? resendToken) async {
          await _storage.write(VERIFICATION_ID_KEY, verificationId);
          this.verificationId.value = verificationId;
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          this.verificationId.value = verificationId;
        },
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Verify OTP and create user
  Future<UserCredential> verifyOTPAndCreateUser(
    String otp,
    UserModel user,
  ) async {
    try {
      String? storedVerificationId = _storage.read(VERIFICATION_ID_KEY);

      if (storedVerificationId == null) {
        throw Exception('Verification ID not found. Please request OTP again.');
      }

      // Normalize phone number before saving
      user = user.copyWith(phoneNumber: normalizePhoneNumber(user.phoneNumber));

      // Final check for phone number uniqueness
      if (await isPhoneNumberRegistered(user.phoneNumber)) {
        throw Exception('This phone number is already registered.');
      }

      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: storedVerificationId,
        smsCode: otp,
      );

      UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      if (userCredential.user != null) {
        await _saveUserToFirestore(userCredential.user!.uid, user);
      }

      await _storage.remove(VERIFICATION_ID_KEY);
      return userCredential;
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Save user to Firestore
  Future<void> _saveUserToFirestore(String uid, UserModel user) async {
    try {
      await _firestore.runTransaction((transaction) async {
        // Check one final time if phone number is unique
        final QuerySnapshot phoneCheck = await _firestore
            .collection('users')
            .where('phoneNumber', isEqualTo: user.phoneNumber)
            .get();

        if (phoneCheck.docs.isNotEmpty) {
          throw Exception(
              'Phone number was registered by another user during the process.');
        }

        // If unique, save the user data
        final DocumentReference userDoc =
            _firestore.collection('users').doc(uid);
        transaction.set(userDoc, user.toJson());
      });
    } catch (e) {
      throw Exception('Failed to save user data: $e');
    }
  }

  // Sign in with phone number
  Future<void> signInWithPhoneNumber(
      String verificationId, String smsCode) async {
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      await _auth.signInWithCredential(credential);
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

Future<void> signInWithPhoneAndPin(String phoneNumber, String pin) async {
  try {
    String normalizedPhone = normalizePhoneNumber(phoneNumber);

    // Check if the user exists in Firestore
    QuerySnapshot userQuery = await _firestore
        .collection('users')
        .where('phoneNumber', isEqualTo: normalizedPhone)
        .limit(1)
        .get();

    if (userQuery.docs.isEmpty) {
      throw Exception('User not found');
    }

    DocumentSnapshot userDoc = userQuery.docs.first;
    Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;

    // Verify PIN (assuming you've securely hashed the PIN)
    if (userData == null || !_verifyPin(pin, userData['pin'])) {
      throw Exception('Invalid PIN');
    }

    // Sign in the user
    await _auth.signInWithCustomToken(userDoc.id);
  } catch (e) {
    throw _handleAuthException(e);
  }
}

bool _verifyPin(String inputPin, String storedHashedPin) {
  return inputPin == storedHashedPin;
}

// Method to set PIN during user registration
Future<void> setUserPin(String pin) async {
  try {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('No authenticated user');
    }

    // Hash the PIN before storing (use a secure hashing method)
    String hashedPin = _hashPin(pin);

    await _firestore
        .collection('users')
        .doc(currentUser.uid)
        .update({
          'pin': hashedPin
        });
  } catch (e) {
    throw Exception('Could not set PIN: $e');
  }
}

// Secure PIN hashing method
String _hashPin(String pin) {

  return pin; // Replace with actual secure hashing
}



  // Sign in anonymously
  Future<UserCredential> signInAnonymously() async {
    try {
      return await _auth.signInAnonymously();
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Handle authentication exceptions
  Exception _handleAuthException(dynamic e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'invalid-verification-code':
          return Exception('Invalid OTP code');
        case 'invalid-phone-number':
          return Exception('Invalid phone number');
        default:
          return Exception('Authentication error: ${e.message}');
      }
    }
    return Exception('An unexpected error occurred');
  }

  void redirect() async {
    if (_storage.read('firstTime') == null) {
      // Redirect to onboarding screen
      Get.offAll(() => const OnboardingScreen());
    } else {
      // Redirect to login page
      Get.offAll(() => const Login());
    }
  }

// get user name
  Future<String> getUserName(String userId) async {
    try {
      // Fetch user document from Firestore
      final userDoc = await _firestore
          .collection(
              'users') 
          .doc(userId)
          .get();

      if (userDoc.exists) {
        return userDoc.data()?['fullName'] ??
            userDoc.data()?['name'] ??
            'Unknown User';
      }

      return 'Unknown User';
    } catch (e) {
      print('Error fetching user name: $e');
      return 'Unknown User';
    }
  }

  // Cached method to improve performance for multiple calls
  final Map<String, String> _userNameCache = {};

  Future<String> getCachedUserName(String userId) async {
    // Check cache first
    if (_userNameCache.containsKey(userId)) {
      return _userNameCache[userId]!;
    }

    // Fetch and cache the name
    final userName = await getUserName(userId);
    _userNameCache[userId] = userName;

    return userName;
  }

  // Fetch user document
  Future<Map<String, dynamic>> getUserDocument(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (userDoc.exists) {
        return userDoc.data() ?? {};
      }
      return {};
    } catch (e) {
      print('Error fetching user document: $e');
      throw Exception('Could not fetch user document');
    }
  }

// Update user profile
  Future<void> updateUserProfile(Map<String, dynamic> userData) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user');
      }

      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .update(userData);
    } catch (e) {
      print('Error updating user profile: $e');
      throw Exception('Could not update user profile');
    }
  }
}
