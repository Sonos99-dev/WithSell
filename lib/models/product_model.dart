import 'package:project/models/product_category.dart' show ProductCategory;

class ProductModel {
  final int discountPrice;
  final int discountQuantity;
  final String name;
  final int price;
  final int productNumber;
  final String imgUrl;
  final ProductCategory category;

  const ProductModel({
    required this.discountPrice,
    required this.discountQuantity,
    required this.name,
    required this.price,
    required this.productNumber,
    required this.imgUrl,
    required this.category,
  });

  //
  factory ProductModel.fromFirestore(Map<String, dynamic> data) {
    return ProductModel(
      discountPrice: data['discountPrice'] ?? 0,
      discountQuantity: data['discountQuantity'] ?? 0,
      name: data['name'] ?? '',
      price: data['price'] ?? 0,
      productNumber: data['productNumber'] ?? 0,
      imgUrl: data['imgUrl'] ?? '',
      category: ProductCategory.values.firstWhere(
            (e) => e.name == (data['category'] ?? 'etc'),
        orElse: () => ProductCategory.etc,
      ),
    );
  }

  // JSON → Model
  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      discountPrice: json['discountPrice'] ?? 0,
      discountQuantity: json['discountQuantity'] ?? 0,
      name: json['name'] ?? '',
      price: json['price'] ?? 0,
      productNumber: json['productNumber'] ?? 0,
      imgUrl: json['imgUrl'] ?? '',
      category: ProductCategory.values.firstWhere(
            (e) => e.name == (json['category'] ?? 'etc'),
        orElse: () => ProductCategory.etc,
      ),
    );
  }

  // Model → JSON
  Map<String, dynamic> toJson() {
    return {
      "discountPrice": discountPrice,
      "discountQuantity": discountQuantity,
      "name": name,
      "price": price,
      "productNumber": productNumber,
      "imgUrl": imgUrl,
      "category": category.name,
    };
  }

  // 🔥 Model → Firestore
  Map<String, dynamic> toMap() => toJson();

  ProductModel copyWith({
    int? discountPrice,
    int? discountQuantity,
    String? name,
    int? price,
    int? productNumber,
    String? borderColor,
    String? imgUrl,
    ProductCategory? category,
  }) {
    return ProductModel(
      discountPrice: discountPrice ?? this.discountPrice,
      discountQuantity: discountQuantity ?? this.discountQuantity,
      name: name ?? this.name,
      price: price ?? this.price,
      productNumber: productNumber ?? this.productNumber,
      imgUrl: imgUrl ?? this.imgUrl,
      category: category ?? this.category
    );
  }
}