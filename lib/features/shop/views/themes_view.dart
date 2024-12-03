import 'package:domo/features/services/controllers/service_controller.dart';
import 'package:domo/features/services/views/service_details_page.dart';
import 'package:domo/features/shop/controller/shop_details_controller.dart';
import 'package:domo/features/shop/model/theme_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:domo/features/shop/controller/theme_controller.dart';
import 'package:domo/features/shop/controller/subtheme_controller.dart';
import 'package:domo/common/widgets/service/vert_service_card.dart';
import 'package:domo/common/styles/style.dart';

class ThemesPage extends StatefulWidget {
  const ThemesPage({Key? key}) : super(key: key);

  @override
  _ThemesPageState createState() => _ThemesPageState();
}

class _ThemesPageState extends State<ThemesPage> {
  late ThemesModel _selectedTheme;
  final SubthemeController _subthemeController = Get.put(SubthemeController());
  final ServiceController _serviceController = Get.put(ServiceController());
  final ThemeController _themeController = Get.find<ThemeController>();
  final ShopDetailsController _shopController = Get.put(ShopDetailsController());

  final TextEditingController _searchController = TextEditingController();

  @override
@override
void initState() {
  super.initState();

  // Retrieve the theme passed from the previous screen
  final theme = Get.arguments?['theme'];
  if (theme != null) {
    setState(() {
      _selectedTheme = theme;
    });

    // Fetch sub-themes for this specific theme
    _subthemeController.fetchSubThemesByThemeId(_selectedTheme.id);
  } else {
    // Fallback if no theme is passed
    _selectedTheme = _themeController.themesList.first;
    _subthemeController.fetchSubThemesByThemeId(_selectedTheme.id);
  }
  _shopController.fetchShops();
}

  // Helper method to map theme names to icons
  IconData _getIconForTheme(String themeName) {
    switch (themeName.toLowerCase()) {
      case 'beauty':
        return Icons.face;
      case 'home services':
        return Icons.home_repair_service;
      case 'cleaning':
        return Icons.clean_hands;
      case 'repair':
        return Icons.build;
      default:
        return Icons.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectedTheme.name,
          style: theme.textTheme.headlineMedium?.copyWith(
            color: theme.colorScheme.secondary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.secondary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Obx(() {
        // Check if sub-themes are loading
        if (_subthemeController.subthemes.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: AppTheme.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search for ${_selectedTheme.name} services',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Sub-themes Horizontal Scroll
              SizedBox(
                height: 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _subthemeController.subthemes.length,
                  itemBuilder: (context, index) {
                    final subTheme = _subthemeController.subthemes[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: ElevatedButton(
                        onPressed: () {
                          // TODO: Implement sub-theme filtering or selection
                          _serviceController.fetchServicesBySubThemeId();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.secondary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Text(
                          subTheme.name,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSecondary,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Services for Sub-themes
              Obx(() {
                if (_serviceController.services.isEmpty) {
                  return const Center(child: Text('No services available'));
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _subthemeController.subthemes.map((subTheme) {
                    // Filter services for this specific sub-theme
                    final servicesForSubTheme = _serviceController.services
                        .where((service) => service.subThemeId == subTheme.id)
                        .toList();

                    if (servicesForSubTheme.isEmpty) return Container();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          subTheme.name,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 350,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: servicesForSubTheme.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8.0),
                                child: ServiceCard(
                                  service: servicesForSubTheme[index],
                                  onPressed: () {
                                    Get.toNamed('/service-details', arguments: servicesForSubTheme[index]);
                                  },                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    );
                  }).toList(),
                );
              }),

              // Explore Other Themes
              Text(
                'Explore Other Themes',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.secondary,
                ),
              ),
              const SizedBox(height: 16),
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
                              child: Image.network(
                                themeItem.image,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.error_outline,
                                    color: AppTheme.background,
                                  );
                                },
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Center(
                                    child: CircularProgressIndicator(
                                      value: loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                          : null,
                                    ),
                                  );
                                },
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
            // See other Shops
// Explore Shops
Text(
  'Explore Shops',
  style: theme.textTheme.headlineSmall?.copyWith(
    color: theme.colorScheme.secondary,
  ),
),
const SizedBox(height: 16),

// Shops Horizontal List
Obx(() {
  if (_shopController.isLoading.value) {
    return const Center(child: CircularProgressIndicator());
  }

  if (_shopController.shops.isEmpty) {
    return Text(
      'No shops available',
      style: theme.textTheme.bodyMedium,
    );
  }

  return SizedBox(
    height: 150, // Adjust height as needed
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: _shopController.shops.length,
      itemBuilder: (context, index) {
        final shop = _shopController.shops[index];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: GestureDetector(
            onTap: () {
          Get.toNamed('/customer/shop-details', arguments: {'shopId': shop.id});              
              
            },
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: 
                      NetworkImage(shop.image),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  shop.name,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.secondary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}),            const SizedBox(height: 16),

            ],
          ),
        );
      }),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
