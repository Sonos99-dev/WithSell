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
      // 'products' 컬렉션에 productNumber를 문서 ID로 저장
      await FirebaseFirestore.instance
          .collection('products')
          .doc(product.productNumber.toString())
          .set(product.toJson());
    } catch (e) {
      print("Firestore Post Error: $e");
      rethrow; // 에러를 위로 던져서 ViewModel에서 잡게 함
    }
  }

  Future<void> deleteProduct(int productNumber) async {
    try {
      final String docId = productNumber.toString();

      await FirebaseFirestore.instance
          .collection('products')
          .doc(docId)
          .delete();

      print("삭제 성공: $docId");
    } catch (e) {
      print("삭제 에러: $e");
      rethrow;
    }
  }
}