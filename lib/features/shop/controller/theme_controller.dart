import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:domo/common/styles/dummydata.dart';
import 'package:domo/data/repos/themes_repository.dart';
import 'package:domo/features/shop/model/sub_theme_model.dart';
import 'package:domo/features/shop/model/theme_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ThemeController extends GetxController {
  static ThemeController get instance => Get.find();

  final _themesRepository = Get.put(ThemesRepository());
  RxList<ThemesModel> themesList = <ThemesModel>[].obs;
  RxList<ThemesModel> featuredThemesList = <ThemesModel>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    fetchThemes();
    super.onInit();
  }

// fecth themes
  Future<void> fetchThemes() async {
    try {
      isLoading(true);
      final themes = await _themesRepository.getThemes();
      print('Fetched themes: ${themes.length}');
      themesList.assignAll(themes);

      // Filter featured themes
      featuredThemesList.assignAll(themes
          .where((theme) => theme.isFeatured && theme.parentId.isEmpty)
          .take(8)
          .toList());
      print('Featured themes: ${featuredThemesList.length}');
    } catch (e) {
      print('Error fetching themes: $e');
    } finally {
      isLoading(false);
    }
  }

// upload theme to the firestore
  Future<void> uploadThemesToFirestore() async {
    try {
      // Set loading state to true
      isLoading.value = true;

      // Reference to Firestore
      final firestore = FirebaseFirestore.instance;

      // Reference to themes collection
      final themesCollection = firestore.collection('themes');

      // Batch write for efficiency
      WriteBatch batch = firestore.batch();

      // Iterate through dummy themes
      for (var theme in DummyData.themes) {
        // Create a document reference with the theme's ID
        DocumentReference docRef = themesCollection.doc(theme.id);

        // Add to batch with toJson method
        batch.set(docRef, theme.toJson(), SetOptions(merge: true));

        print('Preparing to upload theme: ${theme.name} with ID: ${theme.id}');
      }

      // Commit the batch
      await batch.commit();

      // Fetch updated themes
      await fetchThemes();

      // Show success message
      // Get.snackbar(
      //   'Success',
      //   '${DummyData.themes.length} Themes uploaded successfully',
      //   snackPosition: SnackPosition.BOTTOM,
      //   backgroundColor: Colors.green,
      //   colorText: Colors.white,
      // );

      print('Themes upload completed successfully');
    } catch (e, stackTrace) {
      // Detailed error handling
      print('Error uploading themes: $e');
      print('Stack trace: $stackTrace');

      // Get.snackbar(
      //   'Upload Error',
      //   'Failed to upload themes: $e',
      //   snackPosition: SnackPosition.BOTTOM,
      //   backgroundColor: Colors.red,
      //   colorText: Colors.white,
      // );
    } finally {
      // Ensure loading state is set to false
      isLoading.value = false;
    }
  }

}
