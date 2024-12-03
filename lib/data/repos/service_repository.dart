// service repository
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:domo/common/styles/dummydata.dart';
import 'package:domo/features/services/models/service_model.dart';
import 'package:domo/features/shop/model/sub_theme_model.dart';
import 'package:domo/features/shop/model/theme_model.dart';
import 'package:get/get.dart';


class ServiceRepository extends GetxService {
  static ServiceRepository get instance => Get.put(ServiceRepository());

  // variable to store the services
  final _db = FirebaseFirestore.instance;

  // get all services
  Future<List<ServicesModel>> getServices() async {
    try {
      final services = await _db.collection('services').get();
      return services.docs.map((e) => ServicesModel.fromSnapshot(e)).toList();
    } catch (e) {
      print('Error fetching services: $e');
      return [];
    }
  }

  // upload services to the firestore
  Future<void> uploadServices() async {
    try {
      // Reference to the services collection in Firestore
      final servicesCollection = _db.collection('services');

      // Iterate through the dummy services
      for (var service in DummyData.services) {
        // Upload each service to Firestore using toJson()
        await servicesCollection.doc(service.id).set(service.toJson());
      }

      print('Services uploaded successfully');
    } catch (e) {
      print('Error uploading services: $e');
    }
  }


  // fecth services by serviceId
Future<ServicesModel?> fetchServiceById(String serviceId) async {
  try {
    final serviceDoc = await _db.collection('services').doc(serviceId).get();
    
    if (serviceDoc.exists) {
      return ServicesModel.fromSnapshot(serviceDoc);
    }
    return null;
  } catch (e) {
    print('Error fetching service by ID: $e');
    return null;
  }
}


// functions for artisan services

 // Fetch all themes with their subthemes
  Future<List<ThemesModel>> getAllThemesWithSubthemes() async {
    try {
      // Fetch themes
      final themesQuery = await _db.collection('themes').get();
      
      List<ThemesModel> themes = themesQuery.docs
          .map((doc) => ThemesModel.fromSnapshot(doc))
          .toList();
      
      // Fetch subthemes for each theme
      for (var theme in themes) {
        final subthemesQuery = await _db
            .collection('subthemes')
            .where('themeId', isEqualTo: theme.id)
            .get();
        
        theme.subThemes = subthemesQuery.docs
            .map((doc) => SubThemesModel.fromSnapshot(doc))
            .toList();
      }
      
      return themes;
    } catch (e) {
      print('Error fetching themes with subthemes: $e');
      return [];
    }
  }

  // Fetch services with all themes with their subthemes
  Future<List<ServicesModel>> getServicesWithThemeDetails(String shopId) async {
    try {
      // Fetch services for the shop
      final servicesQuery = await _db
          .collection('services')
          .where('shopId', isEqualTo: shopId)
          .get();
      
      List<ServicesModel> services = servicesQuery.docs
          .map((doc) => ServicesModel.fromSnapshot(doc))
          .toList();
      
      // Fetch theme and subtheme details for each service
      for (var service in services) {
        // Fetch subtheme details
        if (service.subThemeId.isNotEmpty) {
          final subthemeDoc = await _db
              .collection('subthemes')
              .doc(service.subThemeId)
              .get();
          
          if (subthemeDoc.exists) {
            final subtheme = SubThemesModel.fromSnapshot(subthemeDoc);
            
            // Fetch theme details
            if (subtheme.themeId.isNotEmpty) {
              final themeDoc = await _db
                  .collection('themes')
                  .doc(subtheme.themeId)
                  .get();
              
              service.themeName = themeDoc.exists ? themeDoc['name'] : '';
              service.subThemeName = subtheme.name;
            }
          }
        }
      }
      
      return services;
    } catch (e) {
      print('Error fetching services with theme details: $e');
      return [];
    }
  }


// Fetch services by shopId
  Future<List<ServicesModel>> getServicesByShop(String shopId) async {
    try {
      final servicesQuery = await _db
          .collection('services')
          .where('shopId', isEqualTo: shopId)
          .get();
      
      return servicesQuery.docs
          .map((doc) => ServicesModel.fromSnapshot(doc))
          .toList();
    } catch (e) {
      print('Error fetching services for shop: $e');
      return [];
    }
  }


Future<String?> addService(ServicesModel service, {String? themeId, String? subthemeId}) async {
    try {
      // Validate theme and subtheme if provided
      if (themeId != null) {
        final themeDoc = await _db.collection('themes').doc(themeId).get();
        if (!themeDoc.exists) {
          print('Invalid theme ID');
          return null;
        }
      }

      if (subthemeId != null) {
        final subthemeDoc = await _db.collection('subthemes').doc(subthemeId).get();
        if (!subthemeDoc.exists) {
          print('Invalid subtheme ID');
          return null;
        }
        
        // Ensure subtheme belongs to the specified theme
        if (themeId != null && subthemeDoc['themeId'] != themeId) {
          print('Subtheme does not belong to the specified theme');
          return null;
        }
      }

      final docRef = await _db.collection('services').add(service.toJson());
      
      // Update the service's ID with the generated ID
      service.id = docRef.id;
      
      return docRef.id;
    } catch (e) {
      print('Error adding service with theme validation: $e');
      return null;
    }
  }

  // Update an existing service in Firestore
 Future<bool> updateService(ServicesModel service, {String? themeId, String? subthemeId}) async {
    try {
      // Validate theme and subtheme if provided
      if (themeId != null) {
        final themeDoc = await _db.collection('themes').doc(themeId).get();
        if (!themeDoc.exists) {
          print('Invalid theme ID');
          return false;
        }
      }

      if (subthemeId != null) {
        final subthemeDoc = await _db.collection('subthemes').doc(subthemeId).get();
        if (!subthemeDoc.exists) {
          print('Invalid subtheme ID');
          return false;
        }
        
        // Ensure subtheme belongs to the specified theme
        if (themeId != null && subthemeDoc['themeId'] != themeId) {
          print('Subtheme does not belong to the specified theme');
          return false;
        }
      }

      // Update service
      await _db
          .collection('services')
          .doc(service.id)
          .update(service.toJson());
      return true;
    } catch (e) {
      print('Error updating service with theme validation: $e');
      return false;
    }
  }
  // Delete a service from Firestore
  Future<bool> deleteService(String serviceId) async {
    try {
      await _db.collection('services').doc(serviceId).delete();
      return true;
    } catch (e) {
      print('Error deleting service: $e');
      return false;
    }
  }

  // get service name by serviceId
  Future<String?> getServiceName(String serviceId) async {
    try {
      final serviceDoc = await _db.collection('services').doc(serviceId).get();
      if (serviceDoc.exists) {
        return serviceDoc['name'];
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
      final servicesQuery = await _db
          .collection('services')
          .where('shopId', isEqualTo: shopId)
          .get();
      
      return servicesQuery.docs
          .map((doc) => ServicesModel.fromSnapshot(doc))
          .toList();
    } catch (e) {
      print('Error fetching services by shop ID: $e');
      return [];
    }
  }

  // get services by SUBthemeId
  Future<List<ServicesModel>> getServicesBySubthemeId(String subthemeId) async {
    try {
      final servicesQuery = await _db
          .collection('services')
          .where('subThemeId', isEqualTo: subthemeId)
          .get();
      
      return servicesQuery.docs
          .map((doc) => ServicesModel.fromSnapshot(doc))
          .toList();
    } catch (e) {
      print('Error fetching services by subtheme ID: $e');
      return [];
    }
  }
  








}