// service controller
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:domo/common/styles/dummydata.dart';
import 'package:domo/data/repos/service_repository.dart';
import 'package:domo/features/services/models/service_model.dart';
import 'package:domo/features/shop/model/sub_theme_model.dart';
import 'package:domo/features/shop/model/theme_model.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';

class ServiceController extends GetxController {
  static ServiceController get instance => Get.put(ServiceController());
  RxList<ServicesModel> services = <ServicesModel>[].obs;
  final RxList<ThemesModel> themes = <ThemesModel>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchServices();
  }

  // fetch all services
  Future<void> fetchServices() async {
    try {
      isLoading(true);
      final servicesList = await ServiceRepository.instance.getServices();
      if (servicesList.isNotEmpty) {
        services.assignAll(servicesList);
      }
    } catch (e) {
      print('Error fetching services: $e');
    } finally {
      isLoading(false);
    }
  }

  // fetch services by subthemeId
  Future<void> fetchServicesBySubThemeId() async {
    try {
      isLoading(true);
      final servicesList = await ServiceRepository.instance.getServices();
      if (servicesList.isNotEmpty) {
        services.assignAll(servicesList);
      }
    } catch (e) {
      print('Error fetching services by subthemeId: $e');
    } finally {
      isLoading(false);
    }
  }

  // upload services to the firestore
  Future<void> uploadServicesToFirestore() async {
    try {
      isLoading.value = true;

      final firestore = FirebaseFirestore.instance;
      final servicesCollection = firestore.collection('services');
      WriteBatch batch = firestore.batch();

      for (var service in DummyData.services) {
        DocumentReference docRef = servicesCollection.doc(service.id);
        batch.set(docRef, service.toJson(), SetOptions(merge: true));
        print(
            'Preparing to upload service: ${service.serviceName} with ID: ${service.id}');
      }

      await batch.commit();
      await fetchServices();

      Get.snackbar(
        'Success',
        '${DummyData.services.length} Services uploaded successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      print('Services upload completed successfully');
    } catch (e, stackTrace) {
      print('Error uploading services: $e');
      print('Stack trace: $stackTrace');
    } finally {
      isLoading.value = false;
    }
  }

  // fetch service by serviceId
  Future<ServicesModel?> fetchServiceById(String serviceId) async {
    try {
      // First, check if the service is already in the local services list
      final localService = services.firstWhere(
        (service) => service.id == serviceId,
        orElse: () => ServicesModel.empty(),
      );

      if (localService.id.isNotEmpty) {
        return localService;
      }

      // If not found locally, fetch from repository
      final service =
          await ServiceRepository.instance.fetchServiceById(serviceId);

      return service;
    } catch (e) {
      print('Error fetching service by ID: $e');
      return null;
    }
  }

// services functions for
  // Method to convert GeoPoint to human-readable address
  Future<String> convertGeoPointToAddress(GeoPoint geoPoint) async {
    try {
      // Use geocoding to convert coordinates to readable address
      List<Placemark> placemarks =
          await placemarkFromCoordinates(geoPoint.latitude, geoPoint.longitude);

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];

        // Construct a readable address string
        return '${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.country}';
      }

      // Fallback to coordinate string if conversion fails
      return '${geoPoint.latitude}, ${geoPoint.longitude}';
    } catch (e) {
      print('Error converting GeoPoint to address: $e');
      // Fallback to coordinate string
      return '${geoPoint.latitude}, ${geoPoint.longitude}';
    }
  }

  // When creating or updating a service
  Future<ServicesModel> prepareServiceWithLocation(
      ServicesModel service, GeoPoint shopLocation) async {
    // Convert shop's GeoPoint to human-readable address
    service.location = await convertGeoPointToAddress(shopLocation);
    return service;
  }

  Future<void> fetchThemesWithSubthemes() async {
    try {
      isLoading(true);
      final fetchedThemes =
          await ServiceRepository.instance.getAllThemesWithSubthemes();
      themes.assignAll(fetchedThemes);
    } catch (e) {
      print('Error fetching themes: $e');
      Get.snackbar('Error', 'Unable to fetch themes',
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading(false);
    }
  }

// fetch services
  Future<void> fetchServicesForArtisn(String shopId) async {
    try {
      isLoading(true);

      // Ensure themes are loaded
      if (themes.isEmpty) {
        await fetchThemesWithSubthemes();
      }

      final servicesList =
          await ServiceRepository.instance.getServicesWithThemeDetails(shopId);

      if (servicesList.isNotEmpty) {
        services.assignAll(servicesList);
      } else {
        services.clear();
      }
    } catch (e) {
      print('Error fetching services: $e');
      Get.snackbar('Error', 'Unable to fetch services',
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading(false);
    }
  }

// add service
  Future<bool> createService(ServicesModel service,
      {String? themeId, String? subthemeId}) async {
    try {
      isLoading(true);

      // Validate service data
      if (!_validateServiceData(service)) {
        return false;
      }

      // If subthemeId is provided, validate it against themes
      if (subthemeId != null) {
        final selectedSubtheme = _findSubtheme(subthemeId);
        if (selectedSubtheme == null) {
          Get.snackbar('Error', 'Invalid subtheme selected',
              backgroundColor: Colors.red, colorText: Colors.white);
          return false;
        }

        // Set subtheme and theme IDs
        service.subThemeId = subthemeId;
      }

      final serviceId = await ServiceRepository.instance
          .addService(service, themeId: themeId, subthemeId: subthemeId);

      if (serviceId != null) {
        service.id = serviceId;
        services.add(service);

        Get.snackbar('Success', 'Service created successfully',
            backgroundColor: Colors.green, colorText: Colors.white);
        return true;
      }
      return false;
    } catch (e) {
      print('Error creating service: $e');
      Get.snackbar('Error', 'Failed to create service',
          backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    } finally {
      isLoading(false);
    }
  }

  // Update an existing service with theme validation
  Future<bool> updateService(ServicesModel service,
      {String? themeId, String? subthemeId}) async {
    try {
      isLoading(true);

      // Validate service data
      if (!_validateServiceData(service)) {
        return false;
      }

      // If subthemeId is provided, validate it against themes
      if (subthemeId != null) {
        final selectedSubtheme = _findSubtheme(subthemeId);
        if (selectedSubtheme == null) {
          Get.snackbar('Error', 'Invalid subtheme selected',
              backgroundColor: Colors.red, colorText: Colors.white);
          return false;
        }

        // Set subtheme and theme IDs
        service.subThemeId = subthemeId;
      }

      final success = await ServiceRepository.instance
          .updateService(service, themeId: themeId, subthemeId: subthemeId);

      if (success) {
        // Update local list
        final index = services.indexWhere((s) => s.id == service.id);
        if (index != -1) {
          services[index] = service;
        }

        Get.snackbar('Success', 'Service updated successfully',
            backgroundColor: Colors.green, colorText: Colors.white);
        return true;
      }
      return false;
    } catch (e) {
      print('Error updating service: $e');
      Get.snackbar('Error', 'Failed to update service',
          backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    } finally {
      isLoading(false);
    }
  }

  // Helper method to find a subtheme by ID
  SubThemesModel? _findSubtheme(String subthemeId) {
    for (var theme in themes) {
      final subtheme = theme.subThemes.firstWhere((sub) => sub.id == subthemeId,
          orElse: () => SubThemesModel(id: '', name: '', themeId: ''));

      if (subtheme.id.isNotEmpty) {
        return subtheme;
      }
    }
    return null;
  }

// Delete a service
  Future<bool> deleteService(String serviceId) async {
    try {
      isLoading(true);

      final success = await ServiceRepository.instance.deleteService(serviceId);

      if (success) {
        // Remove from local list
        services.removeWhere((service) => service.id == serviceId);

        Get.snackbar('Success', 'Service deleted successfully',
            backgroundColor: Colors.green, colorText: Colors.white);
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting service: $e');
      Get.snackbar('Error', 'Failed to delete service',
          backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    } finally {
      isLoading(false);
    }
  }

  // Data validation method
  bool _validateServiceData(ServicesModel service) {
    if (service.serviceName.isEmpty) {
      Get.snackbar('Validation Error', 'Service name is required',
          backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }

    if (service.price <= 0) {
      Get.snackbar('Validation Error', 'Price must be greater than zero',
          backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }

    return true;
  }

  // get service name by serviceId
  Future<String?> getServiceName(String serviceId) async {
    try {
      final serviceDoc =
          await ServiceRepository.instance.getServiceName(serviceId);
      if (serviceDoc != null) {
        return serviceDoc;
      }
      return null;
    } catch (e) {
      print('Error fetching service name: $e');
      return null;
    }
  }

  // get services by shopId
  Future<List<ServicesModel>> getServicesByShopId(String shopId) async {
    try {
      final servicesList =
          await ServiceRepository.instance.getServicesByShopId(shopId);
      return servicesList;
    } catch (e) {
      print('Error fetching services by shop ID: $e');
      return [];
    }
  }
  // get services by SUBthemeId
  Future<List<ServicesModel>> getServicesBySubThemeId(String subThemeId) async {
    try {
      final servicesList =
          await ServiceRepository.instance.getServicesBySubthemeId(subThemeId);
      return servicesList;
    } catch (e) {
      print('Error fetching services by subtheme ID: $e');
      return [];
    }
  }

}
