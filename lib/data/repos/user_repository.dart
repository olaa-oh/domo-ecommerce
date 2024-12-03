// lib/features/authentication/repository/user_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:domo/features/authentication/models/user_model.dart';

class UserRepository extends GetxController {
  static UserRepository get instance => Get.find();

  final _db = FirebaseFirestore.instance;

  // Create user in Firestore
  Future<void> createUser(UserModel user) async {
    try {
      await _db.collection('users').doc(user.id).set(user.toJson());
    } catch (e) {
      throw 'Error creating user: $e';
    }
  }

  // Fetch user details
  Future<UserModel> getUserDetails(String uid) async {
    try {
      final snapshot = await _db.collection('users').doc(uid).get();
      if (snapshot.exists) {
        return UserModel.fromJson({
          'id': snapshot.id,
          ...snapshot.data()!,
        });
      } else {
        throw 'User not found';
      }
    } catch (e) {
      throw 'Error fetching user details: $e';
    }
  }

  // Update user data
  Future<void> updateUser(UserModel user) async {
    try {
      await _db.collection('users').doc(user.id).update(user.toJson());
    } catch (e) {
      throw 'Error updating user: $e';
    }
  }
}