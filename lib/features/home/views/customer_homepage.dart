import 'package:domo/common/widgets/service/vert_service_card.dart';
import 'package:domo/common/styles/style.dart';
import 'package:domo/features/services/controllers/service_controller.dart';
import 'package:domo/features/services/views/service_details_page.dart';
import 'package:domo/features/shop/controller/subtheme_controller.dart';
import 'package:domo/features/shop/controller/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:get/get.dart';

class CustomerHomepage extends StatefulWidget {
  const CustomerHomepage({
    super.key,
  });

  @override
  State<CustomerHomepage> createState() => _CustomerHomepageState();
}

class _CustomerHomepageState extends State<CustomerHomepage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedLocation = 'All Cities';
  int _currentBannerIndex = 0;

  // Sample banner data
  final List<String> _bannerImages = [
    'assets/images/p.png',
    'assets/images/op.png',
    'assets/images/service.png',
  ];

  

  // Sample locations
  final List<String> _locations = [
    'All Cities',
    'New York',
    'Los Angeles',
    'Chicago',
    'Houston'
  ];


  IconData _getIconForTheme(String themeName) {
    switch (themeName.toLowerCase()) {
      case 'home services':
        return Icons.home_repair_service;
      case 'cleaning':
        return Icons.clean_hands;
      case 'repair':
        return Icons.build;
      case 'maintenance':
        return Icons.handyman;
      default:
        return Icons.category;
    }
  }

  void _showLocationBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _locations.map((location) {
              return ListTile(
                title: Text(location),
                onTap: () {
                  setState(() {
                    _selectedLocation = location;
                  });
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

    @override
  void initState() {
    super.initState();
    
    // Option 1: Automatically upload on first load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _uploadThemesIfNeeded();
      _uploadSubThemesIfNeeded();
      _uploadServicesIfNeeded();
    });
  }
// upload themes
  Future<void> _uploadThemesIfNeeded() async {
    final themeController = ThemeController.instance;
    
    // Check if themes are empty before uploading
    if (themeController.themesList.isEmpty) {
      await themeController.uploadThemesToFirestore();
    }
  }

  // upload subthemes
  Future<void> _uploadSubThemesIfNeeded() async {
    final subthemeController = SubthemeController.instance;
    
    // Check if subthemes are empty before uploading
    if (subthemeController.subthemes.isEmpty) {
      await subthemeController.uploadSubThemesByThemeId();
    }
  }

  // upload services
  Future<void> _uploadServicesIfNeeded() async {
    final serviceController = ServiceController.instance;
    
    // Check if services are empty before uploading
    if (serviceController.services.isEmpty) {
      await serviceController.uploadServicesToFirestore();
    }
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Hello, Super!',
          style: theme.textTheme.headlineLarge?.copyWith(
            color: theme.colorScheme.secondary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Get.toNamed('/search');
            },
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Get.toNamed('/you');
            },
          ),
        ],
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: AppTheme.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar with Location Selection
          
            const SizedBox(height: 16),
            // Themes of services
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Themes ',
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(color: theme.colorScheme.secondary),
                ),
              ],
            ),

            // // Display themes from Firestore

            GetX<ThemeController>(
              init: ThemeController(),
              builder: (controller) {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (controller.featuredThemesList.isEmpty) {
                  return Text(
                    'No themes available',
                    style: theme.textTheme.bodyMedium,
                  );
                }

                return SizedBox(
                  height: 100,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: controller.featuredThemesList.length,
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (context, index) {
                      final themeItem = controller.featuredThemesList[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              height: 56,
                              width: 56,
                              decoration: BoxDecoration(
                                color: AppTheme.button,
                                borderRadius: BorderRadius.circular(100),
                              ),
                            child: GestureDetector(
                              onTap: () {
                                Get.toNamed('/themes', arguments:{
                                  'theme': themeItem,
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppTheme.button,
                                  borderRadius: BorderRadius.circular(100),
                                ),
                              child: Image.asset(
                                themeItem.image,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    Icons.error_outline,
                                    color: AppTheme.background,
                                  );
                                },
                                // loadingBuilder: (context, child, loadingProgress) {
                                //   if (loadingProgress == null) return child;
                                //   return Center(
                                //     child: CircularProgressIndicator(
                                //       value: loadingProgress.expectedTotalBytes != null
                                //           ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                //           : null,
                                //     ),
                                //   );
                                // },
                              ),
                            ),
                          ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              themeItem.name,
                              style: AppTheme.textTheme.bodySmall?.copyWith(
                                color: AppTheme.text,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
            // Banner Carousel
            CarouselSlider(
              options: CarouselOptions(
                height: 200.0,
                enlargeCenterPage: true,
                autoPlay: true,
                autoPlayInterval: const Duration(seconds: 5),
                onPageChanged: (index, reason) {
                  setState(() {
                    _currentBannerIndex = index;
                  });
                },
              ),
              items: _bannerImages.map((bannerImage) {
                return Builder(
                  builder: (BuildContext context) {
                    return Container(
                      width: MediaQuery.of(context).size.width,
                      margin: const EdgeInsets.symmetric(horizontal: 8.0),
                      decoration: AppTheme.outlinedBox(
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16.0),
                        child: Image.asset(
                          bannerImage,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: 200,
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
            ),
            // Popoular Services
            const SizedBox(height: 16),
            // Themes of services
            Text(
              'Top-Rated Services ',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(color: theme.colorScheme.secondary),
            ),
            const SizedBox(
              height: 10,
            ),
            // SizedBox(
            //       height: MediaQuery.of(context).size.height / 2, // Adjust the height as needed
            //       width: double.infinity,
            //       child: ListView.builder(
            //       shrinkWrap: true,
            //       physics: const NeverScrollableScrollPhysics(),
            //       itemCount: _services.length,
            //       itemBuilder: (context, index) {
            //         final service = _services[index];
            //         return Padding(
            //         padding: const EdgeInsets.symmetric(vertical: 8.0),
            //         child: ServiceCard(
            //           imageAsset: service['imageAsset'],
            //           serviceName: service['serviceName'],
            //           rating: service['rating'],
            //           themeName: service['themeName'],
            //           price: service['price'],
            //           location: service['location'],
            //           onPressed: () {
            //           // Handle service card press
            //           },
            //         ),
            //         );
            //       },
            //         ),
            //       ),
            const SizedBox(height: 16),
            // // // Perpetually scrolling list of services
            // Inside the build method of _CustomerHomepageState
            SizedBox(
              height: MediaQuery.of(context).size.height / 2,
              child: GetX<ServiceController>(
                init: ServiceController(),
                builder: (controller) {
                  if (controller.services.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  return ListView.builder(
                    itemCount: controller.services.length,
                    itemBuilder: (context, index) {
                      final service = controller.services[index];
                      return ServiceCard(
                        service: service,
                      onPressed: () {
                        Get.toNamed('/service-details', arguments: service);
                      },                      
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }


  
}
