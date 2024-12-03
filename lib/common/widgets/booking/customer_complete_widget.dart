import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:domo/features/bookings/controller/booking_controller.dart';
import 'package:domo/features/bookings/models/booking_model.dart';
import 'package:domo/common/styles/style.dart';

class CustomerBookingCompletionWidget extends StatefulWidget {
  final BookingModel booking;

  const CustomerBookingCompletionWidget({
    super.key, 
    required this.booking
  });

  @override
  _CustomerBookingCompletionWidgetState createState() => _CustomerBookingCompletionWidgetState();
}

class _CustomerBookingCompletionWidgetState extends State<CustomerBookingCompletionWidget> {
  int _rating = 0;
  final TextEditingController _reviewController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return 
    AlertDialog(
      title: Text(
        'Complete Booking',
        style: AppTheme.textTheme.titleLarge,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Rate your experience',
            style: AppTheme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return IconButton(
                icon: Icon(
                  index < _rating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 30,
                ),
                onPressed: () {
                  setState(() {
                    _rating = index + 1;
                  });
                },
              );
            }),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _reviewController,
            decoration: InputDecoration(
              hintText: 'Write your review (optional)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _rating > 0 
            ? () {
                final bookingsController = Get.find<BookingsController>();
                bookingsController.initiateBookingCompletion(
                  bookingId: widget.booking.id,
                  rating: _rating,
                  review: _reviewController.text.trim(),
                );
                Navigator.of(context).pop();
              }
            : null,
          child: const Text('Submit'),
        ),
      ],
    );
  }
}