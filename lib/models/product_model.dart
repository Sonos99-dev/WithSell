class ProductModel {
  final int discountPrice;
  final int discountQuantity;
  final String imgUrl;
  final String name;
  final int price;
  final int productNumber;
  final String borderColor;

  const ProductModel({
    required this.discountPrice,
    required this.discountQuantity,
    required this.imgUrl,
    required this.name,
    required this.price,
    required this.productNumber,
    required this.borderColor,
  });

  //
  factory ProductModel.fromFirestore(Map<String, dynamic> data) {
    return ProductModel(
      discountPrice: data['discount_price'] ?? 0,
      discountQuantity: data['discount_quantity'] ?? 0,
      imgUrl: data['img_url'] ?? '',
      name: data['name'] ?? '',
      price: data['price'] ?? 0,
      productNumber: data['product_number'] ?? 0,
      borderColor: data['border_color'] ?? '',
    );
  }

  // JSON → Model
  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      discountPrice: json['discount_price'] ?? 0,
      discountQuantity: json['discount_quantity'] ?? 0,
      imgUrl: json['img_url'] ?? '',
      name: json['name'] ?? '',
      price: json['price'] ?? 0,
      productNumber: json['product_number'] ?? 0,
      borderColor: json['border_color'] ?? '',
    );
  }

  // Model → JSON
  Map<String, dynamic> toJson() {
    return {
      "discount_price": discountPrice,
      "discount_quantity": discountQuantity,
      "img_url": imgUrl,
      "name": name,
      "price": price,
      "product_number": productNumber,
      "border_color": borderColor,
    };
  }

  // 🔥 Model → Firestore
  Map<String, dynamic> toMap() => toJson();

  ProductModel copyWith({
    int? discountPrice,
    int? discountQuantity,
    String? imgUrl,
    String? name,
    int? price,
    int? productNumber,
    String? borderColor,
  }) {
    return ProductModel(
      discountPrice: discountPrice ?? this.discountPrice,
      discountQuantity: discountQuantity ?? this.discountQuantity,
      imgUrl: imgUrl ?? this.imgUrl,
      name: name ?? this.name,
      price: price ?? this.price,
      productNumber: productNumber ?? this.productNumber,
      borderColor: borderColor ?? this.borderColor,
    );
  }
}