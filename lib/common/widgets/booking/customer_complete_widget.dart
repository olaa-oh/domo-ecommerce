import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:domo/features/bookings/controller/booking_controller.dart';
import 'package:domo/features/bookings/models/booking_model.dart';
import 'package:domo/common/styles/style.dart';

class CustomerBookingCompletionWidget extends StatelessWidget {
  final BookingModel booking;

  const CustomerBookingCompletionWidget({
    super.key, 
    required this.booking
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Complete Booking',
        style: AppTheme.textTheme.titleLarge,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Are you satisfied with the service provided?',
            style: AppTheme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 10),
          Text(
            'After confirming completion, you will be able to leave a detailed review for the service provider.',
            style: AppTheme.textTheme.bodySmall?.copyWith(
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final bookingsController = Get.find<BookingsController>();
            // Simplified to only initiate completion without review data
            bookingsController.initiateBookingCompletion(
              bookingId: booking.id,
              rating: 0, // Default value, not used
              review: '', // Empty, not used
            );
            Navigator.of(context).pop();
            
            // Show success message encouraging review
            Get.snackbar(
              'Booking Completed', 
              'Thank you! You can now leave a detailed review for this service.',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.green,
              colorText: Colors.white,
              duration: const Duration(seconds: 5),
            );
          },
          child: const Text('Confirm Completion'),
        ),
      ],
    );
  }
}