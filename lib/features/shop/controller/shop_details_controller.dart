import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:domo/data/repos/auth_repository.dart';
import 'package:domo/features/shop/controller/directions_controller.dart';
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

class ShopDetailsController extends GetxController {
  final ShopRepository _shopRepository = ShopRepository();
  final AuthenticationRepository _authRepository = AuthenticationRepository();
   final DirectionsController directionsController = Get.put(DirectionsController());

  // Observables for shop details and edit mode
  final Rx<ShopModel> shopDetails = ShopModel.empty().obs;
  final RxBool isEditMode = false.obs;
  final RxBool isMapVisible = false.obs;
  RxList<ShopModel> shops = <ShopModel>[].obs;
  RxBool isLoading = false.obs;

  // Form controllers for editable fields
  late TextEditingController nameController;
  late TextEditingController descriptionController;
  late TextEditingController phoneController;
  late TextEditingController locationController;
  final TextEditingController searchLocationController =
      TextEditingController();

  // Location-related observables
  final Rx<LatLng?> selectedLocation = Rx<LatLng?>(null);
  final RxString selectedLocationAddress = RxString('');
  final RxSet<Marker> mapMarkers = <Marker>{}.obs;
  GoogleMapController? _mapController;
  final RxList<String> locationSuggestions = <String>[].obs;

  // Image upload
  final Rx<File?> shopImage = Rx<File?>(null);

  // Service modes and operating hours
  final RxList<ModeOfService> selectedServiceModes = <ModeOfService>[].obs;
  final RxMap<String, Map<String, TimeOfDay>> operatingHours =
      <String, Map<String, TimeOfDay>>{}.obs;

  // Days of the week
  final List<String> weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  // Validation key
  final GlobalKey<FormState> editFormKey = GlobalKey<FormState>();

  @override
  void onInit() {
    super.onInit();
    _initializeControllers();
    // _fetchShopDetails();
    _fetchShopDetailsForCurrentUser();
    fetchShops();
    fetchShopDetailsById(shopDetails.value.id);

  }

  void _initializeControllers() {
    nameController = TextEditingController();
    descriptionController = TextEditingController();
    phoneController = TextEditingController();
    locationController = TextEditingController();
  }


  // Future<void> _fetchShopDetails() async {
  //   try {
  //     final currentUser = _authRepository.currentUser;
  //     if (currentUser != null) {
  //       final shop = await _shopRepository.fetchShopDetails(shopDetails.value.id);
  //       if (shop != null) {
  //         if (shop.id.isEmpty) {
  //           final shopDoc = await FirebaseFirestore.instance
  //               .collection('shops')
  //               .where('id', isEqualTo: shopDetails.value.id)
  //               .limit(1)
  //               .get();

  //           if (shopDoc.docs.isNotEmpty) {
  //             shop.id = shopDoc.docs.first.id;
  //           }
  //         }

  //         shopDetails.value = shop;
  //         _updateControllersWithShopData();
  //         _updateLocationDetails();
  //       }
  //     }
  //   } catch (e) {
  //     Get.snackbar('Error', 'Failed to fetch shop details');
  //   }
  // }

  void _updateControllersWithShopData() {
    nameController.text = shopDetails.value.name;
    descriptionController.text = shopDetails.value.description;
    phoneController.text = shopDetails.value.phoneNumber;

    // Update service modes
    selectedServiceModes.value = List.from(shopDetails.value.modesOfService);

    // Update operating hours
    operatingHours.value = Map.from(shopDetails.value.operatingHours ?? {});
  }

