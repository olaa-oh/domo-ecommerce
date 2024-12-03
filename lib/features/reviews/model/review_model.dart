// review mode;
import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  String id;
  String serviceId; // References ServicesModel
  String customerId; // References UserModel
  String shopId; // References ArtisanModel
  String reviewText;
  double rating; // e.g., 4.5 stars
  DateTime createdAt;

  ReviewModel({
    required this.id,
    required this.serviceId,
    required this.customerId,
    required this.shopId,
    required this.reviewText,
    required this.rating,
    required this.createdAt,
  });

  static ReviewModel empty() => ReviewModel(
        id: "",
        serviceId: "",
        customerId: "",
        shopId: "",
        reviewText: "",
        rating: 0.0,
        createdAt: DateTime.now(),
      );

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'serviceId': serviceId,
      'customerId': customerId,
      'shopId': shopId,
      'reviewText': reviewText,
      'rating': rating,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ReviewModel.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data()!;
    return ReviewModel(
      id: document.id,
      serviceId: data['serviceId'] ?? "",
      customerId: data['customerId'] ?? "",
      shopId: data['shopId'] ?? "",
      reviewText: data['reviewText'] ?? "",
      rating: (data['rating'] ?? 0.0).toDouble(),
      createdAt: DateTime.parse(data['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}
