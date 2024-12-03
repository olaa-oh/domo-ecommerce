import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentModel {
  String id;
  String bookingId; // References BookingModel
  String customerId; // References UserModel
  String shopId; // References shopModel
  double amount;
  String status; // "pending", "completed", "failed","completed", "canceled"
  DateTime createdAt;

  PaymentModel({
    required this.id,
    required this.bookingId,
    required this.customerId,
    required this.shopId,
    required this.amount,
    required this.status,
    required this.createdAt,
  });

  static PaymentModel empty() => PaymentModel(
        id: "",
        bookingId: "",
        customerId: "",
        shopId: "",
        amount: 0.0,
        status: "pending",
        createdAt: DateTime.now(),
      );

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookingId': bookingId,
      'customerId': customerId,
      'shopId': shopId,
      'amount': amount,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory PaymentModel.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data()!;
    return PaymentModel(
      id: document.id,
      bookingId: data['bookingId'] ?? "",
      customerId: data['customerId'] ?? "",
      shopId: data['shopId'] ?? "",
      amount: (data['amount'] ?? 0.0).toDouble(),
      status: data['status'] ?? "pending",
      createdAt: DateTime.parse(data['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}
