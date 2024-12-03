import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum ModeOfService { home, onSite }

class ShopModel {
  String id;
  String artisanId;
  String name;
  GeoPoint location;
  String image;
  String description;
  double rating;
  List<ModeOfService> modesOfService;
  String phoneNumber;
  Map<String, Map<String, TimeOfDay>> operatingHours;

  ShopModel({
    required this.id,
    required this.artisanId,
    required this.name,
    required this.location,
    required this.image,
    required this.description,
    required this.rating,
    required this.modesOfService,
    required this.phoneNumber,
    required this.operatingHours,
  });

  // Update empty model
  static ShopModel empty() => ShopModel(
        id: "",
        artisanId: "",
        name: "",
        location: GeoPoint(0, 0),
        image: "",
        description: "",
        rating: 0.0,
        modesOfService: [],
        phoneNumber: "",
        operatingHours: {},
      );

  // Convert model to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id, //  the ID
      'artisanId': artisanId,
      'name': name,
      'location': location,
      'image': image,
      'description': description,
      'rating': rating,
      'modesOfService': modesOfService
          .map((mode) => mode.toString().split('.').last)
          .toList(),
      'phoneNumber': phoneNumber,
      'operatingHours': operatingHours.map((day, hours) => MapEntry(day, {
            'start': hours['start'] != null
                ? '${hours['start']?.hour.toString().padLeft(2, '0')}:${hours['start']?.minute.toString().padLeft(2, '0')}'
                : null,
            'end': hours['end'] != null
                ? '${hours['end']?.hour.toString().padLeft(2, '0')}:${hours['end']?.minute.toString().padLeft(2, '0')}'
                : null
          })),
    };
  }

  // Map Firestore snapshot to model
  factory ShopModel.fromSnapshot(
      DocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data();
    if (data == null) {
      print('Null data for document: ${document.id}');
      return ShopModel.empty();
    }

    try {
      // Handle potential null or incorrect types
      final List<dynamic> modesList =
          data['modesOfService'] ?? data['modeOfService'] ?? [];
      final List<ModeOfService> modes = modesList
          .map((mode) => ModeOfService.values.firstWhere(
              (e) => e.toString().split('.').last == mode.toString(),
              orElse: () => ModeOfService.home))
          .toList();

      // Robust operating hours parsing
      final Map<String, Map<String, TimeOfDay>> operatingHours =
          _parseOperatingHours(data['operatingHours']);

      return ShopModel(
        id: document.id,
        artisanId: data['artisanId'] ?? "",
        name: data['name'] ?? "",
        location:
            data['location'] is GeoPoint ? data['location'] : GeoPoint(0, 0),
        image: data['image'] ?? "",
        description: data['description'] ?? "",
        rating: (data['rating'] ?? 0.0).toDouble(),
        modesOfService: modes,
        phoneNumber: data['phoneNumber'] ?? "",
        operatingHours: operatingHours,
      );
    } catch (e) {
      print('Error parsing shop document ${document.id}: $e');
      return ShopModel.empty();
    }
  }

  static Map<String, Map<String, TimeOfDay>> _parseOperatingHours(
      dynamic hoursData) {
    if (hoursData == null) return {};

    try {
      return (hoursData as Map<String, dynamic>).map((day, hours) {
        // Handle different operating hours formats
        if (hours is String) {
          // Format like "9:00 -5:00"
          final timeParts = hours.split('-');
          return MapEntry(day, {
            'start': _parseTimeOfDay(timeParts[0].trim()) ??
                TimeOfDay(hour: 0, minute: 0),
            'end': _parseTimeOfDay(timeParts[1].trim()) ??
                TimeOfDay(hour: 0, minute: 0)
          });
        } else if (hours is Map) {
          // Existing format
          return MapEntry(day, {
            'start': _parseTimeOfDay(hours['start']) ??
                TimeOfDay(hour: 0, minute: 0),
            'end':
                _parseTimeOfDay(hours['end']) ?? TimeOfDay(hour: 0, minute: 0)
          });
        }
        return MapEntry(day, {
          'start': TimeOfDay(hour: 0, minute: 0),
          'end': TimeOfDay(hour: 0, minute: 0)
        });
      });
    } catch (e) {
      print('Error parsing operating hours: $e');
      return {};
    }
  }

  // Helper to parse time string to TimeOfDay
  static TimeOfDay? _parseTimeOfDay(String? timeString) {
    if (timeString == null) return null;
    final parts = timeString.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  ShopModel copyWith({
    String? id,
    String? artisanId,
    String? name,
    GeoPoint? location,
    String? image,
    String? description,
    double? rating,
    List<ModeOfService>? modesOfService,
    String? phoneNumber,
    Map<String, Map<String, TimeOfDay>>? operatingHours,
  }) {
    // Start with the current object's values or use empty model as fallback
    final emptyModel = ShopModel.empty();

    return ShopModel(
      id: id ?? emptyModel.id,
      artisanId: artisanId ?? emptyModel.artisanId,
      name: name ?? emptyModel.name,
      location: location ?? emptyModel.location,
      image: image ?? emptyModel.image,
      description: description ?? emptyModel.description,
      rating: rating ?? emptyModel.rating,
      modesOfService: modesOfService ?? emptyModel.modesOfService,
      phoneNumber: phoneNumber ?? emptyModel.phoneNumber,
      operatingHours: operatingHours ?? emptyModel.operatingHours,
    );
  }
}
