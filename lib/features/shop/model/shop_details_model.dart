import 'package:domo/features/shop/model/shop_model.dart';

class ShopDetailsModel {
  final ShopModel shopData;
  bool isEditMode;

  ShopDetailsModel({
    required this.shopData, 
    this.isEditMode = false
  });

  ShopDetailsModel copyWith({
    ShopModel? shopData,
    bool? isEditMode,
  }) {
    return ShopDetailsModel(
      shopData: shopData ?? this.shopData,
      isEditMode: isEditMode ?? this.isEditMode,
    );
  }
}