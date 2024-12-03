import 'package:domo/common/styles/style.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:domo/features/shop/controller/shop_details_controller.dart';
import 'package:domo/features/shop/model/shop_model.dart';
import 'dart:io';

class ArtisanHomepage extends StatelessWidget {
  const ArtisanHomepage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ShopDetailsController());
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Shop Details', 
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: theme.colorScheme.primary,
        actions: [
          IconButton(onPressed: 
            () => Get.toNamed('/you'),
          icon: Icon(Icons.person_2_outlined,
            color: theme.colorScheme.onPrimary,
          )),
          Obx(() => IconButton(
                icon: Icon(
                  controller.isEditMode.value 
                    ? Icons.cancel 
                    : Icons.edit,
                  color: theme.colorScheme.onPrimary,
                ),
                onPressed: controller.toggleEditMode,
              )),
        ],
        elevation: 0,
      ),
      body: Obx(() {
        final shop = controller.shopDetails.value;
        return _buildShopDetailsContent(context, controller, shop);
      }),
    );
  }

  Widget _buildShopDetailsContent(
    BuildContext context, 
    ShopDetailsController controller, 
    ShopModel shop
  ) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: AppTheme.screenPadding,
      child: Form(
        key: controller.editFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Shop Image
            _buildShopImage(controller),
            
            const SizedBox(height: 24),
            
            // Card-based form fields
            _buildDetailCard(
              context, 
              title: 'Shop Name',
              child: _buildNameField(controller),
            ),
            
            const SizedBox(height: 16),
            
            _buildDetailCard(
              context, 
              title: 'Contact Information',
              child: _buildPhoneField(controller),
            ),
            
            const SizedBox(height: 16),
            
            _buildDetailCard(
              context, 
              title: 'Shop Description',
              child: _buildDescriptionField(controller),
            ),
            
            const SizedBox(height: 16),
            
            _buildDetailCard(
              context, 
              title: 'Service Modes',
              child: _buildServiceModes(controller),
            ),
            
            const SizedBox(height: 16),
            
            _buildDetailCard(
              context, 
              title: 'Operating Hours',
              child: _buildOperatingHours(controller),
            ),
            
            const SizedBox(height: 16),
            
            _buildDetailCard(
              context, 
              title: 'Location',
              child: _buildLocationSection(controller),
            ),
            
            // Edit/Save Button
            if (controller.isEditMode.value)
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: _buildSaveButton(controller),
              ),
          ],
        ),
      ),
    );
  }

