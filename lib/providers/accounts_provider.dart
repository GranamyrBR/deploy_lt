import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/account.dart';

final accountsProvider = FutureProvider<List<Account>>((ref) async {
  final supabase = Supabase.instance.client;
  
  try {
    print('🔍 Tentando buscar dados da tabela account...');
    final response = await supabase
        .from('account')
        .select('*')
        .order('name');
    
    print('✅ Dados encontrados em account: ${response.length} registros');
    
    if (response.isEmpty) {
      print('⚠️ Tabela account está vazia, criando dados padrão...');
      // Inserir dados padrão na tabela account
      await supabase.from('account').insert([
        {
          'name': 'Pessoa Física',
          'contact_name': 'Cliente pessoa física',
          'is_active': true,
        },
        {
          'name': 'Pessoa Jurídica', 
          'contact_name': 'Cliente pessoa jurídica',
          'is_active': true,
        },
      ]);
      
      // Buscar novamente após inserir
      final newResponse = await supabase
          .from('account')
          .select('*')
          .order('name');
      
      print('✅ Dados padrão inseridos: ${newResponse.length} registros');
      final accounts = newResponse.map((json) => Account.fromJson(json)).toList();
      print('📋 Tipos de conta carregados: ${accounts.map((a) => '${a.id}: ${a.name}').join(', ')}');
      return accounts;
    }
    
    final accounts = response.map((json) => Account.fromJson(json)).toList();
    print('📋 Tipos de conta carregados: ${accounts.map((a) => '${a.id}: ${a.name}').join(', ')}');
    return accounts;
  } catch (e) {
    print('❌ Erro ao buscar account: $e');
    // Se a tabela não existir, retornar dados padrão
    print('⚠️ Tabela account não encontrada, retornando dados padrão');
    return [
      Account(
        id: 1,
        name: 'Pessoa Física',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Account(
        id: 2,
        name: 'Pessoa Jurídica',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];
  }
}); 
