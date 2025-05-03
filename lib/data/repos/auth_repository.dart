import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:domo/features/authentication/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class AuthenticationRepository extends GetxController {
  static AuthenticationRepository get instance => Get.find();

  // Dependencies
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GetStorage _storage = GetStorage();

  // Observables
  final Rx<User?> firebaseUser = Rx<User?>(null);
  final RxBool isLoading = false.obs;

  // Store verification ID for OTP
  String? _verificationId;
  // Stream of authentication state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current user
  User? get currentUser => _auth.currentUser;

  @override
  void onInit() {
    super.onInit();
    firebaseUser.bindStream(authStateChanges);
  }

  // Save user to Firestore
  Future<void> _saveUserToFirestore(String uid, UserModel user) async {
    try {
      await _firestore.runTransaction((transaction) async {
        // Check one final time if email is unique
        final QuerySnapshot phonenumberCheck = await _firestore
            .collection('users')
            .where('phoneNumber', isEqualTo: user.phoneNumber)
            .get();

        if (phonenumberCheck.docs.isNotEmpty) {
          throw Exception('phoneNumber was registered by another user during the process.');
        }

        // If unique, save the user data
        final DocumentReference userDoc = _firestore.collection('users').doc(uid);
        transaction.set(userDoc, user.toJson());
      });
    } catch (e) {
      throw Exception('Failed to save user data: $e');
    }
  }

  // Format phone number with country code
    String formatPhoneWithCountryCode(String phoneNumber) {
      String normalized = phoneNumber.trim();
      
      // Remove any existing country code
      if (normalized.startsWith('+233')) {
        normalized = normalized.substring(4);
      }
      
      // Remove leading zero if present
      if (normalized.startsWith('0')) {
        normalized = normalized.substring(1);
      }
      
      // Add Ghana country code
      return '+233$normalized';
    }

  // Send OTP to phone number
// Send OTP to phone number
Future<void> sendOTP(String phoneNumber) async {
  try {
    // Format phone number with country code
    String formattedPhoneNumber = formatPhoneWithCountryCode(phoneNumber);
    print('Sending OTP to formatted number: $formattedPhoneNumber');
    
    await _auth.verifyPhoneNumber(
      phoneNumber: formattedPhoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        print('Auto-verification completed');
        await _auth.signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        print('Verification failed: ${e.code} - ${e.message}');
        throw e.message ?? 'Verification failed';
      },
      codeSent: (String verificationId, int? resendToken) {
        print('Code sent, verification ID received');
        this._verificationId = verificationId;
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        print('Code auto retrieval timeout');
        this._verificationId = verificationId;
      },
      timeout: const Duration(seconds: 60),
    );
  } on FirebaseAuthException catch (e) {
    print('Firebase Auth Exception: ${e.code} - ${e.message}');
    throw e.message ?? 'Failed to send OTP';
  } catch (e) {
    print('Error sending OTP: $e');
    throw 'Something went wrong: $e';
  }
}
  // Verify OTP and register new user
  Future<void> verifyOTPAndRegister(String otp, UserModel user) async {
    try {
      if (_verificationId == null) {
        throw 'OTP verification failed. Please try again.';
      }

      // Create auth credential
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );

      // Sign in with credential
      final userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.user != null) {
        // Create user in Firestore with a specific method to ensure completion
        await _createFirestoreUser(userCredential.user!.uid, user);
      } else {
        throw 'Failed to create user account';
      }
    } on FirebaseAuthException catch (e) {
      throw e.message ?? 'OTP verification failed';
    } catch (e) {
      throw 'Something went wrong: $e';
    }
  }

  // Improved method to create user in Firestore with better error handling
  Future<void> _createFirestoreUser(String uid, UserModel user) async {
    try {
      final userData = user.copyWith(id: uid);
      // Use set with merge to ensure data is properly written
      await _firestore.collection('users').doc(uid).set(
        userData.toJson(),
        SetOptions(merge: true),
      );
      
      // Verify the write completed by reading back
      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (!userDoc.exists) {
        throw 'User data write failed';
      }
    } catch (e) {
      print('Error creating Firestore user: $e');
      throw 'Failed to save user data: $e';
    }
  }

  // Verify OTP and login existing user
// Verify OTP and login existing user
Future<void> verifyOTPAndLogin(String phoneNumber, String otp) async {
  try {
    if (_verificationId == null) {
      throw 'OTP verification failed. Please request a new OTP.';
    }

    // Format phone number with country code
    String formattedPhoneNumber = formatPhoneWithCountryCode(phoneNumber);
    
    // Create auth credential
    final credential = PhoneAuthProvider.credential(
      verificationId: _verificationId!,
      smsCode: otp,
    );

    // Sign in with credential
    final userCredential = await _auth.signInWithCredential(credential);

    if (userCredential.user != null) {
      // Get user data from Firestore
      final userDoc = await _firestore.collection('users').doc(userCredential.user!.uid).get();
      
      if (!userDoc.exists) {
        // User doesn't exist in Firestore
        await _auth.signOut();
        throw 'User not found. Please register first.';
      }
      
      // Store relevant user data in local storage for quick access
      final userData = userDoc.data() ?? {};
      _storage.write('user_role', userData['role'] ?? '');
      _storage.write('user_id', userCredential.user!.uid);
      _storage.write('user_name', userData['fullName'] ?? '');
      
      // Successfully logged in, navigation will be handled by auth state listener
    } else {
      throw 'Login failed';
    }
  } on FirebaseAuthException catch (e) {
    print('Firebase Auth Exception: ${e.code} - ${e.message}');
    if (e.code == 'invalid-verification-code') {
      throw 'Invalid verification code. Please try again.';
    } else if (e.code == 'session-expired') {
      throw 'Verification session expired. Please request a new OTP.';
    }
    throw e.message ?? 'OTP verification failed';
  } catch (e) {
    print('Login error: $e');
    throw 'Something went wrong: $e';
  }
}

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } on FirebaseAuthException catch (e) {
      throw e.message ?? 'Failed to sign out';
    } catch (e) {
      throw 'Something went wrong: $e';
    }
  }

  // Get user name
  Future<String> getUserName(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (userDoc.exists) {
        return userDoc.data()?['fullName'] ?? 'Unknown User';
      }

      return 'Unknown User';
    } catch (e) {
      print('Error fetching user name: $e');
      return 'Unknown User';
    }
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