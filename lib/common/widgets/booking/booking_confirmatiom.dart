import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:domo/features/bookings/controller/booking_controller.dart';
import 'package:domo/features/bookings/models/booking_model.dart';
import 'package:domo/common/styles/style.dart';

class ShopBookingCompletionConfirmationWidget extends StatelessWidget {
  final BookingModel booking;

  const ShopBookingCompletionConfirmationWidget({
    super.key, 
    required this.booking
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Confirm Booking Completion',
        style: AppTheme.textTheme.titleLarge,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Customer Rating: ${booking.rating ?? 'N/A'} / 5',
            style: AppTheme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 10),
          if (booking.review != null && booking.review!.isNotEmpty)
            Text(
              'Customer Review: ${booking.review}',
              style: AppTheme.textTheme.bodyMedium,
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
            bookingsController.confirmBookingCompletion(booking.id);
            Navigator.of(context).pop();
          },
          child: const Text('Confirm Completion'),
        ),
      ],
    );
  }
}