import 'package:domo/common/navigation/app_router.dart';
import 'package:domo/common/styles/style.dart';
import 'package:domo/features/bookings/models/booking_model.dart';
import 'package:domo/features/favorites/controller/favorite_controller.dart';
import 'package:domo/features/favorites/model/favorite_model.dart';
import 'package:domo/features/services/controllers/service_controller.dart';
import 'package:domo/features/services/models/service_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import 'package:domo/features/bookings/controller/booking_controller.dart';


class Wishlist extends StatefulWidget {
  final String? userId;

  const Wishlist({super.key, this.userId});

  @override
  State<Wishlist> createState() => _WishlistState();
}

class _WishlistState extends State<Wishlist> {
  int selectedIndex = 0; // 0 = Favorites, 1 = History

  late final AppRouter appRouter;
  late final FavoritesController favoritesController;
  late final String currentUserId;

@override
void initState() {
  super.initState();
  appRouter = Get.find<AppRouter>();
  favoritesController = Get.find<FavoritesController>();
  final bookingsController = Get.find<BookingsController>();
  currentUserId = widget.userId ?? appRouter.userId.value!;

  if (currentUserId.isNotEmpty) {
    favoritesController.fetchUserFavorites(currentUserId);
    bookingsController.fetchUserBookings();
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.button,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 70,
        title: Container(
          height: 45,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              _buildToggleButton("Favorites", 0),
              _buildToggleButton("History", 1),
            ],
          ),
        ),
      ),

      body: Obx(() {
        final userId = appRouter.userId.value;

        if (userId == null) {
          return _buildLoginPrompt();
        }

        return RefreshIndicator(
          onRefresh: () async {
            if (selectedIndex == 0) {
              favoritesController.fetchUserFavorites(currentUserId);
            } else {
              // TODO: Refresh history data
            }
          },
          child: selectedIndex == 0
              ? StreamBuilder<List<FavoritesModel>>(
                  stream: favoritesController.userFavorites,
                  builder: (context, snapshot) {
                    if (favoritesController.isLoading) {
                      return _buildShimmerList();
                    }
                    if (favoritesController.errorMessage != null) {
                      return _buildErrorState(favoritesController.errorMessage!);
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return _buildEmptyState();
                    }
                    return _buildFavoritesList(snapshot.data!, favoritesController);
                  },
                )
              : _buildHistoryList(),
        );
      }),
    );
  }

  Widget _buildLoginPrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline, size: 100, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Please log in to view favorites',
            style: AppTheme.textTheme.titleMedium?.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String label, int index) {
  final isSelected = selectedIndex == index;

  return Expanded(
    child: GestureDetector(
      onTap: () {
        setState(() {
          selectedIndex = index;
        });
      },
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.button : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppTheme.button,
          ),
        ),
      ),
    ),
  );
}


  Widget _buildShimmerList() {
    return ListView.builder(
      padding: AppTheme.screenPadding,
      itemCount: 5,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: Container(width: 60, height: 60, color: Colors.white),
              title: Container(height: 16, color: Colors.white),
              subtitle: Container(height: 12, width: 100, color: Colors.white),
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorState(String errorMessage) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 100, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            'Oops! Something went wrong',
            style: AppTheme.textTheme.titleMedium?.copyWith(color: Colors.grey),
          ),
          Text(
            errorMessage,
            style: AppTheme.textTheme.bodySmall?.copyWith(color: Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border, size: 100, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No favorites yet',
            style: AppTheme.textTheme.titleMedium?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            'Start exploring services and add them to favorites!',
            style: AppTheme.textTheme.bodySmall?.copyWith(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesList(
      List<FavoritesModel> favorites, FavoritesController favoritesController) {
    return ListView.builder(
      padding: AppTheme.screenPadding,
      itemCount: favorites.length,
      itemBuilder: (context, index) {
        final favorite = favorites[index];

        return FutureBuilder<ServicesModel?>(
          future: Get.find<ServiceController>().fetchServiceById(favorite.serviceId),
          builder: (context, serviceSnapshot) {
            if (serviceSnapshot.connectionState == ConnectionState.waiting) {
              return const LinearProgressIndicator();
            }

            if (!serviceSnapshot.hasData || serviceSnapshot.data == null) {
              return _buildUnavailableServiceTile(context, favorite, favoritesController);
            }

            final service = serviceSnapshot.data!;
            return _buildFavoriteServiceTile(context, service, favorite, favoritesController);
          },
        );
      },
    );
  }

  Widget _buildUnavailableServiceTile(
      BuildContext context, FavoritesModel favorite, FavoritesController favoritesController) {
    return ListTile(
      title: Text(
        'Service Not Available',
        style: AppTheme.textTheme.titleMedium?.copyWith(color: Colors.grey),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete, color: AppTheme.button),
        onPressed: () => _showDeleteConfirmationDialog(context).then((confirmed) {
          if (confirmed) {
            _deleteFavorite(favoritesController, favorite.id, context);
          }
        }),
      ),
    );
  }

  Widget _buildFavoriteServiceTile(BuildContext context, ServicesModel service,
      FavoritesModel favorite, FavoritesController favoritesController) {
    return Dismissible(
      key: Key(favorite.id),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await _showDeleteConfirmationDialog(context);
      },
      onDismissed: (_) => _deleteFavorite(favoritesController, favorite.id, context),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 4,
        shape: const RoundedRectangleBorder(borderRadius: AppTheme.cardRadius),
        child: GestureDetector(
          onTap: () {
            Get.toNamed('/service-details', arguments: service);
          },
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: ClipRRect(
              borderRadius: AppTheme.cardRadius,
              child: Image.network(
                service.imageAsset,
                width: 70,
                height: 70,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 70,
                  height: 70,
                  color: Colors.grey[300],
                  child: const Icon(Icons.image_not_supported),
                ),
              ),
            ),
            title: Text(
              service.serviceName,
              style: AppTheme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              service.location,
              style: AppTheme.textTheme.bodySmall?.copyWith(color: Colors.grey),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: AppTheme.button),
              onPressed: () =>
                  _showDeleteConfirmationDialog(context).then((confirmed) {
                if (confirmed) {
                  _deleteFavorite(favoritesController, favorite.id, context);
                }
              }),
            ),
          ),
        ),
      ),
    );
  }