  void _updateLocationDetails() async {
    final location = shopDetails.value.location;
    try {
      // Convert GeoPoint to human-readable address
      List<Placemark> placemarks =
          await placemarkFromCoordinates(location.latitude, location.longitude);

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        selectedLocationAddress.value =
            '${placemark.street}, ${placemark.locality}, ${placemark.administrativeArea}, ${placemark.country}';
      }

      // Set location for map
      selectedLocation.value = LatLng(location.latitude, location.longitude);

      // Update map markers
      mapMarkers.value = {
        Marker(
          markerId: const MarkerId('shop_location'),
          position: selectedLocation.value!,
        )
      };
    } catch (e) {
      print('Error getting location details: $e');
    }
  }

  // Image picker
  Future<void> pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
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

    // Update operating hours
    operatingHours[day] = {'start': startTime, 'end': endTime};
    operatingHours.refresh();
  }

  // Clear operating hours for a day
  void clearOperatingHours(String day) {
    operatingHours[day] = {};
    operatingHours.refresh();
  }

  // Location selection
  Future<void> onMapTapped(LatLng position) async {
    // Add marker
    mapMarkers.value = {
      Marker(
        markerId: const MarkerId('selected_location'),
        position: position,
      )
    };

    // Get address
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);

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

  // Upload shop image
  Future<String?> _uploadShopImage() async {
    if (shopImage.value == null) return null;

    try {
      final fileName =
          'shop_images/${DateTime.now().millisecondsSinceEpoch}_${shopImage.value!.path.split('/').last}';
      final storageRef = FirebaseStorage.instance.ref().child(fileName);

      final uploadTask = await storageRef.putFile(shopImage.value!);

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

  void toggleEditMode() {
    isEditMode.toggle();
    if (!isEditMode.value) {
      // Reset controllers to original data when canceling edit
      _updateControllersWithShopData();
      shopImage.value = null;
    }
  }

  void toggleMapVisibility() {
    isMapVisible.toggle();
  }

  void onMapCreated(GoogleMapController controller) {
    _mapController = controller;

    // Animate camera to shop location if exists
    if (selectedLocation.value != null) {
      _mapController
          ?.animateCamera(CameraUpdate.newLatLng(selectedLocation.value!));
    }
  }

  Future<void> saveShopDetails() async {
    print('Shop ID before update: ${shopDetails.value.id}');
    print('Shop details before update: ${shopDetails.value.toJson()}');

    if (!editFormKey.currentState!.validate()) return;

    try {
      // Upload image if a new one is selected
      String? imageUrl;
      if (shopImage.value != null) {
        imageUrl = await _uploadShopImage();
        if (imageUrl == null) {
          Get.snackbar('Error', 'Image upload failed');
          return;
        }
      }

      // Validate location is selected
      if (selectedLocation.value == null) {
        Get.snackbar('Error', 'Please select a location');
        return;
      }

      // Create an updated shop model
      final updatedShop = shopDetails.value.copyWith(
          id: shopDetails.value.id,
          artisanId: shopDetails.value.artisanId,
          name: nameController.text,
          description: descriptionController.text,
          phoneNumber: phoneController.text,
          image: imageUrl ?? shopDetails.value.image,
          location: GeoPoint(selectedLocation.value!.latitude,
              selectedLocation.value!.longitude),
          modesOfService: selectedServiceModes,
          operatingHours: Map.from(operatingHours));

      // Update shop in repository
      await _shopRepository.updateShop(updatedShop);

      // Update local shop details and exit edit mode
      shopDetails.value = updatedShop;
      isEditMode.value = false;
      shopImage.value = null;

      Get.snackbar('Success', 'Shop details updated');
    } catch (e) {
      Get.snackbar('Error', 'Failed to update shop details: $e');
    }
  }

  // location search stuff
  void searchLocation() async {
    final query = searchLocationController.text.trim();
    if (query.isEmpty) {
      Get.snackbar('Error', 'Please enter a location');
      return;
    }

    try {
      // Use geocoding to convert address to coordinates
      List<Location> locations = await locationFromAddress(query);

      if (locations.isNotEmpty) {
        final firstLocation = locations.first;
        final newLocation =
            LatLng(firstLocation.latitude, firstLocation.longitude);

        // Update map markers and selected location
        mapMarkers.value = {
          Marker(
            markerId: const MarkerId('searched_location'),
            position: newLocation,
          )
        };

        // Get placemark details for address
        List<Placemark> placemarks = await placemarkFromCoordinates(
            firstLocation.latitude, firstLocation.longitude);

        if (placemarks.isNotEmpty) {
          final placemark = placemarks.first;
          selectedLocationAddress.value =
              '${placemark.street}, ${placemark.locality}, ${placemark.administrativeArea}, ${placemark.country}';
        }

        // Update selected location and animate camera
        selectedLocation.value = newLocation;
        _mapController?.animateCamera(CameraUpdate.newLatLng(newLocation));

        //  Generate nearby location suggestions
        _generateLocationSuggestions(newLocation);
      } else {
        Get.snackbar('Error', 'Location not found');
      }
    } catch (e) {
      print('Location search error: $e');
      Get.snackbar('Error', 'Could not find location');
    }
  }

  void _generateLocationSuggestions(LatLng location) {
    // This is a placeholder. In a real app, you'd use Google Places API
    // or another service to generate nearby location suggestions
    locationSuggestions.value = [
      '${location.latitude}, ${location.longitude} - Nearby Place 1',
      '${location.latitude}, ${location.longitude} - Nearby Place 2',
      '${location.latitude}, ${location.longitude} - Nearby Place 3',
    ];
  }

  void getCurrentLocation() async {
    try {
      // Use geolocator package to get current location
      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      final newLocation = LatLng(position.latitude, position.longitude);

      // Update map markers
      mapMarkers.value = {
        Marker(
          markerId: const MarkerId('current_location'),
          position: newLocation,
        )
      };

      // Get placemark details
      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        selectedLocationAddress.value =
            '${placemark.street}, ${placemark.locality}, ${placemark.administrativeArea}, ${placemark.country}';
      }

      // Update selected location and animate camera
      selectedLocation.value = newLocation;
      _mapController?.animateCamera(CameraUpdate.newLatLng(newLocation));

      // Generate nearby suggestions
      _generateLocationSuggestions(newLocation);
    } catch (e) {
      print('Error getting current location: $e');
      Get.snackbar('Error', 'Could not get current location');
    }
  }

  void showLocationSuggestions() {
    if (locationSuggestions.isEmpty) {
      Get.snackbar('Info', 'No location suggestions available');
      return;
    }

    // Show bottom sheet or dialog with location suggestions
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Location Suggestions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...locationSuggestions
                .map((suggestion) => ListTile(
                      title: Text(suggestion),
                      onTap: () {
                        // Parse and use the suggestion
                        Get.back(); // Close bottom sheet
                      },
                    ))
                .toList(),
          ],
        ),
      ),
      backgroundColor: Colors.transparent,
    );
  }


   void showDirectionsToShop() async {
    try {
      // Check if location is selected
      if (selectedLocation.value == null) {
        Get.snackbar('Error', 'Shop location not available');
        return;
      }

      // Get directions
      await directionsController.getDirections(
        destination: selectedLocation.value!
      );

      // Show bottom sheet with route details
      Get.bottomSheet(
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Directions to Shop',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Get.back(); // Close bottom sheet
                },
                child: const Text('Close Directions'),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      Get.snackbar('Error', 'Could not get directions');
    }
  }

    // get shop name by shop ID
