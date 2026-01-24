import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:project/models/product_model.dart';
import 'package:project/repositories/product_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminViewModel extends ChangeNotifier {
  final ProductRepository _repo;
  AdminViewModel(this._repo);

  List<ProductModel> _products = [];
  List<ProductModel> get products => _products;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // 동기화 및 로컬 저장 (void로 변경)
  Future<void> syncAndSave() async {
    _setLoading(true);
    try {
      final remoteProducts = await _repo.getProductsOnce();
      _products = remoteProducts;

      final prefs = await SharedPreferences.getInstance();
      final String encoded = jsonEncode(
        remoteProducts.map((p) => p.toJson()).toList(),
      );
      await prefs.setString('cached_products', encoded);
      notifyListeners();
    } catch (e) {
      debugPrint("Sync Error: $e");
    } finally {
      _setLoading(false);
    }
  }

  // 로컬 로드 (void로 변경)
  Future<void> loadFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final String? encoded = prefs.getString('cached_products');

    if (encoded != null) {
      final List<dynamic> decoded = jsonDecode(encoded);
      _products = decoded.map((item) => ProductModel.fromJson(item)).toList();
      notifyListeners();
    }
  }

  // 상품 추가
  Future<void> addProduct({
    required String name,
    required int price,
    required String borderColor,
    required int discountPrice,
    required int discountQuantity,
    required String imgUrl
  }) async {
    _setLoading(true);
    try {
      int newNumber = _products.isEmpty
          ? 1
          : _products.map((e) => e.productNumber).reduce((a, b) => a > b ? a : b) + 1;

      final newProduct = ProductModel(
        productNumber: newNumber,
        name: name,
        price: price,
        borderColor: borderColor,
        discountPrice: discountPrice,
        discountQuantity: discountQuantity,
        imgUrl: imgUrl,
      );

      await _repo.postProduct(newProduct);
      await syncAndSave(); // 서버 전송 후 다시 동기화
    } finally {
      _setLoading(false);
    }
  }

  // 상품 삭제
  Future<void> deleteProduct(int productNumber) async {
    _setLoading(true);
    try {
      await _repo.deleteProduct(productNumber);
      await syncAndSave();
    } finally {
      _setLoading(false);
    }
  }

  // 상품 수정 (기존 번호를 그대로 사용하여 덮어씌움)
  Future<void> updateProduct({
    required int productNumber,
    required String name,
    required int price,
    required String borderColor,
    required int discountPrice,
    required int discountQuantity,
    required String imgUrl,
  }) async {
    _setLoading(true);
    try {
      final updatedProduct = ProductModel(
        productNumber: productNumber,
        name: name,
        price: price,
        borderColor: borderColor,
        discountPrice: discountPrice,
        discountQuantity: discountQuantity,
        imgUrl: imgUrl,
      );

      await _repo.postProduct(updatedProduct);
      await syncAndSave(); // 로컬 및 UI 동기화
    } finally {
      _setLoading(false);
    }
  }
}