import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:project/models/product_model.dart';
import 'package:project/repositories/product_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminViewModel extends ChangeNotifier {
  final ProductRepository _repo;
  AdminViewModel(this._repo);

  Future<List<ProductModel>> syncAndSave() async {
    try {
      final remoteProducts = await _repo.getProductsOnce();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('cached_products');

      if (remoteProducts.isNotEmpty) {
        final String encoded = jsonEncode(
          remoteProducts.map((p) => p.toJson()).toList(),
        );
        await prefs.setString('cached_products', encoded);
      }

      return remoteProducts;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<ProductModel>> loadFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final String? encoded = prefs.getString('cached_products');

    if (encoded != null) {
      final List<dynamic> decoded = jsonDecode(encoded);
      return decoded.map((item) => ProductModel.fromJson(item)).toList();
    }
    return [];
  }
}