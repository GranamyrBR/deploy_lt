class ProductCategory {
  final int categoryId;
  final String name;

  ProductCategory({required this.categoryId, required this.name});
 
  factory ProductCategory.fromJson(Map<String, dynamic> json) => ProductCategory(
    categoryId: json['category_id'] as int,
    name: json['name'] as String,
  );
} 
