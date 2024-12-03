import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:domo/data/repos/auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:domo/features/shop/model/shop_model.dart';
import 'package:domo/data/repos/shop_repository.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

enum OnboardingStep { shopInfo, serviceDetails, imageUpload }

class ShopOnboardingController extends GetxController {
  final ShopRepository _shopRepository = ShopRepository();

  // Form Keys
  final GlobalKey<FormState> shopInfoFormKey = GlobalKey<FormState>();

  // Text Controllers
  final nameController = TextEditingController();
  final locationController = TextEditingController();
  final phoneController = TextEditingController();
  final descriptionController = TextEditingController();

  // Cool variables
  final Rx<OnboardingStep> currentStep = OnboardingStep.shopInfo.obs;
  final RxList<ModeOfService> selectedServiceModes = <ModeOfService>[].obs;
  final Rx<File?> shopImage = Rx<File?>(null);
  final AuthenticationRepository _auth = Get.find<AuthenticationRepository>();

   // Map Observables
  final Rx<LatLng?> selectedLocation = Rx<LatLng?>(null);
  final RxString selectedLocationAddress = RxString('Select a location on the map');
  final RxSet<Marker> mapMarkers = <Marker>{}.obs;
  GoogleMapController? _mapController;
  final searchLocationController = TextEditingController();
  final RxList<Map<String, dynamic>> searchLocationSuggestions = <Map<String, dynamic>>[].obs;

  // Map Created Callback
  void onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  //  selected location
  Future<void> onMapTapped(LatLng position) async {
    // Add marker
    mapMarkers.value = {
      Marker(
        markerId: MarkerId('selected_location'),
        position: position,
      )
    };

    // Get address
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude, 
        position.longitude
      );
      
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        selectedLocationAddress.value = 
          '${placemark.street}, ${placemark.locality}, ${placemark.administrativeArea}, ${placemark.country}';
      }

      selectedLocation.value = position;
    } catch (e) {
      print('Error getting location details: $e');
    }
  }

  // Get current location
  Future<void> getCurrentLocation() async {
    try {
      // Check permissions first
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.always || 
          permission == LocationPermission.whileInUse) {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high
        );

        LatLng currentPosition = LatLng(
          position.latitude, 
          position.longitude
        );

        // Update map and markers
        onMapTapped(currentPosition);

        // Move camera if map controller exists
        _mapController?.animateCamera(
          CameraUpdate.newLatLng(currentPosition)
        );
      }
    } catch (e) {
      print('Location error: $e');
      Get.snackbar('Error', 'Could not get current location');
    }
  }

    // search for locations
  Future<void> searchLocation() async {
    final query = searchLocationController.text.trim();
    if (query.isEmpty) return;

    try {
      // Use geocoding to convert address to coordinates
      List<Location> locations = await locationFromAddress(query);
      
      if (locations.isNotEmpty) {
        final firstLocation = locations.first;
        final position = LatLng(firstLocation.latitude, firstLocation.longitude);
        
        // Update map with searched location
        await onMapTapped(position);

        // Optionally get nearby locations as suggestions
        await _getNearbySuggestions(position);
      } else {
        Get.snackbar('Error', 'Location not found');
      }
    } catch (e) {
      print('Location search error: $e');
      Get.snackbar('Error', 'Could not find location');
    }
  }

  // Get nearby location suggestions
  Future<void> _getNearbySuggestions(LatLng position) async {
    try {
      // Use geocoding to get nearby placemarks
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude, 
        position.longitude
      );

      // Convert placemarks to a list of suggestions
      searchLocationSuggestions.value = placemarks.map((placemark) {
        return {
          'name': '${placemark.name ?? ''}, ${placemark.locality ?? ''}, ${placemark.country ?? ''}',
          'latitude': position.latitude,
          'longitude': position.longitude,
        };
      }).toList();
    } catch (e) {
      print('Nearby suggestions error: $e');
    }
  }

  // Show location suggestions in a bottom sheet
  void showLocationSuggestions() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Location Suggestions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: searchLocationSuggestions.length,
                itemBuilder: (context, index) {
                  final suggestion = searchLocationSuggestions[index];
                  return ListTile(
                    title: Text(suggestion['name']),
                    onTap: () {
                      // Use the selected suggestion
                      final position = LatLng(
                        suggestion['latitude'], 
                        suggestion['longitude']
                      );
                      onMapTapped(position);
                      Get.back(); // Close bottom sheet
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  
  //  to match ShopModel's expected type
  final RxMap<String, Map<String, TimeOfDay>> operatingHours = 
    <String, Map<String, TimeOfDay>>{}.obs;
  
  final RxBool isLoading = false.obs;

  // Days of the week for operating hours
  final List<String> weekdays = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 
    'Friday', 'Saturday', 'Sunday'
  ];

  // Navigation Methods
  void goToNextStep() {
    switch (currentStep.value) {
      case OnboardingStep.shopInfo:
        if (!shopInfoFormKey.currentState!.validate()) return;
        currentStep.value = OnboardingStep.serviceDetails;
        break;
      case OnboardingStep.serviceDetails:
        // Validate at least one mode of service and one day of operating hours
        if (_validateServiceAndHours()) {
          currentStep.value = OnboardingStep.imageUpload;
        }
        break;
      case OnboardingStep.imageUpload:
        _submitShopSetup();
        break;
    }
  }

  // Validate service modes and operating hours
  bool _validateServiceAndHours() {
    // Check if at least one mode of service is selected
    if (selectedServiceModes.isEmpty) {
      Get.snackbar('Error', 'Please select at least one service mode');
      return false;
    }

    // Check if at least one day has operating hours
    bool hasOperatingHours = operatingHours.values.any(
      (dayHours) => 
        dayHours['start'] != null && dayHours['end'] != null
    );

    if (!hasOperatingHours) {
      Get.snackbar('Error', 'Please specify operating hours for at least one day');
      return false;
    }

    return true;
  }

  void goToPreviousStep() {
    switch (currentStep.value) {
      case OnboardingStep.shopInfo:
        Get.back(); // Return to previous screen
        break;
      case OnboardingStep.serviceDetails:
        currentStep.value = OnboardingStep.shopInfo;
        break;
      case OnboardingStep.imageUpload:
        currentStep.value = OnboardingStep.serviceDetails;
        break;
    }
  }

  // Image picker
  Future<void> pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      shopImage.value = File(pickedFile.path);
    }
  }

  // Update service modes
  void updateServiceModes(ModeOfService mode) {
    if (selectedServiceModes.contains(mode)) {
      selectedServiceModes.remove(mode);
    } else {
      selectedServiceModes.add(mode);
    }
  }

  // Update operating hours with time picker
  Future<void> pickOperatingHours(String day) async {
    // Pick start time
    final startTime = await showTimePicker(
      context: Get.context!,
      initialTime: TimeOfDay.now(),
      helpText: 'Select Start Time for $day',
    );

    if (startTime == null) return;

    // Pick end time
    final endTime = await showTimePicker(
      context: Get.context!,
      initialTime: TimeOfDay.now(),
      helpText: 'Select End Time for $day',
    );

    if (endTime == null) return;

    // Update operating hours - note the direct assignment
    operatingHours[day] = {
      'start': startTime,
      'end': endTime
    };
    operatingHours.refresh();
  }

  // Clear operating hours for a day
  void clearOperatingHours(String day) {
    operatingHours[day] = {
      'start': TimeOfDay(hour: 0, minute: 0),
      'end': TimeOfDay(hour: 0, minute: 0)
    };
    operatingHours.refresh();
  }

  // Upload shop image
