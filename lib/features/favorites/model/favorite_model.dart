// favorite model
import 'package:cloud_firestore/cloud_firestore.dart';

class FavoritesModel {
  String id;
  String userId; // References UserModel
  String serviceId; // References ArtisanModel or serviceId

  FavoritesModel({
    required this.id,
    required this.userId,
    required this.serviceId,
  });

  static FavoritesModel empty() => FavoritesModel(
        id: "",
        userId: "",
        serviceId: "",
      );

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'serviceId': serviceId,
    };
  }

  factory FavoritesModel.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data()!;
    return FavoritesModel(
      id: document.id,
      userId: data['userId'] ?? "",
      serviceId: data['serviceId'] ?? "",
    );
  }
}
