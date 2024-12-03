import 'package:domo/features/shop/controller/shop_onboarding_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:domo/features/shop/model/shop_model.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ShopOnboardingScreen extends StatelessWidget {
  const ShopOnboardingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ShopOnboardingController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Up Your Shop'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => controller.goToPreviousStep(),
        ),
      ),
      body: Obx(() {
        switch (controller.currentStep.value) {
          case OnboardingStep.shopInfo:
            return _buildShopInfoStep(controller);
          case OnboardingStep.serviceDetails:
            return _buildServiceDetailsStep(controller);
          case OnboardingStep.imageUpload:
            return _buildImageUploadStep(controller);
          default:
            return const Center(child: Text('Error in onboarding'));
        }
      }),
      bottomNavigationBar: _buildNavigationButtons(controller),
    );
  }

  Widget _buildShopInfoStep(ShopOnboardingController controller) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: controller.shopInfoFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: controller.nameController,
              decoration: const InputDecoration(
                labelText: 'Shop Name',
                hintText: 'Enter your shop name',
                prefixIcon: Icon(Icons.storefront),
              ),
              validator: (value) => 
                value == null || value.isEmpty ? 'Shop name is required' : null,
            ),
            const SizedBox(height: 16),
          SizedBox(
            height: 300, // Adjust height as needed
            child: _buildLocationSelectionStep(controller),
          ),
            const SizedBox(height: 16),
            TextFormField(
              controller: controller.phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                hintText: 'Contact number for your shop',
                prefixIcon: Icon(Icons.phone),
              ),
              validator: (value) => 
                _validatePhoneNumber(value) ? null : 'Invalid phone number',
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: controller.descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Shop Description',
                hintText: 'Tell us about your shop',
                prefixIcon: Icon(Icons.description),
              ),
              validator: (value) => 
                value == null || value.isEmpty ? 'Description is required' : null,
            ),
          ],
        ),
      ),
    );
  }

Widget _buildServiceDetailsStep(ShopOnboardingController controller) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Mode of Service',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Obx(() => Column(
            children: ModeOfService.values.map((mode) {
              return CheckboxListTile(
                title: Text(mode == ModeOfService.home ? 'Home Service' : 'On-site'),
                value: controller.selectedServiceModes.contains(mode),
                onChanged: (_) => controller.updateServiceModes(mode),
              );
            }).toList(),
          )),
          const SizedBox(height: 16),
          const Text(
            'Operating Hours',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          ...controller.weekdays.map((day) => _buildOperatingHoursRow(controller, day)),
        ],
      ),
    );
  }


  Widget _buildOperatingHoursRow(ShopOnboardingController controller, String day) {
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

  // location: location,
  Widget _buildLocationSelectionStep(ShopOnboardingController controller) {
  return Column(
    children: [
      // Search bar for location
      Padding(
        padding: const EdgeInsets.all(8.0),
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
      Expanded(
        child: GoogleMap(
          initialCameraPosition: const CameraPosition(
            target: LatLng(0, 0), // Default to a neutral location
            zoom: 15,
          ),
          onMapCreated: controller.onMapCreated,
          onTap: controller.onMapTapped,
          markers: controller.mapMarkers,
        ),
      ),
    Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text(
            controller.selectedLocationAddress.value,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8, // space between buttons
            runSpacing: 8, // space between rows if wrapped
            children: [
              ElevatedButton(
                onPressed: controller.getCurrentLocation,
                child: const Text('Use My Current Location'),
              ),
              if (controller.searchLocationSuggestions.isNotEmpty)
                ElevatedButton(
                  onPressed: () => controller.showLocationSuggestions(),
                  child: const Text('Location Suggestions'),
                ),
            ],
          ),
        ],
      ),
)    
],
  );
}

  // Helper to format TimeOfDay to readable string
  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  Widget _buildImageUploadStep(ShopOnboardingController controller) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Shop Image',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: controller.pickImage,
            child: Obx(() {
              final image = controller.shopImage.value;
              return Container(
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: image != null
                    ? Image.file(image, fit: BoxFit.cover)
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.cloud_upload, size: 50),
                          Text('Tap to upload shop image'),
                        ],
                      ),
              );
            }),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: controller.pickImage,
            child: const Text('Choose Image'),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons(ShopOnboardingController controller) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          controller.currentStep.value != OnboardingStep.shopInfo
              ? ElevatedButton(
                  onPressed: () => controller.goToPreviousStep(),
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all(Colors.grey),
                  ),
                  child: const Text('Previous'),
                )
              : const SizedBox.shrink(),
          ElevatedButton(
            onPressed: () => controller.goToNextStep(),
            child: Text(
              controller.currentStep.value == OnboardingStep.imageUpload 
                  ? 'Finish' 
                  : 'Next'
            ),
          ),
        ],
      ),
    );
  }

  // Phone number validation helper
  bool _validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) return false;
    // Add more robust phone validation if needed
    final phoneRegex = RegExp(r'^[0-9]{10}$');
    return phoneRegex.hasMatch(value);
  }
}