Future<String?> _uploadShopImage() async {
  if (shopImage.value == null) return null;

  try {
    final fileName = 'shop_images/${DateTime.now().millisecondsSinceEpoch}_${shopImage.value!.path.split('/').last}';
    final storageRef = FirebaseStorage.instance.ref().child(fileName);
    
    // Use putFile with compression or metadata if needed
    final uploadTask = await storageRef.putFile(shopImage.value!);
    
    // Check upload status
    if (uploadTask.state == TaskState.success) {
      return await storageRef.getDownloadURL();
    } else {
      Get.snackbar('Error', 'Image upload failed');
      return null;
    }
  } catch (e) {
    print('Image upload error: $e');
    Get.snackbar('Error', 'Could not upload image: ${e.toString()}');
    return null;
  }
}
  // Submit shop setup
  Future<void> _submitShopSetup() async {
    try {
      isLoading.value = true;

          // Validate location is selected
    if (selectedLocation.value == null) {
      Get.snackbar('Error', 'Please select a location');
      return;
    }

      
      // Validate location is selected
      if (selectedLocation.value == null) {
        Get.snackbar('Error', 'Please select a location');
        return;
      }
      
      // Upload image if selected
      final imageUrl = await _uploadShopImage();

      if (shopImage.value != null && imageUrl == null) {
      Get.snackbar('Error', 'Image upload failed. Please try again.');
      return;
    }

      // Create shop model
      final shop = ShopModel(
        id: '', 
        artisanId: _auth.currentUser!.uid, 
        name: nameController.text,
        location: GeoPoint(
          selectedLocation.value!.latitude, 
          selectedLocation.value!.longitude
        ),
        phoneNumber: phoneController.text,
        description: descriptionController.text,
        image: imageUrl ?? '',
        rating: 0.0, // Initial rating
        modesOfService: selectedServiceModes,
        operatingHours: Map.from(operatingHours), // Convert RxMap to regular Map
      );

      // Create shop in repository
        final shopId = await _shopRepository.createShop(shop);

        print('Shop Created Successfully');
        print('Shop ID: $shopId');

      // Navigate to home screen
      Get.offAllNamed('/artisan/navBar');
    } catch (e) {
      Get.snackbar('Error', 'Failed to create shop: $e');
    } finally {
      isLoading.value = false;
    }
  }
  // Get shop ID
  Future<String?> getShopId() async {
    try {
      final shop = await _shopRepository.getShopByArtisanId(_auth.currentUser!.uid);
      return shop?.id;
    } catch (e) {
      print('Error getting shop ID: $e');
      return null;
    }
  }

  // get shop name
  Future<String?> getShopName() async {
    try {
      final shop = await _shopRepository.getShopByArtisanId(_auth.currentUser!.uid);
      return shop?.name;
    } catch (e) {
      print('Error getting shop name: $e');
      return null;
    }
  }






  @override
  void onClose() {
    // Clean up controllers
    nameController.dispose();
    locationController.dispose();
    phoneController.dispose();
    descriptionController.dispose();
    searchLocationController.dispose();
    super.onClose();
  }
}