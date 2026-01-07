import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/contact_category.dart';
import '../models/contact.dart';

class ContactsService {
  SupabaseClient get _client => Supabase.instance.client;

  String _normalizePhone(String phone) {
    return phone.replaceAll(RegExp(r'[^0-9+]'), '');
  }

  // Buscar todos os clientes
  Future<List<Contact>> getContacts({bool? isActive}) async {
    try {
      var query = _client.from('contact').select('*');
      
      if (isActive != null) {
        query = query.eq('is_active', isActive);
      }
      
      final response = await query.order('name');
      return response.map<Contact>((json) => Contact.fromJson(json)).toList();
    } catch (e) {
      print('Erro ao buscar clientes: $e');
      return [];
    }
  }

  // Buscar cliente por ID
  Future<Contact?> getContactById(int id) async {
    try {
      final response = await _client
          .from('contact')
          .select('*')
          .eq('id', id)
          .single();
      
      return Contact.fromJson(response);
    } catch (e) {
      print('Erro ao buscar cliente: $e');
      return null;
    }
  }

  // Buscar cliente por email
  Future<Contact?> getContactByEmail(String email) async {
    try {
      final response = await _client
          .from('contact')
          .select('*')
          .eq('email', email)
          .single();
      
      return Contact.fromJson(response);
    } catch (e) {
      print('Erro ao buscar cliente por email: $e');
      return null;
    }
  }

  // Buscar cliente por telefone
  Future<Contact?> getContactByPhone(String phone) async {
    try {
      final response = await _client
          .from('contact')
          .select('*')
          .eq('phone', phone)
          .single();
      
      return Contact.fromJson(response);
    } catch (e) {
      print('Erro ao buscar cliente por telefone: $e');
      return null;
    }
  }

  // Criar novo cliente
  Future<Contact> createContact({
    required String name,
    required String email,
    required String phone,
    String? address,
    String? city,
    String? state,
    String? country,
    String? postalCode,
    String? notes,
    int? categoryId,
    String? source,
    bool isActive = true,
  }) async {
    try {
      final normalizedPhone = _normalizePhone(phone);
      if (normalizedPhone.isEmpty) {
        throw Exception('Telefone obrigatório');
      }
      final exists = await _client
          .from('contact')
          .select('id')
          .eq('phone', normalizedPhone)
          .order('id', ascending: false).limit(1);
      if (exists.isNotEmpty) {
        throw Exception('Telefone já cadastrado');
      }
      final response = await _client
          .from('contact')
          .insert({
            'name': name,
            'email': email,
            'phone': normalizedPhone,
            'address': address,
            'city': city,
            'state': state,
            'country': country,
            'postal_code': postalCode,
            'notes': notes,
            'category_id': categoryId,
            'source': source,
            'is_active': isActive,
          })
          .select()
          .single();
      
      return Contact.fromJson(response);
    } catch (e) {
      print('Erro ao criar cliente: $e');
      rethrow;
    }
  }

  // Atualizar cliente
  Future<Contact> updateContact(int id, Map<String, dynamic> data) async {
    try {
      final payload = Map<String, dynamic>.from(data);
      if (payload.containsKey('phone')) {
        final p = payload['phone'];
        final normalized = p is String ? _normalizePhone(p) : '';
        if (normalized.isEmpty) {
          throw Exception('Telefone obrigatório');
        }
        payload['phone'] = normalized;
      }
      final response = await _client
          .from('contact')
          .update(payload)
          .eq('id', id)
          .select()
          .single();
      return Contact.fromJson(response);
    } catch (e) {
      print('Erro ao atualizar cliente: $e');
      rethrow;
    }
  }

  // Deletar cliente
  Future<void> deleteContact(int id) async {
    try {
      await _client
          .from('contact')
          .delete()
          .eq('id', id);
    } catch (e) {
      print('Erro ao deletar cliente: $e');
      rethrow;
    }
  }

  // Buscar clientes por nome (busca parcial)
  Future<List<Contact>> searchContacts(String term) async {
    if (term.trim().isEmpty) return [];
    
    try {
      final response = await _client
          .from('contact')
          .select('*')
          .or('name.ilike.%$term%,email.ilike.%$term%,phone.ilike.%$term%')
          .order('name');
      
      return response.map<Contact>((json) => Contact.fromJson(json)).toList();
    } catch (e) {
      print('Erro ao buscar clientes: $e');
      return [];
    }
  }

  // Verificar se email já existe
  Future<bool> isEmailRegistered(String email) async {
    try {
      final response = await _client
          .from('contact')
          .select('id')
          .eq('email', email)
          .order('id', ascending: false).limit(1);
      
      return response.isNotEmpty;
    } catch (e) {
      print('Erro ao verificar email: $e');
      return false;
    }
  }

  // Buscar estatísticas de clientes
  Future<Map<String, dynamic>> getContactStats() async {
    try {
      final response = await _client
          .from('contact')
          .select('id, created_at, is_active');
      
      final total = response.length;
      final active = response.where((c) => c['is_active'] == true).length;
      final inactive = total - active;
      
      return {
        'total': total,
        'active': active,
        'inactive': inactive,
      };
    } catch (e) {
      print('Erro ao buscar estatísticas: $e');
      return {
        'total': 0,
        'active': 0,
        'inactive': 0,
      };
    }
  }

  Future<List<ContactCategory>> getContactCategories() async {
    try {
      final response = await _client
          .from('contact_category')
          .select('*')
          .eq('is_active', true)
          .order('name');
      
      return response.map<ContactCategory>((json) => ContactCategory.fromJson(json)).toList();
    } catch (e) {
      print('Erro ao buscar categorias de contatos: $e');
      return [];
    }
  }
} 
