import 'package:domo/data/repos/review_repository.dart';
import 'package:domo/features/bookings/controller/booking_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:domo/features/reviews/model/review_model.dart';

class ReviewController extends GetxController {
  final ReviewRepository _repository = ReviewRepository();

  // Reactive variables
  RxList<ReviewModel> artisanReviews = <ReviewModel>[].obs;
  RxList<ReviewModel> customerReviews = <ReviewModel>[].obs;
  RxMap<String, dynamic> artisanRatingStats = <String, dynamic>{}.obs;
  
  RxBool _isLoading = false.obs;
  bool get isLoading => _isLoading.value;

  RxnString _errorMessage = RxnString();
  String? get errorMessage => _errorMessage.value;

  // Create a new review
Future<bool> createReview({
  required String bookingId,
  required String shopId,
  required String reviewText,
  required int rating,
}) async {
  try {
    _isLoading.value = true;
    _errorMessage.value = null;
    update();

    // First check if booking is eligible for review
    final bookingsController = Get.find<BookingsController>();
    final isEligible = await bookingsController.isBookingEligibleForReview(bookingId);
    
    if (!isEligible) {
      throw Exception('This booking is not eligible for review');
    }

    await _repository.createReview(
      bookingId: bookingId,
      shopId: shopId,
      reviewText: reviewText,
      rating: rating,
    );

    // Refresh bookings list to show updated review status
    bookingsController.fetchUserBookings();

    // Show success snackbar
    Get.snackbar(
      'Review Submitted', 
      'Thank you for your feedback!',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );

    _isLoading.value = false;
    update();
    return true;
  } catch (e) {
    _isLoading.value = false;
    _errorMessage.value = e.toString();
    
    // Show error snackbar
    Get.snackbar(
      'Review Failed', 
      _errorMessage.value ?? 'Unable to submit review',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );

    update();
    return false;
  }
}

  // Fetch reviews for an artisan
  void fetchArtisanReviews(String shopId) {
    try {
      _isLoading.value = true;
      _errorMessage.value = null;
      update();

      // Subscribe to the stream of artisan reviews
      _repository.getArtisanReviews(shopId).listen((reviewsList) {
        artisanReviews.value = reviewsList;
        _isLoading.value = false;
        update();
      }, onError: (error) {
        _isLoading.value = false;
        _errorMessage.value = 'Failed to fetch reviews: $error';
        update();
      });

      // Also fetch artisan rating statistics
      fetchArtisanRatingStats(shopId);
    } catch (e) {
      _isLoading.value = false;
      _errorMessage.value = 'Failed to fetch reviews: $e';
      update();
    }
  }

  // Fetch reviews left by the current customer
  void fetchCustomerReviews() {
    try {
      _isLoading.value = true;
      _errorMessage.value = null;
      update();

      // Subscribe to the stream of customer reviews
      _repository.getCustomerReviews().listen((reviewsList) {
        customerReviews.value = reviewsList;
        _isLoading.value = false;
        update();
      }, onError: (error) {
        _isLoading.value = false;
        _errorMessage.value = 'Failed to fetch reviews: $error';
        update();
      });
    } catch (e) {
      _isLoading.value = false;
      _errorMessage.value = 'Failed to fetch reviews: $e';
      update();
    }
  }

  // Fetch artisan rating statistics
  Future<void> fetchArtisanRatingStats(String shopId) async {
    try {
      final stats = await _repository.getArtisanRatingStats(shopId);
      artisanRatingStats.value = stats;
      update();
    } catch (e) {
      print('Error fetching artisan rating stats: $e');
    }
  }

  // Update an existing review
  Future<bool> updateReview({
    required String reviewId,
    required String reviewText,
    required int rating,
  }) async {
    try {
      _isLoading.value = true;
      _errorMessage.value = null;
      update();

      await _repository.updateReview(
        reviewId: reviewId,
        reviewText: reviewText,
        rating: rating,
      );

      // Show success snackbar
      Get.snackbar(
        'Review Updated', 
        'Your review has been updated',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      _isLoading.value = false;
      update();
      return true;
    } catch (e) {
      _isLoading.value = false;
      _errorMessage.value = e.toString();
      
      // Show error snackbar
      Get.snackbar(
        'Update Failed', 
        _errorMessage.value ?? 'Unable to update review',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );

      update();
      return false;
    }
  }

    // Get review for a specific booking
  Future<ReviewModel?> getReviewForBooking(String bookingId) async {
    try {
      _isLoading.value = true;
      _errorMessage.value = null;
      update();
      
      final review = await _repository.getReviewForBooking(bookingId);
      
      _isLoading.value = false;
      update();
      
      return review;
    } catch (e) {
      _isLoading.value = false;
      _errorMessage.value = 'Error getting review: $e';
      update();
      return null;
    }
  }

  // Helper method to check if a booking has been reviewed
  Future<bool> hasBookingBeenReviewed(String bookingId) async {
    final review = await getReviewForBooking(bookingId);
    return review != null;
  }


  // Delete a review
  Future<bool> deleteReview(String reviewId) async {
    try {
      _isLoading.value = true;
      _errorMessage.value = null;
      update();

      final success = await _repository.deleteReview(reviewId);

      if (success) {
        // Show success snackbar
        Get.snackbar(
          'Review Deleted', 
          'Your review has been deleted',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }

      _isLoading.value = false;
      update();
      return success;
    } catch (e) {
      _isLoading.value = false;
      _errorMessage.value = 'Failed to delete review';
      
      // Show error snackbar
      Get.snackbar(
        'Delete Failed', 
        'Unable to delete review',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );

      update();
      return false;
    }
  }

  // Respond to a review (artisan only)
  Future<bool> respondToReview({
    required String reviewId,
    required String responseText,
  }) async {
    try {
      _isLoading.value = true;
      _errorMessage.value = null;
      update();

      final success = await _repository.respondToReview(
        reviewId: reviewId,
        responseText: responseText,
      );

      if (success) {
        // Show success snackbar
        Get.snackbar(
          'Response Added', 
          'Your response has been added to the review',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }

      _isLoading.value = false;
      update();
      return success;
    } catch (e) {
      _isLoading.value = false;
      _errorMessage.value = e.toString();
      
      // Show error snackbar
      Get.snackbar(
        'Response Failed', 
        _errorMessage.value ?? 'Unable to respond to review',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );

      update();
      return false;
    }
  }


  // Flag a review for moderation (artisan only)
  Future<bool> flagReview(String reviewId) async {
    try {
      _isLoading.value = true;
      _errorMessage.value = null;
      update();

      final success = await _repository.flagReview(reviewId);

      if (success) {
        // Show success snackbar
        Get.snackbar(
          'Review Flagged', 
          'This review has been flagged for moderation',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.blue,
          colorText: Colors.white,
        );
      }

      _isLoading.value = false;
      update();
      return success;
    } catch (e) {
      _isLoading.value = false;
      _errorMessage.value = e.toString();
      
      // Show error snackbar
      Get.snackbar(
        'Flag Failed', 
        _errorMessage.value ?? 'Unable to flag review',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );

      update();
      return false;
    }
  }

  // Check if a review already exists for a booking
  Future<ReviewModel?> checkExistingReview(String bookingId) async {
    return await _repository.checkExistingReview(bookingId);
  }
}