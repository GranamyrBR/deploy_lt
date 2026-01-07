import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/contact.dart';
import '../models/sale.dart';
import '../models/user.dart' as app_user;
import '../models/agency.dart';
import '../models/driver.dart';
import '../models/lead_tintim.dart';
import '../models/monday_entry.dart';

// Provider para busca global de contatos
final globalContactSearchProvider = FutureProvider.family<List<Contact>, String>((ref, term) async {
  if (term.trim().isEmpty) return [];
  
  try {
    final supabase = Supabase.instance.client;
    final response = await supabase
        .from('contact')
        .select()
        .or('name.ilike.%${term}%,email.ilike.%${term}%,phone.ilike.%${term}%')
        .order('id', ascending: false)
        .order('id', ascending: false).limit(10);
    
    return (response as List<dynamic>)
        .map((data) => Contact.fromJson(data as Map<String, dynamic>))
        .toList();
  } catch (e) {
    print('Erro ao buscar contatos: $e');
    return [];
  }
});

// Provider para busca global de vendas
final globalSalesSearchProvider = FutureProvider.family<List<Sale>, String>((ref, term) async {
  if (term.trim().isEmpty) return [];
  
  try {
    final supabase = Supabase.instance.client;
    
    // Verificar se o termo é um número (ID da venda)
    final saleId = int.tryParse(term);
    
    if (saleId != null) {
      // Buscar por ID da venda
      final response = await supabase
          .from('sale')
          .select('*, contact(*), seller:user_id(*)')
          .eq('id', saleId)
          .order('id', ascending: false)
          .order('id', ascending: false).limit(10);
      
      return (response as List<dynamic>)
          .map((data) => Sale.fromJson(data as Map<String, dynamic>))
          .toList();
    } else {
      // Buscar por nome do contato - fazer join manual
      final response = await supabase
          .from('sale')
          .select('*, contact(*), seller:user_id(*)')
          .order('id', ascending: false)
          .order('id', ascending: false).limit(10);
      
      // Filtrar localmente por nome do contato
      final sales = (response as List<dynamic>)
          .map((data) => Sale.fromJson(data as Map<String, dynamic>))
          .toList();
      
      return sales.where((sale) {
        final contactName = sale.contactName.toLowerCase();
        return contactName.contains(term.toLowerCase());
      }).toList();
    }
  } catch (e) {
    print('Erro ao buscar vendas: $e');
    return [];
  }
});

// Provider para busca global de usuários
final globalUserSearchProvider = FutureProvider.family<List<app_user.User>, String>((ref, term) async {
  if (term.trim().isEmpty) return [];
  
  try {
    final supabase = Supabase.instance.client;
    final response = await supabase
        .from('user')
        .select('*, department:department_id(*)')
        .or('username.ilike.%${term}%,email.ilike.%${term}%')
        .order('id', ascending: false)
        .order('id', ascending: false).limit(10);
    
    return (response as List<dynamic>)
        .map((data) => app_user.User.fromJson(data as Map<String, dynamic>))
        .toList();
  } catch (e) {
    print('Erro ao buscar usuários: $e');
    return [];
  }
});

// Provider para busca global de agências
final globalAgencySearchProvider = FutureProvider.family<List<Agency>, String>((ref, term) async {
  if (term.trim().isEmpty) return [];
  
  try {
    final supabase = Supabase.instance.client;
    final response = await supabase
        .from('account')
        .select()
        .or('name.ilike.%${term}%,email.ilike.%${term}%,phone.ilike.%${term}%')
        .order('id', ascending: false)
        .order('id', ascending: false).limit(10);
    
    return (response as List<dynamic>)
        .map((data) => Agency.fromJson(data as Map<String, dynamic>))
        .toList();
  } catch (e) {
    print('Erro ao buscar agências: $e');
    return [];
  }
});

// Provider para busca global de motoristas
final globalDriverSearchProvider = FutureProvider.family<List<Driver>, String>((ref, term) async {
  if (term.trim().isEmpty) return [];
  
  try {
    final supabase = Supabase.instance.client;
    final response = await supabase
        .from('driver')
        .select()
        .or('name.ilike.%${term}%,email.ilike.%${term}%,phone.ilike.%${term}%,city_name.ilike.%${term}%')
        .order('id', ascending: false)
        .order('id', ascending: false).limit(10);
    
    return (response as List<dynamic>)
        .map((data) => Driver.fromJson(data as Map<String, dynamic>))
        .toList();
  } catch (e) {
    print('Erro ao buscar motoristas: $e');
    return [];
  }
});

// Provider para busca global de leads tintim
final globalLeadTintimSearchProvider = FutureProvider.family<List<LeadTintim>, String>((ref, term) async {
  if (term.trim().isEmpty) return [];
  
  try {
    final supabase = Supabase.instance.client;
    final response = await supabase
        .from('leadstintim')
        .select()
        .or('name.ilike.%${term}%,phone.ilike.%${term}%,message.ilike.%${term}%')
        .order('id', ascending: false)
        .order('id', ascending: false).limit(10);
    
    return (response as List<dynamic>)
        .map((data) => LeadTintim.fromJson(data as Map<String, dynamic>))
        .toList();
  } catch (e) {
    print('Erro ao buscar leads tintim: $e');
    return [];
  }
});

// Provider para busca global de monday
final globalMondaySearchProvider = FutureProvider.family<List<MondayEntry>, String>((ref, term) async {
  if (term.trim().isEmpty) return [];
  
  try {
    final supabase = Supabase.instance.client;
    final response = await supabase
        .from('monday')
        .select('''
          *,
          contact_category:contact_category_id(id, name),
          source:source_id(id, name),
          account:account_id(id, name)
        ''')
        .or('name.ilike.%${term}%,email.ilike.%${term}%,phone.ilike.%${term}%')
        .order('id', ascending: false).limit(10);
    
    return (response as List<dynamic>)
        .map((data) => MondayEntry(
              id: data['contact_id'],
              name: data['name'],
              email: data['email'],
              telefone: data['phone'] ?? data['telefone'],
              cidade: data['city'] ?? data['cidade'],
              state: data['state'],
              country: data['country'],
              postalCode: data['postalCode'],
              address: data['address'],
              sexo: data['gender'] ?? data['sexo'],
              font: data['source']?['name'] ?? data['font'],
              contas: data['account']?['name'] ?? data['contas'],
              tipo: data['customer_type'] ?? data['tipo'],
              status: null, // não existe mais
              vendedor: data['vendedor'],
              previsaoStart: data['previsao_Start'],
              previsaoEnd: data['previsao_End'],
              servicos: data['servicos'],
              observacao: data['observacao'],
              contactDate: data['contact_date'],
              closingDate: data['closing_date'],
              log: data['log'],
              logAtual: data['log_atual'],
              diasViagem: data['dias_viagem'],
              closingDay: data['closing_day'],
              mondayId: data['monday_id'],
              createdAt: data['created_at'] != null ? DateTime.tryParse(data['created_at']) : null,
              updatedAt: data['updated_at'] != null ? DateTime.tryParse(data['updated_at']) : null,
              contactCategoryId: data['contact_category_id'],
              contactCategoryName: data['contact_category']?['name'],
              sourceId: data['source_id'],
              sourceName: data['source']?['name'],
              accountId: data['account_id'],
              accountName: data['account']?['name'],
              customerTypeName: data['contact_category']?['name'], // usar contact_category como fallback
            ))
        .toList();
  } catch (e) {
    print('Erro ao buscar monday: $e');
    return [];
  }
});
