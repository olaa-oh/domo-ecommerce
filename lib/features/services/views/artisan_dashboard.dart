import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:domo/common/styles/style.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:domo/features/services/controllers/service_controller.dart';
import 'package:domo/features/services/models/service_model.dart';
import 'package:image_picker/image_picker.dart';

class ArtisanDashboard extends StatefulWidget {
  final String shopId;

  const ArtisanDashboard({Key? key, required this.shopId}) : super(key: key);

  @override
  _ArtisanDashboardState createState() => _ArtisanDashboardState();
}

class _ArtisanDashboardState extends State<ArtisanDashboard> {
  final ServiceController _serviceController = ServiceController.instance;
  final TextEditingController _searchController = TextEditingController();
  ServicesModel? _selectedService;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _serviceController.fetchServicesForArtisn(widget.shopId);
    _serviceController.fetchThemesWithSubthemes();
  }

  void _showServiceForm({ServicesModel? service}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _ServiceForm(
        service: service,
        shopId: widget.shopId,
        onServiceSaved: () {
          Navigator.of(context).pop();
          _serviceController.fetchServicesForArtisn(widget.shopId);
        },
      ),
    );
  }

  List<ServicesModel> _filterServices(List<ServicesModel> services) {
    if (_searchController.text.isEmpty) return services;

    return services.where((service) {
      final searchTerm = _searchController.text.toLowerCase();
      return service.serviceName.toLowerCase().contains(searchTerm) ||
          service.location.toLowerCase().contains(searchTerm);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search services...',
                  border: InputBorder.none,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        _isSearching = false;
                        _searchController.clear();
                      });
                    },
                  ),
                ),
                onChanged: (_) => setState(() {}),
              )
            : Text('My Services', style: AppTheme.textTheme.headlineSmall),
        actions: [
          if (!_isSearching)
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => setState(() => _isSearching = true),
            ),
        ],
      ),
      body: Obx(() {
        if (_serviceController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final filteredServices = _filterServices(_serviceController.services);

        return Column(
          children: [
            Expanded(
              child: filteredServices.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: AppTheme.screenPadding,
                      itemCount: filteredServices.length,
                      itemBuilder: (context, index) {
                        final service = filteredServices[index];
                        return _ServiceCard(
                          service: service,
                          onEdit: () => _showServiceForm(service: service),
                          onDelete: () => _confirmDeleteService(service),
                        );
                      },
                    ),
            ),
          ],
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showServiceForm(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.design_services_outlined,
            size: 80,
            color: AppTheme.background,
          ),
          const SizedBox(height: 16),
          Text(
            'No Services Yet',
            style: AppTheme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Click the + button to create your first service',
            style: AppTheme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _confirmDeleteService(ServicesModel service) {
    Get.defaultDialog(
      title: 'Confirm Delete',
      middleText: 'Are you sure you want to delete ${service.serviceName}?',
      textConfirm: 'Delete',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      onConfirm: () {
        _serviceController.deleteService(service.id);
        Get.back(); // Close dialog
      },
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final ServicesModel service;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ServiceCard(
      {required this.service, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Get.toNamed('/artisan-services', arguments: service);
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 2,
        child: ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              service.imageAsset,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 60,
                height: 60,
                color: Colors.grey[200],
                child: const Icon(Icons.image_not_supported),
              ),
            ),
          ),
          title: Text(
            service.serviceName,
            style: AppTheme.textTheme.titleMedium,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '\$${service.price.toStringAsFixed(2)}',
                style: AppTheme.textTheme.bodySmall,
              ),
              Text(
                service.location,
                style: AppTheme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: onEdit,
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceForm extends StatefulWidget {
  final ServicesModel? service;
  final String shopId;
  final VoidCallback onServiceSaved;

  const _ServiceForm(
      {this.service, required this.shopId, required this.onServiceSaved});

  @override
  _ServiceFormState createState() => _ServiceFormState();
}

class _ServiceFormState extends State<_ServiceForm> {
  final ServiceController _serviceController = ServiceController.instance;
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;

  String? _selectedThemeId;
  String? _selectedSubthemeId;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.service?.serviceName ?? '');
    _descriptionController =
        TextEditingController(text: widget.service?.description ?? '');
    _priceController =
        TextEditingController(text: widget.service?.price.toString() ?? '');

    if (widget.service != null) {
      _findThemeAndSubtheme(widget.service!);
    }
  }

  void _findThemeAndSubtheme(ServicesModel service) {
    for (var theme in _serviceController.themes) {
      for (var subtheme in theme.subThemes) {
        if (subtheme.id == service.subThemeId) {
          _selectedThemeId = theme.id;
          _selectedSubthemeId = subtheme.id;
          break;
        }
      }
    }
  }

  File? _imageFile;

  // Add method to pick an image
  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  void _saveService() async {
    if (!_formKey.currentState!.validate()) return;

    final service = widget.service ?? ServicesModel.empty();
    service
      ..serviceName = _nameController.text
      ..description = _descriptionController.text
      ..price = double.parse(_priceController.text)
      ..shopId = widget.shopId
      ..subThemeId = _selectedSubthemeId ?? '';

    // Upload image if selected
    if (_imageFile != null) {
      final imageUrl = await _uploadServiceImage(_imageFile!);
      service.imageAsset = imageUrl;
    }

    // Fetch shop location and prepare service with location
    try {
      final shopLocation = await _fetchShopLocation(widget.shopId);
      final serviceWithLocation = await _serviceController
          .prepareServiceWithLocation(service, shopLocation);

      if (widget.service == null) {
        _serviceController
            .createService(serviceWithLocation,
                themeId: _selectedThemeId, subthemeId: _selectedSubthemeId)
            .then((success) {
          if (success) widget.onServiceSaved();
        });
      } else {
        _serviceController
            .updateService(serviceWithLocation,
                themeId: _selectedThemeId, subthemeId: _selectedSubthemeId)
            .then((success) {
          if (success) widget.onServiceSaved();
        });
      }
    } catch (e) {
      // Handle location fetching error
      Get.snackbar('Error', 'Could not fetch shop location');
    }
  }

  // Method to upload service image to Firebase Storage
  Future<String> _uploadServiceImage(File imageFile) async {
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('service_images')
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

      await storageRef.putFile(imageFile);
      return await storageRef.getDownloadURL();
    } catch (e) {
      print('Error uploading image: $e');
      return ''; // Fallback to empty string
    }
  }

  // Method to fetch shop location (you'll need to implement this in your repository)
  Future<GeoPoint> _fetchShopLocation(String shopId) async {
    // Implement fetching shop location from Firestore
    // This is a placeholder - you'll need to create the actual implementation
    final shopDoc =
        await FirebaseFirestore.instance.collection('shops').doc(shopId).get();
    return shopDoc.data()?['location'] ?? GeoPoint(0, 0);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final themes = _serviceController.themes;

      return SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.service == null ? 'Create Service' : 'Edit Service',
                style: AppTheme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Service Name',
                  prefixIcon: Icon(Icons.design_services),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'Service name is required'
                    : null,
              ),
              const SizedBox(height: 12),
              // Image picker
              GestureDetector(
                onTap: _pickImage,
                child: _imageFile != null
                    ? Image.file(_imageFile!, height: 100, width: 100)
                    : (widget.service?.imageAsset != null
                        ? Image.network(widget.service!.imageAsset,
                            height: 100, width: 100)
                        : Container(
                            height: 100,
                            width: 100,
                            color: Colors.grey[200],
                            child: Icon(Icons.add_photo_alternate),
                          )),
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Price',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Price is required';
                  }
                  final price = double.tryParse(value);
                  return price == null || price <= 0
                      ? 'Please enter a valid price'
                      : null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Theme',
                  prefixIcon: Icon(Icons.category),
                ),
                value: _selectedThemeId,
                items: themes.map((theme) {
                  return DropdownMenuItem(
                    value: theme.id,
                    child: Text(theme.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedThemeId = value;
                    _selectedSubthemeId = null;
                  });
                },
                validator: (value) =>
                    value == null ? 'Please select a theme' : null,
              ),
              const SizedBox(height: 12),
              if (_selectedThemeId != null)
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Subtheme',
                    prefixIcon: Icon(Icons.subdirectory_arrow_right),
                  ),
                  value: _selectedSubthemeId,
                  items: themes
                      .firstWhere((theme) => theme.id == _selectedThemeId)
                      .subThemes
                      .map((subtheme) {
                    return DropdownMenuItem(
                      value: subtheme.id,
                      child: Text(subtheme.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedSubthemeId = value);
                  },
                  validator: (value) =>
                      value == null ? 'Please select a subtheme' : null,
                ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _saveService,
                child: Text(widget.service == null ? 'Create' : 'Update'),
              ),
            ],
          ),
        ),
      );
    });
  }

  // void _saveService() {
  //   if (!_formKey.currentState!.validate()) return;

  //   final service = widget.service ?? ServicesModel.empty();
  //   service
  //     ..serviceName = _nameController.text
  //     ..description = _descriptionController.text
  //     ..price = double.parse(_priceController.text)
  //     ..shopId = widget.shopId
  //     ..subThemeId = _selectedSubthemeId ?? '';

  //   if (widget.service == null) {
  //     _serviceController.createService(
  //       service,
  //       themeId: _selectedThemeId,
  //       subthemeId: _selectedSubthemeId
  //     ).then((success) {
  //       if (success) widget.onServiceSaved();
  //     });
  //   } else {
  //     _serviceController.updateService(
  //       service,
  //       themeId: _selectedThemeId,
  //       subthemeId: _selectedSubthemeId
  //     ).then((success) {
  //       if (success) widget.onServiceSaved();
  //     });
  //   }
  // }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }
}
