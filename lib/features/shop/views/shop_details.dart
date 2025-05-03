import 'package:domo/common/styles/style.dart';
import 'package:domo/common/widgets/service/vert_service_card.dart';
import 'package:domo/features/services/controllers/service_controller.dart';
import 'package:domo/features/services/views/service_details_page.dart';
import 'package:domo/features/shop/controller/shop_details_controller.dart';
import 'package:domo/features/shop/model/shop_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class ShopDetailsPage extends StatelessWidget {
  final ShopModel shopDetails;

  const ShopDetailsPage({Key? key, required this.shopDetails})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final serviceController = Get.find<ServiceController>();
    final controller = Get.find<ShopDetailsController>();

    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<ShopModel?>(
            future: controller.fetchShopDetailsById(shopDetails.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data == null) {
                return const Center(child: Text('Shop details not found'));
              }

              final shopDetails = snapshot.data!;

              // Set location after data is fetched
              final geoPoints = controller.getShopGeoPoints(shopDetails);
              if (geoPoints != null) {
                controller.selectedLocation.value = geoPoints;
                controller.selectedLocationAddress.value =
                    shopDetails.location.toString();

                // Add marker
                controller.mapMarkers.clear();
                controller.mapMarkers.add(Marker(
                  markerId: MarkerId(shopDetails.id.toString()),
                  position: geoPoints,
                  infoWindow: InfoWindow(title: shopDetails.name),
                ));
              }

              // Trigger service fetch
              WidgetsBinding.instance.addPostFrameCallback((_) {
                serviceController.getServicesByShopId(shopDetails.id);
              });

              return CustomScrollView(
                slivers: [
                  _buildSliverAppBar(shopDetails),
                  SliverToBoxAdapter(
                    child: Obx(() => Padding(
                          padding: AppTheme.screenPadding,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLocationSection(context, controller),
                              // Rest of the sections remain the same
                              _buildDescriptionSection(shopDetails),
                              _buildServiceModesSection(shopDetails),
                              _buildOperatingHoursSection(context, shopDetails),
                              _buildContactSection(shopDetails),
                              _buildServicesSection(serviceController),
                            ],
                          ),
                        )),
                  ),
                ],
              );
            }),
      ),
    );
  }

  // Sliver App Bar with Image and Shop Name
  SliverAppBar _buildSliverAppBar(ShopModel shopDetails) {
    return SliverAppBar(
      expandedHeight: 250,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          shopDetails.name,
          style: AppTheme.textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            shadows: [
              const Shadow(
                blurRadius: 10.0,
                color: Colors.black,
                offset: Offset(2.0, 2.0),
              ),
            ],
          ),
        ),
        background: shopDetails.image.isNotEmpty
            ? Image.network(
                shopDetails.image,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Container(color: AppTheme.background),
              )
            : Container(color: AppTheme.background),
      ),
    );
  }

  // Location Section with Map and Directions
  Widget _buildLocationSection(
      BuildContext context, ShopDetailsController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Location',
          style: AppTheme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 10),
        Container(
          height: 200,
          decoration: AppTheme.outlinedBox(),
          child: controller.selectedLocation.value != null
              ? GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: controller.selectedLocation.value!,
                    zoom: 15,
                  ),
                  markers: controller.mapMarkers,
                  onMapCreated: controller.onMapCreated,
                )
              : const Center(child: CircularProgressIndicator()),
        ),
        const SizedBox(height: 10),
        FutureBuilder<String>(
          future: controller.getReadableAddress(
              shopDetails.location.latitude, shopDetails.location.longitude),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return const Center(child: Text('Error fetching address'));
            }
            return Text(
              snapshot.data ?? 'Address not available',
              style: AppTheme.textTheme.bodyMedium,
            );
          },
        ),
        ElevatedButton.icon(
          onPressed: () => _launchDirections(controller),
          icon: const Icon(Icons.directions),
          label: const Text('Get Directions'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.button,
            foregroundColor: AppTheme.buttonText,
          ),
        ),
      ],
    );
  }

  // Launch directions using Google Maps
  void _launchDirections(ShopDetailsController controller) async {
    final location = controller.selectedLocation.value;
    if (location != null) {
      final uri = Uri.parse(
          'https://www.google.com/maps/dir/?api=1&destination=${location.latitude},${location.longitude}');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    }
  }

  // Description Section
  Widget _buildDescriptionSection(ShopModel shopDetails) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About Us',
            style: AppTheme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 10),
          Text(
            shopDetails.description,
            style: AppTheme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  // Modes of Service Section
  Widget _buildServiceModesSection(ShopModel shopDetails) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Service Modes',
            style: AppTheme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: shopDetails.modesOfService
                .map((mode) => Chip(
                      label: Text(
                        mode == ModeOfService.home ? 'Home Service' : 'On-Site',
                        style: AppTheme.textTheme.bodySmall,
                      ),
                      backgroundColor: AppTheme.button.withOpacity(0.1),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  // Operating Hours Section
  Widget _buildOperatingHoursSection(
      BuildContext context, ShopModel shopDetails) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Operating Hours',
            style: AppTheme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 10),
          ...shopDetails.operatingHours.entries.map((entry) {
            final startTime = entry.value['start'];
            final endTime = entry.value['end'];
            return ListTile(
              title: Text(
                entry.key,
                style: AppTheme.textTheme.bodyMedium,
              ),
              trailing: Text(
                startTime != null && endTime != null
                    ? '${startTime.format(context)} - ${endTime.format(context)}'
                    : 'Closed',
                style: AppTheme.textTheme.bodySmall,
              ),
            );
          }),
        ],
      ),
    );
  }

  // Contact Section
  Widget _buildContactSection(ShopModel shopDetails) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contact',
            style: AppTheme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 10),
          ListTile(
            leading: const Icon(Icons.phone, color: AppTheme.icon),
            title: Text(
              shopDetails.phoneNumber,
              style: AppTheme.textTheme.bodyMedium,
            ),
            onTap: () => _launchPhone(shopDetails.phoneNumber),
          ),
        ],
      ),
    );
  }

  // Launch phone call
  void _launchPhone(String phoneNumber) async {
    final uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

// Services Section
// Services Section
  Widget _buildServicesSection(ServiceController serviceController) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Our Services',
            style: AppTheme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 10),
          Obx(() {
            if (serviceController.isLoading.value) {
              return const Center(child: CircularProgressIndicator());
            }

            if (serviceController.services.isEmpty) {
              return Center(
                child: Text(
                  'No services available',
                  style: AppTheme.textTheme.bodyMedium,
                ),
              );
            }

            // Display services in a horizontal scrollable list
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: serviceController.services.map((service) {
                  return ServiceCard(
                    service: service,
                    onPressed: () {
                      Get.to(
                        () => ServiceDetailsPage(service: service),
                        arguments: service,
                      );
                    },
                  );
                }).toList(),
              ),
            );
          }),
        ],
      ),
    );
  }
}
