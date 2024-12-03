import 'package:domo/common/navigation/app_router.dart';
import 'package:domo/common/styles/style.dart';
import 'package:domo/features/favorites/controller/favorite_controller.dart';
import 'package:domo/features/favorites/model/favorite_model.dart';
import 'package:domo/features/services/controllers/service_controller.dart';
import 'package:domo/features/services/models/service_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';

class Wishlist extends StatelessWidget {
  final String? userId;

  const Wishlist({super.key, this.userId});

  @override
  Widget build(BuildContext context) {
    final AppRouter appRouter = Get.find<AppRouter>();
    final FavoritesController favoritesController =
        Get.find<FavoritesController>();
    final String currentUserId = userId ?? appRouter.userId.value!;

    // Initial fetch when the widget is created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (currentUserId.isNotEmpty) {
        favoritesController.fetchUserFavorites(currentUserId);
      }
    });

    return Scaffold(
    backgroundColor: AppTheme.button,
      appBar: AppBar(
        title: Text(
          'My Favorites',
          style: AppTheme.textTheme.headlineSmall?.copyWith(
            color: AppTheme.button,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Obx(() {
        final userId = appRouter.userId.value;

        if (userId == null) {
          return _buildLoginPrompt();
        }

        return RefreshIndicator(
          onRefresh: () async {
            favoritesController.fetchUserFavorites(currentUserId);
          },
          child: StreamBuilder<List<FavoritesModel>>(
            stream: favoritesController.userFavorites,
            builder: (context, snapshot) {
              // Loading state with Shimmer
              if (favoritesController.isLoading) {
                return _buildShimmerList();
              }

              // Error state
              if (favoritesController.errorMessage != null) {
                return _buildErrorState(favoritesController.errorMessage!);
              }

              // Empty state
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return _buildEmptyState();
              }

              // Favorites list
              return _buildFavoritesList(snapshot.data!, favoritesController);
            },
          ),
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
              leading: Container(
                width: 60,
                height: 60,
                color: Colors.white,
              ),
              title: Container(
                height: 16,
                color: Colors.white,
              ),
              subtitle: Container(
                height: 12,
                width: 100,
                color: Colors.white,
              ),
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
          Icon(
            Icons.favorite_border,
            size: 100,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No favorites yet',
            style: AppTheme.textTheme.titleMedium?.copyWith(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start exploring services and add them to favorites!',
            style: AppTheme.textTheme.bodySmall?.copyWith(
              color: Colors.grey,
            ),
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
          future: Get.find<ServiceController>()
              .fetchServiceById(favorite.serviceId),
          builder: (context, serviceSnapshot) {
            if (serviceSnapshot.connectionState == ConnectionState.waiting) {
              return const LinearProgressIndicator();
            }

            if (!serviceSnapshot.hasData || serviceSnapshot.data == null) {
              return _buildUnavailableServiceTile(
                  context, favorite, favoritesController);
            }

            final service = serviceSnapshot.data!;
            return _buildFavoriteServiceTile(
                context, service, favorite, favoritesController);
          },
        );
      },
    );
  }

  Widget _buildUnavailableServiceTile(BuildContext context,
      FavoritesModel favorite, FavoritesController favoritesController) {
    return ListTile(
      title: Text(
        'Service Not Available',
        style: AppTheme.textTheme.titleMedium?.copyWith(color: Colors.grey),
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
      onDismissed: (_) =>
          _deleteFavorite(favoritesController, favorite.id, context),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: AppTheme.cardRadius,
        ),
        child: GestureDetector(
          onTap: () {
            // Navigate to service details page; come back to this...beacue it is not working beacuse of the images hmm
            Get.toNamed('/service-details', arguments: service);
          },
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              style: AppTheme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
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

  // New helper methods for delete confirmation and snackbar
  Future<bool> _showDeleteConfirmationDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title:
                Text('Remove Favorite', style: AppTheme.textTheme.titleMedium),
            content: Text(
                'Are you sure you want to remove this service from favorites?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('Cancel', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: Text('Remove'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _deleteFavorite(FavoritesController favoritesController,
      String favoriteId, BuildContext context) {
    favoritesController.removeFromFavorites(favoriteId);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Service removed from favorites'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }
}
