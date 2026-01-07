import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product.dart';

final productsProvider = FutureProvider<List<Product>>((ref) async {
  final supabase = Supabase.instance.client;
  final response = await supabase
      .from('product')
      .select('*, product_category!category_id(name)')
      .eq('active_for_sale', true)
      .order('name');
  
  return (response as List).map((json) {
    // Extrair o nome da categoria do JOIN  
    final categoryData = json['product_category'] as Map<String, dynamic>?;
    final categoryName = categoryData?['name'] as String?;
    
    // Criar um JSON modificado com a categoria
    final modifiedJson = Map<String, dynamic>.from(json);
    modifiedJson['category'] = categoryName;
    
    return Product.fromJson(modifiedJson);
  }).toList();
}); 
