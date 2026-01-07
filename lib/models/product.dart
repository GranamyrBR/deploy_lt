class Product {
  final int productId;
  final String name;
  final double pricePerUnit;
  final double taxPercentage;
  final bool limited;
  final bool activeForSale;
  final int? categoryId;
  final String? imageUrl;
  final String? category;
  final String? description;

  // Computed property for backward compatibility
  double? get price => pricePerUnit;

  Product({
    required this.productId,
    required this.name,
    required this.pricePerUnit,
    required this.taxPercentage,
    required this.limited,
    required this.activeForSale,
    this.categoryId,
    this.imageUrl,
    this.category,
    this.description,
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        productId: json['product_id'] as int,
        name: json['name'] as String,
        pricePerUnit: (json['price_per_unit'] as num).toDouble(),
        taxPercentage: (json['tax_percentage'] as num).toDouble(),
        limited: json['limited'] as bool,
        activeForSale: json['active_for_sale'] as bool,
        categoryId: json['category_id'] as int?,
        imageUrl: json['image_url'] as String?,
        category: json['category'] as String?,
        description: json['description'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'product_id': productId,
        'name': name,
        'price_per_unit': pricePerUnit,
        'tax_percentage': taxPercentage,
        'limited': limited,
        'active_for_sale': activeForSale,
        'category_id': categoryId,
        'image_url': imageUrl,
        'category': category,
        'description': description,
      };
}
