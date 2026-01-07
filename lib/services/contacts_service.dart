import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/contact_category.dart';
import '../models/contact.dart';

class ContactsService {
  SupabaseClient get _client => Supabase.instance.client;

  String _normalizePhone(String phone) {
    return phone.replaceAll(RegExp(r'[^0-9+]'), '');
  }

  // Buscar todos os contatos
  Future<List<Contact>> getContacts({bool? isActive}) async {
    try {
      var query = _client.from('contact').select('*');

      final response = await query.order('name');
      return response.map<Contact>((json) => Contact.fromJson(json)).toList();
    } catch (e) {
      print('Erro ao buscar contatos: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getContactsPage({
    int limit = 100,
    int offset = 0,
    String? search,
    String sortField = 'name',
    bool ascending = true,
  }) async {
    try {
      final filter = _client.from('contact').select(
          'id, name, email, phone, city, country, updated_at, account:account_id(name), contact_category:contact_category_id(name)');

      if (search != null && search.trim().isNotEmpty) {
        final q = search.trim();
        filter.or(
            'name.ilike.%$q%,email.ilike.%$q%,phone.ilike.%$q%,city.ilike.%$q%,country.ilike.%$q%');
      }

      final builder = filter
          .order(sortField, ascending: ascending)
          .range(offset, offset + limit - 1);

      final rows = await builder;
      return (rows as List)
          .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (e) {
      print('Erro ao paginar contatos: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getContactsCountByCountry({
    DateTime? start,
    DateTime? end,
    String? categoryName,
    String? search,
    int pageSize = 200,
  }) async {
    try {
      final Map<String, int> counts = {};
      var offset = 0;
      while (true) {
        final sel = _client.from('contact').select(
            'country, updated_at, contact_category:contact_category_id(name)');
        if (search != null && search.trim().isNotEmpty) {
          final q = search.trim();
          sel.or(
              'name.ilike.%$q%,email.ilike.%$q%,phone.ilike.%$q%,city.ilike.%$q%,country.ilike.%$q%');
        }
        final page =
            await sel.order('country').range(offset, offset + pageSize - 1);
        if (page is! List || page.isEmpty) break;
        for (final row in page) {
          final updatedAtStr = row['updated_at'] as String?;
          if (start != null || end != null) {
            if (updatedAtStr == null) continue;
            final dt = DateTime.tryParse(updatedAtStr);
            if (dt == null) continue;
            if (start != null && dt.isBefore(start)) continue;
            if (end != null && dt.isAfter(end)) continue;
          }
          if (categoryName != null && categoryName.trim().isNotEmpty) {
            final cat = row['contact_category']?['name'] as String?;
            if (cat == null || cat != categoryName) continue;
          }
          final country = (row['country'] as String?)?.trim();
          final key =
              (country == null || country.isEmpty) ? 'Desconhecido' : country;
          counts[key] = (counts[key] ?? 0) + 1;
        }
        offset += pageSize;
        if ((page as List).length < pageSize) break;
      }
      final total = counts.values.fold<int>(0, (a, b) => a + b);
      final list = counts.entries
          .map((e) => {
                'country': e.key,
                'total': e.value,
                'percent': total == 0 ? 0.0 : (e.value / total) * 100.0,
              })
          .toList();
      list.sort((a, b) => (b['total'] as int).compareTo(a['total'] as int));
      return list;
    } catch (e) {
      print('Erro ao agregar contatos por país: $e');
      return [];
    }
  }

  Future<List<Contact>> getContactsByUserType(UserType userType,
      {int limit = 100, int offset = 0}) async {
    try {
      final rows = await Supabase.instance.client
          .rpc('get_contacts_by_user_type', params: {
        'p_user_type': userType.name,
        'p_limit': limit,
        'p_offset': offset,
      });
      return (rows as List)
          .map<Contact>((json) => Contact.fromJson(json))
          .toList();
    } catch (e) {
      print('Erro ao buscar contatos por user_type: $e');
      return [];
    }
  }

  // Buscar contato por ID
  Future<Contact?> getContactById(int id) async {
    try {
      final response =
          await _client.from('contact').select('*').eq('id', id).single();

      return Contact.fromJson(response);
    } catch (e) {
      print('Erro ao buscar contato: $e');
      return null;
    }
  }

  // Buscar contato por email
  Future<Contact?> getContactByEmail(String email) async {
    try {
      final response =
          await _client.from('contact').select('*').eq('email', email).single();

      return Contact.fromJson(response);
    } catch (e) {
      print('Erro ao buscar contato por email: $e');
      return null;
    }
  }

  // Buscar contato por telefone diretamente na tabela contact
  Future<Contact?> getContactByPhone(String phone) async {
    try {
      print('🔍 DEBUG: Buscando contato por telefone: "$phone"');
      final original = phone.trim();
      final clean = original.replaceAll(RegExp(r'[^0-9+]'), '');

      // 1) Tentativa com o telefone original
      var resp = await _client
          .from('contact')
          .select('*')
          .eq('phone', original)
          .maybeSingle();
      if (resp != null) {
        print('✅ DEBUG: Contato encontrado com telefone original');
        return Contact.fromJson(resp);
      }

      // 2) Tentativa com telefone normalizado
      resp = await _client
          .from('contact')
          .select('*')
          .eq('phone', clean)
          .maybeSingle();
      if (resp != null) {
        print('✅ DEBUG: Contato encontrado com telefone normalizado');
        return Contact.fromJson(resp);
      }

      // 3) Fallback: busca parcial pelos últimos 8 dígitos
      final last8 =
          clean.length >= 8 ? clean.substring(clean.length - 8) : clean;
      if (last8.isNotEmpty) {
        final list = await _client
            .from('contact')
            .select('*')
            .like('phone', '%$last8%')
            .order('id', ascending: false).limit(1);
        if (list is List && list.isNotEmpty) {
          print('✅ DEBUG: Contato encontrado por correspondência parcial');
          return Contact.fromJson(list.first);
        }
      }

      print('❌ DEBUG: Nenhum contato encontrado para telefone: $phone');
      return null;
    } catch (e) {
      print('❌ Erro ao buscar contato por telefone: $e');
      return null;
    }
  }

  // Criar novo contato
  Future<Contact> createContact({
    required String name,
    required String email,
    required String phone,
    String? address,
    String? city,
    String? state,
    String? country,
    String? postalCode,
    String? gender,
    String? userType = 'normal',
    int? accountId = 179, // Lecotour padrão
    int? sourceId = 13, // WhatsApp padrão
    int? contactCategoryId = 12, // Lead padrão
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
      if (exists is List && exists.isNotEmpty) {
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
            'gender': gender,
            'user_type': userType,
            'account_id': accountId,
            'source_id': sourceId,
            'contact_category_id': contactCategoryId,
          })
          .select()
          .single();

      return Contact.fromJson(response);
    } catch (e) {
      print('Erro ao criar contato: $e');
      rethrow;
    }
  }

  // Atualizar contato
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
      print('Erro ao atualizar contato: $e');
      rethrow;
    }
  }

