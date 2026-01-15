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
}