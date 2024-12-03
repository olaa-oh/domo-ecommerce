// sub themes model
import 'package:cloud_firestore/cloud_firestore.dart';
class SubThemesModel {
  String id;
  String name;
  String themeId; // References ThemesModel

  SubThemesModel({
    required this.id,
    required this.name,
    required this.themeId,
  });

  static SubThemesModel empty() =>
      SubThemesModel(id: "", name: "", themeId: "", );

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'themeId': themeId,
    };
  }

  factory SubThemesModel.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data()!;
    return SubThemesModel(
      id: document.id,
      name: data['name'] ?? "",
      themeId: data['themeId'] ?? "",
    );
  }
}
