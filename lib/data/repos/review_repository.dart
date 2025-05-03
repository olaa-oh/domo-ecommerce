import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:domo/features/reviews/model/review_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:domo/features/bookings/models/booking_model.dart';

class ReviewRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create a new review
  Future<ReviewModel> createReview({
    required String bookingId,
    required String shopId,
    required String reviewText,
    required int rating,
  }) async {
    try {
      // Check if the booking exists and is completed
      final bookingDoc = await _firestore.collection('bookings').doc(bookingId).get();
      if (!bookingDoc.exists) {
        throw Exception('The booking does not exist');
      }
      
      final booking = BookingModel.fromSnapshot(bookingDoc);
      
      // Check if booking is completed
      if (booking.status != 'completed') {
        throw Exception('You can only review completed bookings');
      }
      
      // Check if booking already has a review
      if (booking.isReviewed) {
        throw Exception('You have already submitted a review for this booking');
      }

      // Check if the current user is the customer of this booking
      if (booking.customerId != _auth.currentUser!.uid) {
        throw Exception('You can only review your own bookings');
      }

      // Create the review
      final reviewRef = _firestore.collection('reviews').doc();
      final review = ReviewModel(
        id: reviewRef.id,
        bookingId: bookingId,
        customerId: _auth.currentUser!.uid,
        shopId: shopId,
        reviewText: reviewText,
        rating: rating,
        createdAt: DateTime.now(),
      );

      // Use transaction to ensure atomic updates
      await _firestore.runTransaction((transaction) async {
        // Create the review
        transaction.set(reviewRef, review.toJson());
        
        // Update the booking with reviewId
        transaction.update(bookingDoc.reference, {
          'reviewId': reviewRef.id,
          'isReviewed': true,
        });
      });
      
      // Update artisan average rating
      await _updateArtisanRating(shopId);
      
      return review;
    } catch (e) {
      print('Error creating review: $e');
      rethrow;
    }
  }

    // Get review for specific booking
  Future<ReviewModel?> getReviewForBooking(String bookingId) async {
    try {
      final querySnapshot = await _firestore
          .collection('reviews')
          .where('bookingId', isEqualTo: bookingId)
          .limit(1)
          .get();
          
      if (querySnapshot.docs.isEmpty) {
        return null;
      }
      
      return ReviewModel.fromSnapshot(querySnapshot.docs.first);
    } catch (e) {
      print('Error getting review for booking: $e');
      return null;
    }
  }


  // Check if a review already exists for this booking
  Future<ReviewModel?> checkExistingReview(String bookingId) async {
    final querySnapshot = await _firestore
        .collection('reviews')
        .where('bookingId', isEqualTo: bookingId)
        .where('customerId', isEqualTo: _auth.currentUser!.uid)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      return ReviewModel.fromSnapshot(querySnapshot.docs.first);
    }
    return null;
  }

  // Get reviews for an artisan
  Stream<List<ReviewModel>> getArtisanReviews(String shopId) {
    return _firestore
        .collection('reviews')
        .where('shopId', isEqualTo: shopId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => 
            snapshot.docs.map((doc) => ReviewModel.fromSnapshot(doc)).toList());
  }

  // Get reviews left by the current customer
  Stream<List<ReviewModel>> getCustomerReviews() {
    return _firestore
        .collection('reviews')
        .where('customerId', isEqualTo: _auth.currentUser!.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => 
            snapshot.docs.map((doc) => ReviewModel.fromSnapshot(doc)).toList());
  }

  // Update an existing review (within 24 hours)
  Future<ReviewModel> updateReview({
    required String reviewId,
    required String reviewText,
    required int rating,
  }) async {
    try {
      // Get the current review
      final reviewDoc = await _firestore.collection('reviews').doc(reviewId).get();
      final review = ReviewModel.fromSnapshot(reviewDoc);

      // Check if the review is still editable
      if (!review.isEditable) {
        throw Exception('Reviews can only be edited within 24 hours of creation');
      }

      // Check if the current user is the review owner
      if (review.customerId != _auth.currentUser!.uid) {
        throw Exception('You can only edit your own reviews');
      }

      // Update the review
      await _firestore.collection('reviews').doc(reviewId).update({
        'reviewText': reviewText,
        'rating': rating,
        'editedAt': DateTime.now().toIso8601String(),
        'isEdited': true,
      });

      // Update artisan average rating
      await _updateArtisanRating(review.shopId);

      // Return the updated review
      final updatedDoc = await _firestore.collection('reviews').doc(reviewId).get();
      return ReviewModel.fromSnapshot(updatedDoc);
    } catch (e) {
      print('Error updating review: $e');
      rethrow;
    }
  }

  // Delete a review (within 24 hours)
  Future<bool> deleteReview(String reviewId) async {
    try {
      // Get the current review
      final reviewDoc = await _firestore.collection('reviews').doc(reviewId).get();
      final review = ReviewModel.fromSnapshot(reviewDoc);

      // Check if the review is still editable
      if (!review.isEditable) {
        throw Exception('Reviews can only be deleted within 24 hours of creation');
      }

      // Check if the current user is the review owner
      if (review.customerId != _auth.currentUser!.uid) {
        throw Exception('You can only delete your own reviews');
      }

      // Delete the review
      await _firestore.collection('reviews').doc(reviewId).delete();

      // Update artisan average rating
      await _updateArtisanRating(review.shopId);

      return true;
    } catch (e) {
      print('Error deleting review: $e');
      return false;
    }
  }

  // Add artisan response to a review
  Future<bool> respondToReview({
    required String reviewId,
    required String responseText,
  }) async {
    try {
      // Get the current review
      final reviewDoc = await _firestore.collection('reviews').doc(reviewId).get();
      final review = ReviewModel.fromSnapshot(reviewDoc);

      // Check if the current user is the artisan
      if (review.shopId != _auth.currentUser!.uid) {
        throw Exception('Only the artisan can respond to this review');
      }

      // Check if the artisan has already responded
      if (review.artisanResponse != null) {
        throw Exception('You have already responded to this review');
      }

      // Add the response
      await _firestore.collection('reviews').doc(reviewId).update({
        'artisanResponse': responseText,
        'responseDate': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      print('Error responding to review: $e');
      return false;
    }
  }

  // Flag a review for moderation
  Future<bool> flagReview(String reviewId) async {
    try {
      // Get the current review
      final reviewDoc = await _firestore.collection('reviews').doc(reviewId).get();
      final review = ReviewModel.fromSnapshot(reviewDoc);

      // Check if the current user is the artisan
      if (review.shopId != _auth.currentUser!.uid) {
        throw Exception('Only the artisan can flag this review');
      }

      // Flag the review
      await _firestore.collection('reviews').doc(reviewId).update({
        'isFlagged': true,
      });

      return true;
    } catch (e) {
      print('Error flagging review: $e');
      return false;
    }
  }

  // Calculate and update artisan's average rating
  Future<void> _updateArtisanRating(String shopId) async {
    try {
      // Get all reviews for the artisan
      final querySnapshot = await _firestore
          .collection('reviews')
          .where('shopId', isEqualTo: shopId)
          .get();

      if (querySnapshot.docs.isEmpty) {
        // No reviews, reset rating to 0
        await _firestore.collection('artisans').doc(shopId).update({
          'averageRating': 0,
          'totalReviews': 0,
        });
        return;
      }

      // Calculate average rating
      double totalRating = 0;
      final reviews = querySnapshot.docs.map((doc) => ReviewModel.fromSnapshot(doc)).toList();
      for (var review in reviews) {
        totalRating += review.rating;
      }
      final averageRating = totalRating / reviews.length;

      // Update artisan document
      await _firestore.collection('artisans').doc(shopId).update({
        'averageRating': averageRating,
        'totalReviews': reviews.length,
      });
    } catch (e) {
      print('Error updating artisan rating: $e');
    }
  }

  // Get average rating for an artisan
  Future<Map<String, dynamic>> getArtisanRatingStats(String shopId) async {
    try {
      // Get all reviews for the artisan
      final querySnapshot = await _firestore
          .collection('reviews')
          .where('shopId', isEqualTo: shopId)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return {
          'averageRating': 0.0,
          'totalReviews': 0,
          'ratingCounts': {
            '5': 0,
            '4': 0,
            '3': 0,
            '2': 0,
            '1': 0,
          }
        };
      }

      // Calculate statistics
      double totalRating = 0;
      final reviews = querySnapshot.docs.map((doc) => ReviewModel.fromSnapshot(doc)).toList();
      final ratingCounts = {
        '5': 0,
        '4': 0,
        '3': 0,
        '2': 0,
        '1': 0,
      };

      for (var review in reviews) {
        totalRating += review.rating;
        ratingCounts['${review.rating}'] = (ratingCounts['${review.rating}'] ?? 0) + 1;
      }

      final averageRating = totalRating / reviews.length;

      return {
        'averageRating': averageRating,
        'totalReviews': reviews.length,
        'ratingCounts': ratingCounts,
      };
    } catch (e) {
      print('Error getting artisan rating stats: $e');
      rethrow;
    }
  }
}