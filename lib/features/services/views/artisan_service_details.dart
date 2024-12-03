import 'package:domo/features/bookings/controller/booking_controller.dart';
import 'package:domo/features/favorites/controller/favorite_controller.dart';
import 'package:flutter/material.dart';
import 'package:domo/features/services/models/service_model.dart';
import 'package:domo/common/styles/style.dart';
import 'package:get/get.dart';

class ArtisanServiceDetails extends StatefulWidget {
  final ServicesModel service;

  const ArtisanServiceDetails({Key? key, required this.service}) : super(key: key);

  @override
  _ArtisanServiceDetailsState createState() => _ArtisanServiceDetailsState();
}

class _ArtisanServiceDetailsState extends State<ArtisanServiceDetails> {
  bool _showReviews = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300.0,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.service.serviceName,
                style: theme.textTheme.titleLarge?.copyWith(color: Colors.white),
              ),
              background: Hero(
                tag: 'service-image-${widget.service.serviceName}',
                child: Image.network(
                  widget.service.imageAsset,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.image_not_supported, size: 50),
                  ),
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: AppTheme.screenPadding,
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildServiceHeader(theme),
                const SizedBox(height: 16),
                _buildServiceInsights(theme),
                const SizedBox(height: 16),
                _buildDescriptionSection(theme),
                const SizedBox(height: 16),
                _buildReviewSection(theme),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceHeader(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.service.serviceName,
                style: theme.textTheme.headlineMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on, 
                    color: AppTheme.button, 
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.service.location,
                      style: theme.textTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Text(
          '${widget.service.price.toStringAsFixed(2)} GHS',
          style: theme.textTheme.titleLarge?.copyWith(
            color: AppTheme.button,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

Widget _buildServiceInsights(ThemeData theme) {
  return Container(
    decoration: AppTheme.outlinedBox(
      color: theme.cardColor,
      boxShadow: [
        const BoxShadow(
          color: Colors.black12,
          blurRadius: 10,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [

        FutureBuilder<int>(
          future: BookingsController().bookingCountForService(widget.service.id),
          builder: (context, snapshot) {
            final bookingCount = snapshot.data ?? 0;
            return _buildInsightItem(
              icon: Icons.calendar_today,
              label: 'Bookings',
              value: bookingCount.toString(),
              theme: theme,
              onTap: () {
              Get.toNamed('/artisan/bookings', 
                arguments: {
                  'serviceId': widget.service.id,
                  'serviceName': widget.service.serviceName
                }
              );
              },
            );
          },
        ),
        FutureBuilder<int>(
          future: FavoritesController().countServiceFavorites(widget.service.id),
          builder: (context, snapshot) {
            final favoritesCount = snapshot.data ?? 0;
            return _buildInsightItem(
              icon: Icons.favorite,
              label: 'Favorites',
              value: favoritesCount.toString(),
              theme: theme,
            );
          },
        ),
        _buildInsightItem(
          icon: Icons.star,
          label: 'Rating',
          value: '0.0',
          theme: theme,
        ),
      ],
    ),
  );
}

  Widget _buildDescriptionSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.service.description,
          style: theme.textTheme.bodyMedium,
        ),
        if (widget.service.themeName != null || widget.service.subThemeName != null)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(
                'Service Category',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              if (widget.service.themeName != null)
                Text(
                  'Theme: ${widget.service.themeName}',
                  style: theme.textTheme.bodyMedium,
                ),
              if (widget.service.subThemeName != null)
                Text(
                  'Subtheme: ${widget.service.subThemeName}',
                  style: theme.textTheme.bodyMedium,
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildReviewSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _showReviews = !_showReviews;
            });
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Reviews',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(
                _showReviews 
                  ? Icons.keyboard_arrow_up 
                  : Icons.keyboard_arrow_down,
                color: AppTheme.button,
              ),
            ],
          ),
        ),
        if (_showReviews)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 8),
            padding: AppTheme.cardPadding,
            decoration: AppTheme.outlinedBox(
              color: theme.cardColor,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No reviews yet',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Wonder what people think of this service?',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.caption,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // TODO: Implement review submission logic
                  },
                  child: const Text('See Reviews'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.button,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

}


  Widget _buildInsightItem({
    required IconData icon,
    required String label,
    required String value,
    required ThemeData theme,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: AppTheme.button, size: 28),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
