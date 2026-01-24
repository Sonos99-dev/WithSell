import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project/models/product_model.dart';
import 'package:project/services/firestore_service.dart';

class ProductRepository {
  final FireStoreService service;
  ProductRepository(this.service);

  Future<List<ProductModel>> getProductsOnce() async {
    final snapshot = await FirebaseFirestore.instance.collection('products').get();
    return snapshot.docs.map((doc) {
      return ProductModel.fromFirestore(doc.data());
    }).toList();
  }

  Future<void> postProduct(ProductModel product) async {
    try {
      await FirebaseFirestore.instance
          .collection('products')
          .doc(product.productNumber.toString())
          .set(product.toJson());
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteProduct(int productNumber) async {
    try {
      final String docId = productNumber.toString();

      await FirebaseFirestore.instance
          .collection('products')
          .doc(docId)
          .delete();
    } catch (e) {
      rethrow;
    }
  }
}