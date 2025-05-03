import 'package:domo/features/reviews/controllers/review_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:domo/features/bookings/models/booking_model.dart';
import 'package:domo/features/reviews/model/review_model.dart';
import 'package:domo/common/styles/style.dart';

class BookingReviewWidget extends StatefulWidget {
  final BookingModel booking;
  final ReviewModel? existingReview;

  const BookingReviewWidget({
    super.key, 
    required this.booking,
    this.existingReview,
  });

  @override
  _BookingReviewWidgetState createState() => _BookingReviewWidgetState();
}

class _BookingReviewWidgetState extends State<BookingReviewWidget> {
  final ReviewController _reviewController = Get.find<ReviewController>();
  late int _rating;
  late TextEditingController _reviewControllers;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.existingReview != null;
    
    // Initialize with existing review data if available
    if (_isEditMode) {
      _rating = widget.existingReview!.rating;
      _reviewControllers = TextEditingController(text: widget.existingReview!.reviewText);
    } else {
      _rating = 0;
      _reviewControllers = TextEditingController();
    }
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        _isEditMode ? 'Edit Review' : 'Write a Review',
        style: AppTheme.textTheme.titleLarge,
      ),
      content: SingleChildScrollView(
        child: Column(
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
              controller: _reviewControllers,
              decoration: InputDecoration(
                hintText: 'Share your experience with this service',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              maxLines: 5,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _rating > 0 
            ? () async {
                if (_isEditMode) {
                  // Update existing review
                  await _reviewController.updateReview(
                    reviewId: widget.existingReview!.id,
                    reviewText: _reviewControllers.text.trim(),
                    rating: _rating,
                  );
                } else {
                  // Create new review
                  await _reviewController.createReview(
                    bookingId: widget.booking.id,
                    shopId: widget.booking.shopId,
                    reviewText: _reviewControllers.text.trim(),
                    rating: _rating,
                  );
                }
                // Close dialog
                Navigator.of(context).pop();
              }
            : null,
          child: Text(_isEditMode ? 'Update' : 'Submit'),
        ),
      ],
    );
  }
}