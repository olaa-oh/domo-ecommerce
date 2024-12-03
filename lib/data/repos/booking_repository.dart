// booking repository

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:domo/features/bookings/models/booking_model.dart';

class BookingRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Book a service
  Future<BookingModel?> bookService({
    required String serviceId, 
     String? shopId,
    required DateTime bookingDate,
    String notes = '',
    required double price,
  }) async {
    try {
      // Check if user already has an active booking for this service
      final existingBooking = await _checkExistingActiveBooking(serviceId);
      if (existingBooking != null) {
        throw Exception('You already have an active booking for this service');
      }

      // Create a new booking
      final bookingRef = _firestore.collection('bookings').doc();
      final booking = BookingModel(
        id: bookingRef.id,
        serviceId: serviceId,
        customerId: _auth.currentUser!.uid,
        shopId: shopId ?? '',
        bookingDate: bookingDate,
        status: 'pending',
        notes: notes,
        price: price,
      );

      await bookingRef.set(booking.toJson());
      return booking;
    } catch (e) {
      rethrow;
    }
  }



  // Check for existing active booking
  Future<BookingModel?> _checkExistingActiveBooking(String serviceId) async {
    final querySnapshot = await _firestore
        .collection('bookings')
        .where('customerId', isEqualTo: _auth.currentUser!.uid)
        .where('serviceId', isEqualTo: serviceId)
        .where('status', whereIn: ['pending', 'accepted'])
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      return BookingModel.fromSnapshot(querySnapshot.docs.first);
    }
    return null;
  }

  // Fetch user's bookings
Stream<List<BookingModel>> fetchUserBookings() {
  print('Fetching bookings for user: ${_auth.currentUser!.uid}');
  return _firestore
      .collection('bookings')
      .where('customerId', isEqualTo: _auth.currentUser!.uid)
      .snapshots()
      .map((snapshot) {
        print('Fetched ${snapshot.docs.length} bookings');
        return snapshot.docs.map((doc) => BookingModel.fromSnapshot(doc)).toList();
      });
}

  // Update booking date
  Future<bool> updateBookingDate({
    required String bookingId, 
    required DateTime newBookingDate,
  }) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'bookingDate': newBookingDate.toIso8601String(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // Cancel booking
  Future<bool> cancelBooking(String bookingId) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': 'canceled',
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // Booking count for a service
  Future<int> bookingCountForService(String serviceId) async {
    final querySnapshot = await _firestore
        .collection('bookings')
        .where('serviceId', isEqualTo: serviceId)
        .where('status', isEqualTo: 'pending')
        .get();
    return querySnapshot.docs.length;
  }

  // fectch bookings per a service
  Future<List<BookingModel>> fetchBookingsForService(String serviceId) async {
    final querySnapshot = await _firestore
        .collection('bookings')
        .where('serviceId', isEqualTo: serviceId)
        .get();
    return querySnapshot.docs.map((doc) => BookingModel.fromSnapshot(doc)).toList();
  }

  // accept booking
  Future<bool> acceptBooking(String bookingId) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': 'accepted',
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // fecth bookings per shop
  Future<List<BookingModel>> fetchBookingsForShop(String shopId) async {
    final querySnapshot = await _firestore
        .collection('bookings')
        .where('shopId', isEqualTo: shopId)
        .get();
    return querySnapshot.docs.map((doc) => BookingModel.fromSnapshot(doc)).toList();
  }

 // Initiate booking completion by customer
  Future<bool> initiateBookingCompletion({
    required String bookingId,
    required int rating,
    required String review,
  }) async {
    try {
      // Fetch the current booking
      final bookingDoc = await _firestore.collection('bookings').doc(bookingId).get();
      final booking = BookingModel.fromSnapshot(bookingDoc);

      // Validate current status
      if (booking.status != 'accepted') {
        throw Exception('Booking must be in "accepted" status to initiate completion');
      }

      // Update booking with completion details
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': 'completion_initiated',
        'rating': rating,
        'review': review,
        'completionInitiatedAt': DateTime.now().toIso8601String(),
        'completionInitiatedBy': _auth.currentUser!.uid,
      });

      return true;
    } catch (e) {
      print('Error initiating booking completion: $e');
      rethrow;
    }
  }

  // Confirm booking completion by shop
  Future<bool> confirmBookingCompletion(String bookingId) async {
    try {
      // Fetch the current booking
      final bookingDoc = await _firestore.collection('bookings').doc(bookingId).get();
      final booking = BookingModel.fromSnapshot(bookingDoc);

      // Validate current status
      if (booking.status != 'completion_initiated') {
        throw Exception('Booking must be in "completion_initiated" status to confirm completion');
      }

      // Verify shop is confirming their own booking
      if (booking.shopId != _auth.currentUser!.uid) {
        throw Exception('Only the shop can confirm booking completion');
      }

      // Update booking to completed status
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': 'completed',
      });

      return true;
    } catch (e) {
      print('Error confirming booking completion: $e');
      rethrow;
    }
  }




}