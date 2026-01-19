import 'package:flutter/material.dart';
import '../models/product_model.dart';

class ProductViewModel extends ChangeNotifier {
  List<ProductModel> _products = [];
  List<ProductModel> get products => _products;
  final Map<int, int> _quantities = {};

  /// 데이터 주입 (SyncViewModel로부터 전달받음)
  void setProducts(List<ProductModel> newProducts) {
    _products = newProducts;
    _quantities.clear(); // 데이터 갱신 시 수량 초기화 (선택 사항)
    notifyListeners();
  }

  void setQuantity(int productNumber, int quantity) {
    _quantities[productNumber] = quantity;
    notifyListeners();
  }

  /// 갯수
  int getQuantity(int productNumber) => _quantities[productNumber] ?? 0;

  /// 할인이 적용되지 않은 총 금액
  int getTotalPrice(int productNumber) {
    final p = _products.firstWhere((p) => p.productNumber == productNumber);
    return getQuantity(productNumber) * p.price;
  }

  /// 할인이 적용된 가격
  int getTotalPriceWithDiscount(int productNumber) {
    final p = _products.firstWhere((p) => p.productNumber == productNumber);

    final qty = getQuantity(productNumber);
    final baseTotal = qty * p.price;

    final dq = p.discountQuantity; // 예: 3
    final dp = p.discountPrice;    // 예: 1000

    // 할인 조건 없거나 잘못된 값 방어
    if (dq <= 0 || dp <= 0) return baseTotal;

    final discountCount = qty ~/ dq;
    final discountTotal = discountCount * dp;

    final discounted = baseTotal - discountTotal;
    return discounted < 0 ? 0 : discounted;
  }

  /// 할인 가격만 리턴
  int getDiscountAmount(int productNumber) {
    final p = _products.firstWhere((p) => p.productNumber == productNumber);

    final qty = getQuantity(productNumber);
    final dq = p.discountQuantity;
    final dp = p.discountPrice;

    if (dq <= 0 || dp <= 0) return 0;

    final discountCount = qty ~/ dq;
    return discountCount * dp;
  }

  void saveSelection() {
    // 실제 결제 내역 저장 로직 구현...
    print("선택 내역 저장됨");
  }
}