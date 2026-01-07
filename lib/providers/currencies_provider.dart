import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/currency.dart';

final currenciesProvider = FutureProvider<List<Currency>>((ref) async {
  final supabase = Supabase.instance.client;
  final response = await supabase
      .from('currency')
      .select('*')
      .eq('is_active', true)
      .order('currency_name');
  
  return (response as List)
      .map((json) => Currency.fromJson(json as Map<String, dynamic>))
      .toList();
});

final currencyProvider = FutureProvider.family<Currency?, int>((ref, id) async {
  final currencies = await ref.watch(currenciesProvider.future);
  try {
    return currencies.firstWhere((currency) => currency.currencyId == id);
  } catch (e) {
    return null;
  }
});

final defaultCurrencyProvider = FutureProvider<Currency?>((ref) async {
  final currencies = await ref.watch(currenciesProvider.future);
  try {
    // Tentar encontrar USD primeiro
    return currencies.firstWhere((currency) => currency.currencyCode == 'USD');
  } catch (e) {
    // Se não encontrar USD, retornar a primeira moeda
    if (currencies.isNotEmpty) {
      return currencies.first;
    }
    return null;
  }
}); 
