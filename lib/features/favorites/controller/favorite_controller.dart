import 'package:domo/data/repos/favorite_repository.dart';
import 'package:domo/features/favorites/model/favorite_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FavoritesController extends GetxController {
  final FavoritesRepository _repository = FavoritesRepository();

  // Use RxnStream for nullable stream
  Rxn<Stream<List<FavoritesModel>>> _userFavorites = Rxn();
  Stream<List<FavoritesModel>>? get userFavorites => _userFavorites.value;

  RxBool _isLoading = false.obs;
  bool get isLoading => _isLoading.value;

  RxnString _errorMessage = RxnString();
  String? get errorMessage => _errorMessage.value;



  // Add service to favorites
  Future<bool> addToFavorites({
    required String userId, 
    required String serviceId,
  }) async {
    try {
      _isLoading.value = true;
      _errorMessage.value = null;
      update();

      final isAlreadyFavorite = await _repository.isServiceInFavorites(
        userId: userId, 
        serviceId: serviceId,
      );

      if (isAlreadyFavorite) {
        _errorMessage.value = 'Service is already in favorites';
        _isLoading.value = false;
        update();
        return false;
      }

      await _repository.addToFavorites(
        userId: userId, 
        serviceId: serviceId,
      );

      _isLoading.value = false;
      update();
      return true;
    } catch (e) {
      _isLoading.value = false;
      _errorMessage.value = 'Failed to add to favorites';
      update();
      return false;
    }
  }  



  // Fetch user favorites
void fetchUserFavorites(String userId) {
    try {
      _isLoading.value = true;
      _errorMessage.value = null;
      update();

      _userFavorites.value = _repository.fetchUserFavorites(userId);
      
      _isLoading.value = false;
      update();
    } catch (e) {
      _isLoading.value = false;
      _errorMessage.value = 'Failed to fetch favorites';
      update();
    }
  }



  // Check if service is in favorites
  Future<bool> isServiceInFavorites({
    required String userId, 
    required String serviceId,
  }) async {
    try {
      return await _repository.isServiceInFavorites(
        userId: userId, 
        serviceId: serviceId,
      );
    } catch (e) {
      return false;
    }
  }

    // Remove from favorites
  Future<bool> removeFromFavorites(String favoriteId) async {
    try {
      _isLoading.value = true;
      _errorMessage.value = null;

      await _repository.removeFromFavorites(favoriteId: favoriteId);

      _isLoading.value = false;
      return true;
    } catch (e) {
      _isLoading.value = false;
      _errorMessage.value = 'Failed to remove from favorites';
      return false;
    }
  }

  // Count service favorites
  Future<int> countServiceFavorites(String serviceId) async {
    try {
      return await _repository.countServiceFavorites(serviceId);
    } catch (e) {
      return 0;
    }
  }

  //  method to find a favorite by service ID
  Future<FavoritesModel?> findFavoriteByServiceId({
    required String userId, 
    required String serviceId,
  }) async {
    try {
      final querySnapshot = await _repository.findFavoriteByServiceId(
        userId: userId, 
        serviceId: serviceId,
      );
      
      return querySnapshot;
    } catch (e) {
      debugPrint('Error finding favorite: $e');
      return null;
    }
  }



}