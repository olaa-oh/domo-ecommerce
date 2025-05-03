import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  String id;
  String bookingId; // References BookingModel
  String customerId; // References UserModel (customer)
  String shopId; // References ArtisanModel (artisan)
  String reviewText;
  int rating; // 1-5 stars
  DateTime createdAt;
  DateTime? editedAt;
  bool isEdited;
  String? artisanResponse;
  DateTime? responseDate;
  bool isFlagged;

  ReviewModel({
    required this.id,
    required this.bookingId,
    required this.customerId,
    required this.shopId,
    required this.reviewText,
    required this.rating,
    required this.createdAt,
    this.editedAt,
    this.isEdited = false,
    this.artisanResponse,
    this.responseDate,
    this.isFlagged = false,
  });

  static ReviewModel empty() => ReviewModel(
        id: "",
        bookingId: "",
        customerId: "",
        shopId: "",
        reviewText: "",
        rating: 0,
        createdAt: DateTime.now(),
      );

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookingId': bookingId,
      'customerId': customerId,
      'shopId': shopId,
      'reviewText': reviewText,
      'rating': rating,
      'createdAt': createdAt.toIso8601String(),
      'editedAt': editedAt?.toIso8601String(),
      'isEdited': isEdited,
      'artisanResponse': artisanResponse,
      'responseDate': responseDate?.toIso8601String(),
      'isFlagged': isFlagged,
    };
  }

  factory ReviewModel.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data()!;
    return ReviewModel(
      id: document.id,
      bookingId: data['bookingId'] ?? "",
      customerId: data['customerId'] ?? "",
      shopId: data['shopId'] ?? "",
      reviewText: data['reviewText'] ?? "",
      rating: data['rating'] ?? 0,
      createdAt: DateTime.parse(data['createdAt'] ?? DateTime.now().toIso8601String()),
      editedAt: data['editedAt'] != null ? DateTime.parse(data['editedAt']) : null,
      isEdited: data['isEdited'] ?? false,
      artisanResponse: data['artisanResponse'],
      responseDate: data['responseDate'] != null ? DateTime.parse(data['responseDate']) : null,
      isFlagged: data['isFlagged'] ?? false,
    );
  }

  // Check if review is still editable (within 24 hours)
  bool get isEditable {
    final difference = DateTime.now().difference(createdAt);
    return difference.inHours < 24;
  }
}