Future<String?> getShopNameById(String shopId) async {
    try {
      print('Requested Shop ID: $shopId');
      final shopName = await _shopRepository.getShopName(shopId);
      print('Retrieved Shop Name: $shopName');
      print('Service Shop ID: $shopId');
      
      return shopName; 
    } catch (e) {
      print('Error getting shop name: $e');
      return null;
    }
}

// fetch shop details by shop ID
Future<ShopModel?> fetchShopDetailsById(String shopId) async {
 try {
   final shop = await _shopRepository.fetchShopDetailsById(shopId);
   
   if (shop != null) {
     if (shop.id.isEmpty) {
       final shopDoc = await FirebaseFirestore.instance
           .collection('shops')
           .where('id', isEqualTo: shopId)
           .limit(1)
           .get();

       if (shopDoc.docs.isNotEmpty) {
         shop.id = shopDoc.docs.first.id;
       }
     }

     return shop;
   }
   
   return null;
 } catch (e) {
   print('Shop details fetch error: $e');
   return null;
 }
}

Future<void> _fetchShopDetailsForCurrentUser() async {
  try {
    final currentUser = _authRepository.currentUser;
    if (currentUser != null) {
      // Fetch shop by artisan ID instead of relying on an existing shop ID
      final shop = await _shopRepository.fetchShopByArtisanId(currentUser.uid);
      
      if (shop != null) {
        shopDetails.value = shop;
        _updateControllersWithShopData();
        _updateLocationDetails();
      } else {
        print('No shop found for current artisan');
      }
    }
  } catch (e) {
    print('Error fetching shop details: $e');
    Get.snackbar('Error', 'Failed to fetch shop details');
  }
}

// fetch shops
Future<void> fetchShops() async {
    try {
      isLoading.value = true;
      final fetchedShops = await _shopRepository.fetchShops();
      
      print('Fetched shops count: ${fetchedShops.length}');
      if (fetchedShops.isEmpty) {
        print('Shops list is empty. Check Firestore collection and data.');
      }
      
      shops.assignAll(fetchedShops);
    } catch (e) {
      print('Error fetching shops in controller: $e');
      shops.clear();
    } finally {
      isLoading.value = false;
    }
  }  

  // initialize map
LatLng? getShopGeoPoints(ShopModel shopDetails) {
  if (shopDetails.location.latitude != null && shopDetails.location.longitude != null) {
    return LatLng(shopDetails.location.latitude!, shopDetails.location.longitude!);
  }
  return null;
}

Future<String> getReadableAddress(double latitude, double longitude) async {
  try {
    List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
    
    if (placemarks.isNotEmpty) {
      Placemark place = placemarks.first;
      return '${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.country}';
    }
  } catch (e) {
    print('Error getting readable address: $e');
  }
  
  return 'Address not available';
}

// Usage in controller
Future<void> convertLocationToAddress() async {
  if (selectedLocation.value != null) {
    selectedLocationAddress.value = await getReadableAddress(
      selectedLocation.value!.latitude, 
      selectedLocation.value!.longitude
    );
  }
}


  
  //  the map creation to include polylines
  Widget buildDirectionsMap() {
    return Obx(() => GoogleMap(
      initialCameraPosition: CameraPosition(
        target: selectedLocation.value ?? const LatLng(0, 0),
        zoom: 15,
      ),
      markers: mapMarkers,
      polylines: directionsController.polylines,
      onMapCreated: onMapCreated,
    ));
  }


  @override
  void onClose() {
    nameController.dispose();
    descriptionController.dispose();
    phoneController.dispose();
    locationController.dispose();
    searchLocationController.dispose();
    super.onClose();
  }
}
