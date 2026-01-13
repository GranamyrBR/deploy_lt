import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/contact.dart';
import '../widgets/base_screen_layout.dart';
import '../widgets/standard_search_bar.dart';
import '../widgets/customer_profile_modal.dart';
import 'create_sale_screen_v2.dart';
import '../providers/sources_provider.dart';
import '../providers/accounts_provider.dart';
import '../providers/contact_categories_provider.dart';
import '../utils/source_colors.dart';
import '../utils/phone_utils.dart';
import '../utils/flag_utils.dart';
import '../widgets/whatsapp_messages_modal.dart';
import '../services/contacts_service.dart';
import '../widgets/enhanced_quotation_dialog.dart';
import '../widgets/contact_follow_up_timeline.dart';
import '../widgets/quotation_management_dialog.dart';
import '../widgets/create_quotation_with_whatsapp_dialog.dart';
import '../widgets/quick_dates_dialog.dart';
import '../providers/lead_tintim_provider.dart';
import '../models/lead_tintim.dart';
import 'dart:math';

class ContactsScreen extends ConsumerStatefulWidget {
  const ContactsScreen({super.key});

  @override
  ConsumerState<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends ConsumerState<ContactsScreen> {
  final _client = Supabase.instance.client;
  final _contactsService = ContactsService();

  List<Map<String, dynamic>> _contacts = [];
  bool _isLoading = false;
  bool _visualizarComoCartao = false;
  bool _visualizarComoKanban = false;
  String _searchTerm = '';

  // Adicionado para scroll sincronizado
  final ScrollController _horizontalScrollController = ScrollController();

  // Variáveis para ordenação
  String _sortField = 'updated_at';
  bool _sortAscending = false; // Mais recente primeiro
  String _sortType =
      'date_updated'; // alphabetical, date_created, date_updated, account_type

  // Chaves para SharedPreferences
  static const String _sortFieldKey = 'contacts_sort_field';
  static const String _sortAscendingKey = 'contacts_sort_ascending';
  static const String _sortTypeKey = 'contacts_sort_type';

  // Map para rastrear tipos de usuário dos contatos
  final Map<String, UserType> _contactUserTypes = {};
  final Set<int> _contactsWithPurchase = {};
  final Set<int> _contactsWithLeadConverted = {};
  String _normalizePhone(dynamic phone) {
    final s = phone?.toString() ?? '';
    return s.replaceAll(RegExp(r'[^0-9+]'), '');
  }

  UserType? _filterUserType;

  @override
  void initState() {
    super.initState();
    _loadSortPreferences();
  }

  // Carregar configurações de ordenação salvas
  Future<void> _loadSortPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Verificar se é a primeira execução (sem preferências salvas)
      final isFirstRun = !prefs.containsKey(_sortTypeKey);

      setState(() {
        _sortField = prefs.getString(_sortFieldKey) ?? 'updated_at';
        _sortAscending = prefs.getBool(_sortAscendingKey) ?? false;
        _sortType = prefs.getString(_sortTypeKey) ?? 'date_updated';
      });

      // Se for a primeira execução, salvar as configurações padrão
      if (isFirstRun) {
        await _saveSortPreferences();
      }

      await _fetchContacts();
    } catch (e) {
      print('Erro ao carregar preferências de ordenação: $e');
      await _fetchContacts();
    }
  }

  // Salvar configurações de ordenação
  Future<void> _saveSortPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_sortFieldKey, _sortField);
      await prefs.setBool(_sortAscendingKey, _sortAscending);
      await prefs.setString(_sortTypeKey, _sortType);
    } catch (e) {
      print('Erro ao salvar preferências de ordenação: $e');
    }
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    super.dispose();
  }

  // Função para obter a bandeira do país (usando FlagUtils)
  String _getCountryFlag(String country) {
    return FlagUtils.getCountryFlag(country);
  }

  // Funções auxiliares para cores dos tipos de usuário
  Color _getCircleColor(UserType userType, bool isConverted) {
    switch (userType) {
      case UserType.driver:
        return isConverted
            ? const Color(0xFF9C27B0) // Roxo mais escuro para convertido
            : const Color(0xFFE1BEE7); // Roxo claro para não convertido
      case UserType.employee:
        return isConverted
            ? const Color(0xFF2196F3) // Azul mais escuro para convertido
            : const Color(0xFFBBDEFB); // Azul claro para não convertido
      case UserType.agency:
        return isConverted
            ? const Color(0xFFF97316) // Laranja mais escuro para convertido
            : const Color(0xFFFED7AA); // Laranja claro para não convertido
      case UserType.normal:
        return isConverted
            ? Theme.of(context)
                .colorScheme
                .primary // Cor primária para convertido
            : Theme.of(context).colorScheme.primary.withValues(
                alpha: 0.2); // Cor primária clara para não convertido
    }
  }

  Color _getBorderColor(UserType userType, bool isConverted) {
    switch (userType) {
      case UserType.driver:
        return isConverted
            ? const Color(0xFF7B1FA2) // Roxo mais escuro para borda
            : const Color(0xFF9C27B0); // Roxo médio para borda
      case UserType.employee:
        return isConverted
            ? const Color(0xFF1976D2) // Azul mais escuro para borda
            : const Color(0xFF2196F3); // Azul médio para borda
      case UserType.agency:
        return isConverted
            ? const Color(0xFFEA580C) // Laranja mais escuro para borda
            : const Color(0xFFF97316); // Laranja médio para borda
      case UserType.normal:
        return Theme.of(context).colorScheme.primary;
    }
  }

  Color _getTextColor() {
    return Colors.white;
  }

  Color _getUserTypeColor(UserType userType) {
    switch (userType) {
      case UserType.driver:
        return const Color(0xFF9C27B0); // Roxo
      case UserType.employee:
        return const Color(0xFF2196F3); // Azul
      case UserType.agency:
        return const Color(0xFF2196F3); // Azul
      case UserType.normal:
        return Colors.grey;
    }
  }

  String _getUserTypeLabel(UserType userType) {
    switch (userType) {
      case UserType.driver:
        return 'Motorista';
      case UserType.employee:
        return 'Colaborador';
      case UserType.agency:
        return 'Agência';
      case UserType.normal:
        return 'Normal';
    }
  }

  Future<void> _refreshContacts() async {
    print('🔄 Forçando atualização da lista...');
    await _fetchContacts();
  }

  Future<void> _fetchContacts() async {
    print('🔄 Iniciando _fetchContacts...');
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      List<dynamic> response;
      List<dynamic> quotationsResponse = []; // Declarar fora do bloco
      
      if (_filterUserType != null) {
        response = await Supabase.instance.client
            .rpc('get_contacts_by_user_type', params: {
          'p_user_type': _filterUserType!.name,
          'p_limit': 500,
          'p_offset': 0,
        });
      } else {
        response = await _client.from('contact').select('''
              *,
              source(name),
              account(name),
              contact_category(name)
            ''').order((_sortField == 'name' || _sortField == 'created_at' || _sortField == 'updated_at' || _sortField == 'account_id') ? _sortField : 'name', ascending: (_sortField == 'name' || _sortField == 'created_at' || _sortField == 'updated_at' || _sortField == 'account_id') ? _sortAscending : true);
        
        // Buscar cotações separadamente para adicionar datas aos contatos
        quotationsResponse = await _client
            .from('quotation')
            .select('client_id, travel_date, return_date, status, quotation_date')
            .not('travel_date', 'is', null)
            .order('travel_date', ascending: false);
      }

      print('✅ Dados recebidos: ${response.length} contatos');

      if (mounted) {
        // Montar listas para checar compras e leads convertidos
        final contactsList = response;
        
        // Criar mapa de cotações por client_id (se houver cotações)
        final quotationsByClientId = <int, Map<String, dynamic>>{};
        for (final q in quotationsResponse) {
          final clientId = q['client_id'] as int?;
          if (clientId != null) {
            // Guardar apenas a mais recente (já ordenado por travel_date DESC)
            if (!quotationsByClientId.containsKey(clientId)) {
              quotationsByClientId[clientId] = q;
            }
          }
        }
        
        // Adicionar datas aos contatos
        for (final c in contactsList) {
          final contactId = c['id'] as int?;
          if (contactId != null && quotationsByClientId.containsKey(contactId)) {
            final quotation = quotationsByClientId[contactId]!;
            c['travel_date'] = quotation['travel_date'];
            c['return_date'] = quotation['return_date'];
            c['quotation_status'] = quotation['status'];
          }
        }
        final ids = contactsList
            .map<int?>((c) => c['id'] as int?)
            .whereType<int>()
            .toList();
        final phoneToId = <String, int>{};
        for (final c in contactsList) {
          if (c['phone'] != null && c['id'] is int) {
            final norm = _normalizePhone(c['phone']);
            if (norm.isNotEmpty) phoneToId[norm] = c['id'] as int;
          }
        }

        // Buscar vendas concluídas/pagas para os contatos exibidos
        _contactsWithPurchase.clear();
        if (ids.isNotEmpty) {
          try {
            final sales = await Supabase.instance.client
                .from('sale')
                .select('customer_id, status, payment_status')
                .inFilter('customer_id', ids);
            for (final s in sales) {
              final status = (s['status'] as String?)?.toLowerCase();
              final payment = (s['payment_status'] as String?)?.toLowerCase();
              if (status == 'completed' || payment == 'paid') {
                final cid = s['customer_id'] as int?;
                if (cid != null) _contactsWithPurchase.add(cid);
              }
            }
          } catch (e) {
            print('Erro ao buscar vendas para contatos: $e');
          }
        }

        // Buscar leads com status convertido/compra
        _contactsWithLeadConverted.clear();
        if (phoneToId.isNotEmpty) {
          try {
            final leadRows = await Supabase.instance.client
                .from('leadstintim')
                .select('phone, status')
                .not('phone', 'is', null);
            for (final row in leadRows) {
              final phone = _normalizePhone(row['phone']);
              final status = (row['status'] as String?)?.toLowerCase() ?? '';
              if (phoneToId.containsKey(phone)) {
                final isConverted = status == 'converted' ||
                    status == 'comprou' ||
                    status.contains('compra');
                if (isConverted) {
                  _contactsWithLeadConverted.add(phoneToId[phone]!);
                }
              }
            }
          } catch (e) {
            print('Erro ao buscar leads convertidos: $e');
          }
        }

        setState(() {
          _contacts = List<Map<String, dynamic>>.from(contactsList);

          _contactUserTypes.clear();
          for (final contact in _contacts) {
            final contactId = contact['id'].toString();
            final userTypeString = contact['user_type'] as String?;
            if (userTypeString != null) {
              try {
                final userType = UserType.values.firstWhere(
                  (e) => e.name == userTypeString,
                  orElse: () => UserType.normal,
                );
                _contactUserTypes[contactId] = userType;
              } catch (e) {
                _contactUserTypes[contactId] = UserType.normal;
              }
            } else {
              _contactUserTypes[contactId] = UserType.normal;
            }
          }
          _isLoading = false;
        });
      }

      print(
          '✅ Lista atualizada com ${_contacts.length} contatos e ${_contactUserTypes.length} user_types carregados');
    } catch (e) {
      print('❌ Erro ao buscar contatos: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar contatos: $e')),
        );
      }
    }
  }

  void _criarVendaParaCliente(Map<String, dynamic> contactData) {
    final contact = Contact(
      id: contactData['id'] as int,
      name: contactData['name'] as String?,
      email: contactData['email'] as String?,
      phone: contactData['phone'] as String?,
      city: contactData['city'] as String?,
      country: contactData['country'] as String?,
      state: contactData['state'] as String?,
      zipCode: contactData['postal_code'] as String?,
      gender: contactData['gender'] as String?,
      sourceId: contactData['source_id'] as int?,
      source: contactData['source']?['name'] as String?,
      accountId: contactData['account_id'] as int?,
      accountType: contactData['account']?['name'] as String?,
      contactCategoryId: contactData['contact_category_id'] as int?,
      contactCategory: contactData['contact_category']?['name'] as String?,
      createdAt: contactData['created_at'] != null
          ? DateTime.tryParse(contactData['created_at'])
          : null,
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateSaleScreenV2(contact: contact),
      ),
    ).then((_) => _refreshContacts());
  }

  void _abrirPerfilCompleto(Map<String, dynamic> contactData) {
    showDialog(
      context: context,
      builder: (context) => CustomerProfileModal(
        customerId: contactData['id'] as int,
        customerName: contactData['name'] as String? ?? 'Cliente',
      ),
    );
  }

  void _abrirPerfilNaPagina(Map<String, dynamic> contactData) {
    Navigator.pushNamed(
      context,
      '/customer-profile',
      arguments: {
        'customerId': contactData['id'] as int,
        'customerName': contactData['name'] as String? ?? 'Cliente',
      },
    );
  }


  void _abrirTabelaGrid() {
    Navigator.pushNamed(
      context,
      '/contacts-grid',
      arguments: {
        'contacts': const <Map<String, dynamic>>[],
        'onOpenProfileModal': (Map<String, dynamic> c) =>
            _abrirPerfilCompleto(c),
        'onOpenProfilePage': (Map<String, dynamic> c) =>
            _abrirPerfilNaPagina(c),
        'onOpenWhatsApp': (Map<String, dynamic> c) => _abrirWhatsApp(c),
        'onCreateSale': (Map<String, dynamic> c) => _criarVendaParaCliente(c),
      },
    );
  }

  // Função para abrir mensagens do WhatsApp
  void _abrirWhatsApp(Map<String, dynamic> contactData) {
    final phone = contactData['phone'] as String?;
    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Este contato não possui número de telefone cadastrado'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Criar objeto Contact a partir dos dados
    final contact = Contact(
      id: contactData['id'],
      name: contactData['name'],
      phone: phone,
      email: contactData['email'],
      country: contactData['country'],
      state: contactData['state'],
      city: contactData['city'],
      sourceId: contactData['source_id'],
      contactCategoryId: contactData['contact_category_id'],
      createdAt: contactData['created_at'] != null
          ? DateTime.parse(contactData['created_at'])
          : null,
      updatedAt: contactData['updated_at'] != null
          ? DateTime.parse(contactData['updated_at'])
          : null,
    );

    showDialog(
      context: context,
      builder: (context) => WhatsAppMessagesModal(contact: contact),
    );
  }

  // Adiciona método para padronizar InputDecoration
  InputDecoration _buildModernInputDecoration(String label,
      {String? hintText, String? suffixText}) {
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      suffixText: suffixText,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      filled: true,
      fillColor: Theme.of(context).colorScheme.surface,
    );
  }

  // Função para obter nome do país a partir do código ISO
  String _getCountryName(String? countryCode) {
    if (countryCode == null) return 'Desconhecido';
    return FlagUtils.getCountryNameFromIsoCode(countryCode);
  }

  // Método para construir estatísticas de estados

  Future<void> _abrirCriarCotacaoComWhatsApp(Map<String, dynamic> contactData) async {
    final phone = contactData['phone'] as String?;
    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este contato não possui número de telefone cadastrado'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Criar objeto Contact a partir dos dados
    final contact = Contact(
      id: contactData['id'],
      name: contactData['name'],
      phone: phone,
      email: contactData['email'],
      country: contactData['country'],
      state: contactData['state'],
      city: contactData['city'],
      sourceId: contactData['source_id'],
      contactCategoryId: contactData['contact_category_id'],
      createdAt: contactData['created_at'] != null
          ? DateTime.parse(contactData['created_at'])
          : null,
      updatedAt: contactData['updated_at'] != null
          ? DateTime.parse(contactData['updated_at'])
          : null,
    );

    // Buscar mensagens do WhatsApp diretamente do banco
    List<LeadTintim> whatsappMessages = [];
    try {
      // Normalizar telefone (remover caracteres especiais)
      final normalizedPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
      
      print('🔍 Buscando mensagens para telefone: $phone (normalizado: $normalizedPhone)');
      
      // Buscar por telefone exato ou normalizado
      final response = await _client
          .from('leadstintim')
          .select()
          .or('phone.eq.$phone,phone.eq.$normalizedPhone')
          .order('created_at', ascending: false);
      
      whatsappMessages = (response as List)
          .map((json) => LeadTintim.fromJson(json))
          .toList();
      
      print('✅ Carregadas ${whatsappMessages.length} mensagens para $phone');
    } catch (e) {
      print('❌ Erro ao carregar mensagens: $e');
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => CreateQuotationWithWhatsAppDialog(
        initialContact: contact,
        whatsappMessages: whatsappMessages,
      ),
    );
  }

  Future<void> _abrirDatasRapidas(Map<String, dynamic> contactData) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => QuickDatesDialog(
        contactName: contactData['name'] ?? 'Sem nome',
        contactPhone: contactData['phone'] ?? '',
        contactId: contactData['id'],
      ),
    );

    if (result == null) return;

    // Salvar cotação rápida com apenas as datas
    await _salvarCotacaoRapida(contactData, result);
  }

  Future<void> _salvarCotacaoRapida(
    Map<String, dynamic> contactData,
    Map<String, dynamic> dates,
  ) async {
    try {
      // Criar cotação simplificada
      final quotationNumber = 'QT-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(9999).toString().padLeft(4, '0')}';
      
      final payload = {
        'quotation_number': quotationNumber,
        'type': 'service', // Tipo padrão
        'status': 'draft', // Status draft para cotações com apenas datas
        'client_id': contactData['id'], // FK para contact
        'client_name': contactData['name'],
        'client_phone': contactData['phone'],
        'client_email': contactData['email'],
        'travel_date': (dates['departure_date'] as DateTime).toIso8601String(),
        'return_date': dates['return_date'] != null 
            ? (dates['return_date'] as DateTime).toIso8601String() 
            : null,
        'notes': dates['notes'] ?? '', // Notas internas
        'subtotal': 0,
        'total': 0,
        'currency': 'USD',
        'quotation_date': DateTime.now().toIso8601String(),
        'created_by': 'system',
      };

      final response = await _client
          .from('quotation')
          .insert(payload)
          .select()
          .single();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('Datas salvas! ${_formatDate(dates['departure_date'])}'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        // Recarregar contatos para atualizar badges
        _fetchContacts();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar datas: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Widget _buildDaysUntilBadge(DateTime travelDate) {
    final daysUntil = travelDate.difference(DateTime.now()).inDays;
    
    Color backgroundColor;
    Color textColor;
    if (daysUntil <= 7) {
      backgroundColor = Colors.red.shade100;
      textColor = Colors.red.shade700;
    } else if (daysUntil <= 30) {
      backgroundColor = Colors.orange.shade100;
      textColor = Colors.orange.shade700;
    } else {
      backgroundColor = Colors.green.shade100;
      textColor = Colors.green.shade700;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'em $daysUntil ${daysUntil == 1 ? "dia" : "dias"}',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  // Função para extrair o código ISO do país a partir do DDI do telefone
  String? _getCountryCodeFromPhone(dynamic phone) {
    return FlagUtils.getCountryIsoCodeFromPhone(phone?.toString() ?? '');
  }

  String? _resolveIsoFromPhoneAndCountry(dynamic phone, dynamic country) {
    return _getCountryCodeFromPhone(phone) ??
        (country != null
            ? FlagUtils.getCountryIsoCode(country.toString())
            : null);
  }

  // Função para formatar telefone
  String _formatPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^\d+]'), '');

    if (digits.startsWith('+55')) {
      // Brasil com +: +55 (11) 99999-9999 ou +55 (11) 9999-9999
      if (digits.length == 13) {
        return '+55 (${digits.substring(3, 5)}) ${digits.substring(5, 10)}-${digits.substring(10)}';
      } else if (digits.length == 12) {
        return '+55 (${digits.substring(3, 5)}) ${digits.substring(5, 9)}-${digits.substring(9)}';
      }
    } else if (digits.startsWith('55') && digits.length == 13) {
      // Brasil sem +: 55 (11) 99999-9999
      return '+55 (${digits.substring(2, 4)}) ${digits.substring(4, 9)}-${digits.substring(9)}';
    } else if (digits.startsWith('55') && digits.length == 12) {
      // Brasil sem +: 55 (11) 9999-9999
      return '+55 (${digits.substring(2, 4)}) ${digits.substring(4, 8)}-${digits.substring(8)}';
    } else if (digits.startsWith('+1') && digits.length == 12) {
      // EUA: +1 (555) 123-4567
      return '+1 (${digits.substring(2, 5)}) ${digits.substring(5, 8)}-${digits.substring(8)}';
    } else if (digits.startsWith('1') && digits.length == 11) {
      // EUA sem +: 1 (555) 123-4567
      return '1 (${digits.substring(1, 4)}) ${digits.substring(4, 7)}-${digits.substring(7)}';
    } else if (digits.length == 11) {
      // Brasil sem DDI: (11) 99999-9999
      return '(${digits.substring(0, 2)}) ${digits.substring(2, 7)}-${digits.substring(7)}';
    } else if (digits.length == 10) {
      // Brasil sem DDI: (11) 9999-9999
      return '(${digits.substring(0, 2)}) ${digits.substring(2, 6)}-${digits.substring(6)}';
    } else if (digits.startsWith('351') && digits.length == 12) {
      // Portugal sem +: +351 963 788 149
      return '+351 ${digits.substring(3, 6)} ${digits.substring(6, 9)} ${digits.substring(9)}';
    } else if (digits.startsWith('+351') && digits.length == 13) {
      // Portugal com +: +351 963 788 149
      return '+351 ${digits.substring(4, 7)} ${digits.substring(7, 10)} ${digits.substring(10)}';
    }
    // Para outros casos, retorna o número original
    return phone;
  }

  // Método para visualizar detalhes do contato
  void _visualizarContato(Map<String, dynamic> contact) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF2A2D3E)
            : const Color(0xFFE8F2FF),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text(
                (contact['name'] ?? 'C').substring(0, 1).toUpperCase(),
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            if (_resolveIsoFromPhoneAndCountry(
                    contact['phone'], contact['country']) !=
                null)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Image.network(
                  FlagUtils.getFlagUrl(
                      _resolveIsoFromPhoneAndCountry(
                          contact['phone'], contact['country'])!,
                      width: 24,
                      height: 18),
                  width: 24,
                  height: 18,
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox(width: 24, height: 18),
                ),
              ),
            Expanded(
              child: Text(
                contact['name'] ?? 'Nome não informado',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow(
                  'Nome', contact['name'] ?? 'Não informado', Icons.person),
              _buildDetailRow(
                  'Email', contact['email'] ?? 'Não informado', Icons.email),
              _buildDetailRow(
                  'Telefone', contact['phone'] ?? 'Não informado', Icons.phone),
              _buildDetailRow('Gênero', _getGenderText(contact['gender']),
                  Icons.person_outline),
              _buildDetailRow('Cidade', contact['city'] ?? 'Não informado',
                  Icons.location_city),
              _buildDetailRow('Estado', contact['state'] ?? 'Não informado',
                  Icons.location_on),
              _buildDetailRow(
                  'País', contact['country'] ?? 'Não informado', Icons.public),
              _buildDetailRow('CEP', contact['postal_code'] ?? 'Não informado',
                  Icons.markunread_mailbox),
              _buildDetailRow('Origem',
                  contact['source']?['name'] ?? 'Não informado', Icons.source),
              _buildDetailRow(
                  'Tipo de Conta',
                  contact['account']?['name'] ?? 'Não informado',
                  Icons.account_circle),
              _buildDetailRow(
                  'Categoria',
                  contact['contact_category']?['name'] ?? 'Não informado',
                  Icons.category),
              if (contact['created_at'] != null)
                _buildDetailRow(
                    'Data de Criação',
                    DateTime.tryParse(contact['created_at'])
                            ?.toString()
                            .split(' ')[0] ??
                        'Não informado',
                    Icons.calendar_today),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              final parent = Navigator.of(context).overlay?.context ?? context;
              Navigator.pop(context);
              showDialog(
                context: parent,
                builder: (ctx) => EnhancedQuotationDialog(
                  leadTitle: (contact['name'] ?? '').toString(),
                ),
              ).then((quotation) {
                if (quotation != null) {
                  showDialog(
                    context: parent,
                    builder: (ctx) => QuotationManagementDialog(
                      quotation: quotation,
                    ),
                  );
                }
              });
            },
            icon: const Icon(Icons.description),
            label: const Text('Cotação'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _editarContato(contact);
            },
            icon: const Icon(Icons.edit),
            label: const Text('Editar'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _criarVendaParaCliente(contact);
            },
            icon: const Icon(Icons.shopping_cart),
            label: const Text('Nova Venda'),
          ),
        ],
      ),
    );
  }

  String _getGenderText(String? gender) {
    switch (gender) {
      case 'M':
        return 'Masculino';
      case 'F':
        return 'Feminino';
      case 'O':
        return 'Outro';
      default:
        return 'Não informado';
    }
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 16,
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.7),
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                // Adicionar flag do país antes do telefone
                if (label == 'Telefone' &&
                    value != 'Não informado' &&
                    _getCountryCodeFromPhone(value) != null) ...[
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Image.network(
                      FlagUtils.getFlagUrl(_getCountryCodeFromPhone(value)!,
                          width: 20, height: 15),
                      width: 20,
                      height: 15,
                      errorBuilder: (context, error, stackTrace) =>
                          const SizedBox(width: 20, height: 15),
                    ),
                  ),
                ],
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Método para editar contato
  void _editarContato(Map<String, dynamic> contact) async {
    final formKey = GlobalKey<FormState>();
    String? name = contact['name'],
        phone = contact['phone'],
        email = contact['email'],
        cityName = contact['city'],
        countryCode = contact['country'],
        stateCode = contact['state'],
        zipCode = contact['postal_code'],
        gender = contact['gender'];
    int? sourceId = contact['source_id'],
        accountId = contact['account_id'],
        contactCategoryId = contact['contact_category_id'];
    bool isSubmitting = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, modalSetState) => AlertDialog(
            backgroundColor: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF2A2D3E)
                : const Color(0xFFE8F2FF),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              'Editar Contato',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            content: SizedBox(
              width: 600,
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Primeira linha: Nome e Telefone
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              initialValue: name,
                              decoration: _buildModernInputDecoration('Nome *'),
                              validator: (v) => v == null || v.isEmpty
                                  ? 'Informe o nome'
                                  : null,
                              onSaved: (v) => name = v,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              initialValue: phone,
                              decoration:
                                  _buildModernInputDecoration('Telefone *'),
                              keyboardType: TextInputType.phone,
                              inputFormatters: [
                                PhoneInputFormatter(
                                  allowEndlessPhone: true,
                                ),
                              ],
                              validator: (v) => v == null || v.isEmpty
                                  ? 'Informe o telefone'
                                  : null,
                              onSaved: (v) => phone = v,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Segunda linha: Email e Gênero
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              initialValue: email,
                              decoration: _buildModernInputDecoration('Email'),
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) =>
                                  v != null && v.isNotEmpty && !v.contains('@')
                                      ? 'Email inválido'
                                      : null,
                              onSaved: (v) => email = v,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 1,
                            child: DropdownButtonFormField<String>(
                              decoration: _buildModernInputDecoration('Gênero'),
                              initialValue: gender,
                              items: const [
                                DropdownMenuItem(
                                    value: null, child: Text('Selecione')),
                                DropdownMenuItem(
                                    value: 'M', child: Text('Masculino')),
                                DropdownMenuItem(
                                    value: 'F', child: Text('Feminino')),
                                DropdownMenuItem(
                                    value: 'O', child: Text('Outro')),
                              ],
                              onChanged: (value) {
                                modalSetState(() {
                                  gender = value;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Terceira linha: Origem (largura total)
                      Consumer(
                        builder: (context, ref, child) {
                          final sourceAsync = ref.watch(sourcesProvider);
                          return sourceAsync.when(
                            data: (source) => DropdownButtonFormField<int>(
                              decoration: _buildModernInputDecoration('Origem'),
                              initialValue: sourceId,
                              items: [
                                const DropdownMenuItem(
                                    value: null, child: Text('Selecione')),
                                ...source.map((source) => DropdownMenuItem(
                                      value: source.id,
                                      child: Text(source.name ?? ''),
                                    )),
                              ],
                              onChanged: (value) {
                                modalSetState(() {
                                  sourceId = value;
                                });
                              },
                              validator: (value) =>
                                  value == null ? 'Selecione a origem' : null,
                            ),
                            loading: () => const SizedBox(
                              height: 56,
                              child: Center(child: CircularProgressIndicator()),
                            ),
                            error: (error, stack) => SizedBox(
                              height: 56,
                              child: Center(child: Text('Erro: $error')),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      // Quarta linha: Tipo de Conta (largura total)
                      Consumer(
                        builder: (context, ref, child) {
                          final accountAsync = ref.watch(accountsProvider);
                          return accountAsync.when(
                            data: (account) => DropdownButtonFormField<int>(
                              decoration:
                                  _buildModernInputDecoration('Tipo Conta'),
                              initialValue: account.any((a) => a.id == accountId)
                                  ? accountId
                                  : null,
                              items: [
                                const DropdownMenuItem(
                                    value: null, child: Text('Selecione')),
                                ...account.map((account) => DropdownMenuItem(
                                      value: account.id,
                                      child: Text(
                                        account.name ?? '',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    )),
                              ],
                              onChanged: (value) {
                                modalSetState(() {
                                  accountId = value;
                                });
                              },
                              validator: (value) => value == null
                                  ? 'Selecione o tipo de conta'
                                  : null,
                            ),
                            loading: () => const SizedBox(
                              height: 56,
                              child: Center(child: CircularProgressIndicator()),
                            ),
                            error: (error, stack) => SizedBox(
                              height: 56,
                              child: Center(child: Text('Erro: $error')),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      // Quinta linha: Tipo de Contato (largura total)
                      Consumer(
                        builder: (context, ref, child) {
                          final contactCategoriesAsync =
                              ref.watch(contactCategoriesProvider);
                          return contactCategoriesAsync.when(
                            data: (contactCategories) =>
                                DropdownButtonFormField<int>(
                              decoration:
                                  _buildModernInputDecoration('Tipo Contato'),
                              initialValue: contactCategories
                                      .any((c) => c.id == contactCategoryId)
                                  ? contactCategoryId
                                  : null,
                              items: [
                                const DropdownMenuItem(
                                    value: null, child: Text('Selecione')),
                                ...contactCategories
                                    .map((contactCategory) => DropdownMenuItem(
                                          value: contactCategory.id,
                                          child: Text(
                                            contactCategory.name ?? '',
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        )),
                              ],
                              onChanged: (value) {
                                modalSetState(() {
                                  contactCategoryId = value;
                                });
                              },
                              validator: (value) => value == null
                                  ? 'Selecione o tipo de contato'
                                  : null,
                            ),
                            loading: () => const SizedBox(
                              height: 56,
                              child: Center(child: CircularProgressIndicator()),
                            ),
                            error: (error, stack) => SizedBox(
                              height: 56,
                              child: Center(child: Text('Erro: $error')),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 16),
                      // Sexta linha: Cidade e UF
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              initialValue: cityName,
                              decoration: _buildModernInputDecoration('Cidade'),
                              onSaved: (v) => cityName = v,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 1,
                            child: TextFormField(
                              initialValue: stateCode,
                              decoration: _buildModernInputDecoration('UF'),
                              onSaved: (v) => stateCode = v,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Sétima linha: País e CEP
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              initialValue: countryCode,
                              decoration: _buildModernInputDecoration('País'),
                              onSaved: (v) => countryCode = v,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 1,
                            child: TextFormField(
                              initialValue: zipCode,
                              decoration: _buildModernInputDecoration('CEP'),
                              inputFormatters: [
                                MaskedInputFormatter('#####-###'),
                              ],
                              onSaved: (v) => zipCode = v,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed:
                    isSubmitting ? null : () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  foregroundColor:
                      Theme.of(context).colorScheme.onSurfaceVariant,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        if (formKey.currentState!.validate()) {
                          modalSetState(() {
                            isSubmitting = true;
                          });

                          formKey.currentState!.save();

                          // Validação adicional dos campos obrigatórios
                          if (sourceId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Selecione a origem do contato')),
                            );
                            modalSetState(() {
                              isSubmitting = false;
                            });
                            return;
                          }

                          if (contactCategoryId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Selecione o tipo de contato')),
                            );
                            modalSetState(() {
                              isSubmitting = false;
                            });
                            return;
                          }

                          final scaffoldMessenger =
                              ScaffoldMessenger.of(context);

                          try {
                            final updateData = {
                              'name': name,
                              'phone': phone,
                              'email': email,
                              'gender': gender,
                              'source_id': sourceId,
                              'contact_category_id': contactCategoryId,
                              'city': cityName,
                              'country': countryCode,
                              'state': stateCode,
                              'postal_code': zipCode,
                            };

                            // Só adiciona account_id se foi selecionado e é válido
                            if (accountId != null && accountId! > 0) {
                              updateData['account_id'] = accountId;
                            }

                            // Remove apenas campos vazios, mantém os obrigatórios
                            updateData.removeWhere((key, value) =>
                                value == null ||
                                value.toString().trim().isEmpty);

                            print(
                                'Dados para atualização: $updateData'); // Debug

                            await _client
                                .from('contact')
                                .update(updateData)
                                .eq('id', contact['id']);

                            Navigator.of(context).pop();

                            scaffoldMessenger.showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Contato atualizado com sucesso!')),
                            );

                            await Future.delayed(
                                const Duration(milliseconds: 300));
                            if (mounted) {
                              await _refreshContacts();
                            }
                          } catch (e) {
                            print('Erro detalhado: $e'); // Debug
                            scaffoldMessenger.showSnackBar(
                              SnackBar(content: Text('Erro ao atualizar: $e')),
                            );
                          } finally {
                            if (mounted) {
                              modalSetState(() {
                                isSubmitting = false;
                              });
                            }
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Atualizar'),
              ),
            ],
          ),
        );
      },
    );
  }

  // Método para excluir contato
  void _excluirContato(Map<String, dynamic> contact) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF2A2D3E)
            : const Color(0xFFE8F2FF),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Confirmar Exclusão'),
          ],
        ),
        content: Text(
          'Tem certeza que deseja excluir o contato "${contact['name']}"?\n\nEsta ação não pode ser desfeita.',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              try {
                await _client.from('contact').delete().eq('id', contact['id']);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Contato excluído com sucesso!'),
                    backgroundColor: Colors.green,
                  ),
                );

                await _refreshContacts();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erro ao excluir contato: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  // Método para adicionar novo contato
  Future<void> _adicionarCliente(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    String? name,
        phone,
        email,
        cityName,
        countryCode,
        stateCode,
        zipCode,
        gender;
    int? sourceId, accountId, contactCategoryId;
    bool isSubmitting = false;
    final TextEditingController phoneController = TextEditingController();
    final TextEditingController countryController = TextEditingController();
    final TextEditingController stateController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        String? detectedCountry;
        String? detectedState;
        return StatefulBuilder(
          builder: (context, modalSetState) => AlertDialog(
            backgroundColor: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF2A2D3E)
                : const Color(0xFFE8F2FF),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              'Novo Contato',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            content: SizedBox(
              width: 600,
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Primeira linha: Nome e Telefone
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              decoration: _buildModernInputDecoration('Nome *'),
                              validator: (v) => v == null || v.isEmpty
                                  ? 'Informe o nome'
                                  : null,
                              onSaved: (v) => name = v,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextFormField(
                                  controller: phoneController,
                                  decoration:
                                      _buildModernInputDecoration('Telefone *'),
                                  keyboardType: TextInputType.phone,
                                  inputFormatters: [
                                    PhoneInputFormatter(
                                      allowEndlessPhone: true,
                                    ),
                                  ],
                                  validator: (v) => v == null || v.isEmpty
                                      ? 'Informe o telefone'
                                      : null,
                                  onSaved: (v) => phone = v,
                                  onChanged: (value) {
                                    modalSetState(() {
                                      detectedCountry =
                                          PhoneUtils.getCountryFromPhone(value);
                                      detectedState =
                                          PhoneUtils.getStateFromPhone(value);

                                      // Atualizar os controllers dos campos País e UF
                                      if (detectedCountry != null) {
                                        countryController.text =
                                            detectedCountry!;
                                      }
                                      if (detectedState != null) {
                                        stateController.text = detectedState!;
                                      }
                                    });
                                  },
                                ),
                                if (detectedCountry != null) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primaryContainer
                                          .withValues(alpha: 0.3),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          _getCountryFlag(detectedCountry!),
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          detectedCountry!,
                                          style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                            fontWeight: FontWeight.w500,
                                            fontSize: 12,
                                          ),
                                        ),
                                        if (detectedState != null) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .secondary
                                                  .withValues(alpha: 0.2),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              detectedState!,
                                              style: TextStyle(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .secondary,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 10,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Segunda linha: Email e Gênero
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              decoration: _buildModernInputDecoration('Email'),
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) =>
                                  v != null && v.isNotEmpty && !v.contains('@')
                                      ? 'Email inválido'
                                      : null,
                              onSaved: (v) => email = v,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 1,
                            child: DropdownButtonFormField<String>(
                              decoration: _buildModernInputDecoration('Gênero'),
                              initialValue: gender,
                              items: const [
                                DropdownMenuItem(
                                    value: null, child: Text('Selecione')),
                                DropdownMenuItem(
                                    value: 'M', child: Text('Masculino')),
                                DropdownMenuItem(
                                    value: 'F', child: Text('Feminino')),
                                DropdownMenuItem(
                                    value: 'O', child: Text('Outro')),
                              ],
                              onChanged: (value) {
                                modalSetState(() {
                                  gender = value;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Terceira linha: Origem (largura total)
                      Consumer(
                        builder: (context, ref, child) {
                          final sourceAsync = ref.watch(sourcesProvider);
                          return sourceAsync.when(
                            data: (source) => DropdownButtonFormField<int>(
                              decoration: _buildModernInputDecoration('Origem'),
                              initialValue: sourceId,
                              items: [
                                const DropdownMenuItem(
                                    value: null, child: Text('Selecione')),
                                ...source.map((source) => DropdownMenuItem(
                                      value: source.id,
                                      child: Text(source.name ?? ''),
                                    )),
                              ],
                              onChanged: (value) {
                                modalSetState(() {
                                  sourceId = value;
                                });
                              },
                              validator: (value) =>
                                  value == null ? 'Selecione a origem' : null,
                            ),
                            loading: () => const SizedBox(
                              height: 56,
                              child: Center(child: CircularProgressIndicator()),
                            ),
                            error: (error, stack) => SizedBox(
                              height: 56,
                              child: Center(child: Text('Erro: $error')),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      // Quarta linha: Tipo de Conta (largura total)
                      Consumer(
                        builder: (context, ref, child) {
                          final accountAsync = ref.watch(accountsProvider);
                          return accountAsync.when(
                            data: (account) => DropdownButtonFormField<int>(
                              decoration:
                                  _buildModernInputDecoration('Tipo Conta'),
                              initialValue: account.any((a) => a.id == accountId)
                                  ? accountId
                                  : null,
                              items: [
                                const DropdownMenuItem(
                                    value: null, child: Text('Selecione')),
                                ...account.map((account) => DropdownMenuItem(
                                      value: account.id,
                                      child: Text(
                                        account.name ?? '',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    )),
                              ],
                              onChanged: (value) {
                                modalSetState(() {
                                  accountId = value;
                                });
                              },
                              validator: (value) => value == null
                                  ? 'Selecione o tipo de conta'
                                  : null,
                            ),
                            loading: () => const SizedBox(
                              height: 56,
                              child: Center(child: CircularProgressIndicator()),
                            ),
                            error: (error, stack) => SizedBox(
                              height: 56,
                              child: Center(child: Text('Erro: $error')),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      // Quinta linha: Tipo de Contato (largura total)
                      Consumer(
                        builder: (context, ref, child) {
                          final contactCategoriesAsync =
                              ref.watch(contactCategoriesProvider);
                          return contactCategoriesAsync.when(
                            data: (contactCategories) =>
                                DropdownButtonFormField<int>(
                              decoration:
                                  _buildModernInputDecoration('Tipo Contato'),
                              initialValue: contactCategories
                                      .any((c) => c.id == contactCategoryId)
                                  ? contactCategoryId
                                  : null,
                              items: [
                                const DropdownMenuItem(
                                    value: null, child: Text('Selecione')),
                                ...contactCategories
                                    .map((contactCategory) => DropdownMenuItem(
                                          value: contactCategory.id,
                                          child: Text(
                                            contactCategory.name ?? '',
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        )),
                              ],
                              onChanged: (value) {
                                modalSetState(() {
                                  contactCategoryId = value;
                                });
                              },
                              validator: (value) => value == null
                                  ? 'Selecione o tipo de contato'
                                  : null,
                            ),
                            loading: () => const SizedBox(
                              height: 56,
                              child: Center(child: CircularProgressIndicator()),
                            ),
                            error: (error, stack) => SizedBox(
                              height: 56,
                              child: Center(child: Text('Erro: $error')),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 16),
                      // Sexta linha: Cidade e UF
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              decoration: _buildModernInputDecoration('Cidade'),
                              onSaved: (v) => cityName = v,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 1,
                            child: TextFormField(
                              controller: stateController,
                              decoration: _buildModernInputDecoration('UF'),
                              onSaved: (v) => stateCode = v,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Sétima linha: País e CEP
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: countryController,
                              decoration: _buildModernInputDecoration('País'),
                              onSaved: (v) => countryCode = v,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 1,
                            child: TextFormField(
                              decoration: _buildModernInputDecoration('CEP'),
                              inputFormatters: [
                                MaskedInputFormatter('#####-###'),
                              ],
                              onSaved: (v) => zipCode = v,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed:
                    isSubmitting ? null : () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  foregroundColor:
                      Theme.of(context).colorScheme.onSurfaceVariant,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        if (formKey.currentState!.validate()) {
                          modalSetState(() {
                            isSubmitting = true;
                          });

                          formKey.currentState!.save();

                          // Validação adicional dos campos obrigatórios
                          if (sourceId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Selecione a origem do contato')),
                            );
                            modalSetState(() {
                              isSubmitting = false;
                            });
                            return;
                          }

                          if (contactCategoryId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Selecione o tipo de contato')),
                            );
                            modalSetState(() {
                              isSubmitting = false;
                            });
                            return;
                          }

                          final scaffoldMessenger =
                              ScaffoldMessenger.of(context);

                          try {
                            final insertData = {
                              'name': name,
                              'phone': phone,
                              'email': email,
                              'gender': gender,
                              'source_id': sourceId,
                              'contact_category_id': contactCategoryId,
                              'city': cityName,
                              'country': countryCode,
                              'state': stateCode,
                              'postal_code': zipCode,
                            };

                            // Só adiciona account_id se foi selecionado e é válido
                            if (accountId != null && accountId! > 0) {
                              insertData['account_id'] = accountId;
                            }

                            // Remove apenas campos vazios, mantém os obrigatórios
                            insertData.removeWhere((key, value) =>
                                value == null ||
                                value.toString().trim().isEmpty);

                            print('Dados para inserção: $insertData'); // Debug

                            await _client.from('contact').insert(insertData);

                            Navigator.of(context).pop();

                            scaffoldMessenger.showSnackBar(
                              const SnackBar(
                                  content: Text('Contato salvo com sucesso!')),
                            );

                            await Future.delayed(
                                const Duration(milliseconds: 300));
                            if (mounted) {
                              await _refreshContacts();
                            }
                          } catch (e) {
                            print('Erro detalhado: $e'); // Debug
                            scaffoldMessenger.showSnackBar(
                              SnackBar(content: Text('Erro ao salvar: $e')),
                            );
                          } finally {
                            if (mounted) {
                              modalSetState(() {
                                isSubmitting = false;
                              });
                            }
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Salvar'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSpreadsheetView(List<Map<String, dynamic>> contacts) {
    final screenWidth = MediaQuery.of(context).size.width;
    final availableWidth = screenWidth - 32;

    final columns = [
      {'key': 'name', 'label': 'Nome', 'width': availableWidth * 0.11},
      {'key': 'phone', 'label': 'Telefone', 'width': availableWidth * 0.11},
      {'key': 'email', 'label': 'Email', 'width': availableWidth * 0.13},
      {'key': 'gender', 'label': 'Sexo', 'width': availableWidth * 0.08},
      {'key': 'source', 'label': 'Origem', 'width': availableWidth * 0.09},
      {'key': 'city', 'label': 'Cidade', 'width': availableWidth * 0.09},
      {'key': 'state', 'label': 'UF', 'width': availableWidth * 0.05},
      {'key': 'country', 'label': 'País', 'width': availableWidth * 0.07},
      {'key': 'postal_code', 'label': 'CEP', 'width': availableWidth * 0.09},
      {'key': 'account', 'label': 'Tipo Conta', 'width': availableWidth * 0.09},
      {
        'key': 'contact_category',
        'label': 'Categoria',
        'width': availableWidth * 0.11
      },
      {'key': 'actions', 'label': 'Ações', 'width': availableWidth * 0.09},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .primaryContainer
                  .withValues(alpha: 0.3),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.table_chart,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Contatos',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const Spacer(),
                Text(
                  '${contacts.length} contatos',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Scrollbar(
              thumbVisibility: true,
              trackVisibility: true,
              thickness: 8,
              radius: const Radius.circular(4),
              controller: _horizontalScrollController,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                controller: _horizontalScrollController,
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: Column(
                    children: [
                      // Cabeçalho
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primaryContainer
                              .withValues(alpha: 0.2),
                          border: Border(
                            bottom: BorderSide(
                              color: Theme.of(context)
                                  .colorScheme
                                  .outline
                                  .withValues(alpha: 0.3),
                              width: 2,
                            ),
                          ),
                        ),
                        child: Row(
                          children: columns.map((column) {
                            return Container(
                              width: column['width'] as double,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 16),
                              decoration: BoxDecoration(
                                border: Border(
                                  right: BorderSide(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .outline
                                        .withValues(alpha: 0.2),
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: Text(
                                column['label'] as String,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      // Dados
                      ...contacts.asMap().entries.map((entry) {
                        final index = entry.key;
                        final contact = entry.value;

                        return Container(
                          decoration: BoxDecoration(
                            color: index.isEven
                                ? Theme.of(context).colorScheme.surface
                                : Theme.of(context)
                                    .colorScheme
                                    .surface
                                    .withValues(alpha: 0.5),
                            border: Border(
                              bottom: BorderSide(
                                color: Theme.of(context)
                                    .colorScheme
                                    .outline
                                    .withValues(alpha: 0.1),
                                width: 1,
                              ),
                            ),
                          ),
                          child: Row(
                            children: columns.map((column) {
                              return Container(
                                width: column['width'] as double,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 12),
                                decoration: BoxDecoration(
                                  border: Border(
                                    right: BorderSide(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .outline
                                          .withValues(alpha: 0.1),
                                      width: 1,
                                    ),
                                  ),
                                ),
                                child: _buildCellContent(
                                    column['key'] as String, contact),
                              );
                            }).toList(),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCellContent(String key, Map<String, dynamic> contact) {
    switch (key) {
      case 'name':
        return Text(
          contact['name'] ?? '',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          overflow: TextOverflow.ellipsis,
        );

      case 'phone':
        return Text(
          contact['phone'] ?? '',
          style: TextStyle(
            color: Colors.orange[700],
            fontSize: 13,
          ),
          overflow: TextOverflow.ellipsis,
        );

      case 'email':
        return Text(
          contact['email'] ?? '',
          style: TextStyle(
            color: Colors.orange[700],
            fontSize: 13,
          ),
          overflow: TextOverflow.ellipsis,
        );

      case 'gender':
        if (contact['gender'] != null) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              contact['gender'] == 'M'
                  ? 'M'
                  : contact['gender'] == 'F'
                      ? 'F'
                      : 'O',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          );
        }
        return const SizedBox();

      case 'source':
        if (contact['source']?['name'] != null) {
          final sourceName = contact['source']['name'] as String;
          final sourceColor = SourceColors.getSourceColor(sourceName);

          // Debug: imprimir informações da cor
          print('🎨 Source: $sourceName, Color: $sourceColor');

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: sourceColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: sourceColor.withValues(alpha: 0.6),
                width: 1.5,
              ),
            ),
            child: Text(
              sourceName,
              style: TextStyle(
                color: sourceColor,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          );
        }
        // Se não há source, mostrar um placeholder para debug
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: Colors.grey.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: const Text(
            'Sem origem',
            style: TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.w500,
              fontSize: 10,
            ),
          ),
        );

      case 'account':
        if (contact['account']?['name'] != null) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .secondary
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .secondary
                    .withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Text(
              contact['account']['name'],
              style: TextStyle(
                color: Theme.of(context).colorScheme.secondary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          );
        }
        return const SizedBox();

      case 'contact_category':
        if (contact['contact_category']?['name'] != null) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.purple.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: Colors.purple.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Text(
              contact['contact_category']['name'],
              style: TextStyle(
                color: Colors.purple[700],
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          );
        }
        return const SizedBox();

      case 'actions':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.visibility,
                  color: Theme.of(context).colorScheme.primary, size: 20),
              onPressed: () => _visualizarContato(contact),
              tooltip: 'Visualizar',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
            IconButton(
              icon: Icon(Icons.edit,
                  color: Theme.of(context).colorScheme.primary, size: 20),
              onPressed: () => _editarContato(contact),
              tooltip: 'Editar',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red[700], size: 20),
              onPressed: () => _excluirContato(contact),
              tooltip: 'Excluir',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        );

      default:
        return Text(
          contact[key] ?? '',
          style: const TextStyle(fontSize: 13),
          overflow: TextOverflow.ellipsis,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> contactsFiltrados = _contacts.where((c) {
      if (_searchTerm.isEmpty) return true;
      final termo = _searchTerm.toLowerCase();
      final nome = (c['name'] ?? '').toString().toLowerCase();
      final telefone =
          (c['phone'] ?? '').toString().replaceAll(RegExp(r'\D'), '');
      final email = (c['email'] ?? '').toString().toLowerCase();
      final cidade = (c['city'] ?? '').toString().toLowerCase();
      return nome.contains(termo) ||
          telefone.contains(termo) ||
          email.contains(termo) ||
          cidade.contains(termo);
    }).toList();

    final List<Map<String, dynamic>> contatosExibidos =
        List<Map<String, dynamic>>.from(contactsFiltrados);

    return BaseScreenLayout(
      title: 'Contatos',
      actions: [
        IconButton(
          icon: Icon(
              _visualizarComoCartao ? Icons.table_chart : Icons.credit_card),
          tooltip: _visualizarComoCartao
              ? 'Visualizar como planilha'
              : 'Visualizar como cartões',
          onPressed: () {
            setState(() {
              _visualizarComoCartao = !_visualizarComoCartao;
              _visualizarComoKanban = false; // Desativa kanban
            });
          },
        ),
        IconButton(
          icon: Icon(
            _visualizarComoKanban ? Icons.view_list : Icons.view_kanban,
            color: _visualizarComoKanban ? Colors.blue : null,
          ),
          tooltip: _visualizarComoKanban
              ? 'Visualizar como lista'
              : 'Visualizar como Kanban',
          onPressed: () {
            setState(() {
              _visualizarComoKanban = !_visualizarComoKanban;
              if (_visualizarComoKanban) {
                _visualizarComoCartao = false; // Desativa cartão quando ativa kanban
              }
            });
          },
        ),
        IconButton(
          icon: const Icon(Icons.table_rows),
          onPressed: _contacts.isEmpty ? null : _abrirTabelaGrid,
          tooltip: 'Tabela (Grid)',
        ),
        IconButton(
          icon: const Icon(Icons.sort),
          onPressed: _showSortModal,
          tooltip: 'Ordenar contatos',
        ),
        IconButton(
          icon: const Icon(Icons.person_add),
          onPressed: () => _adicionarCliente(context),
          tooltip: 'Novo Contato',
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _refreshContacts,
          tooltip: 'Atualizar lista',
        ),
        PopupMenuButton<UserType?>(
          icon: const Icon(Icons.filter_alt),
          tooltip: 'Filtrar por tipo',
          onSelected: (val) async {
            setState(() {
              _filterUserType = val;
            });
            await _fetchContacts();
          },
          itemBuilder: (context) => [
            const PopupMenuItem<UserType?>(value: null, child: Text('Todos')),
            const PopupMenuItem<UserType?>(
                value: UserType.normal, child: Text('Normal')),
            const PopupMenuItem<UserType?>(
                value: UserType.employee, child: Text('Colaborador')),
            const PopupMenuItem<UserType?>(
                value: UserType.agency, child: Text('Agência')),
          ],
        ),
      ],
      searchBar: StandardSearchBar(
        controller: TextEditingController(text: _searchTerm),
        hintText: 'Buscar por nome, email, telefone, cidade...',
        onChanged: (v) {
          setState(() {
            _searchTerm = v.trim();
          });
        },
      ),
      child: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : contatosExibidos.isEmpty
                    ? const Center(
                        child: Text(
                            'Nenhum contato encontrado com os filtros aplicados.'))
                    : _visualizarComoKanban
                        ? _buildKanbanView(contatosExibidos)
                        : ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: contatosExibidos.length,
                        itemBuilder: (context, index) {
                          final c = contatosExibidos[index];

                          final id = c['id'] as int? ?? -1;
                          final hasPurchase =
                              _contactsWithPurchase.contains(id);
                          final hasLeadConverted =
                              _contactsWithLeadConverted.contains(id) &&
                                  !hasPurchase;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12.0),
                            elevation: 2,
                            color: hasPurchase
                                ? (Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? const Color(
                                        0xFF1B3A2E) // Verde escuro vendido
                                    : const Color(0xFFE8F5E8))
                                : hasLeadConverted
                                    ? (Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? const Color(
                                            0xFF1E4620) // Verde médio para lançar venda
                                        : const Color(0xFFE9F7EF))
                                    : (Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? const Color(0xFF2A2D3E)
                                        : const Color(0xFFE8F2FF)),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            child: ExpansionTile(
                              key: PageStorageKey(c['id']),
                              leading: InkWell(
                                onTap: () async {
                                  final contactId = c['id'].toString();
                                  final currentType =
                                      _contactUserTypes[contactId] ??
                                          UserType.normal;
                                  UserType newType;

                                  // Alterna entre os tipos: normal -> driver -> employee -> agency -> normal
                                  switch (currentType) {
                                    case UserType.normal:
                                      newType = UserType.driver;
                                      print(
                                          'Contato ${c['name']} alterado para: Motorista');
                                      break;
                                    case UserType.driver:
                                      newType = UserType.employee;
                                      print(
                                          'Contato ${c['name']} alterado para: Colaborador');
                                      break;
                                    case UserType.employee:
                                      newType = UserType.agency;
                                      print(
                                          'Contato ${c['name']} alterado para: Agência');
                                      break;
                                    case UserType.agency:
                                      newType = UserType.normal;
                                      print(
                                          'Contato ${c['name']} alterado para: Normal');
                                      break;
                                  }

                                  // Atualiza localmente primeiro
                                  setState(() {
                                    _contactUserTypes[contactId] = newType;
                                  });

                                  // Persiste no banco de dados
                                  try {
                                    await _contactsService
                                        .updateContactUserType(
                                            c['id'], newType);
                                    print(
                                        'UserType persistido no banco: ${newType.name}');
                                  } catch (e) {
                                    print('Erro ao persistir UserType: $e');
                                    // Reverte a mudança local em caso de erro
                                    setState(() {
                                      _contactUserTypes[contactId] =
                                          currentType;
                                    });
                                    if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content: Text(
                                                'Erro ao salvar alteração: $e')),
                                      );
                                    }
                                  }
                                },
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _getCircleColor(
                                        _contactUserTypes[c['id'].toString()] ??
                                            UserType.normal,
                                        false),
                                    border: Border.all(
                                      color: _getBorderColor(
                                          _contactUserTypes[
                                                  c['id'].toString()] ??
                                              UserType.normal,
                                          false),
                                      width: 2,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      (c['name'] ?? 'C')
                                          .substring(0, 1)
                                          .toUpperCase(),
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: _getTextColor(),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              title: Row(
                                children: [
                                  // Nome
                                  Expanded(
                                    flex: 4,
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            c['name'] ?? 'Nome não informado',
                                            style: (Theme.of(context)
                                                        .textTheme
                                                        .titleMedium ??
                                                    const TextStyle())
                                                .copyWith(
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'Inter',
                                              fontSize: 16,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface,
                                            ),
                                            softWrap: true,
                                            maxLines: 2,
                                          ),
                                        ),
                                        // Indicador de tipo de usuário
                                        if ((_contactUserTypes[
                                                    c['id'].toString()] ??
                                                UserType.normal) !=
                                            UserType.normal) ...[
                                          const SizedBox(width: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: _getUserTypeColor(
                                                  _contactUserTypes[
                                                          c['id'].toString()] ??
                                                      UserType.normal),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              _getUserTypeLabel(
                                                  _contactUserTypes[
                                                          c['id'].toString()] ??
                                                      UserType.normal),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                        const SizedBox(width: 6),
                                        if (_contactsWithLeadConverted
                                                .contains(c['id'] as int) &&
                                            !_contactsWithPurchase
                                                .contains(c['id'] as int))
                                          InkWell(
                                            onTap: () =>
                                                _criarVendaParaCliente(c),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Theme.of(context)
                                                            .brightness ==
                                                        Brightness.dark
                                                    ? const Color(0xFF33663B)
                                                    : const Color(0xFFA5D6A7),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: const Text(
                                                'Lançar venda',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                        if (_contactsWithPurchase
                                            .contains(c['id'] as int))
                                          Container(
                                            margin:
                                                const EdgeInsets.only(left: 6),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context)
                                                          .brightness ==
                                                      Brightness.dark
                                                  ? const Color(0xFF2E7D32)
                                                  : const Color(0xFF4CAF50),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: const Text(
                                              'Vendido',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Telefone
                                  if (c['phone'] != null) ...[
                                    Expanded(
                                      flex: 3,
                                      child: Row(
                                        children: [
                                          Tooltip(
                                            message: 'Ver mensagens WhatsApp',
                                            child: InkWell(
                                              onTap: () => _abrirWhatsApp(c),
                                              borderRadius: BorderRadius.circular(10),
                                              child: Container(
                                                width: 20,
                                                height: 20,
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF25D366),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Padding(
                                                  padding: const EdgeInsets.all(3),
                                                  child: SvgPicture.asset(
                                                    'assets/icons/whatsapp.svg',
                                                    colorFilter: const ColorFilter.mode(
                                                      Colors.white,
                                                      BlendMode.srcIn,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          // Bandeira do país
                                          if (_resolveIsoFromPhoneAndCountry(
                                                  c['phone'], c['country']) !=
                                              null)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  right: 4),
                                              child: Image.network(
                                                FlagUtils.getFlagUrl(
                                                    _resolveIsoFromPhoneAndCountry(
                                                        c['phone'],
                                                        c['country'])!,
                                                    width: 16,
                                                    height: 12),
                                                width: 16,
                                                height: 12,
                                                errorBuilder: (context, error,
                                                        stackTrace) =>
                                                    const SizedBox(
                                                        width: 16, height: 12),
                                              ),
                                            ),
                                          Expanded(
                                            child: Text(
                                              _formatPhone(c['phone']),
                                              style: const TextStyle(
                                                fontFamily: 'Inter',
                                                fontSize: 14,
                                                color: Colors.orange,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          // Chip redondo para criar cotação
                                          InkWell(
                                            onTap: () => _abrirCriarCotacaoComWhatsApp(c),
                                            borderRadius: BorderRadius.circular(20),
                                            child: Container(
                                              width: 32,
                                              height: 32,
                                              decoration: BoxDecoration(
                                                color: Colors.blue.shade50,
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: Colors.blue.shade300,
                                                  width: 1.5,
                                                ),
                                              ),
                                              child: Icon(
                                                Icons.request_quote,
                                                size: 18,
                                                color: Colors.blue.shade700,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          // Chip redondo para datas rápidas
                                          InkWell(
                                            onTap: () => _abrirDatasRapidas(c),
                                            borderRadius: BorderRadius.circular(20),
                                            child: Container(
                                              width: 32,
                                              height: 32,
                                              decoration: BoxDecoration(
                                                color: Colors.green.shade50,
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: Colors.green.shade300,
                                                  width: 1.5,
                                                ),
                                              ),
                                              child: Icon(
                                                Icons.calendar_today,
                                                size: 18,
                                                color: Colors.green.shade700,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  
                                  // Data de criação
                                  if (c['created_at'] != null) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.grey.shade300, width: 1),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.calendar_today, size: 12, color: Colors.grey.shade600),
                                          const SizedBox(width: 4),
                                          Text(
                                            _formatDate(DateTime.parse(c['created_at'])),
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey.shade700,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  
                                  // Badge de datas de viagem (se existir)
                                  if (c['travel_date'] != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4, bottom: 4),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.flight_takeoff, size: 11, color: Colors.blue.shade700),
                                          const SizedBox(width: 3),
                                          Text(
                                            _formatDate(DateTime.parse(c['travel_date'])),
                                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.blue.shade700),
                                          ),
                                          if (c['return_date'] != null) ...[
                                            const SizedBox(width: 6),
                                            Icon(Icons.flight_land, size: 11, color: Colors.green.shade700),
                                            const SizedBox(width: 3),
                                            Text(
                                              _formatDate(DateTime.parse(c['return_date'])),
                                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.green.shade700),
                                            ),
                                          ],
                                          const SizedBox(width: 6),
                                          _buildDaysUntilBadge(DateTime.parse(c['travel_date'])),
                                        ],
                                      ),
                                    ),
                                  
                                  // Tipo de Conta
                                  if (c['account']?['name'] != null) ...[
                                    Expanded(
                                      flex: 1,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 4, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: Colors.blue
                                              .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          c['account']['name'],
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: Colors.blue,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  // Categoria de Contato (usando cores do kanban)
                                  if (c['contact_category']?['name'] != null)
                                    Expanded(
                                      flex: 1,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 4, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: _getCategoryColor(c['contact_category']['name'])
                                              .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          c['contact_category']['name'],
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: _getCategoryColor(c['contact_category']['name']),
                                            fontWeight: FontWeight.w500,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                  const SizedBox(width: 8),
                                  PopupMenuButton<String>(
                                    icon: const Icon(
                                      Icons.more_vert,
                                      size: 20,
                                      color: Colors.grey,
                                    ),
                                    onSelected: (value) {
                                      switch (value) {
                                        case 'view':
                                          _visualizarContato(c);
                                          break;
                                        case 'profile':
                                          _abrirPerfilCompleto(c);
                                          break;
                                        case 'profile_page':
                                          _abrirPerfilNaPagina(c);
                                          break;
                                        case 'edit':
                                          _editarContato(c);
                                          break;
                                        case 'delete':
                                          _excluirContato(c);
                                          break;
                                        case 'sale':
                                          _criarVendaParaCliente(c);
                                          break;
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'view',
                                        child: Row(
                                          children: [
                                            Icon(Icons.visibility, size: 16),
                                            SizedBox(width: 8),
                                            Text('Visualizar'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'profile',
                                        child: Row(
                                          children: [
                                            Icon(Icons.analytics,
                                                size: 16, color: Colors.purple),
                                            SizedBox(width: 8),
                                            Text('Perfil Completo',
                                                style: TextStyle(
                                                    color: Colors.purple)),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'profile_page',
                                        child: Row(
                                          children: [
                                            Icon(Icons.open_in_new,
                                                size: 16, color: Colors.blue),
                                            SizedBox(width: 8),
                                            Text('Abrir na Página',
                                                style: TextStyle(
                                                    color: Colors.blue)),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            Icon(Icons.edit, size: 16),
                                            SizedBox(width: 8),
                                            Text('Editar'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'sale',
                                        child: Row(
                                          children: [
                                            Icon(Icons.shopping_cart, size: 16),
                                            SizedBox(width: 8),
                                            Text('Nova Venda'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(Icons.delete,
                                                size: 16, color: Colors.red),
                                            SizedBox(width: 8),
                                            Text('Excluir',
                                                style: TextStyle(
                                                    color: Colors.red)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: ContactFollowUpTimeline(
                                    contactId: c['id'] as int,
                                    maxItems: 5,
                                  ),
                                ),
                                
                                // Mantém botões de ação no final (oculto por enquanto)
                                Padding(
                                  padding: const EdgeInsets.all(0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 0),

                                      // Botões de ação (comentado - agora só follow-ups)
                                      Column(
                                        children: [
                                          // Primeira linha de botões
                                          Row(
                                            children: [
                                              Expanded(
                                                child: ElevatedButton.icon(
                                                  onPressed: () =>
                                                      _criarVendaParaCliente(c),
                                                  icon: const Icon(
                                                      Icons.shopping_cart,
                                                      size: 14),
                                                  label: const Text(
                                                      'Nova Venda',
                                                      style: TextStyle(
                                                          fontSize: 12)),
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    padding: const EdgeInsets
                                                        .symmetric(vertical: 8),
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              6),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: OutlinedButton.icon(
                                                  onPressed: () =>
                                                      _visualizarContato(c),
                                                  icon: const Icon(
                                                      Icons.visibility,
                                                      size: 14),
                                                  label: const Text('Detalhes',
                                                      style: TextStyle(
                                                          fontSize: 12)),
                                                  style:
                                                      OutlinedButton.styleFrom(
                                                    padding: const EdgeInsets
                                                        .symmetric(vertical: 8),
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              6),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          // Segunda linha de botões
                                          Row(
                                            children: [
                                              Expanded(
                                                child: ElevatedButton.icon(
                                                  onPressed: () =>
                                                      _abrirPerfilCompleto(c),
                                                  icon: const Icon(
                                                      Icons.analytics,
                                                      size: 14),
                                                  label: const Text('Perfil',
                                                      style: TextStyle(
                                                          fontSize: 12)),
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        Colors.purple,
                                                    foregroundColor:
                                                        Colors.white,
                                                    padding: const EdgeInsets
                                                        .symmetric(vertical: 8),
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              6),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: OutlinedButton.icon(
                                                  onPressed: () =>
                                                      _abrirPerfilNaPagina(c),
                                                  icon: const Icon(
                                                      Icons.open_in_new,
                                                      size: 14),
                                                  label: const Text(
                                                      'Abrir Página',
                                                      style: TextStyle(
                                                          fontSize: 12)),
                                                  style:
                                                      OutlinedButton.styleFrom(
                                                    padding: const EdgeInsets
                                                        .symmetric(vertical: 8),
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              6),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  // Método para mostrar o modal de ordenação
  void _showSortModal() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: 500,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cabeçalho do modal
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.sort,
                            color: Theme.of(context).colorScheme.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Opções de Ordenação',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close),
                          style: IconButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.surface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Seção de tipos de ordenação
                    Text(
                      'Tipo de Ordenação',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Opções de ordenação
                    _buildSortOption(
                      context,
                      setState,
                      'alphabetical',
                      'Ordem Alfabética',
                      'Ordenar por nome (A-Z ou Z-A)',
                      Icons.sort_by_alpha,
                    ),
                    _buildSortOption(
                      context,
                      setState,
                      'date_created',
                      'Data de Criação',
                      'Ordenar por data de cadastro',
                      Icons.calendar_today,
                    ),
                    _buildSortOption(
                      context,
                      setState,
                      'date_updated',
                      'Data de Atualização',
                      'Ordenar por última modificação',
                      Icons.update,
                    ),
                    _buildSortOption(
                      context,
                      setState,
                      'account_type',
                      'Tipo de Conta',
                      'Ordenar por categoria da conta',
                      Icons.account_circle,
                    ),

                    const SizedBox(height: 24),

                    // Seção de direção da ordenação
                    Text(
                      'Direção da Ordenação',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _buildDirectionOption(
                            context,
                            setState,
                            true,
                            'Crescente',
                            _getSortDirectionDescription(true),
                            Icons.arrow_upward,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDirectionOption(
                            context,
                            setState,
                            false,
                            'Decrescente',
                            _getSortDirectionDescription(false),
                            Icons.arrow_downward,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Botões de ação
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Cancelar'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              _applySorting();
                              Navigator.of(context).pop();
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Aplicar Ordenação'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Widget para opção de ordenação
  Widget _buildSortOption(
    BuildContext context,
    StateSetter setState,
    String value,
    String title,
    String description,
    IconData icon,
  ) {
    final isSelected = _sortType == value;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            setState(() {
              _sortType = value;
              _updateSortField();
            });
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context)
                        .colorScheme
                        .outline
                        .withValues(alpha: 0.3),
                width: isSelected ? 2 : 1,
              ),
              color: isSelected
                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                  : Colors.transparent,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.2)
                        : Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.7),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget para opção de direção
  Widget _buildDirectionOption(
    BuildContext context,
    StateSetter setState,
    bool ascending,
    String title,
    String description,
    IconData icon,
  ) {
    final isSelected = _sortAscending == ascending;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          setState(() {
            _sortAscending = ascending;
          });
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context)
                      .colorScheme
                      .outline
                      .withValues(alpha: 0.3),
              width: isSelected ? 2 : 1,
            ),
            color: isSelected
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                : Colors.transparent,
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.7),
                size: 24,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Atualizar campo de ordenação baseado no tipo
  void _updateSortField() {
    switch (_sortType) {
      case 'alphabetical':
        _sortField = 'name';
        break;
      case 'date_created':
        _sortField = 'created_at';
        break;
      case 'date_updated':
        _sortField = 'updated_at';
        break;
      case 'account_type':
        _sortField = 'account_id';
        break;
      default:
        _sortField = 'name';
        break;
    }
  }

  // Obter descrição da direção da ordenação
  String _getSortDirectionDescription(bool ascending) {
    switch (_sortType) {
      case 'alphabetical':
        return ascending ? 'A → Z' : 'Z → A';
      case 'date_created':
      case 'date_updated':
        return ascending ? 'Mais antigo primeiro' : 'Mais recente primeiro';
      case 'account_type':
        return ascending ? 'Ordem padrão' : 'Ordem inversa';
      default:
        return ascending ? 'Crescente' : 'Decrescente';
    }
  }

  // Aplicar ordenação
  void _applySorting() {
    setState(() {
      _isLoading = true;
    });

    // Atualizar o campo de ordenação baseado no tipo selecionado
    _updateSortField();

    // Salvar as configurações de ordenação
    _saveSortPreferences();

    _fetchContacts();
  }

  // ============================================================================
  // KANBAN VIEW - Visualização estilo Monday
  // ============================================================================

  Widget _buildKanbanView(List<Map<String, dynamic>> contacts) {
    final categories = ref.watch(contactCategoriesProvider);
    
    return categories.when(
      data: (categoriesList) {
        if (categoriesList.isEmpty) {
          return const Center(child: Text('Nenhuma categoria encontrada'));
        }

        // Criar colunas baseadas nas categorias de contato
        final columns = categoriesList.map((category) {
          return {
            'id': category.id,
            'name': category.name ?? 'Sem categoria',
            'color': _getCategoryColor(category.name ?? 'Sem categoria'),
            'order': _getCategoryOrder(category.name ?? 'Sem categoria'),
          };
        }).toList();
        
        // Ordenar colunas: Lead → Prospect → Negociado → Cliente → Leads Perdidos
        columns.sort((a, b) => (a['order'] as int).compareTo(b['order'] as int));

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: columns.map((column) {
            final categoryId = column['id'] as int;
            final categoryName = column['name'] as String;
            final color = column['color'] as Color;
            
            final columnContacts = contacts.where((contact) => 
                contact['contact_category_id'] == categoryId).toList();

            return Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  children: [
                    // Header da coluna
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                        ),
                        border: Border.all(color: color.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              categoryName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: color,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              columnContacts.length.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Cards da coluna com DragTarget
                    Expanded(
                      child: DragTarget<Map<String, dynamic>>(
                        onWillAcceptWithDetails: (data) => true,
                        onAcceptWithDetails: (details) {
                          _moveContactToCategory(details.data, categoryId);
                        },
                        builder: (context, candidateData, rejectedData) {
                          return Container(
                            decoration: BoxDecoration(
                              color: candidateData.isNotEmpty 
                                  ? color.withValues(alpha: 0.05)
                                  : Theme.of(context).colorScheme.surfaceContainerLowest,
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(8),
                                bottomRight: Radius.circular(8),
                              ),
                              border: Border.all(
                                color: candidateData.isNotEmpty 
                                    ? color.withValues(alpha: 0.5)
                                    : color.withValues(alpha: 0.3),
                                width: candidateData.isNotEmpty ? 2 : 1,
                              ),
                            ),
                            child: ListView.builder(
                              padding: const EdgeInsets.all(8),
                              itemCount: columnContacts.length,
                              itemBuilder: (context, index) {
                                return _buildDraggableContactCard(columnContacts[index], color);
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Erro ao carregar categorias: $error')),
    );
  }

  Widget _buildDraggableContactCard(Map<String, dynamic> contact, Color categoryColor) {
    return Draggable<Map<String, dynamic>>(
      data: contact,
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 280,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: categoryColor, width: 2),
          ),
          child: _buildContactCardContent(contact, categoryColor),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _buildContactKanbanCard(contact, categoryColor),
      ),
      child: _buildContactKanbanCard(contact, categoryColor),
    );
  }

  Widget _buildContactKanbanCard(Map<String, dynamic> contact, Color categoryColor) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: categoryColor.withValues(alpha: 0.3)),
      ),
      child: InkWell(
        onTap: () => _abrirPerfilCompleto(contact),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: _buildContactCardContent(contact, categoryColor),
        ),
      ),
    );
  }

  Widget _buildContactCardContent(Map<String, dynamic> contact, Color categoryColor) {
    final name = contact['name'] as String? ?? 'Sem nome';
    final email = contact['email'] as String? ?? '';
    final phone = contact['phone'] as String? ?? '';
    final sourceName = contact['source_name'] as String? ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: categoryColor.withValues(alpha: 0.2),
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: TextStyle(
                  color: categoryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        if (email.isNotEmpty) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.email, size: 12, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  email,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
        if (phone.isNotEmpty) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              // Flag do país (usando método existente)
              if (_getCountryCodeFromPhone(phone) != null)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Image.network(
                    FlagUtils.getFlagUrl(_getCountryCodeFromPhone(phone)!,
                        width: 20, height: 15),
                    width: 20,
                    height: 15,
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox(width: 20, height: 15),
                  ),
                )
              else
                const SizedBox(width: 20, height: 15),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  PhoneUtils.formatPhone(phone),
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
        if (sourceName.isNotEmpty) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _getSourceColor(sourceName).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: _getSourceColor(sourceName).withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              sourceName,
              style: TextStyle(
                fontSize: 10,
                color: _getSourceColor(sourceName),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }

  int _getCategoryOrder(String categoryName) {
    final lowerName = categoryName.toLowerCase();
    
    // Ordem: Lead (1), Prospect (2), Negociado (3), Cliente (4), Leads Perdidos (5)
    if (lowerName.contains('lead') && !lowerName.contains('perdido')) return 1;
    if (lowerName.contains('prospect')) return 2;
    if (lowerName.contains('negociad')) return 3;
    if (lowerName.contains('client')) return 4;
    if (lowerName.contains('perdido') || lowerName.contains('inativo')) return 5;
    
    return 99; // Outros no final
  }

  Color _getCategoryColor(String categoryName) {
    final lowerName = categoryName.toLowerCase();
    
    // Ordem: Lead, Prospect, Negociado, Cliente, Leads Perdidos
    if (lowerName.contains('perdido') || lowerName.contains('inativo')) {
      return const Color(0xFFEC4899); // Rosa/Pink para leads perdidos
    }
    if (lowerName.contains('client')) {
      return const Color(0xFF059669); // Verde mais forte para clientes
    }
    if (lowerName.contains('negociad')) {
      return const Color(0xFF10B981); // Verde médio para negociados
    }
    if (lowerName.contains('prospect')) {
      return const Color(0xFFF59E0B); // Laranja para prospects
    }
    if (lowerName.contains('lead')) {
      return const Color(0xFF3B82F6); // Azul para leads
    }
    
    return const Color(0xFF6366F1); // Default purple
  }

  Color _getSourceColor(String sourceName) {
    return SourceColors.getSourceColor(sourceName);
  }


  Future<void> _moveContactToCategory(Map<String, dynamic> contact, int newCategoryId) async {
    try {
      await _client
          .from('contact')
          .update({'contact_category_id': newCategoryId})
          .eq('id', contact['id']);

      // Atualizar localmente
      setState(() {
        final index = _contacts.indexWhere((c) => c['id'] == contact['id']);
        if (index != -1) {
          _contacts[index]['contact_category_id'] = newCategoryId;
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Contato movido com sucesso!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao mover contato: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
