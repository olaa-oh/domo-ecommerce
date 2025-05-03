import 'package:domo/common/navigation/app_router.dart';
import 'package:domo/common/widgets/service/vert_service_card.dart';
import 'package:domo/common/styles/style.dart';
import 'package:domo/features/bookings/controller/booking_controller.dart';
import 'package:domo/features/favorites/controller/favorite_controller.dart';
import 'package:domo/features/reviews/controllers/review_controller.dart';
import 'package:domo/features/services/controllers/service_controller.dart';
import 'package:domo/features/services/views/service_details_page.dart';
import 'package:domo/features/services/models/service_model.dart';
import 'package:domo/features/shop/controller/shop_details_controller.dart';
import 'package:domo/features/shop/model/shop_model.dart';
import 'package:domo/features/reviews/model/review_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:get/get.dart';

class ServiceDetailsPage extends StatefulWidget {
  final ServicesModel service;

  const ServiceDetailsPage({super.key, required this.service});

  @override
  State<ServiceDetailsPage> createState() => _ServiceDetailsPageState();
}

class _ServiceDetailsPageState extends State<ServiceDetailsPage> {
  late ReviewController _reviewController;

  @override
  void initState() {
    super.initState();
    _reviewController = Get.put(ReviewController());
    // Fetch reviews for this service's shop
    _reviewController.fetchArtisanReviews(widget.service.shopId);
  }