  // Atualizar tipo de usuário do contato
  Future<Contact> updateContactUserType(int id, UserType userType) async {
    try {
      if (userType == UserType.driver) {
        throw Exception(
            'UserType driver deve ser gerenciado na tabela driver, não em contact');
      }
      print(
          '🔍 DEBUG: Iniciando atualização do contato ID $id para tipo ${userType.name}');
      final response = await _client
          .from('contact')
          .update({'user_type': userType.name})
          .eq('id', id)
          .select()
          .single();
      print('🔍 DEBUG: Resposta do banco: $response');
      final updatedContact = Contact.fromJson(response);
      print(
          '✅ DEBUG: Contato atualizado com sucesso - ID: ${updatedContact.id}, UserType: ${updatedContact.userType}');
      return updatedContact;
    } catch (e) {
      print('❌ Erro ao atualizar tipo de usuário do contato ID $id: $e');
      rethrow;
    }
  }

  Future<Contact> setContactUserTypeByPhone(String phone, UserType userType,
      {String? name}) async {
    final found = await getContactByPhone(phone);
    if (found != null) {
      if (userType == UserType.driver) {
        await ensureDriverFromLead(phone, name);
        await Supabase.instance.client.rpc('set_lead_user_type', params: {
          'p_phone': phone,
          'p_user_type': userType.name,
        });
        return found;
      }
      return await updateContactUserType(found.id, userType);
    }
    // Se não existe contato, persistir no leadstintim (se coluna existir)
    try {
      await Supabase.instance.client.rpc('set_lead_user_type', params: {
        'p_phone': phone,
        'p_user_type': userType.name,
      });
      // Retornar um contato sintético apenas para fluxo
      return Contact(
        id: -1,
        name: name ?? 'Lead WhatsApp',
        email: null,
        phone: phone,
        city: null,
        country: null,
        state: null,
        zipCode: null,
        gender: null,
        sourceId: null,
        source: null,
        accountId: null,
        accountType: null,
        contactCategoryId: null,
        contactCategory: null,
        createdAt: null,
        updatedAt: null,
        userType: userType,
      );
    } catch (e) {
      throw Exception(
          'Persistência de user_type indisponível (leadstintim sem coluna): $e');
    }
  }

