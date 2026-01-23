import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product_model.dart';

class ProductViewModel extends ChangeNotifier {
  List<ProductModel> _products = [];
  List<ProductModel> get products => _products;
  final Map<int, int> _quantities = {};

  /// 데이터 주입 (SyncViewModel로부터 전달받음)
  void setProducts(List<ProductModel> newProducts) {
    _products = newProducts;
    _quantities.clear();
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

  int getTotalCartPrice() {
    int total = 0;
    for (var product in _products) {
      total += getTotalPriceWithDiscount(product.productNumber);
    }
    return total;
  }

  void clearQuantities() {
    _quantities.clear();
    notifyListeners();
  }

  Future<void> saveSelection(bool isCardPayment) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<Map<String, dynamic>> currentSaleItems = _products
          .where((p) => getQuantity(p.productNumber) > 0)
          .map((p) => {
        'productNumber': p.productNumber,
        'name': p.name,
        'quantity': getQuantity(p.productNumber),
        'price': p.price,
        'totalPrice': getTotalPriceWithDiscount(p.productNumber),
        'isCardPayment': isCardPayment,
        'isCanceled': false,
        'timestamp': DateTime.now().toIso8601String(),
      })
          .toList();

      if (currentSaleItems.isEmpty) {
        debugPrint("저장할 항목이 없습니다.");
        return;
      }

      String? existingHistory = prefs.getString('sales_history');
      List<dynamic> historyList = [];
      if (existingHistory != null && existingHistory.isNotEmpty) {
        try {
          historyList = jsonDecode(existingHistory);
        } catch (e) {
          historyList = [];
        }
      }

      int newSalesNumber = 1;
      if (historyList.isNotEmpty) {
        final int lastNumber = historyList.first['salesNumber'] ?? 0;
        newSalesNumber = lastNumber + 1;
      }

      Map<String, dynamic> saleRecord = {
        'id': DateTime.now().millisecondsSinceEpoch,
        'salesNumber': newSalesNumber,
        'items': currentSaleItems,
        'totalAmount': getTotalCartPrice(),
        'isCardPayment': isCardPayment,
        'date': DateTime.now().toIso8601String(),
      };
      historyList.insert(0, saleRecord);

      String jsonString = jsonEncode(historyList);
      await prefs.setString('sales_history', jsonString);
    } catch (e) {
      debugPrint("판매 내역 저장 오류: $e");
      rethrow;
    }
  }
}