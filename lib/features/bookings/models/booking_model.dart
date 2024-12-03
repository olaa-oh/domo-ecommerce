// booking_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class BookingModel {
  String id;
  String serviceId;
  String customerId;
  String shopId;
  DateTime bookingDate;
  String status; // Updated to include new statuses
  String notes;
  double price;
  final String? serviceName;
  
  // New fields for completion
  int? rating;
  String? review;
  DateTime? completionInitiatedAt;
  String? completionInitiatedBy;

  BookingModel({
    required this.id,
    required this.serviceId,
    required this.customerId,
    required this.shopId,
    required this.bookingDate,
    required this.status,
    required this.notes,
    required this.price,
    this.serviceName,
    this.rating,
    this.review,
    this.completionInitiatedAt,
    this.completionInitiatedBy,
  });

  static BookingModel empty() => BookingModel(
        id: "",
        serviceId: "",
        customerId: "",
        shopId: "",
        bookingDate: DateTime.now(),
        status: "pending",
        notes: "",
        price: 0.0,
      );

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'serviceId': serviceId,
      'customerId': customerId,
      'shopId': shopId,
      'bookingDate': bookingDate.toIso8601String(),
      'status': status,
      'notes': notes,
      'price': price,
      'rating': rating,
      'review': review,
      'completionInitiatedAt': completionInitiatedAt?.toIso8601String(),
      'completionInitiatedBy': completionInitiatedBy,
    };
  }

  factory BookingModel.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data()!;
    return BookingModel(
      id: document.id,
      serviceId: data['serviceId'] ?? "",
      customerId: data['customerId'] ?? "",
      shopId: data['shopId'] ?? "",
      bookingDate: DateTime.parse(data['bookingDate'] ?? DateTime.now().toIso8601String()),
      status: data['status'] ?? "pending",
      notes: data['notes'] ?? "",
      price: (data['price'] ?? 0.0).toDouble(),
      rating: data['rating'],
      review: data['review'],
      completionInitiatedAt: data['completionInitiatedAt'] != null 
        ? DateTime.parse(data['completionInitiatedAt']) 
        : null,
      completionInitiatedBy: data['completionInitiatedBy'],
    );
  }
}