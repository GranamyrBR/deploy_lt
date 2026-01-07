import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product_category.dart';

final productCategoriesProvider = FutureProvider<List<ProductCategory>>((ref) async {
  final supabase = Supabase.instance.client;
  final response = await supabase
      .from('product_category')
      .select('category_id, name')
      .order('name');
  return (response as List)
      .map((json) => ProductCategory.fromJson(json))
      .toList();
}); 
