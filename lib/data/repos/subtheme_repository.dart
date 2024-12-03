// subtheme repository

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:domo/common/styles/dummydata.dart';
import 'package:domo/features/shop/model/sub_theme_model.dart';
import 'package:get/get.dart';

class SubthemeRepository extends GetxService {
  static SubthemeRepository get instance => Get.put(SubthemeRepository());

  // variable to store the subthemes
  final _db = FirebaseFirestore.instance;

  // get all subthemes
  Future<List<SubThemesModel>> getSubThemes() async {
    try {
      final subthemes = await _db.collection('subthemes').get();
      return subthemes.docs.map((e) => SubThemesModel.fromSnapshot(e)).toList();
    } catch (e) {
      print('Error fetching subthemes: $e');
      return [];
    }
  }

  // get all subthemes by themeId
  Future<List<SubThemesModel>> getSubThemesByThemeId(String themeId) async {
    try {
      final subthemes = await _db.collection('subthemes').where('themeId', isEqualTo: themeId).get();
      return subthemes.docs.map((e) => SubThemesModel.fromSnapshot(e)).toList();
    } catch (e) {
      print('Error fetching subthemes: $e');
      return [];
    }
  }

  // upload subthemes to the firestore
  Future<void> uploadSubThemes() async {
    try {
      // Reference to the subthemes collection in Firestore
      final subthemesCollection = _db.collection('subthemes');

      // Iterate through the dummy subthemes
      for (var subtheme in DummyData.subThemes) {
        // Upload each subtheme to Firestore using toJson()
        await subthemesCollection.doc(subtheme.id).set(subtheme.toJson());
      }

      print('Subthemes uploaded successfully');
    } catch (e) {
      print('Error uploading subthemes: $e');
    }
  }

  // upload subthemes in reference to themeId
  Future<void> uploadSubThemesByThemeId(String themeId) async {
    try {
      // Reference to the subthemes collection in Firestore
      final subthemesCollection = _db.collection('subthemes');

      // Iterate through the dummy subthemes
      for (var subtheme in DummyData.subThemes) {
        // Upload each subtheme to Firestore using toJson()
        await subthemesCollection.doc(subtheme.id).set(subtheme.toJson());
      }

      print('Subthemes uploaded successfully');
    } catch (e) {
      print('Error uploading subthemes: $e');
    }
  }















}
