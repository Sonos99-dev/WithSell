import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project/constants/constants.dart';
import 'package:project/models/product_model.dart';

class FireStoreService {
  final _db = FirebaseFirestore.instance;

  Stream<List<ProductModel>> streamProducts() {
   return _db
       .collection(Constants.products)
       .orderBy("product_number")
       .snapshots()
       .map((snapShot) => snapShot.docs
          .map((doc) => ProductModel.fromFirestore(doc.data()))
          .toList()
        );
  }

}