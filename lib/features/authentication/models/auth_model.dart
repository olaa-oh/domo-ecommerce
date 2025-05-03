// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:get_storage/get_storage.dart';
// import '../models/user_model.dart';

// class AuthModel {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final GetStorage _storage = GetStorage();
//     static const String VERIFICATION_ID_KEY = 'verification_id';
  
//   // Singleton pattern
//   static final AuthModel _instance = AuthModel._internal();
//   factory AuthModel() => _instance;
//   AuthModel._internal();

//   // Stream of authentication state changes
//   Stream<User?> get authStateChanges => _auth.authStateChanges();

//   // Get current user
//   User? get currentUser => _auth.currentUser;
  

//   // Sign in anonymously
//   Future<UserCredential> signInAnonymously() async {
//     try {
//       return await _auth.signInAnonymously();
//     } catch (e) {
//       throw _handleAuthException(e);
//     }
//   }


//   // New method to check if phone number is already registered
//   Future<bool> isPhoneNumberRegistered(String phoneNumber) async {
//     try {
//       // Normalize phone number format before checking
//       String normalizedPhone = normalizePhoneNumber(phoneNumber);
      
//       final QuerySnapshot result = await _firestore
//           .collection('users')
//           .where('phoneNumber', isEqualTo: normalizedPhone)
//           .limit(1)
//           .get();

//       return result.docs.isNotEmpty;
//     } catch (e) {
//       throw Exception('Error checking phone number: $e');
//     }
//   }

//   // Helper method to normalize phone numbers
//   String normalizePhoneNumber(String phoneNumber) {
//     // Remove any whitespace or special characters
//     String cleaned = phoneNumber.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    
//     // Ensure it starts with +
//     if (!cleaned.startsWith('+')) {
//       // Add Kenyan country code if not present (adjust as needed)
//       if (cleaned.startsWith('0')) {
//         cleaned = '+233${cleaned.substring(1)}';
//       } else if (!cleaned.startsWith('233')) {
//         cleaned = '+233$cleaned';
//       } else {
//         cleaned = '+$cleaned';
//       }
//     }
    
//     return cleaned;
//   }

//   Future<void> sendOTP(String phoneNumber) async {
//     try {
//       String normalizedPhone = normalizePhoneNumber(phoneNumber);

//       await _auth.verifyPhoneNumber(
//         phoneNumber: normalizedPhone,
//         verificationCompleted: (PhoneAuthCredential credential) async {
//           await _auth.signInWithCredential(credential);
//         },
//         verificationFailed: (FirebaseAuthException e) {
//           throw _handleAuthException(e);
//         },
//         codeSent: (String verificationId, int? resendToken) async {
//           await _storage.write(VERIFICATION_ID_KEY, verificationId);
//         },
//         codeAutoRetrievalTimeout: (String verificationId) {},
//         timeout: const Duration(seconds: 60),
//       );
//     } catch (e) {
//       throw _handleAuthException(e);
//     }
//   }

//   Future<UserCredential> verifyOTPAndCreateUser(
//     String otp,
//     UserModel user,
//   ) async {
//     try {
//       String? verificationId = _storage.read(VERIFICATION_ID_KEY);
      
//       if (verificationId == null) {
//         throw Exception('Verification ID not found. Please request OTP again.');
//       }

//       // Normalize phone number before saving
//       user = user.copyWith(phoneNumber: normalizePhoneNumber(user.phoneNumber));

//       // Final check for phone number uniqueness
//       if (await isPhoneNumberRegistered(user.phoneNumber)) {
//         throw Exception('This phone number is already registered.');
//       }

//       PhoneAuthCredential credential = PhoneAuthProvider.credential(
//         verificationId: verificationId,
//         smsCode: otp,
//       );

//       UserCredential userCredential = await _auth.signInWithCredential(credential);

//       if (userCredential.user != null) {
//         await _saveUserToFirestore(userCredential.user!.uid, user);
//       }

//       await _storage.remove(VERIFICATION_ID_KEY);
//       return userCredential;
//     } catch (e) {
//       throw _handleAuthException(e);
//     }
//   }

//   Future<void> _saveUserToFirestore(String uid, UserModel user) async {
//     try {
//       // Create a transaction to ensure atomicity
//       await _firestore.runTransaction((transaction) async {
//         // Check one final time if phone number is unique
//         final QuerySnapshot phoneCheck = await _firestore
//             .collection('users')
//             .where('phoneNumber', isEqualTo: user.phoneNumber)
//             .get();

//         if (phoneCheck.docs.isNotEmpty) {
//           throw Exception('Phone number was registered by another user during the process.');
//         }

//         // If unique, save the user data
//         final DocumentReference userDoc = _firestore.collection('users').doc(uid);
//         transaction.set(userDoc, user.toJson());
//       });
//     } catch (e) {
//       throw Exception('Failed to save user data: $e');
//     }
//   }




//     Future<void> signInWithPhoneNumber(String verificationId, String smsCode) async {
//       try {
//         // Create a PhoneAuthCredential with the verification ID and SMS code
//         PhoneAuthCredential credential = PhoneAuthProvider.credential(
//           verificationId: verificationId,
//           smsCode: smsCode,
//         );

//         // Sign in with the credential
//         await _auth.signInWithCredential(credential);
//         print("User signed in successfully");
//       } catch (e) {
//         print("Sign in error: $e");
//       }
//     }


//   // Sign out
//   Future<void> signOut() async {
//     try {
//       await _auth.signOut();
//     } catch (e) {
//       throw _handleAuthException(e);
//     }
//   }

//   // Helper method to generate custom token (implement secure token generation)
//   Future<String> _generateCustomToken(String phoneNumber) async {
//     throw UnimplementedError('Custom token generation not implemented');
//   }

//   // Handle authentication exceptions
//   Exception _handleAuthException(dynamic e) {
//     if (e is FirebaseAuthException) {
//       switch (e.code) {
//         case 'invalid-verification-code':
//           return Exception('Invalid OTP code');
//         case 'invalid-phone-number':
//           return Exception('Invalid phone number');
//         default:
//           return Exception('Authentication error: ${e.message}');
//       }
//     }
//     return Exception('An unexpected error occurred');
//   }
// }
