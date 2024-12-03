// servicd_model.dart is a model class that represents a service in the app.
import 'package:cloud_firestore/cloud_firestore.dart';

class ServicesModel {
  String id;
  String serviceName;
  String imageAsset;
  String subThemeId;
  double rating;
  String location;
  double price;
  String description;
  bool isFeatured;
  String shopId;
  String? themeName;
  String? subThemeName;

  ServicesModel({
    required this.id,
    required this.serviceName,
    required this.imageAsset,
    required this.subThemeId,
    required this.rating,
    required this.location,
    required this.price,
    required this.description,
    required this.isFeatured,
    required this.shopId,
    this.themeName,
    this.subThemeName,
  });

  // Helper function: Create an empty ServicesModel
  static ServicesModel empty() => ServicesModel(
        id: "",
        serviceName: "",
        imageAsset: "",
        subThemeId: "",
        rating: 0.0,
        location: "",
        price: 0.0,
        description: "",
        isFeatured: false,
        shopId: "",
      );

  // Convert model to a JSON object
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'serviceName': serviceName,
      'imageAsset': imageAsset,
      'subThemeId': subThemeId,
      'rating': rating,
      'location': location,
      'price': price,
      'description': description,
      'isFeatured': isFeatured,
      'shopId': shopId,
    };
  }

  // Map JSON-oriented document snapshot from Firebase to model
  factory ServicesModel.fromSnapshot(
      DocumentSnapshot<Map<String, dynamic>> document) {
    if (document.data() != null) {
      final data = document.data()!;
      return ServicesModel(
        id: document.id,
        serviceName: data['serviceName'] ?? "",
        imageAsset: data['imageAsset'] ?? "",
        subThemeId: data['subThemeId'] ?? "",
        rating: (data['rating'] ?? 0.0).toDouble(),
        location: data['location'] ?? "",
        price: data['price'] ?? "",
        description: data['description'] ?? "",
        isFeatured: data['isFeatured'] ?? false,
        shopId: data['shopId'] ?? "",
        themeName: data['themeName'] ?? "",
        subThemeName: data['subThemeName'] ?? "",
      );
    } else {
      return ServicesModel.empty();
    }
  }
}
