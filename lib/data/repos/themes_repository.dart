import 'package:domo/common/styles/dummydata.dart';
import 'package:domo/features/shop/model/theme_model.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ThemesRepository extends GetxService {
  static ThemesRepository get instance => Get.find();

  // variable to store the themes
  final _db = FirebaseFirestore.instance;

// get all themes
  Future<List<ThemesModel>> getThemes() async {
    try {
      final themes = await _db.collection('themes').get();
      return themes.docs.map((e) => ThemesModel.fromSnapshot(e)).toList();
    } catch (e) {
      print('Error fetching themes: $e');
      return [];
    }
  }

// get all sub themes

// upload themes to the firestore
  Future<void> uploadThemes() async {
    try {
      // Reference to the themes collection in Firestore
      final themesCollection = _db.collection('themes');

      // Iterate through the dummy themes
      for (var theme in DummyData.themes) {
        // Upload each theme to Firestore using toJson()
        await themesCollection.doc(theme.id).set(theme.toJson());
      }

      print('Themes uploaded successfully');
    } catch (e) {
      print('Error uploading themes: $e');
    }
  }

}
