import 'package:domo/features/shop/controller/shop_details_controller.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import 'package:domo/common/styles/style.dart';
import 'package:domo/common/widgets/service/vert_service_card.dart';
import 'package:domo/features/home/controllers/search_controller.dart'
    as custom;
import 'package:domo/features/services/models/service_model.dart';
import 'package:domo/features/shop/model/shop_model.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final custom.SearchController _searchController =
      custom.SearchController.instance;
  final TextEditingController _shopNameController = TextEditingController();
  final RangeValues _currentRangeValues = const RangeValues(20, 100);
  double _selectedRating = 0;
  
  // Add a tab controller and observable variable for selected tab
  final RxInt _selectedTabIndex = 0.obs;

  @override
  void initState() {
    super.initState();
    _searchController.fetchFilterData();
    _shopNameController.text = _searchController.shopNameFilter.value;
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Search',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Theme.of(context).colorScheme.secondary,
                fontWeight: FontWeight.bold,
              ),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _searchController.toggleFilterDrawer,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: _searchController.updateSearchQuery,
              decoration: const InputDecoration(
                hintText: 'Search services or shops...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: AppTheme.buttonRadius,
                ),
              ),
            ),
          ),
          
          // Add tabs for Services and Shops
          Obx(() => _searchController.searchResults.isNotEmpty
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _buildTabSelector(),
              )
            : const SizedBox()
          ),
          
          Expanded(
            child: Stack(
              children: [
                // Search results with tabs
                Obx(() {
                  if (_searchController.isLoading.value) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (_searchController.searchResults.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.search_off,
                              size: 64, color: AppTheme.caption),
                          const SizedBox(height: 16),
                          Text(
                            'No results found',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Try adjusting your search or filters',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppTheme.caption,
                                ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Filter results based on selected tab
                  final filteredResults = _getFilteredResults();

                  if (filteredResults.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.search_off,
                              size: 64, color: AppTheme.caption),
                          const SizedBox(height: 16),
                          Text(
                            _selectedTabIndex.value == 0 
                                ? 'No services found' 
                                : 'No shops found',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Try adjusting your search or filters',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppTheme.caption,
                                ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: filteredResults.length,
                    itemBuilder: (context, index) {
                      final item = filteredResults[index];

                      if (item is ServicesModel) {
                        return ServiceCard(
                          service: item,
                          onPressed: () {
                            Get.toNamed('/service-details', arguments: item);
                          },
                        );
                      } else if (item is ShopModel) {
                        return ShopListTile(shop: item);
                      }

                      return const SizedBox();
                    },
                  );
                }),

                // Filter drawer
                Obx(() => AnimatedPositioned(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      right: _searchController.isFilterDrawerOpen.value
                          ? 0
                          : -MediaQuery.of(context).size.width,
                      top: 0,
                      bottom: 0,
                      width: MediaQuery.of(context).size.width * 0.85,
                      child: _buildFilterDrawer(),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Build the tab selector
  Widget _buildTabSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _buildTabButton(0, 'Services', Icons.home_repair_service),
          _buildTabButton(1, 'Shops', Icons.store),
        ],
      ),
    );
  }

  // Build individual tab button
  Widget _buildTabButton(int index, String title, IconData icon) {
    return Expanded(
      child: Obx(() {
        final isSelected = _selectedTabIndex.value == index;
        return GestureDetector(
          onTap: () => _selectedTabIndex.value = index,
          child: Container(
            height: 46,
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.button : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: isSelected ? Colors.white : AppTheme.caption,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.caption,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  // Get filtered results based on selected tab
  List<dynamic> _getFilteredResults() {
    if (_selectedTabIndex.value == 0) {
      // Show only services
      return _searchController.searchResults
          .where((item) => item is ServicesModel)
          .toList();
    } else {
      // Show only shops
      return _searchController.searchResults
          .where((item) => item is ShopModel)
          .toList();
    }
  }

  Widget _buildFilterDrawer() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(-5, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Drawer header
          Container(
            padding: const EdgeInsets.all(16),
            color: AppTheme.button,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filter Results',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.buttonText,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppTheme.buttonText),
                  onPressed: _searchController.toggleFilterDrawer,
                ),
              ],
            ),
          ),

          // Filter options
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Shop Name Filter
                  _buildSectionTitle('Shop Name'),
                  TextField(
                    controller: _shopNameController,
                    decoration: const InputDecoration(
                      hintText: 'Enter shop name',
                      border: OutlineInputBorder(
                        borderRadius: AppTheme.buttonRadius,
                      ),
                    ),
                    onChanged: (value) {
                      _searchController.shopNameFilter.value = value;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Services Filter
                  _buildSectionTitle('Services Offered'),
                  Obx(() => _searchController.availableServices.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : _buildMultiSelectChips(
                          items: _searchController.availableServices
                              .map((service) => service.serviceName)
                              .toList(),
                          selectedItems: _searchController.selectedServices,
                        )),
                  const SizedBox(height: 16),

                  // Themes Filter
                  _buildSectionTitle('Themes'),
                  Obx(() => _searchController.availableThemes.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : _buildMultiSelectChips(
                          items: _searchController.availableThemes
                              .map((theme) => theme.name)
                              .toList(),
                          selectedItems: _searchController.selectedThemes,
                        )),
                  const SizedBox(height: 16),

                  // Price Range Filter
                  _buildSectionTitle('Price Range'),
                  Obx(() => Column(
                        children: [
                          RangeSlider(
                            values: RangeValues(
                              _searchController.minPrice.value,
                              _searchController.maxPrice.value,
                            ),
                            min: 0,
                            max: _searchController.maxPrice.value.isFinite
                                ? _searchController.maxPrice.value
                                : 5000,
                            divisions: 100,
                            labels: RangeLabels(
                              '\GHS${_searchController.minPrice.value.toStringAsFixed(0)}',
                              '\GHS${_searchController.maxPrice.value.toStringAsFixed(0)}',
                            ),
                            onChanged: (RangeValues values) {
                              _searchController.minPrice.value = values.start;
                              _searchController.maxPrice.value = values.end;
                            },
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                  '\GHS${_searchController.minPrice.value.toStringAsFixed(0)}'),
                              Text(
                                  '\GHS${_searchController.maxPrice.value.toStringAsFixed(0)}'),
                            ],
                          ),
                        ],
                      )),
                  const SizedBox(height: 16),

                  // Location Filter
                  _buildSectionTitle('Location'),
                  Obx(() => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Region dropdown
                          const Text('Region',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          _buildDropdown(
                            items: _searchController.regions,
                            value:
                                _searchController.selectedRegion.value.isEmpty
                                    ? null
                                    : _searchController.selectedRegion.value,
                            hint: 'Select region',
                            onChanged: (value) {
                              if (value != null) {
                                _searchController.selectedRegion.value = value;
                              }
                            },
                          ),
                          const SizedBox(height: 16),

                          // City dropdown
                          const Text('City',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          _buildDropdown(
                            items: _searchController.cities,
                            value: _searchController.selectedCity.value.isEmpty
                                ? null
                                : _searchController.selectedCity.value,
                            hint: 'Select city',
                            onChanged: (value) {
                              if (value != null) {
                                _searchController.selectedCity.value = value;
                              }
                            },
                          ),
                        ],
                      )),
                  const SizedBox(height: 16),

                  // Rating Filter
                  _buildSectionTitle('Minimum Rating'),
                  RatingBar.builder(
                    initialRating: _searchController.minRating.value,
                    minRating: 0,
                    direction: Axis.horizontal,
                    allowHalfRating: true,
                    itemCount: 5,
                    itemSize: 28,
                    itemBuilder: (context, _) => const Icon(
                      Icons.star,
                      color: Colors.amber,
                    ),
                    onRatingUpdate: (rating) {
                      _searchController.minRating.value = rating;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Filter action buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            _searchController.clearFilters();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Clear All'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            _searchController.search();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.button,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text(
                            'Apply',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.button,
              ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildMultiSelectChips({
    required List<String> items,
    required RxList<String> selectedItems,
  }) {
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: items.map((item) {
        return Obx(() {
          final isSelected = selectedItems.contains(item);
          return FilterChip(
            label: Text(item),
            selected: isSelected,
            onSelected: (selected) {
              if (selected) {
                selectedItems.add(item);
              } else {
                selectedItems.remove(item);
              }
            },
            backgroundColor: Colors.grey[200],
            selectedColor: AppTheme.button.withOpacity(0.2),
            checkmarkColor: AppTheme.button,
            labelStyle: TextStyle(
              color: isSelected ? AppTheme.button : Colors.black,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          );
        });
      }).toList(),
    );
  }

  Widget _buildDropdown({
    required List<String> items,
    required String? value,
    required String hint,
    required Function(String?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: AppTheme.buttonRadius,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(hint),
          ),
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down),
          style: const TextStyle(color: AppTheme.text, fontSize: 16),
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          onChanged: onChanged,
          items: items.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// A custom widget to display shop items in the search results
class ShopListTile extends StatefulWidget {
  final ShopModel shop;

  const ShopListTile({
    Key? key,
    required this.shop,
  }) : super(key: key);

  @override
  State<ShopListTile> createState() => _ShopListTileState();
}

class _ShopListTileState extends State<ShopListTile> {
  String address = 'Loading address...';
  bool isAddressLoading = true;

  @override
  void initState() {
    super.initState();
    _getReadableAddress();
  }

  Future<void> _getReadableAddress() async {
    try {
      if (widget.shop.location.latitude != null && widget.shop.location.longitude != null) {
        List<Placemark> placemarks = await placemarkFromCoordinates(
            widget.shop.location.latitude!, widget.shop.location.longitude!);
        
        if (placemarks.isNotEmpty) {
          Placemark place = placemarks.first;
          setState(() {
            address = '${place.street}, ${place.locality}, ${place.administrativeArea}';
            isAddressLoading = false;
          });
        }
      } else {
        setState(() {
          address = 'Address not available';
          isAddressLoading = false;
        });
      }
    } catch (e) {
      print('Error getting readable address: $e');
      setState(() {
        address = 'Address not available';
        isAddressLoading = false;
      });
    }
  }



  // navigate to shop
  void navigateToShopDetails(BuildContext context) async {
  final ShopDetailsController shopController = Get.put(ShopDetailsController());
  
  try {
    // Print the shop ID to validate it's not empty
    print("Attempting to navigate to shop with ID: ${widget.shop.id}");
    
    if (widget.shop.id == null || widget.shop.id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid shop ID')),
      );
      return;
    }

    // Pass the shop ID as part of a map, as expected by the route
    Get.toNamed('/customer/shop-details', arguments: {'shopId': widget.shop.id});
    
  } catch (e) {
    print('Error navigating to shop details: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
      navigateToShopDetails(context);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: AppTheme.outlinedBox(
          borderRadius: AppTheme.cardRadius,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Shop image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                bottomLeft: Radius.circular(10),
              ),
              child: Image.network(
                widget.shop.image,
                width: 120,
                height: 120,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 120,
                  height: 120,
                  color: Colors.grey[300],
                  child: const Icon(Icons.store, size: 48, color: Colors.grey),
                ),
              ),
            ),
            // Shop details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.shop.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.shop.rating.toStringAsFixed(1)}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            color: AppTheme.caption, size: 16),
                        const SizedBox(width: 4),
                        Expanded(
                          child: isAddressLoading
                              ? Row(
                                  children: [
                                    SizedBox(
                                      width: 12,
                                      height: 12,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppTheme.caption,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Loading address...',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: AppTheme.caption,
                                          ),
                                    ),
                                  ],
                                )
                              : Text(
                                  address,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: AppTheme.caption,
                                      ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}