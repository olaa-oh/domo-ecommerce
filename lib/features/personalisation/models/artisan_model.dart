import 'package:cloud_firestore/cloud_firestore.dart';

class ArtisanModel {
  String userId; // References UserModel
  String shopId; // References ShopModel
  String profileImage;

  ArtisanModel({
    required this.userId,
    required this.shopId,
    this.profileImage = "",
  });

  // Helper function
  static ArtisanModel empty() =>
      ArtisanModel(userId: "", shopId: "");

  // Convert model to a JSON object
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'shopId': shopId,
      'profileImage': profileImage,
    };
  }

  // Map Firestore document snapshot to model
  factory ArtisanModel.fromSnapshot(
      DocumentSnapshot<Map<String, dynamic>> document) {
    if (document.data() != null) {
      final data = document.data()!;
      return ArtisanModel(
        userId: document.id,
        shopId: data['shopId'] ?? "",
        profileImage: data['profileImage'] ?? "",
      );
    } else {
      return ArtisanModel.empty();
    }
  }
}
