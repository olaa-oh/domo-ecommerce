//  booking controller
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:domo/data/repos/booking_repository.dart';
import 'package:domo/features/bookings/models/booking_model.dart';
import 'package:domo/features/services/models/service_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';


class BookingsController extends GetxController {
  final BookingRepository _repository = BookingRepository();

  // Reactive variables
  Rxn<Stream<List<BookingModel>>> _userBookings = Rxn();
  RxList<BookingModel> userBookings = <BookingModel>[].obs;
  RxBool _isLoading = false.obs;
  bool get isLoading => _isLoading.value;


  RxnString _errorMessage = RxnString();
  String? get errorMessage => _errorMessage.value;

  // Book a service
  Future<bool> bookService({
    required String serviceId, 
    required String shopId,
    required DateTime bookingDate,
    String notes = '',
    required double price,
    required String serviceName,
  }) async {
    try {
      _isLoading.value = true;
      _errorMessage.value = null;
      update();

      final booking = await _repository.bookService(
        serviceId: serviceId, 
        shopId: shopId,
        bookingDate: bookingDate,
        notes: notes,
        price: price,
        serviceName: serviceName,
      );

      // Show success snackbar
      Get.snackbar(
        'Booking Successful', 
        'Your booking is pending approval',
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
        'Booking Failed', 
        _errorMessage.value ?? 'Unable to book service',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );

      update();
      return false;
    }
  }

  // Fetch user bookings
void fetchUserBookings() {
    try {
      _isLoading.value = true;
      _errorMessage.value = null;
      update();

      // Check if user is authenticated
      // if (_repository._auth.currentUser == null) {
      //   _isLoading.value = false;
      //   _errorMessage.value = 'User not authenticated';
      //   update();
      //   return;
      // }

      // Subscribe to the stream and update userBookings
      _repository.fetchUserBookings().listen((bookingsList) {
        print('Fetched bookings count: ${bookingsList.length}');
        userBookings.value = bookingsList;
        _isLoading.value = false;
        update();
      }, onError: (error) {
        print('Booking fetch error: $error');
        _isLoading.value = false;
        _errorMessage.value = 'Failed to fetch bookings: $error';
        update();
      });
    } catch (e) {
      print('Booking fetch exception: $e');
      _isLoading.value = false;
      _errorMessage.value = 'Failed to fetch bookings: $e';
      update();
    }
  }

  
// void fetchUserBookings() {
//   try {
//     _isLoading.value = true;
//     _errorMessage.value = null;
//     update();

//     // Subscribe to the stream and update userBookings
//     _repository.fetchUserBookings().listen((bookingsList) {
//       print('Fetched bookings count: ${bookingsList.length}');
//       // Debug: Print status of all bookings
//       for (var booking in bookingsList) {
//         print('Booking ${booking.id}: Status = ${booking.status}');
//       }
      
//       userBookings.value = bookingsList;
//       _isLoading.value = false;
//       update();
//     }, onError: (error) {
//       print('Booking fetch error: $error');
//       _isLoading.value = false;
//       _errorMessage.value = 'Failed to fetch bookings: $error';
//       update();
//     });
//   } catch (e) {
//     print('Booking fetch exception: $e');
//     _isLoading.value = false;
//     _errorMessage.value = 'Failed to fetch bookings: $e';
//     update();
//   }
// }


// Get a specific booking by ID
Future<BookingModel?> getBookingById(String bookingId) async {
  try {
    _isLoading.value = true;
    _errorMessage.value = null;
    update();

    final booking = await _repository.getBookingById(bookingId);
    
    _isLoading.value = false;
    update();
    return booking;
  } catch (e) {
    _isLoading.value = false;
    _errorMessage.value = 'Failed to fetch booking details: $e';
    update();
    return null;
  }
}