Widget _buildDetailCard(BuildContext context, {
    required String title, 
    required Widget child
  }) {
    final theme = Theme.of(context);
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildShopImage(ShopDetailsController controller) {
    return Obx(() {
      final shop = controller.shopDetails.value;
      return Center(
        child: GestureDetector(
          onTap: controller.isEditMode.value ? controller.pickImage : null,
          child: Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[300], // Fallback background
              image: controller.shopImage.value != null
                  ? DecorationImage(
                      image: FileImage(controller.shopImage.value!),
                      fit: BoxFit.cover,
                    )
                  : (shop.image.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(shop.image),
                          fit: BoxFit.cover,
                        )
                      : null),
            ),
            child: controller.isEditMode.value
                ? const Icon(Icons.camera_alt, color: Colors.white, size: 50)
                : (shop.image.isEmpty ? Icon(Icons.camera_alt, color: Colors.grey[600], size: 50) : null),
          ),
        ),
      );
    });
  }

  Widget _buildNameField(ShopDetailsController controller) {
    return Obx(() => TextFormField(
          controller: controller.nameController,
          decoration: InputDecoration(
            labelText: 'Shop Name',
            enabled: controller.isEditMode.value,
          ),
          validator: (value) => 
            value == null || value.isEmpty ? 'Shop name is required' : null,
        ));
  }

  Widget _buildPhoneField(ShopDetailsController controller) {
    return Obx(() => TextFormField(
          controller: controller.phoneController,
          decoration: InputDecoration(
            labelText: 'Phone Number',
            enabled: controller.isEditMode.value,
          ),
          keyboardType: TextInputType.phone,
          validator: (value) => 
            value == null || value.isEmpty ? 'Phone number is required' : null,
        ));
  }

  Widget _buildDescriptionField(ShopDetailsController controller) {
    return Obx(() => TextFormField(
          controller: controller.descriptionController,
          decoration: InputDecoration(
            labelText: 'Shop Description',
            enabled: controller.isEditMode.value,
          ),
          maxLines: 3,
          validator: (value) => 
            value == null || value.isEmpty ? 'Description is required' : null,
        ));
  }

  Widget _buildServiceModes(ShopDetailsController controller) {
    return Obx(() {
      final isEditMode = controller.isEditMode.value;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Service Modes', 
            style: TextStyle(fontWeight: FontWeight.bold)
          ),
          if (!isEditMode)
            ...controller.shopDetails.value.modesOfService.map((mode) => ListTile(
              leading: Icon(
                mode == ModeOfService.home 
                  ? Icons.home 
                  : Icons.location_on
              ),
              title: Text(
                mode == ModeOfService.home 
                  ? 'Home Service' 
                  : 'On-site Service'
              ),
            )),
          if (isEditMode)
            ...ModeOfService.values.map((mode) => CheckboxListTile(
              title: Text(mode == ModeOfService.home ? 'Home Service' : 'On-site'),
              value: controller.selectedServiceModes.contains(mode),
              onChanged: (_) => controller.updateServiceModes(mode),
            )),
        ],
      );
    });
  }

  Widget _buildOperatingHours(ShopDetailsController controller) {
    return Obx(() {
      final isEditMode = controller.isEditMode.value;
      final operatingHours = controller.shopDetails.value.operatingHours ?? {};

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Operating Hours', 
            style: TextStyle(fontWeight: FontWeight.bold)
          ),
          if (!isEditMode)
            ...controller.weekdays.map((day) {
              final dayHours = operatingHours[day] ?? {};
              final startTime = dayHours['start'];
              final endTime = dayHours['end'];

              return ListTile(
                title: Text(day),
                trailing: Text(
                  startTime != null && endTime != null
                    ? '${_formatTime(startTime)} - ${_formatTime(endTime)}'
                    : 'Not Set',
                ),
              );
            }),
          if (isEditMode)
            ...controller.weekdays.map((day) => _buildOperatingHoursRow(controller, day)),
        ],
      );
    });
  }

  Widget _buildOperatingHoursRow(ShopDetailsController controller, String day) {
    return Obx(() {
      final dayHours = controller.operatingHours[day] ?? {};
      final startTime = dayHours['start'];
      final endTime = dayHours['end'];

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Expanded(flex: 2, child: Text(day)),
            Expanded(
              flex: 5,
              child: GestureDetector(
                onTap: () => controller.pickOperatingHours(day),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    startTime != null && endTime != null
                      ? '${_formatTime(startTime)} - ${_formatTime(endTime)}'
                      : 'Select Hours',
                    style: TextStyle(
                      color: startTime != null && endTime != null 
                        ? Colors.black 
                        : Colors.grey
                    ),
                  ),
                ),
              ),
            ),
            if (startTime != null && endTime != null)
              IconButton(
                icon: const Icon(Icons.clear, color: Colors.red),
                onPressed: () => controller.clearOperatingHours(day),
              ),
          ],
        ),
      );
    });
  }

  // Helper to format TimeOfDay to readable string
  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

Widget _buildLocationSection(ShopDetailsController controller) {
  return Obx(() {
    final isEditMode = controller.isEditMode.value;
    final selectedAddress = controller.selectedLocationAddress.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Location', 
          style: TextStyle(fontWeight: FontWeight.bold)
        ),
        
        // Location Search and Map in Edit Mode
        if (isEditMode) Column(
          children: [
            // Search bar for location
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller.searchLocationController,
                      decoration: InputDecoration(
                        hintText: 'Search for a location',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            controller.searchLocationController.clear();
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onSubmitted: (value) => controller.searchLocation(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: controller.searchLocation,
                    child: const Text('Search'),
                  ),
                ],
              ),
            ),

            // Google Map
            SizedBox(
              height: 250,
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: controller.selectedLocation.value ?? 
                          const LatLng(0, 0),
                  zoom: 15,
                ),
                markers: controller.mapMarkers,
                onMapCreated: controller.onMapCreated,
                onTap: controller.onMapTapped,
              ),
            ),

            // Location Actions
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    selectedAddress.isNotEmpty 
                      ? selectedAddress 
                      : 'No location selected',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton(
                        onPressed: controller.getCurrentLocation,
                        child: const Text('Use My Location'),
                      ),
                      if (controller.locationSuggestions.isNotEmpty)
                        ElevatedButton(
                          onPressed: controller.showLocationSuggestions,
                          child: const Text('Location Suggestions'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        )
        else 
          // Non-edit mode display
          Text(
            selectedAddress.isNotEmpty 
              ? selectedAddress 
              : 'Location not set',
            style: const TextStyle(color: Colors.grey),
          ),
      ],
    );
  });
}
  Widget _buildSaveButton(ShopDetailsController controller) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onPressed: controller.saveShopDetails,
      child: const Text(
        'Save Changes', 
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}