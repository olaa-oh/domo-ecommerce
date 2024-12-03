import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:domo/features/shop/model/shop_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ShopRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;


  Future<String> createShop(ShopModel shop) async {
  try {
    // Ensure the shop is created by an authenticated artisan
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User must be authenticated');
    }

    // Set the artisan ID to the current user's ID
    shop.artisanId = currentUser.uid;

    // Create a new document reference with an auto-generated ID
    final docRef = _firestore.collection('shops').doc(); // This generates a new unique ID
    
    // Set the generated ID to the shop model
    shop.id = docRef.id;

    // Add to Firestore using the generated ID
    await docRef.set(shop.toJson());

    return docRef.id;
  } catch (e) {
    print('Error creating shop: $e');
    rethrow;
  }
}

  // Read shop details
  Future<ShopModel?> getShopByArtisanId(String artisanId) async {
    try {
      final querySnapshot = await _firestore
          .collection('shops')
          .where('artisanId', isEqualTo: artisanId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return ShopModel.fromSnapshot(querySnapshot.docs.first);
      }
      return null;
    } catch (e) {
      print('Error fetching shop: $e');
      return null;
    }
  }

  // Update shop details
Future<void> updateShop(ShopModel shop) async {
  try {
    // Add detailed logging
    print('Updating shop with details:');
    print('Shop ID: ${shop.id}');
    print('Shop Name: ${shop.name}');

    // Validate shop ID
    if (shop.id.isEmpty) {
      throw Exception('Shop ID cannot be empty');
    }

    // Attempt to get the document reference directly
    final docRef = _firestore.collection('shops').doc(shop.id);

    // Use set with merge option instead of update
    await docRef.set(shop.toJson(), SetOptions(merge: true));

    print('Shop updated successfully');
  } catch (e) {
    print('Detailed error updating shop: $e');
    rethrow;
  }
}
  // Delete shop
  Future<void> deleteShop(String shopId) async {
    try {
      // TODO: Implement cascading deletions (services, etc.)
      await _firestore.collection('shops').doc(shopId).delete();
    } catch (e) {
      print('Error deleting shop: $e');
      rethrow;
    }
  }

  // get shop name
  Future<String> getShopName(String shopId) async {
    try {
      final doc = await _firestore.collection('shops').doc(shopId).get();
      if (doc.exists) {
        return doc.data()?['name'];
      }
      return '';
    } catch (e) {
      print('Error fetching shop name: $e');
      return '';
    }
  }

  // fetch shop details
  Future<ShopModel?> fetchShopDetails(String shopId) async {
    try {
      final doc = await _firestore.collection('shops').doc(shopId).get();
      if (doc.exists) {
        return ShopModel.fromSnapshot(doc);
      }
      return null;
    } catch (e) {
      print('Error fetching shop details: $e');
      return null;
    }
  }

  // fetch shop deyails by id
  Future<ShopModel?> fetchShopDetailsById(String shopId) async {
    try {
      final doc = await _firestore.collection('shops').doc(shopId).get();
      if (doc.exists) {
        return ShopModel.fromSnapshot(doc);
      }
      return null;
    } catch (e) {
      print('Error fetching shop details: $e');
      return null;
    }
  }

  // get all shops
Future<List<ShopModel>> fetchShops() async {
  try {
    final querySnapshot = await _firestore.collection('shops').get();
    
    print('Total documents in shops collection: ${querySnapshot.docs.length}');
    
    querySnapshot.docs.forEach((doc) {
      print('Document ID: ${doc.id}');
      print('Document Data: ${doc.data()}');
    });

    final shops = querySnapshot.docs.map((doc) => ShopModel.fromSnapshot(doc)).toList();
    
    print('Parsed shops count: ${shops.length}');
    
    return shops;
  } catch (e) {
    print('Error fetching all shops: $e');
    return [];
  }
}



}