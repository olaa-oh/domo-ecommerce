import 'package:domo/common/styles/style.dart';
import 'package:domo/features/bookings/controller/booking_controller.dart';
import 'package:domo/features/favorites/controller/favorite_controller.dart';
import 'package:domo/features/services/models/service_model.dart';
import 'package:domo/common/navigation/app_router.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ServiceCard extends StatelessWidget {
  final ServicesModel service;
  final VoidCallback onPressed;

  const ServiceCard({
    Key? key,
    required this.service,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final AppRouter appRouter = Get.find<AppRouter>();
    final FavoritesController favoritesController =
        Get.find<FavoritesController>();

    return Container(
      width: 160,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: AppTheme.outlinedBox(
        borderRadius: AppTheme.cardRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 2),
          )
        ],
      ),
      child: GestureDetector(
        onTap: () {
          Get.toNamed('/service-details', arguments: service);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                  child: Image.network(
                    service.imageAsset,
                    width: double.infinity,
                    height: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: double.infinity,
                        height: 100,
                        color: AppTheme.caption.withOpacity(0.2),
                        child: Icon(
                          Icons.image_not_supported,
                          color: AppTheme.icon,
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Obx(() {
                    final userId = appRouter.userId.value;
                    if (userId == null) {
                      return const SizedBox.shrink();
                    }

                    return StatefulBuilder(
                      builder: (context, setState) {
                        return FutureBuilder<bool>(
                          future: favoritesController.isServiceInFavorites(
                              userId: userId, serviceId: service.id),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Icon(
                                Icons.favorite_border,
                                color: Colors.white,
                                shadows: [
                                  Shadow(color: Colors.black54, blurRadius: 4)
                                ],
                              );
                            }

                            bool isInFavorites = snapshot.data ?? false;

                            return GestureDetector(
                              onTap: () async {
                                if (userId == null) return;

                                try {
                                  if (isInFavorites) {
                                    final favorites = await favoritesController
                                            .userFavorites?.first ??
                                        [];

                                    final favoriteToRemove =
                                        favorites.firstWhere(
                                            (fav) =>
                                                fav.serviceId == service.id,
                                            orElse: () => throw Exception(
                                                'Favorite not found'));

                                    await favoritesController
                                        .removeFromFavorites(
                                            favoriteToRemove.id);
                                    setState(() => isInFavorites = false);
                                  } else {
                                    await favoritesController.addToFavorites(
                                        userId: userId, serviceId: service.id);
                                    setState(() => isInFavorites = true);
                                  }
                                } catch (e) {
                                  print('Favorite toggle error: $e');
                                }
                              },
                              child: Icon(
                                isInFavorites
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color:
                                    isInFavorites ? Colors.red : Colors.white,
                                shadows: [
                                  Shadow(
                                      color: Colors.black54,
                                      blurRadius: isInFavorites ? 0 : 4)
                                ],
                              ),
                            );
                          },
                        );
                      },
                    );
                  }),
                ),
              ],
            ),
            Padding(
              padding: AppTheme.cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.serviceName,
                    style: AppTheme.textTheme.titleMedium?.copyWith(
                      color: AppTheme.text,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${service.price} GHS',
                        style: AppTheme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.caption,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Flexible(
                        child: Text(
                          service.location,
                          style: AppTheme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.caption,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            service.rating.toString(),
                            style: AppTheme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.caption,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: () => _bookService(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.button,
                          foregroundColor: AppTheme.buttonText,
                          shape: RoundedRectangleBorder(
                            borderRadius: AppTheme.buttonRadius,
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          elevation: 2,
                        ),
                        child: Text(
                          'Book',
                          style: AppTheme.textTheme.labelLarge?.copyWith(
                            color: AppTheme.buttonText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // booking widget
  void _bookService(BuildContext context) async {
    // Get the BookingsController
    final bookingsController = Get.find<BookingsController>();

    // Show date and time picker
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
        // Combine date and time
        final DateTime bookingDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        // Book the service
        await bookingsController.bookService(
          serviceId: service.id,
          shopId: '',
          bookingDate: bookingDateTime,
          price: service.price,
        );
      }
    }
  }
}
