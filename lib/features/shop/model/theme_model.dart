// categories model
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:domo/features/shop/model/sub_theme_model.dart';

class ThemesModel {
  String id;
  String name;
  String image;
  String parentId;
  bool isFeatured;
   List<SubThemesModel> subThemes;

  ThemesModel({
    required this.id,
    required this.name,
    required this.image,
    this.parentId = "",
    required this.isFeatured,
    this.subThemes = const [],
  });

// helper function
  static ThemesModel empty() =>
      ThemesModel(id: "", name: "", image: "", isFeatured: false);

// convert model to a json object
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image': image,
      'parentId': parentId,
      'isFeatured': isFeatured,
    };
  }

  // map json oriented document snapshot from firebase to model
  factory ThemesModel.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> document) {
    if(document.data() != null) {
      final data = document.data()!;
      return ThemesModel(
        id: document.id,
        name: data['name'] ?? "",
        image: data['image'] ?? "",
        parentId: data['parentId']  ?? "", 
        isFeatured: data['isFeatured'] ?? false,
        subThemes: [],
      );
    }else{
      return ThemesModel.empty();
    }
  }

}