  // navigate to shop details page
  void _navigateToShopDetails(BuildContext context) async {
    final ShopDetailsController shopController = Get.put(ShopDetailsController());
    
    try {
      // Print the shop ID to validate it's not empty
      print("Attempting to fetch shop with ID: ${widget.service.shopId}");
      
      if (widget.service.shopId == null || widget.service.shopId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid shop ID')),
        );
        return;
      }
      
      final shop = await shopController.fetchShopDetailsById(widget.service.shopId);
      
      if (shop != null) {
        // Pass the shop directly, not in a map
        Get.toNamed('/customer/shop-details', arguments: shop);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not fetch shop details')),
        );
      }
    } catch (e) {
      print('Error navigating to shop details: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300.0,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.service.serviceName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Image.network(
                widget.service.imageAsset,
                fit: BoxFit.cover,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Service Details Section
                  _buildServiceDetailsSection(context),

                  // Reviews Section
                  _buildReviewsSection(context),

                  // Similar Services Section
                  _buildSimilarServicesSection(context),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomActionBar(context),
    );
  }

  Widget _buildServiceDetailsSection(BuildContext context) {
    final ShopDetailsController shopController =
        Get.put(ShopDetailsController());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${widget.service.price} GHS',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        //location
        Text(
          widget.service.location,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
        ),

        const SizedBox(height: 8),

        // shop name
        FutureBuilder<String?>(
          future: shopController.getShopNameById(widget.service.shopId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Text(
                'Loading shop...',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
              );
            }

            if (snapshot.hasError || snapshot.data == null) {
              return Text(
                'Shop Not Available',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
              );
            }
            return GestureDetector(
              onTap: () => _navigateToShopDetails(context),
              child: 
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.button,
                  borderRadius: BorderRadius.circular(5),              
                ),
                child: Text(
                 'Check Out Shop',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        RatingBar.builder(
          initialRating: widget.service.rating,
          minRating: 1,
          direction: Axis.horizontal,
          allowHalfRating: true,
          itemCount: 5,
          itemSize: 20,
          itemPadding: const EdgeInsets.symmetric(horizontal: 2.0),
          itemBuilder: (context, _) => const Icon(
            Icons.star,
            color: Colors.amber,
          ),
          onRatingUpdate: (rating) {},
          ignoreGestures: true,
        ),
        const SizedBox(height: 16),
        Text(
          'Description',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.service.description,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildReviewsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Reviews',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Obx(() {
              final stats = _reviewController.artisanRatingStats;
              if (stats.isEmpty) {
                return const SizedBox.shrink();
              }
              return Text(
                '${stats['averageRating']?.toStringAsFixed(1) ?? '0.0'} (${stats['totalReviews'] ?? '0'})',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              );
            }),
          ],
        ),
        const SizedBox(height: 8),
        Obx(() {
          if (_reviewController.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final reviews = _reviewController.artisanReviews;
          
          if (reviews.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 30.0),
                child: Text(
                  'No reviews yet',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[400],
                      ),
                ),
              ),
            );
          }
          
          return SizedBox(
            height: 150,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: reviews.length,
              itemBuilder: (context, index) {
                return _buildReviewCard(context, reviews[index]);
              },
            ),
          );
        }),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildReviewCard(BuildContext context, ReviewModel review) {
    return Container(
      width: 250,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.grey[300],
                child: const Icon(Icons.person, color: Colors.white),
              ),
              const SizedBox(width: 8),
              // Expanded(
              //   child: Text(
              //     // review.customerName ?? 'Anonymous',
              //     // maxLines: 1,
              //     overflow: TextOverflow.ellipsis,
              //     style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              //           fontWeight: FontWeight.bold,
              //         ),
              //   ),
              // ),
            ],
          ),
          const SizedBox(height: 8),
          RatingBar.builder(
            initialRating: review.rating.toDouble(),
            minRating: 1,
            direction: Axis.horizontal,
            allowHalfRating: true,
            itemCount: 5,
            itemSize: 16,
            itemPadding: const EdgeInsets.symmetric(horizontal: 1.0),
            itemBuilder: (context, _) => const Icon(
              Icons.star,
              color: Colors.amber,
            ),
            onRatingUpdate: (rating) {},
            ignoreGestures: true,
          ),
          const SizedBox(height: 8),
          Text(
            review.reviewText,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildSimilarServicesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'You Might Also Like',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        FutureBuilder<List<ServicesModel>>(
          future: Get.find<ServiceController>().getServicesBySubThemeId(widget.service.subThemeId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Text('No similar services found');
            }

            return SizedBox(
              height: 300, 
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final similarService = snapshot.data![index];
                  return ServiceCard(
                    service: similarService, 
                    onPressed: () {
                      // Use the similarService, not the current service
                      Get.to(
                        () => ServiceDetailsPage(service: similarService),
                        arguments: similarService,
                      );
                    },
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBottomActionBar(BuildContext context) {
    final AppRouter appRouter = Get.find<AppRouter>();
    final FavoritesController favoritesController =
        Get.find<FavoritesController>();
    final BookingsController bookingsController =
        Get.find<BookingsController>();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Obx(() {
            final userId = appRouter.userId.value;
            if (userId == null) {
              return const SizedBox.shrink();
            }

            return FutureBuilder<bool>(
              future: favoritesController.isServiceInFavorites(
                  userId: userId, serviceId: widget.service.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return ElevatedButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.favorite_border),
                    label: const Text('Add'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                }

                bool isInFavorites = snapshot.data ?? false;

                return ElevatedButton.icon(
                  onPressed: () async {
                    if (userId == null) return;

                    try {
                      if (isInFavorites) {
                        final favorites =
                            await favoritesController.userFavorites?.first ??
                                [];
                        final favoriteToRemove = favorites.firstWhere(
                            (fav) => fav.serviceId == widget.service.id,
                            orElse: () =>
                                throw Exception('Favorite not found'));

                        await favoritesController
                            .removeFromFavorites(favoriteToRemove.id);
                      } else {
                        await favoritesController.addToFavorites(
                            userId: userId, serviceId: widget.service.id);
                      }
                    } catch (e) {
                      print('Favorite toggle error: $e');
                    }
                  },
                  icon: Icon(
                    isInFavorites ? Icons.favorite : Icons.favorite_border,
                    color: isInFavorites ? Colors.red : Colors.blue,
                  ),
                  label: Text(isInFavorites
                      ? 'Remove '
                      : 'Add '),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.blue,
                    side: BorderSide(color: Colors.blue),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              },
            );
          }),
          ElevatedButton(
            onPressed: () => _bookService(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Book Now'),
          ),
        ],
      ),
    );
  }

  // Booking method similar to the one in ServiceCard
  void _bookService(BuildContext context) async {
    final BookingsController bookingsController =
        Get.find<BookingsController>();

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        final DateTime bookingDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        await bookingsController.bookService(
          serviceId: widget.service.id,
          shopId: widget.service.shopId,
          bookingDate: bookingDateTime,
          price: widget.service.price,
          serviceName: widget.service.serviceName,
        );
      }
    }
  }
}