class ProductModel {
  final int discountPrice;
  final int discountQuantity;
  final String name;
  final int price;
  final int productNumber;
  final String borderColor;

  const ProductModel({
    required this.discountPrice,
    required this.discountQuantity,
    required this.name,
    required this.price,
    required this.productNumber,
    required this.borderColor,
  });

  //
  factory ProductModel.fromFirestore(Map<String, dynamic> data) {
    return ProductModel(
      discountPrice: data['discountPrice'] ?? 0,
      discountQuantity: data['discountQuantity'] ?? 0,
      name: data['name'] ?? '',
      price: data['price'] ?? 0,
      productNumber: data['productNumber'] ?? 0,
      borderColor: data['borderColor'] ?? '',
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
      borderColor: json['borderColor'] ?? '',
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
      "borderColor": borderColor,
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
  }) {
    return ProductModel(
      discountPrice: discountPrice ?? this.discountPrice,
      discountQuantity: discountQuantity ?? this.discountQuantity,
      name: name ?? this.name,
      price: price ?? this.price,
      productNumber: productNumber ?? this.productNumber,
      borderColor: borderColor ?? this.borderColor,
    );
  }
}