  // Update booking date
  Future<bool> updateBookingDate({
    required String bookingId, 
    required DateTime newBookingDate,
  }) async {
    try {
      _isLoading.value = true;
      _errorMessage.value = null;
      update();

      final success = await _repository.updateBookingDate(
        bookingId: bookingId, 
        newBookingDate: newBookingDate,
      );

      if (success) {
        // Show success snackbar
        Get.snackbar(
          'Booking Updated', 
          'Your booking date has been updated',
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
      _errorMessage.value = 'Failed to update booking';
      
      // Show error snackbar
      Get.snackbar(
        'Update Failed', 
        'Unable to update booking date',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );

      update();
      return false;
    }
  }

  // Cancel booking
  Future<bool> cancelBooking(String bookingId) async {
    try {
      _isLoading.value = true;
      _errorMessage.value = null;
      update();

      final success = await _repository.cancelBooking(bookingId);

      if (success) {
        // Show success snackbar
        Get.snackbar(
          'Booking Canceled', 
          'Your booking has been canceled',
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
      _errorMessage.value = 'Failed to cancel booking';
      
      // Show error snackbar
      Get.snackbar(
        'Cancellation Failed', 
        'Unable to cancel booking',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );

      update();
      return false;
    }
  }

  // Booking count for a service
  Future<int> bookingCountForService(String serviceId) async {
    try {
      _isLoading.value = true;
      _errorMessage.value = null;
      update();

      final count = await _repository.bookingCountForService(serviceId);

      _isLoading.value = false;
      update();
      return count;
    } catch (e) {
      _isLoading.value = false;
      _errorMessage.value = 'Failed to fetch booking count';
      update();
      return 0;
    }
  }

    // fectch bookings per a service
  Future<List<BookingModel>> fetchBookingsForService(String serviceId) async {
    try {
      _isLoading.value = true;
      _errorMessage.value = null;
      update();

      final bookings = await _repository.fetchBookingsForService(serviceId);

      _isLoading.value = false;
      update();
      return bookings;
    } catch (e) {
      _isLoading.value = false;
      _errorMessage.value = 'Failed to fetch bookings';
      update();
      return [];
    }
  }

  // accept booking
  Future<bool> acceptBooking(String bookingId) async {
    try {
      _isLoading.value = true;
      _errorMessage.value = null;
      update();

      final success = await _repository.acceptBooking(bookingId);

      if (success) {
        // Show success snackbar
        Get.snackbar(
          'Booking Accepted', 
          'You have accepted the booking',
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
      _errorMessage.value = 'Failed to accept booking';
      
      // Show error snackbar
      Get.snackbar(
        'Acceptance Failed', 
        'Unable to accept booking',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );

      update();
      return false;
    }
  }

  // fecth bookings per shop
  Future<List<BookingModel>> fetchBookingsForShop(String shopId) async {
    try {
      _isLoading.value = true;
      _errorMessage.value = null;
      update();

      final bookings = await _repository.fetchBookingsForShop(shopId);

      _isLoading.value = false;
      update();
      return bookings;
    } catch (e) {
      _isLoading.value = false;
      _errorMessage.value = 'Failed to fetch bookings';
      update();
      return [];
    }
  }

// initiate booking completion
Future<bool> initiateBookingCompletion({
  required String bookingId,
  int rating = 0,  
  String review = '',  
}) async {
  try {
    _isLoading.value = true;
    _errorMessage.value = null;
    update();

    final success = await _repository.initiateBookingCompletion(
      bookingId: bookingId,
      rating: rating,
      review: review,
    );

    if (success) {
      // Show success snackbar
      Get.snackbar(
        'Completion Initiated', 
        'Booking completion request sent',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      // Refresh user bookings
      fetchUserBookings();
    }

    _isLoading.value = false;
    update();
    return success;
  } catch (e) {
    _isLoading.value = false;
    _errorMessage.value = e.toString();
    
    // Show error snackbar
    Get.snackbar(
      'Completion Failed', 
      _errorMessage.value ?? 'Unable to initiate booking completion',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );

    update();
    return false;
  }
}


  // Confirm booking completion
  Future<bool> confirmBookingCompletion(String bookingId) async {
    try {
      _isLoading.value = true;
      _errorMessage.value = null;
      update();

      final success = await _repository.confirmBookingCompletion(bookingId);

      if (success) {
        // Show success snackbar
        Get.snackbar(
          'Booking Completed', 
          'Booking has been successfully completed',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        // Refresh user bookings
        fetchUserBookings();
      }

      _isLoading.value = false;
      update();
      return success;
    } catch (e) {
      _isLoading.value = false;
      _errorMessage.value = e.toString();
      
      // Show error snackbar
      Get.snackbar(
        'Confirmation Failed', 
        _errorMessage.value ?? 'Unable to confirm booking completion',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );

      update();
      return false;
    }
  }

  // Check if a booking is eligible for review
Future<bool> isBookingEligibleForReview(String bookingId) async {
  try {
    return await _repository.isBookingEligibleForReview(bookingId);
  } catch (e) {
    _errorMessage.value = 'Error checking review eligibility: $e';
    return false;
  }
}

// Get all completed bookings eligible for review
Future<List<BookingModel>> getCompletedBookingsForReview() async {
  try {
    _isLoading.value = true;
    update();
    
    final allBookings = userBookings.where((booking) => 
      booking.status == 'completed' && 
      (booking.reviewId == null || booking.reviewId!.isEmpty)
    ).toList();
    
    _isLoading.value = false;
    update();
    
    return allBookings;
  } catch (e) {
    _isLoading.value = false;
    _errorMessage.value = 'Error getting completed bookings: $e';
    update();
    return [];
  }
}




}