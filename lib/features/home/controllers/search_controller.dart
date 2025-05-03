import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:domo/features/services/models/service_model.dart';
import 'package:domo/features/shop/model/shop_model.dart';
import 'package:domo/features/shop/model/theme_model.dart';
import 'package:domo/features/shop/model/sub_theme_model.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:async';

class SearchController extends GetxController {
  static SearchController get instance => Get.put(SearchController());

  // Search query and results
  final searchQuery = ''.obs;
  final RxList<dynamic> searchResults = <dynamic>[].obs;
  final isLoading = false.obs;
  final isFilterDrawerOpen = false.obs;

  // Debounce timer for search delay
  Timer? _debounceTimer;

  // Filters
  final shopNameFilter = ''.obs;
  final RxList<String> selectedServices = <String>[].obs;
  final RxList<String> selectedThemes = <String>[].obs;
  final RxList<String> selectedSubThemes = <String>[].obs;
  final selectedRegion = ''.obs;
  final selectedCity = ''.obs;
  final minRating = 0.0.obs;
  final RxDouble minPrice = 0.0.obs;
  final RxDouble maxPrice = 5000.0.obs; // Default max price
  final RxList<String> regions = <String>[].obs;
  final RxList<String> cities = <String>[].obs;

  // Cache for location data to reduce geocoding API calls
  final Map<String, Map<String, String>> _locationCache = {};

  // Services, themes, and subthemes for filter options
  final RxList<ServicesModel> availableServices = <ServicesModel>[].obs;
  final RxList<ThemesModel> availableThemes = <ThemesModel>[].obs;
  final RxList<SubThemesModel> availableSubThemes = <SubThemesModel>[].obs;
  
  // Map of subtheme ID to theme ID for quick lookup
  final Map<String, String> _subthemeToThemeMap = {};
  // Map theme IDs to theme names for lookup
  final Map<String, String> _themeIdToNameMap = {};
  // Map to store all subthemes for a theme
  final Map<String, List<String>> _themeToSubthemesMap = {};

  // Search types
  final searchType = 'all'.obs; // 'all', 'services', 'shops'

  @override
  void onInit() {
    super.onInit();
    fetchFilterData();
  }

  @override
  void onClose() {
    _debounceTimer?.cancel();
    super.onClose();
  }

