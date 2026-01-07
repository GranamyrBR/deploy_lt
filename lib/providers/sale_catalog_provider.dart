import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product.dart';
import '../models/service.dart';
import '../models/sale_item.dart';

final saleCatalogProvider = FutureProvider<List<SaleItem>>((ref) async {
  final supabase = Supabase.instance.client;
  
  try {
  // Buscar produtos
  final productsResponse = await supabase.from('product').select();
    final products = (productsResponse as List).map((json) {
      try {
        return Product.fromJson(json);
      } catch (e) {
        print('Erro ao converter produto: $e');
        return null;
      }
    }).where((p) => p != null).cast<Product>().toList();
    
  // Buscar serviços
  final servicesResponse = await supabase.from('service').select();
    final services = (servicesResponse as List).map((json) {
      try {
        return Service.fromJson(json);
      } catch (e) {
        print('Erro ao converter serviço: $e');
        return null;
      }
    }).where((s) => s != null).cast<Service>().toList();

  // Transformar em SaleItem
    final productItems = products.where((p) => p.name.isNotEmpty && p.pricePerUnit != null).map((p) => SaleItem(
    type: SaleItemType.product,
    id: p.productId,
    name: p.name,
    price: p.pricePerUnit ?? 0.0,
    taxPercentage: p.taxPercentage ?? 0.0,
    imageUrl: p.imageUrl,
    sku: null,
    stock: null,
  ));
    
  final serviceItems = services.map((s) => SaleItem(
    type: SaleItemType.service,
    id: s.id,
      name: s.name ?? 'Serviço sem nome',
    price: s.price ?? 0.0,
    taxPercentage: 0.0,
    imageUrl: null,
    sku: null,
    stock: null,
  ));

  return [...productItems, ...serviceItems];
  } catch (e) {
    print('Erro no saleCatalogProvider: $e');
    return [];
  }
}); 
