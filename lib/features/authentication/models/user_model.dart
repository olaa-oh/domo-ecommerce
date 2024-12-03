// lib/features/authentication/models/user_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String? id;
  final String fullName;
  final String phoneNumber;
  final String role;
  
  final DateTime? createdAt;

  const UserModel({
    this.id,
    required this.fullName,
    required this.phoneNumber,
    required this.role,
    this.createdAt,
  });

  // Convert model to JSON
  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'role': role,
      'createdAt': createdAt ?? Timestamp.now(),
    };
  }

  // Factory constructor to create UserModel from JSON/Map
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      fullName: json['fullName'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      role: json['role'] ?? '',
      createdAt: (json['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  // Create a copy of user with modified fields
  UserModel copyWith({
    String? id,
    String? fullName,
    String? phoneNumber,
    String? role,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}