import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:domo/features/reviews/controllers/review_controller.dart';

class CreateReviewScreen extends StatefulWidget {
  const CreateReviewScreen({Key? key}) : super(key: key);

  @override
  _CreateReviewScreenState createState() => _CreateReviewScreenState();
}

class _CreateReviewScreenState extends State<CreateReviewScreen> {
  final ReviewController _reviewController = Get.find<ReviewController>();
  final TextEditingController _reviewTextController = TextEditingController();
  
  late String bookingId;
  late String shopId;
  late String serviceName;
  int _selectedRating = 0;

  @override
  void initState() {
    super.initState();
    
    // Get the booking details from route arguments
    final args = Get.arguments as Map<String, dynamic>;
    bookingId = args['bookingId'];
    shopId = args['shopId'];
    serviceName = args['serviceName'];
  }

  @override
  void dispose() {
    _reviewTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave a Review'),
        elevation: 0,
      ),
      body: GetBuilder<ReviewController>(
        builder: (controller) {
          return controller.isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Review for: $serviceName',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Rate your experience:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildRatingSelector(),
                      const SizedBox(height: 20),
                      const Text(
                        'Share your experience (optional):',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _reviewTextController,
                        maxLines: 5,
                        maxLength: 300,
                        decoration: InputDecoration(
                          hintText: 'Tell others about your experience...',
                          border: const OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.grey[100],
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _selectedRating > 0
                            ? _submitReview
                            : null,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          alignment: Alignment.center,
                          child: const Text(
                            'Submit Review',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
        },
      ),
    );
  }

  Widget _buildRatingSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final starValue = index + 1;
        return IconButton(
          icon: Icon(
            starValue <= _selectedRating ? Icons.star : Icons.star_border,
            color: starValue <= _selectedRating ? Colors.amber : Colors.grey,
            size: 36,
          ),
          onPressed: () {
            setState(() {
              _selectedRating = starValue;
            });
          },
        );
      }),
    );
  }

  void _submitReview() async {
    if (_selectedRating == 0) {
      Get.snackbar(
        'Invalid Rating',
        'Please select a rating from 1 to 5 stars',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    final success = await _reviewController.createReview(
      bookingId: bookingId,
      shopId: shopId,
      reviewText: _reviewTextController.text.trim(),
      rating: _selectedRating,
    );

    if (success) {
      Get.snackbar(
        'Review Submitted',
        'Thank you for your feedback!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      Get.back(); // Close the review screen
    } else {  
      Get.snackbar(
        'Submission Failed',
        'Unable to submit your review. Please try again later.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  } 
}