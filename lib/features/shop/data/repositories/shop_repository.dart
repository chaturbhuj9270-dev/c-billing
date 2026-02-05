import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/shop.dart';

/// Repository for fetching and managing shop details
class ShopRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Shop? _cachedShop;

  ShopRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  /// Get shop details for the current user
  Future<Shop> getShopDetails({bool forceRefresh = false}) async {
    // Return cached shop if available and not forcing refresh
    if (_cachedShop != null && !forceRefresh) {
      return _cachedShop!;
    }

    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final doc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('shop_details')
          .doc('main')
          .get();

      if (doc.exists && doc.data() != null) {
        _cachedShop = Shop.fromJson(doc.data()!);
        return _cachedShop!;
      }

      // Return default shop if not found
      return Shop.empty;
    } catch (e) {
      print('[ERROR] Failed to fetch shop details: $e');
      return Shop.empty;
    }
  }

  /// Save or update shop details
  Future<bool> saveShopDetails(Shop shop) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('shop_details')
          .doc('main')
          .set(shop.toJson(), SetOptions(merge: true));

      _cachedShop = shop;
      return true;
    } catch (e) {
      print('[ERROR] Failed to save shop details: $e');
      return false;
    }
  }

  /// Stream of shop details changes
  Stream<Shop> watchShopDetails() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value(Shop.empty);
    }

    return _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('shop_details')
        .doc('main')
        .snapshots()
        .map((doc) {
      if (doc.exists && doc.data() != null) {
        _cachedShop = Shop.fromJson(doc.data()!);
        return _cachedShop!;
      }
      return Shop.empty;
    });
  }

  /// Clear cached shop data
  void clearCache() {
    _cachedShop = null;
  }
}