  Future<void> ensureDriverFromLead(String phone, String? name) async {
    final clean = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    try {
      final exists =
          await _client.from('driver').select('id').eq('phone', clean).order('id', ascending: false).limit(1);
      if (exists is List && exists.isNotEmpty) return;
      await _client.from('driver').insert({
        'name': name ?? 'Motorista',
        'phone': clean,
      });
      print('✅ Driver criado a partir do lead: $clean');
    } catch (e) {
      print('❌ Erro ao garantir driver do lead: $e');
    }
  }

  Future<Map<String, UserType>> fetchLeadUserTypesFromLeadstintim() async {
    final map = <String, UserType>{};
    try {
      final rows = await Supabase.instance.client
          .from('leadstintim')
          .select('phone, user_type')
          .not('user_type', 'is', null)
          .not('phone', 'is', null);
      for (final row in rows) {
        final phone = row['phone'] as String?;
        final ut = row['user_type'] as String?;
        if (phone != null && ut != null) {
          try {
            map[phone] = UserType.values.firstWhere(
              (e) => e.name == ut,
              orElse: () => UserType.normal,
            );
          } catch (_) {
            map[phone] = UserType.normal;
          }
        }
      }
    } catch (e) {
      // Coluna pode não existir ainda; retornar vazio
    }
    return map;
  }

  // Deletar contato
  Future<void> deleteContact(int id) async {
    try {
      await _client.from('contact').delete().eq('id', id);
    } catch (e) {
      print('Erro ao deletar contato: $e');
      rethrow;
    }
  }

  // Buscar contatos por nome (busca parcial)
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
      print('Erro ao buscar contatos: $e');
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

  // Buscar estatísticas de contatos
  Future<Map<String, dynamic>> getContactStats() async {
    try {
      final response =
          await _client.from('contact').select('id, created_at, user_type');

      final total = response.length;
      final vips = response.where((c) => c['user_type'] == 'vip').length;

      return {
        'total': total,
        'vips': vips,
      };
    } catch (e) {
      print('Erro ao buscar estatísticas: $e');
      return {
        'total': 0,
        'vips': 0,
      };
    }
  }

  // Buscar categorias de contatos
  Future<List<ContactCategory>> getContactCategories() async {
    try {
      final response =
          await _client.from('contact_category').select('*').order('name');

      return response
          .map<ContactCategory>((json) => ContactCategory.fromJson(json))
          .toList();
    } catch (e) {
      print('Erro ao buscar categorias de contatos: $e');
      return [];
    }
  }
}
