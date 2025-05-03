// lib/features/authentication/models/user_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String? id;
  final String phoneNumber;
  final String fullName;
  final String role; // customer, artisan
  final DateTime? createdAt;

  const UserModel({
    this.id,
    required this.phoneNumber,
    required this.fullName,
    required this.role,
    this.createdAt,
  });

  // Convert model to JSON
  Map<String, dynamic> toJson() {
    return {
      'phoneNumber': phoneNumber,
      'fullName': fullName,
      'role': role,
      'createdAt': createdAt ?? Timestamp.now(),
    };
  }

  // Factory constructor to create UserModel from JSON/Map
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      phoneNumber: json['phoneNumber'] ?? '',
      fullName: json['fullName'] ?? '',
      role: json['role'] ?? '',
      createdAt: (json['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  // Create a copy of user with modified fields
  UserModel copyWith({
    String? id,
    String? phoneNumber,
    String? fullName,
    String? role,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}