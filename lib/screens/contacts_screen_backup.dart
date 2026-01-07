import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

class ContactsScreen extends ConsumerStatefulWidget {
  const ContactsScreen({super.key});

  @override
  ConsumerState<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends ConsumerState<ContactsScreen> {
  final _client = Supabase.instance.client;

  List<Map<String, dynamic>> _contacts = [];
  bool _isLoading = false;
  bool _visualizarComoCartao = false;
  String _searchTerm = '';
  String? _selectedCountryForStates; // Para controlar qual país mostrar estados

  // Adicionado para scroll sincronizado
  final ScrollController _horizontalScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchContacts();
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
      final response = await _client
          .from('contact')
          .select('''
            *,
            source(name),
            account(name),
            contact_category(name)
          ''')
          .order('name', ascending: true);
      
      print('✅ Dados recebidos: ${response.length} contatos');
      
      if (mounted) {
        setState(() {
          _contacts = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
      
      print('✅ Lista atualizada com ${_contacts.length} contatos');
      
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
    );
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

  // Função para abrir mensagens do WhatsApp
  void _abrirWhatsApp(Map<String, dynamic> contactData) {
    final phone = contactData['phone'] as String?;
    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este contato não possui número de telefone cadastrado'),
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
  InputDecoration _buildModernInputDecoration(String label, {String? hintText, String? suffixText}) {
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

  // Método para construir estatísticas de países
  List<Widget> _buildCountryStats() {
    final Map<String, int> countryCount = {};
    
    for (final contact in _contacts) {
      String? countryName;
      
      // Primeiro, tenta usar o campo 'country' do banco de dados
      final countryFromDB = contact['country'];
      if (countryFromDB != null && countryFromDB.toString().isNotEmpty) {
        countryName = countryFromDB.toString();
      } else {
        // Se não houver país no banco, tenta detectar pelo telefone
        final phone = contact['phone'];
        if (phone != null && phone.toString().isNotEmpty) {
          final countryCode = _getCountryCodeFromPhone(phone.toString());
          countryName = _getCountryName(countryCode);
        } else {
          countryName = 'Desconhecido';
        }
      }
      
      countryCount[countryName] = (countryCount[countryName] ?? 0) + 1;
    }
    
    final sortedCountries = countryCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    List<Widget> widgets = [
      Wrap(
        spacing: 8,
        runSpacing: 6,
        children: sortedCountries.map((entry) {
          final countryCode = FlagUtils.getCountryIsoCode(entry.key);
          final isClickable = entry.key == 'Brasil' || entry.key == 'Estados Unidos';
          final isSelected = _selectedCountryForStates == entry.key;
          
          Widget chip = Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isSelected 
                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)
                  : Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.6)
                    : Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (countryCode != null) ...[
                  Image.network(
                    FlagUtils.getFlagUrl(countryCode, width: 16, height: 12),
                    width: 16,
                    height: 12,
                    errorBuilder: (context, error, stackTrace) => const SizedBox(width: 16, height: 12),
                  ),
                  const SizedBox(width: 4),
                ],
                Text(
                  '${entry.key}: ${entry.value}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                if (isClickable) ...[
                  const SizedBox(width: 4),
                  Icon(
                    isSelected ? Icons.expand_less : Icons.expand_more,
                    size: 14,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ],
            ),
          );
          
          if (isClickable) {
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCountryForStates = isSelected ? null : entry.key;
                });
              },
              child: chip,
            );
          }
          
          return chip;
        }).toList(),
      ),
    ];
    
    // Adiciona estatísticas de estados se um país estiver selecionado
    if (_selectedCountryForStates != null) {
      widgets.add(const SizedBox(height: 12));
      widgets.addAll(_buildStateStatsForCountry(_selectedCountryForStates!));
    }
    
    return widgets;
  }

  // Função para normalizar nomes de estados e evitar duplicações
  String _normalizeStateName(String stateName, String country) {
    if (country == 'Brasil') {
      // Mapa de normalização para estados brasileiros
      const Map<String, String> brazilianStateNormalization = {
        // Siglas para nomes completos
        'AC': 'Acre',
        'AL': 'Alagoas',
        'AP': 'Amapá',
        'AM': 'Amazonas',
        'BA': 'Bahia',
        'CE': 'Ceará',
        'DF': 'Distrito Federal',
        'ES': 'Espírito Santo',
        'GO': 'Goiás',
        'MA': 'Maranhão',
        'MT': 'Mato Grosso',
        'MS': 'Mato Grosso do Sul',
        'MG': 'Minas Gerais',
        'PA': 'Pará',
        'PB': 'Paraíba',
        'PR': 'Paraná',
        'PE': 'Pernambuco',
        'PI': 'Piauí',
        'RJ': 'Rio de Janeiro',
        'RN': 'Rio Grande do Norte',
        'RS': 'Rio Grande do Sul',
        'RO': 'Rondônia',
        'RR': 'Roraima',
        'SC': 'Santa Catarina',
        'SP': 'São Paulo',
        'SE': 'Sergipe',
        'TO': 'Tocantins',
        // Variações de nomes que podem aparecer
        'Sao Paulo': 'São Paulo',
        'sao paulo': 'São Paulo',
        'SAO PAULO': 'São Paulo',
        'Rio de janeiro': 'Rio de Janeiro',
        'rio de janeiro': 'Rio de Janeiro',
        'RIO DE JANEIRO': 'Rio de Janeiro',
        'Minas gerais': 'Minas Gerais',
        'minas gerais': 'Minas Gerais',
        'MINAS GERAIS': 'Minas Gerais',
      };
      
      // Primeiro tenta encontrar uma normalização direta
      String normalized = brazilianStateNormalization[stateName] ?? stateName;
      
      // Se não encontrou, tenta buscar por nome completo (case insensitive)
      if (normalized == stateName) {
        for (var entry in brazilianStateNormalization.entries) {
          if (entry.value.toLowerCase() == stateName.toLowerCase()) {
            return entry.value;
          }
        }
      }
      
      return normalized;
    } else if (country == 'Estados Unidos') {
      // Mapa de normalização para estados americanos
      const Map<String, String> usStateNormalization = {
        'AL': 'Alabama',
        'AK': 'Alaska',
        'AZ': 'Arizona',
        'AR': 'Arkansas',
        'CA': 'California',
        'CO': 'Colorado',
        'CT': 'Connecticut',
        'DE': 'Delaware',
        'FL': 'Florida',
        'GA': 'Georgia',
        'HI': 'Hawaii',
        'ID': 'Idaho',
        'IL': 'Illinois',
        'IN': 'Indiana',
        'IA': 'Iowa',
        'KS': 'Kansas',
        'KY': 'Kentucky',
        'LA': 'Louisiana',
        'ME': 'Maine',
        'MD': 'Maryland',
        'MA': 'Massachusetts',
        'MI': 'Michigan',
        'MN': 'Minnesota',
        'MS': 'Mississippi',
        'MO': 'Missouri',
        'MT': 'Montana',
        'NE': 'Nebraska',
        'NV': 'Nevada',
        'NH': 'New Hampshire',
        'NJ': 'New Jersey',
        'NM': 'New Mexico',
        'NY': 'New York',
        'NC': 'North Carolina',
        'ND': 'North Dakota',
        'OH': 'Ohio',
        'OK': 'Oklahoma',
        'OR': 'Oregon',
        'PA': 'Pennsylvania',
        'RI': 'Rhode Island',
        'SC': 'South Carolina',
        'SD': 'South Dakota',
        'TN': 'Tennessee',
        'TX': 'Texas',
        'UT': 'Utah',
        'VT': 'Vermont',
        'VA': 'Virginia',
        'WA': 'Washington',
        'WV': 'West Virginia',
        'WI': 'Wisconsin',
        'WY': 'Wyoming',
        'DC': 'District of Columbia',
      };
      
      return usStateNormalization[stateName] ?? stateName;
    }
    
    return stateName;
  }

  // Função para converter siglas de estados em nomes completos
  String _getFullStateName(String stateCode, String country) {
    if (country == 'Brasil') {
      const Map<String, String> brazilianStates = {
        'AC': 'Acre',
        'AL': 'Alagoas',
        'AP': 'Amapá',
        'AM': 'Amazonas',
        'BA': 'Bahia',
        'CE': 'Ceará',
        'DF': 'Distrito Federal',
        'ES': 'Espírito Santo',
        'GO': 'Goiás',
        'MA': 'Maranhão',
        'MT': 'Mato Grosso',
        'MS': 'Mato Grosso do Sul',
        'MG': 'Minas Gerais',
        'PA': 'Pará',
        'PB': 'Paraíba',
        'PR': 'Paraná',
        'PE': 'Pernambuco',
        'PI': 'Piauí',
        'RJ': 'Rio de Janeiro',
        'RN': 'Rio Grande do Norte',
        'RS': 'Rio Grande do Sul',
        'RO': 'Rondônia',
        'RR': 'Roraima',
        'SC': 'Santa Catarina',
        'SP': 'São Paulo',
        'SE': 'Sergipe',
        'TO': 'Tocantins',
      };
      return brazilianStates[stateCode] ?? stateCode;
    } else if (country == 'Estados Unidos') {
      const Map<String, String> usStates = {
        'AL': 'Alabama',
        'AK': 'Alaska',
        'AZ': 'Arizona',
        'AR': 'Arkansas',
        'CA': 'California',
        'CO': 'Colorado',
        'CT': 'Connecticut',
        'DE': 'Delaware',
        'FL': 'Florida',
        'GA': 'Georgia',
        'HI': 'Hawaii',
        'ID': 'Idaho',
        'IL': 'Illinois',
        'IN': 'Indiana',
        'IA': 'Iowa',
        'KS': 'Kansas',
        'KY': 'Kentucky',
        'LA': 'Louisiana',
        'ME': 'Maine',
        'MD': 'Maryland',
        'MA': 'Massachusetts',
        'MI': 'Michigan',
        'MN': 'Minnesota',
        'MS': 'Mississippi',
        'MO': 'Missouri',
        'MT': 'Montana',
        'NE': 'Nebraska',
        'NV': 'Nevada',
        'NH': 'New Hampshire',
        'NJ': 'New Jersey',
        'NM': 'New Mexico',
        'NY': 'New York',
        'NC': 'North Carolina',
        'ND': 'North Dakota',
        'OH': 'Ohio',
        'OK': 'Oklahoma',
        'OR': 'Oregon',
        'PA': 'Pennsylvania',
        'RI': 'Rhode Island',
        'SC': 'South Carolina',
        'SD': 'South Dakota',
        'TN': 'Tennessee',
        'TX': 'Texas',
        'UT': 'Utah',
        'VT': 'Vermont',
        'VA': 'Virginia',
        'WA': 'Washington',
        'WV': 'West Virginia',
        'WI': 'Wisconsin',
        'WY': 'Wyoming',
        'DC': 'District of Columbia',
      };
      return usStates[stateCode] ?? stateCode;
    }
    return stateCode;
  }

  // Método para construir estatísticas de estados por país específico
  List<Widget> _buildStateStatsForCountry(String country) {
    final Map<String, int> stateCount = {};
    
    for (final contact in _contacts) {
      // Verifica se o contato é do país selecionado
      String? contactCountry;
      final countryFromDB = contact['country'];
      if (countryFromDB != null && countryFromDB.toString().isNotEmpty) {
        contactCountry = countryFromDB.toString();
      } else {
        final phone = contact['phone'];
        if (phone != null && phone.toString().isNotEmpty) {
          final countryCode = _getCountryCodeFromPhone(phone.toString());
          contactCountry = _getCountryName(countryCode);
        }
      }
      
      if (contactCountry == country) {
        final state = contact['state'];
        if (state != null && state.toString().isNotEmpty) {
          // Normalizar o nome do estado para evitar duplicações
          String normalizedStateName = _normalizeStateName(state.toString(), country);
          stateCount[normalizedStateName] = (stateCount[normalizedStateName] ?? 0) + 1;
        }
      }
    }
    
    if (stateCount.isEmpty) {
      return [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            'Nenhum estado encontrado para $country',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ),
      ];
    }
    
    final sortedStates = stateCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: 16,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Estados - $country',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: sortedStates.map((entry) {
                String fullStateName = _getFullStateName(entry.key, country);
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '$fullStateName: ${entry.value}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    ];
  }

  // Método para construir estatísticas de estados


  // Função para extrair o código ISO do país a partir do DDI do telefone
  String? _getCountryCodeFromPhone(String phone) {
    return FlagUtils.getCountryIsoCodeFromPhone(phone);
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
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            if (contact['phone'] != null && _getCountryCodeFromPhone(contact['phone']) != null)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Image.network(
                  FlagUtils.getFlagUrl(_getCountryCodeFromPhone(contact['phone'])!, width: 24, height: 18),
                  width: 24,
                  height: 18,
                  errorBuilder: (context, error, stackTrace) => const SizedBox(width: 24, height: 18),
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
              _buildDetailRow('Nome', contact['name'] ?? 'Não informado', Icons.person),
              _buildDetailRow('Email', contact['email'] ?? 'Não informado', Icons.email),
              _buildDetailRow('Telefone', contact['phone'] ?? 'Não informado', Icons.phone),
              _buildDetailRow('Gênero', _getGenderText(contact['gender']), Icons.person_outline),
              _buildDetailRow('Cidade', contact['city'] ?? 'Não informado', Icons.location_city),
              _buildDetailRow('Estado', contact['state'] ?? 'Não informado', Icons.location_on),
              _buildDetailRow('País', contact['country'] ?? 'Não informado', Icons.public),
              _buildDetailRow('CEP', contact['postal_code'] ?? 'Não informado', Icons.markunread_mailbox),
              _buildDetailRow('Origem', contact['source']?['name'] ?? 'Não informado', Icons.source),
              _buildDetailRow('Tipo de Conta', contact['account']?['name'] ?? 'Não informado', Icons.account_circle),
              _buildDetailRow('Categoria', contact['contact_category']?['name'] ?? 'Não informado', Icons.category),
                              if (contact['created_at'] != null)
                  _buildDetailRow('Data de Criação', 
                    DateTime.tryParse(contact['created_at'])?.toString().split(' ')[0] ?? 'Não informado', Icons.calendar_today),
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
      case 'M': return 'Masculino';
      case 'F': return 'Feminino';
      case 'O': return 'Outro';
      default: return 'Não informado';
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
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                // Adicionar flag do país antes do telefone
                if (label == 'Telefone' && value != 'Não informado' && _getCountryCodeFromPhone(value) != null) ...[
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Image.network(
                      FlagUtils.getFlagUrl(_getCountryCodeFromPhone(value)!, width: 20, height: 15),
                      width: 20,
                      height: 15,
                      errorBuilder: (context, error, stackTrace) => const SizedBox(width: 20, height: 15),
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                              validator: (v) => v == null || v.isEmpty ? 'Informe o nome' : null,
                              onSaved: (v) => name = v,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              initialValue: phone,
                              decoration: _buildModernInputDecoration('Telefone *'),
                              keyboardType: TextInputType.phone,
                              inputFormatters: [
                                PhoneInputFormatter(
                                  allowEndlessPhone: true,
                                ),
                              ],
                              validator: (v) => v == null || v.isEmpty ? 'Informe o telefone' : null,
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
                              validator: (v) => v != null && v.isNotEmpty && !v.contains('@') ? 'Email inválido' : null,
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
                                DropdownMenuItem(value: null, child: Text('Selecione')),
                                DropdownMenuItem(value: 'M', child: Text('Masculino')),
                                DropdownMenuItem(value: 'F', child: Text('Feminino')),
                                DropdownMenuItem(value: 'O', child: Text('Outro')),
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
                                const DropdownMenuItem(value: null, child: Text('Selecione')),
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
                              validator: (value) => value == null ? 'Selecione a origem' : null,
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
                              decoration: _buildModernInputDecoration('Tipo Conta'),
                              initialValue: account.any((a) => a.id == accountId) ? accountId : null,
                              items: [
                                const DropdownMenuItem(value: null, child: Text('Selecione')),
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
                              validator: (value) => value == null ? 'Selecione o tipo de conta' : null,
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
                          final contactCategoriesAsync = ref.watch(contactCategoriesProvider);
                          return contactCategoriesAsync.when(
                            data: (contactCategories) => DropdownButtonFormField<int>(
                              decoration: _buildModernInputDecoration('Tipo Contato'),
                              initialValue: contactCategories.any((c) => c.id == contactCategoryId) ? contactCategoryId : null,
                              items: [
                                const DropdownMenuItem(value: null, child: Text('Selecione')),
                                ...contactCategories.map((contactCategory) => DropdownMenuItem(
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
                              validator: (value) => value == null ? 'Selecione o tipo de contato' : null,
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
                onPressed: isSubmitting ? null : () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: isSubmitting ? null : () async {
                  if (formKey.currentState!.validate()) {
                    modalSetState(() {
                      isSubmitting = true;
                    });
                    
                    formKey.currentState!.save();
                    
                    // Validação adicional dos campos obrigatórios
                    if (sourceId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Selecione a origem do contato')),
                      );
                      modalSetState(() {
                        isSubmitting = false;
                      });
                      return;
                    }
                    
                    if (contactCategoryId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Selecione o tipo de contato')),
                      );
                      modalSetState(() {
                        isSubmitting = false;
                      });
                      return;
                    }
                    
                    final scaffoldMessenger = ScaffoldMessenger.of(context);
                    
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
                      updateData.removeWhere((key, value) => value == null || value.toString().trim().isEmpty);
                      
                      print('Dados para atualização: $updateData'); // Debug
                      
                      await _client
                          .from('contact')
                          .update(updateData)
                          .eq('id', contact['id']);
                      
                      Navigator.of(context).pop();
                      
                      scaffoldMessenger.showSnackBar(
                        const SnackBar(content: Text('Contato atualizado com sucesso!')),
                      );
                      
                      await Future.delayed(const Duration(milliseconds: 300));
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
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
                await _client
                    .from('contact')
                    .delete()
                    .eq('id', contact['id']);
                
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
    String? name, phone, email, cityName, countryCode, stateCode, zipCode, gender;
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                              validator: (v) => v == null || v.isEmpty ? 'Informe o nome' : null,
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
                                  decoration: _buildModernInputDecoration('Telefone *'),
                                  keyboardType: TextInputType.phone,
                                  inputFormatters: [
                                    PhoneInputFormatter(
                                      allowEndlessPhone: true,
                                    ),
                                  ],
                                  validator: (v) => v == null || v.isEmpty ? 'Informe o telefone' : null,
                                  onSaved: (v) => phone = v,
                                  onChanged: (value) {
                                modalSetState(() {
                                  detectedCountry = PhoneUtils.getCountryFromPhone(value);
                                  detectedState = PhoneUtils.getStateFromPhone(value);
                                  
                                  // Atualizar os controllers dos campos País e UF
                                  if (detectedCountry != null) {
                                    countryController.text = detectedCountry!;
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
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
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
                                            color: Theme.of(context).colorScheme.primary,
                                            fontWeight: FontWeight.w500,
                                            fontSize: 12,
                                          ),
                                        ),
                                        if (detectedState != null) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.2),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              detectedState!,
                                              style: TextStyle(
                                                color: Theme.of(context).colorScheme.secondary,
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
                              validator: (v) => v != null && v.isNotEmpty && !v.contains('@') ? 'Email inválido' : null,
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
                                DropdownMenuItem(value: null, child: Text('Selecione')),
                                DropdownMenuItem(value: 'M', child: Text('Masculino')),
                                DropdownMenuItem(value: 'F', child: Text('Feminino')),
                                DropdownMenuItem(value: 'O', child: Text('Outro')),
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
                                const DropdownMenuItem(value: null, child: Text('Selecione')),
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
                              validator: (value) => value == null ? 'Selecione a origem' : null,
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
                              decoration: _buildModernInputDecoration('Tipo Conta'),
                              initialValue: account.any((a) => a.id == accountId) ? accountId : null,
                              items: [
                                const DropdownMenuItem(value: null, child: Text('Selecione')),
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
                              validator: (value) => value == null ? 'Selecione o tipo de conta' : null,
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
                          final contactCategoriesAsync = ref.watch(contactCategoriesProvider);
                          return contactCategoriesAsync.when(
                            data: (contactCategories) => DropdownButtonFormField<int>(
                              decoration: _buildModernInputDecoration('Tipo Contato'),
                              initialValue: contactCategories.any((c) => c.id == contactCategoryId) ? contactCategoryId : null,
                              items: [
                                const DropdownMenuItem(value: null, child: Text('Selecione')),
                                ...contactCategories.map((contactCategory) => DropdownMenuItem(
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
                              validator: (value) => value == null ? 'Selecione o tipo de contato' : null,
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
                onPressed: isSubmitting ? null : () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: isSubmitting ? null : () async {
                  if (formKey.currentState!.validate()) {
                    modalSetState(() {
                      isSubmitting = true;
                    });
                    
                    formKey.currentState!.save();
                    
                    // Validação adicional dos campos obrigatórios
                    if (sourceId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Selecione a origem do contato')),
                      );
                      modalSetState(() {
                        isSubmitting = false;
                      });
                      return;
                    }
                    
                    if (contactCategoryId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Selecione o tipo de contato')),
                      );
                      modalSetState(() {
                        isSubmitting = false;
                      });
                      return;
                    }
                    
                    final scaffoldMessenger = ScaffoldMessenger.of(context);
                    
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
                      insertData.removeWhere((key, value) => value == null || value.toString().trim().isEmpty);
                      
                      print('Dados para inserção: $insertData'); // Debug
                      
                      await _client.from('contact').insert(insertData);
                      
                      Navigator.of(context).pop();
                      
                      scaffoldMessenger.showSnackBar(
                        const SnackBar(content: Text('Contato salvo com sucesso!')),
                      );
                      
                      await Future.delayed(const Duration(milliseconds: 300));
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
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
      {'key': 'contact_category', 'label': 'Categoria', 'width': availableWidth * 0.11},
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
              color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.table_chart, color: Theme.of(context).colorScheme.primary),
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
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
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
                          color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.2),
                          border: Border(
                            bottom: BorderSide(
                              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                              width: 2,
                            ),
                          ),
                        ),
                        child: Row(
                          children: columns.map((column) {
                            return Container(
                              width: column['width'] as double,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                              decoration: BoxDecoration(
                                border: Border(
                                  right: BorderSide(
                                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
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
                                : Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
                            border: Border(
                              bottom: BorderSide(
                                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
                                width: 1,
                              ),
                            ),
                          ),
                          child: Row(
                            children: columns.map((column) {
                              return Container(
                                width: column['width'] as double,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                decoration: BoxDecoration(
                                  border: Border(
                                    right: BorderSide(
                                      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
                                      width: 1,
                                    ),
                                  ),
                                ),
                                child: _buildCellContent(column['key'] as String, contact),
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
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              contact['gender'] == 'M' ? 'M' : contact['gender'] == 'F' ? 'F' : 'O',
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
              color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.3),
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
              icon: Icon(Icons.visibility, color: Theme.of(context).colorScheme.primary, size: 20),
              onPressed: () => _visualizarContato(contact),
              tooltip: 'Visualizar',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
            IconButton(
              icon: Icon(Icons.edit, color: Theme.of(context).colorScheme.primary, size: 20),
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
      final telefone = (c['phone'] ?? '').toString().replaceAll(RegExp(r'\D'), '');
      final email = (c['email'] ?? '').toString().toLowerCase();
      final cidade = (c['city'] ?? '').toString().toLowerCase();
      return nome.contains(termo) || telefone.contains(termo) || email.contains(termo) || cidade.contains(termo);
    }).toList();

    final List<Map<String, dynamic>> contatosExibidos = List<Map<String, dynamic>>.from(contactsFiltrados);

    return BaseScreenLayout(
      title: 'Contatos',
      actions: [
        IconButton(
          icon: Icon(_visualizarComoCartao ? Icons.table_chart : Icons.credit_card),
          tooltip: _visualizarComoCartao ? 'Visualizar como planilha' : 'Visualizar como cartões',
          onPressed: () {
            setState(() {
              _visualizarComoCartao = !_visualizarComoCartao;
            });
          },
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
          // Card de estatísticas expandido
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).colorScheme.outline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Estatísticas de Contatos',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Por País',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ..._buildCountryStats(),
                        ],
                      ),
                    ),

                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : contatosExibidos.isEmpty
                    ? const Center(child: Text('Nenhum contato encontrado com os filtros aplicados.'))
                    : ListView.builder(
                            padding: const EdgeInsets.all(16.0),
                            itemCount: contatosExibidos.length,
                            itemBuilder: (context, index) {
                              final c = contatosExibidos[index];
                              
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12.0),
                                elevation: 2,
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? const Color(0xFF2A2D3E)
                                    : const Color(0xFFE8F2FF),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                child: ExpansionTile(
                                  key: PageStorageKey(c['id']),
                                  leading: CircleAvatar(
                                    backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                                    child: Text(
                                      (c['name'] ?? 'C').substring(0, 1).toUpperCase(),
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                  title: Row(
                                    children: [
                                      // Nome
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          c['name'] ?? 'Nome não informado',
                                          style: (Theme.of(context).textTheme.titleMedium ?? const TextStyle())
                                              .copyWith(
                                                fontWeight: FontWeight.bold,
                                                fontFamily: 'Inter',
                                                fontSize: 16,
                                                color: Theme.of(context).colorScheme.onSurface,
                                              ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Telefone
                                      if (c['phone'] != null) ...[
                                        Expanded(
                                          flex: 3,
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.phone,
                                                size: 14,
                                                color: Colors.orange,
                                              ),
                                              const SizedBox(width: 4),
                                              // Bandeira do país
                                              if (c['phone'] != null && c['phone'].toString().isNotEmpty && _getCountryCodeFromPhone(c['phone'].toString()) != null)
                                                Padding(
                                                  padding: const EdgeInsets.only(right: 4),
                                                  child: Image.network(
                                                    FlagUtils.getFlagUrl(_getCountryCodeFromPhone(c['phone'].toString())!, width: 16, height: 12),
                                                    width: 16,
                                                    height: 12,
                                                    errorBuilder: (context, error, stackTrace) => const SizedBox(width: 16, height: 12),
                                                  ),
                                                ),
                                              Expanded(
                                                 child: Text(
                                                   _formatPhone(c['phone']),
                                                   style: const TextStyle(
                                                     fontFamily: 'Inter',
                                                     fontSize: 13,
                                                     color: Colors.orange,
                                                   ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                      ],
                                      // Tipo de Conta
                                      if (c['account']?['name'] != null) ...[
                                        Expanded(
                                          flex: 2,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              c['account']['name'],
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Colors.blue,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                      ],
                                      // Categoria de Contato
                                      if (c['contact_category']?['name'] != null)
                                        Expanded(
                                          flex: 2,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.green.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              c['contact_category']['name'],
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Colors.green,
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
                                                Icon(Icons.analytics, size: 16, color: Colors.purple),
                                                SizedBox(width: 8),
                                                Text('Perfil Completo', style: TextStyle(color: Colors.purple)),
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
                                                Icon(Icons.delete, size: 16, color: Colors.red),
                                                SizedBox(width: 8),
                                                Text('Excluir', style: TextStyle(color: Colors.red)),
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
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Apenas 2 linhas de informações essenciais
                                          if (c['email'] != null && c['phone'] != null)
                                            _buildDetailRow('Email', c['email'], Icons.email),
                                          if (c['city'] != null)
                                            _buildDetailRow('Cidade', c['city'], Icons.location_city),
                                          
                                          const SizedBox(height: 16),
                                          
                                          // Botões de ação
                                          Column(
                                            children: [
                                              // Primeira linha de botões
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: ElevatedButton.icon(
                                                      onPressed: () => _criarVendaParaCliente(c),
                                                      icon: const Icon(Icons.shopping_cart, size: 14),
                                                      label: const Text('Nova Venda', style: TextStyle(fontSize: 12)),
                                                      style: ElevatedButton.styleFrom(
                                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius: BorderRadius.circular(6),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Expanded(
                                                    child: OutlinedButton.icon(
                                                      onPressed: () => _visualizarContato(c),
                                                      icon: const Icon(Icons.visibility, size: 14),
                                                      label: const Text('Detalhes', style: TextStyle(fontSize: 12)),
                                                      style: OutlinedButton.styleFrom(
                                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius: BorderRadius.circular(6),
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
                                                      onPressed: () => _abrirPerfilCompleto(c),
                                                      icon: const Icon(Icons.analytics, size: 14),
                                                      label: const Text('Perfil', style: TextStyle(fontSize: 12)),
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor: Colors.purple,
                                                        foregroundColor: Colors.white,
                                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius: BorderRadius.circular(6),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Expanded(
                                                    child: ElevatedButton.icon(
                                                      onPressed: () => _abrirWhatsApp(c),
                                                      icon: const Icon(Icons.chat, size: 14),
                                                      label: const Text('WhatsApp', style: TextStyle(fontSize: 12)),
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor: const Color(0xFF25D366),
                                                        foregroundColor: Colors.white,
                                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius: BorderRadius.circular(6),
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
}
