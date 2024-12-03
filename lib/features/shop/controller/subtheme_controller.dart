// subtheme controller
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:domo/common/styles/dummydata.dart';
import 'package:domo/data/repos/subtheme_repository.dart';
import 'package:domo/features/shop/model/sub_theme_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SubthemeController extends GetxController {
  static SubthemeController get instance => Get.put(SubthemeController());

  final _subThemesRepository = Get.put(SubthemeRepository());
  RxList<SubThemesModel> subthemes = <SubThemesModel>[].obs;
  final isLoading = false.obs;


  @override
  void onInit() {
    fetchSubThemes();
    super.onInit();

  }
// fetch all subthemes
  void fetchSubThemes() async {
    final subthemesList = await SubthemeRepository.instance.getSubThemes();
    if (subthemesList.isNotEmpty) {
      subthemes.assignAll(subthemesList);
    }
  }
// fetch subthemes by themeId
  void fetchSubThemesByThemeId(String themeId) async {
    final subthemesList = await SubthemeRepository.instance.getSubThemesByThemeId(themeId);
    if (subthemesList.isNotEmpty) {
      subthemes.assignAll(subthemesList);
    }
  }


// upload subthemes in reference to themeId
  Future<void> uploadSubThemesByThemeId() async {
    try {
      // Reference to the subthemes collection in Firestore
      final subthemesCollection =
          FirebaseFirestore.instance.collection('subthemes');

      // Iterate through the dummy subthemes
      for (var subtheme in DummyData.subThemes) {
        // Upload each subtheme to Firestore using toJson()
        await subthemesCollection.doc(subtheme.id).set(subtheme.toJson());
      }

      // Show success message
      Get.snackbar(
        'Success',
        'Subthemes uploaded successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      print('Subthemes uploaded successfully');
    } catch (e) {
      print('Error uploading subthemes: $e');

      // Show error message
      // Get.snackbar(
      //   'Upload Error',
      //   'Failed to upload subthemes: $e',
      //   snackPosition: SnackPosition.BOTTOM,
      //   backgroundColor: Colors.red,
      //   colorText: Colors.white,
      // );
    }
  }


















}