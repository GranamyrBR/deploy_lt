import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import 'products_provider.dart';

final filteredProductsProvider = FutureProvider.family<List<Product>, int?>((ref, categoryId) async {
  final productsAsync = await ref.read(productsProvider.future);
  
  if (categoryId == null) {
    return productsAsync;
  }
  
  return productsAsync.where((product) => product.categoryId == categoryId).toList();
}); 
