import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:domo/features/favorites/model/favorite_model.dart';
import 'package:flutter/material.dart';


class FavoritesRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;



  // Add a service to favorites
  Future<void> addToFavorites({
    required String userId, 
    required String serviceId,
  }) async {
    try {
      // Create a new favorites document
      final favoritesRef = _firestore.collection('favorites').doc();
      
      final favoritesModel = FavoritesModel(
        id: favoritesRef.id,
        userId: userId,
        serviceId: serviceId,
      );

      // Save to Firestore
      await favoritesRef.set(favoritesModel.toJson());
    } catch (e) {
      debugPrint('Error adding to favorites: $e');
      rethrow;
    }
  }

  // Remove a service from favorites
  Future<void> removeFromFavorites({
    required String favoriteId,
  }) async {
    try {
      await _firestore.collection('favorites').doc(favoriteId).delete();
    } catch (e) {
      debugPrint('Error removing from favorites: $e');
      rethrow;
    }
  }

  // Fetch user's favorite services
  Stream<List<FavoritesModel>> fetchUserFavorites(String userId) {
    return _firestore
        .collection('favorites')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FavoritesModel.fromSnapshot(doc))
            .toList());
  }

  // Check if a service is already in favorites
  Future<bool> isServiceInFavorites({
    required String userId, 
    required String serviceId,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection('favorites')
          .where('userId', isEqualTo: userId)
          .where('serviceId', isEqualTo: serviceId)
          .get();
      
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking favorites: $e');
      return false;
    }
  }

  // Count total favorites for a service
  Future<int> countServiceFavorites(String serviceId) async {
    try {
      final querySnapshot = await _firestore
          .collection('favorites')
          .where('serviceId', isEqualTo: serviceId)
          .get();
      
      return querySnapshot.docs.length;
    } catch (e) {
      debugPrint('Error counting service favorites: $e');
      return 0;
    }
  }

  //  method to find a favorite by service ID
  Future<FavoritesModel?> findFavoriteByServiceId({
    required String userId, 
    required String serviceId,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection('favorites')
          .where('userId', isEqualTo: userId)
          .where('serviceId', isEqualTo: serviceId)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        return FavoritesModel.fromSnapshot(querySnapshot.docs.first);
      }
      
      return null;
    } catch (e) {
      debugPrint('Error finding favorite: $e');
      return null;
    }
  }
}