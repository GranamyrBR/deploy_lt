import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/source.dart';

final sourcesProvider = FutureProvider<List<Source>>((ref) async {
  final supabase = Supabase.instance.client;
  
  try {
    final response = await supabase
        .from('sources')
        .select('*')
        .order('name');
    
    return response.map((json) => Source.fromJson(json)).toList();
  } catch (e) {
    // Se a tabela sources não existir, tentar com source
    try {
      final response = await supabase
          .from('source')
          .select('*')
          .order('name');
      
      return response.map((json) => Source.fromJson(json)).toList();
    } catch (e2) {
      // Se nenhuma tabela existir, retornar lista vazia
      return [];
    }
  }
}); 