Widget _buildHistoryList() {
  final bookingsController = Get.find<BookingsController>();
  
  return Obx(() {
    // Check if loading
    if (bookingsController.isLoading) {
      return _buildShimmerList();
    }
    
    // Get all bookings
    final allBookings = bookingsController.userBookings;
    
    if (allBookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 70, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No bookings found',
              style: AppTheme.textTheme.titleMedium?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              'Book a service to see your history here!',
              style: AppTheme.textTheme.bodySmall?.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Filter completed bookings
    final completedBookings = allBookings
        .where((booking) => booking.status.toLowerCase() == 'completed')
        .toList();
    
    // Debug print
    print('All bookings: ${allBookings.length}');
    print('Completed bookings: ${completedBookings.length}');
    
    if (completedBookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 70, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No completed services yet',
              style: AppTheme.textTheme.titleMedium?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              'Your completed services will appear here',
              style: AppTheme.textTheme.bodySmall?.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: AppTheme.screenPadding,
      itemCount: completedBookings.length,
      itemBuilder: (context, index) {
        final booking = completedBookings[index];
        return _buildCompletedServiceCard(context, booking);
      },
    );
  });
}


Widget _buildCompletedServiceCard(BuildContext context, BookingModel booking) {
  return Card(
    margin: const EdgeInsets.only(bottom: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
      ),
    ),
    elevation: 2,
    child: InkWell(
      onTap: () {
        Get.toNamed('/service-history', arguments: booking);
      },
      borderRadius: BorderRadius.circular(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with image and basic info
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail image
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                child: Container(
                  width: 90,
                  height: 90,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  child: booking.serviceId.isNotEmpty
                      ? Image.network(
                          'https://via.placeholder.com/100',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.image_not_supported,
                            size: 40,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        )
                      : Icon(
                          Icons.check_circle,
                          size: 40,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                ),
              ),
              const SizedBox(width: 12),
              // Service details
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12, right: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.serviceName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Completed on ${DateFormat('MMMM d, yyyy').format(booking.bookingDate)}',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (booking.rating != null && booking.rating! > 0)
                            Row(
                              children: List.generate(5, (index) {
                                return Icon(
                                  index < (booking.rating ?? 0) ? Icons.star : Icons.star_border,
                                  color: index < (booking.rating ?? 0) ? Colors.amber : Colors.grey,
                                  size: 16,
                                );
                              }),
                            )
                          else
                            const Text(
                              'Not rated',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          const Spacer(),
                          const Icon(
                            Icons.chevron_right,
                            color: AppTheme.button,
                            size: 20,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}



String _formatDate(DateTime date) {
  return '${date.day}/${date.month}/${date.year}';
}

  Future<bool> _showDeleteConfirmationDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Remove Favorite', style: AppTheme.textTheme.titleMedium),
            content: const Text('Are you sure you want to remove this service from favorites?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Remove'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _deleteFavorite(FavoritesController favoritesController, String favoriteId, BuildContext context) {
    favoritesController.removeFromFavorites(favoriteId);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Service removed from favorites'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }
}