  // Fetch all necessary data for filters
  Future<void> fetchFilterData() async {
    try {
      isLoading(true);

      // Fetch services for service filter
      await fetchAvailableServices();

      // Fetch themes and subthemes for theme filter
      await fetchThemesAndSubthemes();

      // Fetch regions and cities for location filter
      await fetchLocations();

      // Fetch price range
      await fetchPriceRange();
    } catch (e) {
      print('Error fetching filter data: $e');
      Get.snackbar(
        'Error',
        'Failed to load filter data.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading(false);
    }
  }

  // Fetch available services for the service filter
  Future<void> fetchAvailableServices() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final servicesSnapshot = await firestore.collection('services').get();

      final services = servicesSnapshot.docs
          .map((doc) => ServicesModel.fromSnapshot(doc))
          .toList();

      availableServices.assignAll(services);
    } catch (e) {
      print('Error fetching services: $e');
    }
  }

  // Fetch themes and subthemes for the theme filter
  Future<void> fetchThemesAndSubthemes() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final themesSnapshot = await firestore.collection('themes').get();

      final List<ThemesModel> themes = [];
      final List<SubThemesModel> subThemes = [];

      // Clear mappings before populating
      _subthemeToThemeMap.clear();
      _themeIdToNameMap.clear();
      _themeToSubthemesMap.clear();

      for (var themeDoc in themesSnapshot.docs) {
        final themeData = themeDoc.data();

        // Create theme
        final theme = ThemesModel(
          id: themeDoc.id,
          name: themeData['name'] ?? '',
          image: themeData['image'] ?? '',
          isFeatured: themeData['isFeatured'] ?? false,
        );
        
        // Add theme ID to name mapping
        _themeIdToNameMap[theme.id] = theme.name;
        
        // Initialize subthemes list for this theme
        _themeToSubthemesMap[theme.id] = [];

        // Fetch subthemes for this theme
        final subthemesSnapshot = await firestore
            .collection('themes')
            .doc(themeDoc.id)
            .collection('subThemes')
            .get();

        for (var subthemeDoc in subthemesSnapshot.docs) {
          final subthemeData = subthemeDoc.data();

          final subTheme = SubThemesModel(
            id: subthemeDoc.id,
            name: subthemeData['name'] ?? '',
            themeId: themeDoc.id,
          );

          theme.subThemes.add(subTheme);
          subThemes.add(subTheme);
          
          // Update mappings for quick lookups
          _subthemeToThemeMap[subTheme.id] = theme.id;
          _themeToSubthemesMap[theme.id]?.add(subTheme.id);
        }

        themes.add(theme);
      }

      print('Fetched ${themes.length} themes and ${subThemes.length} subthemes');
      print('Theme to subthemes map: $_themeToSubthemesMap');

      availableThemes.assignAll(themes);
      availableSubThemes.assignAll(subThemes);
    } catch (e) {
      print('Error fetching themes and subthemes: $e');
    }
  }

  // Fetch regions and cities for location filter
  Future<void> fetchLocations() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final shopsSnapshot = await firestore.collection('shops').get();

      final Set<String> uniqueRegions = {};
      final Set<String> uniqueCities = {};

      for (var shopDoc in shopsSnapshot.docs) {
        final shopData = shopDoc.data();
        final shopModel = ShopModel.fromSnapshot(shopDoc);

        if (shopModel.location != null) {
          try {
            // Store raw location data from Firestore for debugging
            print('Shop ${shopModel.name} location: ${shopModel.location.latitude}, ${shopModel.location.longitude}');
            
            final locationInfo = await _getLocationInfoFromCoordinates(
              shopModel.location.latitude,
              shopModel.location.longitude,
            );

            final region = locationInfo['region'] ?? '';
            final city = locationInfo['city'] ?? '';

            print('Shop ${shopModel.name} region: $region, city: $city');

            if (region.isNotEmpty) uniqueRegions.add(region);
            if (city.isNotEmpty) uniqueCities.add(city);
          } catch (e) {
            print('Error getting location for shop ${shopModel.name}: $e');
          }
        } else {
          print('Shop ${shopModel.name} has no location data');
        }
      }

      print('Fetched ${uniqueRegions.length} regions and ${uniqueCities.length} cities');
      
      regions.assignAll(uniqueRegions.toList()..sort());
      cities.assignAll(uniqueCities.toList()..sort());
    } catch (e) {
      print('Error fetching locations: $e');
    }
  }

  // Helper method to get location info with caching
  Future<Map<String, String>> _getLocationInfoFromCoordinates(
      double latitude, double longitude) async {
    final String locationKey = '$latitude,$longitude';

    // Check cache first
    if (_locationCache.containsKey(locationKey)) {
      return _locationCache[locationKey]!;
    }

    // If not in cache, do geocoding
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );

      if (placemarks.isNotEmpty) {
        final placemark = placemarks[0];
        final region = placemark.administrativeArea ?? '';
        final city = placemark.locality ?? '';

        final locationInfo = {
          'region': region,
          'city': city,
        };

        // Debug the geocoding result
        print('Geocoded $latitude, $longitude to region: $region, city: $city');

        // Cache the result
        _locationCache[locationKey] = locationInfo;
        return locationInfo;
      }
    } catch (e) {
      print('Geocoding error: $e');
    }

    return {'region': '', 'city': ''};
  }

  // Fetch price range from available services
  Future<void> fetchPriceRange() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final servicesSnapshot = await firestore.collection('services').get();

      double minPriceValue = double.infinity;
      double maxPriceValue = 0.0;

      for (var serviceDoc in servicesSnapshot.docs) {
        final serviceData = serviceDoc.data();
        final price = (serviceData['price'] ?? 0.0).toDouble();

        if (price > 0) {
          if (price < minPriceValue) minPriceValue = price;
          if (price > maxPriceValue) maxPriceValue = price;
        }
      }

      // Set min and max prices if valid data was found
      if (minPriceValue != double.infinity && maxPriceValue > 0) {
        minPrice.value = minPriceValue;
        maxPrice.value = maxPriceValue;
      }
    } catch (e) {
      print('Error fetching price range: $e');
    }
  }

  // Toggle filter drawer
  void toggleFilterDrawer() {
    isFilterDrawerOpen.value = !isFilterDrawerOpen.value;
  }

  // Clear all filters
  void clearFilters() {
    shopNameFilter.value = '';
    selectedServices.clear();
    selectedThemes.clear();
    selectedSubThemes.clear();
    selectedRegion.value = '';
    selectedCity.value = '';
    minRating.value = 0.0;
    minPrice.value = 0.0;
    maxPrice.value = maxPrice.value; // Reset to the fetched max price
    
    // Also clear the main search query
    searchQuery.value = '';
    
    // Run search to refresh results
    search();
  }

  // Update search query and trigger search
  void updateSearchQuery(String query) {
    searchQuery.value = query;
    
    // Cancel previous timer if it exists
    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer!.cancel();
    }
    
    // Set a new timer to delay search for better UX
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      search();
    });
  }

  // Apply search with current filters
  Future<void> search() async {
    try {
      isLoading(true);
      searchResults.clear();
      
      print('Searching with filters:');
      print('Search query: ${searchQuery.value}');
      print('Shop name: ${shopNameFilter.value}');
      print('Selected services: $selectedServices');
      print('Selected themes: $selectedThemes');
      print('Location - Region: ${selectedRegion.value}, City: ${selectedCity.value}');
      print('Rating: ${minRating.value}');
      print('Price range: ${minPrice.value} - ${maxPrice.value}');

      // Update subthemes based on selected themes
      _updateSelectedSubthemesFromThemes();
      
      List<dynamic> results = [];
      
      if (searchType.value == 'all' || searchType.value == 'shops') {
        final shops = await searchShopsEfficiently();
        print('Found ${shops.length} shops');
        results.addAll(shops);
      }

      if (searchType.value == 'all' || searchType.value == 'services') {
        final services = await searchServicesEfficiently();
        print('Found ${services.length} services');
        results.addAll(services);
      }

      searchResults.assignAll(results);
      print('Total results: ${searchResults.length}');
      
      isFilterDrawerOpen.value = false; // Close drawer after search
    } catch (e) {
      print('Error searching: $e');
      Get.snackbar(
        'Error',
        'Failed to perform search.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading(false);
    }
  }

  // Update selected subthemes based on selected themes
  void _updateSelectedSubthemesFromThemes() {
    // When themes are selected, add all their subthemes to the selected subthemes
    if (selectedThemes.isNotEmpty) {
      Set<String> subthemesToAdd = {};
      
      for (String themeId in selectedThemes) {
        final subthemes = _themeToSubthemesMap[themeId] ?? [];
        subthemesToAdd.addAll(subthemes);
      }
      
      // Add new subthemes without removing manually selected ones
      selectedSubThemes.addAll(subthemesToAdd);
      
      print('Updated selected subthemes based on themes: $selectedSubThemes');
    }
  }

  // Improved search shops method that reduces query complexity
  Future<List<ShopModel>> searchShopsEfficiently() async {
    final firestore = FirebaseFirestore.instance;
    Query query = firestore.collection('shops');
    
    // Apply rating filter - one of the few filters we can apply directly on shops collection
    if (minRating.value > 0) {
      query = query.where('rating', isGreaterThanOrEqualTo: minRating.value);
    }
    
    // Apply shop name filter if provided
    if (shopNameFilter.value.isNotEmpty) {
      // For case-insensitive partial search
      String searchTerm = shopNameFilter.value.toLowerCase();
      query = query
          .where('name', isGreaterThanOrEqualTo: searchTerm)
          .where('name', isLessThanOrEqualTo: '$searchTerm\uf8ff');
    } else if (searchQuery.value.isNotEmpty) {
      // If no shop name filter but search query exists, use that instead
      String searchTerm = searchQuery.value.toLowerCase();
      query = query
          .where('name', isGreaterThanOrEqualTo: searchTerm)
          .where('name', isLessThanOrEqualTo: '$searchTerm\uf8ff');
    }
    
    // Execute the initial query
    final QuerySnapshot snapshot = await query.get();
    
    // Create a map of shop IDs to shops for quick lookups
    Map<String, ShopModel> shopMap = {};
    for (var doc in snapshot.docs) {
      final shop = ShopModel.fromSnapshot(doc as DocumentSnapshot<Map<String, dynamic>>);
      shopMap[shop.id] = shop;
    }
    
    // If we have service, theme, or subtheme filters, we need to query services
    if (selectedServices.isNotEmpty || selectedThemes.isNotEmpty || selectedSubThemes.isNotEmpty ||
        (minPrice.value > 0 || maxPrice.value < double.infinity)) {
        
      // Set to track shop IDs that match our service filters
      Set<String> matchingShopIds = Set<String>();
      
      // Build a service query
      Query serviceQuery = firestore.collection('services');
      
      // We need to perform multiple queries and combine results because of Firestore limitations
      List<Future<QuerySnapshot>> futureQueries = [];
      
      // Handle price range filter
      Query priceQuery = serviceQuery;
      if (minPrice.value > 0) {
        priceQuery = priceQuery.where('price', isGreaterThanOrEqualTo: minPrice.value);
      }
      if (maxPrice.value < double.infinity) {
        priceQuery = priceQuery.where('price', isLessThanOrEqualTo: maxPrice.value);
      }
      futureQueries.add(priceQuery.get());
      
      // Handle service name filter
      if (selectedServices.isNotEmpty) {
        // Split into chunks if there are too many services (Firestore limit of 10 for whereIn queries)
        for (int i = 0; i < selectedServices.length; i += 10) {
          final end = (i + 10 < selectedServices.length) ? i + 10 : selectedServices.length;
          final chunk = selectedServices.sublist(i, end);
          Query serviceNameQuery = serviceQuery.where('serviceName', whereIn: chunk);
          futureQueries.add(serviceNameQuery.get());
        }
      }
      
      // Handle subtheme filter
      if (selectedSubThemes.isNotEmpty) {
        // Split into chunks if there are too many subthemes
        for (int i = 0; i < selectedSubThemes.length; i += 10) {
          final end = (i + 10 < selectedSubThemes.length) ? i + 10 : selectedSubThemes.length;
          final chunk = selectedSubThemes.sublist(i, end);
          Query subthemeQuery = serviceQuery.where('subThemeId', whereIn: chunk);
          futureQueries.add(subthemeQuery.get());
        }
      }
      
      // If no specific service queries were built, add a base query
      if (futureQueries.isEmpty) {
        futureQueries.add(serviceQuery.get());
      }
      
      // Execute all queries in parallel
      List<QuerySnapshot> queryResults = await Future.wait(futureQueries);
      
      // Process each query result
      for (var result in queryResults) {
        for (var doc in result.docs) {
          final service = ServicesModel.fromSnapshot(doc as DocumentSnapshot<Map<String, dynamic>>);
          
          // Skip if this shop wasn't in our initial shop results
          if (!shopMap.containsKey(service.shopId)) continue;
          
          // This service passed filters, so its shop should be included
          matchingShopIds.add(service.shopId);
        }
      }
      
      // Filter shops list to only include those from matchingShopIds
      List<ShopModel> filteredShops = shopMap.values
          .where((shop) => matchingShopIds.contains(shop.id))
          .toList();
      
      // Apply location filter if needed
      if (selectedRegion.value.isNotEmpty || selectedCity.value.isNotEmpty) {
        List<ShopModel> locationFilteredShops = [];
        
        for (var shop in filteredShops) {
          if (shop.location != null) {
            try {
              final locationInfo = await _getLocationInfoFromCoordinates(
                  shop.location.latitude, shop.location.longitude);
              
              final region = locationInfo['region'] ?? '';
              final city = locationInfo['city'] ?? '';
              
              print('Filtering shop ${shop.name} - region: $region (selected: ${selectedRegion.value}), city: $city (selected: ${selectedCity.value})');
              
              bool regionMatch = selectedRegion.value.isEmpty || 
                  region.toLowerCase() == selectedRegion.value.toLowerCase();
              bool cityMatch = selectedCity.value.isEmpty || 
                  city.toLowerCase() == selectedCity.value.toLowerCase();
              
              if (regionMatch && cityMatch) {
                print('Shop ${shop.name} matches location filters');
                locationFilteredShops.add(shop);
              }
            } catch (e) {
              print('Error filtering shop ${shop.name} by location: $e');
            }
          }
        }
        
        return locationFilteredShops;
      }
      
      return filteredShops;
    } else {
      // If we don't have service, theme, price, or subtheme filters, we can just use the shops
      // from our initial query and only apply location filter if needed
      List<ShopModel> shops = shopMap.values.toList();
      
      // Apply location filter
      if (selectedRegion.value.isNotEmpty || selectedCity.value.isNotEmpty) {
        List<ShopModel> locationFilteredShops = [];
        
        for (var shop in shops) {
          if (shop.location != null) {
            try {
              final locationInfo = await _getLocationInfoFromCoordinates(
                  shop.location.latitude, shop.location.longitude);
              
              final region = locationInfo['region'] ?? '';
              final city = locationInfo['city'] ?? '';
              
              print('Filtering shop ${shop.name} - region: $region (selected: ${selectedRegion.value}), city: $city (selected: ${selectedCity.value})');
              
              bool regionMatch = selectedRegion.value.isEmpty || 
                  region.toLowerCase() == selectedRegion.value.toLowerCase();
              bool cityMatch = selectedCity.value.isEmpty || 
                  city.toLowerCase() == selectedCity.value.toLowerCase();
              
              if (regionMatch && cityMatch) {
                print('Shop ${shop.name} matches location filters');
                locationFilteredShops.add(shop);
              } else {
                print('Shop ${shop.name} does NOT match location filters');
              }
            } catch (e) {
              print('Error filtering shop by location: $e');
            }
          }
        }
        
        return locationFilteredShops;
      } else {
        return shops;
      }
    }
  }

  // Improved search services method
  Future<List<ServicesModel>> searchServicesEfficiently() async {
    final firestore = FirebaseFirestore.instance;
    List<Future<QuerySnapshot>> futureQueries = [];
    Set<String> serviceIds = Set<String>();
    Map<String, ServicesModel> servicesMap = {};
    
    // Basic query for services
    Query baseQuery = firestore.collection('services');
    
    // Apply search query filter to service name if provided
    if (searchQuery.value.isNotEmpty) {
      String searchTerm = searchQuery.value.toLowerCase();
      Query nameQuery = baseQuery
          .where('serviceName', isGreaterThanOrEqualTo: searchTerm)
          .where('serviceName', isLessThanOrEqualTo: '$searchTerm\uf8ff');
      futureQueries.add(nameQuery.get());
      
      // Also search by description
      Query descriptionQuery = baseQuery
          .where('description', isGreaterThanOrEqualTo: searchTerm)
          .where('description', isLessThanOrEqualTo: '$searchTerm\uf8ff');
      futureQueries.add(descriptionQuery.get());
    }
    
    // Apply selected services filter
    if (selectedServices.isNotEmpty) {
      // Split into chunks if there are too many services (Firestore limit)
      for (int i = 0; i < selectedServices.length; i += 10) {
        final end = (i + 10 < selectedServices.length) ? i + 10 : selectedServices.length;
        final chunk = selectedServices.sublist(i, end);
        Query serviceNameQuery = baseQuery.where('serviceName', whereIn: chunk);
        futureQueries.add(serviceNameQuery.get());
      }
    }
    
    // Apply price range filter
    if (minPrice.value > 0 || maxPrice.value < double.infinity) {
      Query priceQuery = baseQuery;
      
      if (minPrice.value > 0) {
        priceQuery = priceQuery.where('price', isGreaterThanOrEqualTo: minPrice.value);
      }
      
      if (maxPrice.value < double.infinity) {
        priceQuery = priceQuery.where('price', isLessThanOrEqualTo: maxPrice.value);
      }
      
      futureQueries.add(priceQuery.get());
    }
    
    // Apply subtheme filter
    if (selectedSubThemes.isNotEmpty) {
      // Split into chunks if there are too many subthemes
      for (int i = 0; i < selectedSubThemes.length; i += 10) {
        final end = (i + 10 < selectedSubThemes.length) ? i + 10 : selectedSubThemes.length;
        final chunk = selectedSubThemes.sublist(i, end);
        Query subthemeQuery = baseQuery.where('subThemeId', whereIn: chunk);
        futureQueries.add(subthemeQuery.get());
      }
    }
    
    // If no specific queries were built, use the base query
    if (futureQueries.isEmpty) {
      futureQueries.add(baseQuery.get());
    }
    
    // Execute all queries in parallel
    List<QuerySnapshot> queryResults = await Future.wait(futureQueries);
    
    // Process all query results
    for (var result in queryResults) {
      for (var doc in result.docs) {
        final service = ServicesModel.fromSnapshot(doc as DocumentSnapshot<Map<String, dynamic>>);
        
        // Apply rating filter
        if (minRating.value > 0 && service.rating < minRating.value) {
          continue;
        }
        
        // Deduplicate by adding to our map
        if (!serviceIds.contains(service.id)) {
          servicesMap[service.id] = service;
          serviceIds.add(service.id);
        }
      }
    }
    
    // Apply location filter if needed
    if (selectedRegion.value.isNotEmpty || selectedCity.value.isNotEmpty) {
      Set<String> locationMatchingServiceIds = {};
      Map<String, Map<String, String>> shopLocationCache = {};
      
      for (var serviceId in serviceIds) {
        final service = servicesMap[serviceId]!;
        
        // Get shop info for this service
        DocumentSnapshot<Map<String, dynamic>> shopDoc;
        try {
          shopDoc = await firestore.collection('shops').doc(service.shopId).get();
        } catch (e) {
          print('Error fetching shop: $e');
          continue;
        }
        
        if (!shopDoc.exists) continue;
        
        final shop = ShopModel.fromSnapshot(shopDoc);
        
        if (shop.location != null) {
          Map<String, String> locationInfo;
          
          // Check if we already cached this shop's location
          if (shopLocationCache.containsKey(shop.id)) {
            locationInfo = shopLocationCache[shop.id]!;
          } else {
            locationInfo = await _getLocationInfoFromCoordinates(
                shop.location.latitude, shop.location.longitude);
            shopLocationCache[shop.id] = locationInfo;
          }
          
          final region = locationInfo['region'] ?? '';
          final city = locationInfo['city'] ?? '';
          
          bool regionMatch = selectedRegion.value.isEmpty || 
              region.toLowerCase() == selectedRegion.value.toLowerCase();
          bool cityMatch = selectedCity.value.isEmpty || 
              city.toLowerCase() == selectedCity.value.toLowerCase();
          
          if (regionMatch && cityMatch) {
            locationMatchingServiceIds.add(serviceId);
          }
        }
      }
      
      // Filter serviceIds to only include location matches
      serviceIds = serviceIds.intersection(locationMatchingServiceIds);
    }
    
    // Create final list of services
    List<ServicesModel> filteredServices = serviceIds.map((id) => servicesMap[id]!).toList();
    
    return filteredServices;
  }

  // Update search type
  void setSearchType(String type) {
    searchType.value = type;
    // Refresh search results when search type changes
    search();
  }
}