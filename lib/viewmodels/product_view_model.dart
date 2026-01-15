import 'package:flutter/material.dart';
import '../models/product_model.dart';

class ProductViewModel extends ChangeNotifier {
  List<ProductModel> _products = [];
  List<ProductModel> get products => _products;
  final Map<int, int> _quantities = {};

  // 데이터 주입 (SyncViewModel로부터 전달받음)
  void setProducts(List<ProductModel> newProducts) {
    _products = newProducts;
    _quantities.clear(); // 데이터 갱신 시 수량 초기화 (선택 사항)
    notifyListeners();
  }

  void setQuantity(int productNumber, int quantity) {
    _quantities[productNumber] = quantity;
    notifyListeners();
  }

  int getQuantity(int productNumber) => _quantities[productNumber] ?? 0;

  int getTotalPrice(int productNumber) {
    final p = _products.firstWhere((p) => p.productNumber == productNumber);
    return getQuantity(productNumber) * p.price;
  }

  // 계산 로직 (기존 saveSelection 대체)
  void saveSelection() {
    // 실제 결제 내역 저장 로직 구현...
    print("선택 내역 저장됨");
  }
}