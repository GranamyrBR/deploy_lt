import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/contact.dart';
import '../widgets/base_screen_layout.dart';
import '../widgets/standard_search_bar.dart';
import '../widgets/customer_profile_modal.dart';
import 'create_sale_screen_v2.dart';
import '../providers/sources_provider.dart';
import '../providers/accounts_provider.dart';
import '../providers/contact_categories_provider.dart';
import '../utils/phone_utils.dart';
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
    // Implementação simples para bandeiras
    switch (country.toUpperCase()) {
      case 'BR':
      case 'BRAZIL':
      case 'BRASIL':
        return '🇧🇷';
      case 'US':
      case 'USA':
      case 'UNITED STATES':
        return '🇺🇸';
      case 'GB':
      case 'UK':
      case 'UNITED KINGDOM':
        return '🇬🇧';
      case 'FR':
      case 'FRANCE':
        return '🇫🇷';
      case 'DE':
      case 'GERMANY':
        return '🇩🇪';
      case 'ES':
      case 'SPAIN':
        return '🇪🇸';
      case 'IT':
      case 'ITALY':
        return '🇮🇹';
      case 'PT':
      case 'PORTUGAL':
        return '🇵🇹';
      case 'AR':
      case 'ARGENTINA':
        return '🇦🇷';
      case 'MX':
      case 'MEXICO':
        return '🇲🇽';
      default:
        return '🌍';
    }
  }

  Future<void> _fetchContacts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _client
          .from('contact')
          .select('''
            id,
            name,
            phone,
            email,
            gender,
            address,
            city,
            uf,
            country,
            zip_code,
            created_at,
            updated_at,
            source_id,
            account_id,
            contact_category_id,
            source:source_id(name, color),
            account:account_id(name),
            contact_category:contact_category_id(name)
          ''')
          .order('created_at', ascending: false);

      setState(() {
        _contacts = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar contatos: $e')),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredContacts {
    if (_searchTerm.isEmpty) {
      return _contacts;
    }
    return _contacts.where((contact) {
      final name = contact['name']?.toString().toLowerCase() ?? '';
      final phone = contact['phone']?.toString().toLowerCase() ?? '';
      final email = contact['email']?.toString().toLowerCase() ?? '';
      final city = contact['city']?.toString().toLowerCase() ?? '';
      final country = contact['country']?.toString().toLowerCase() ?? '';
      final searchLower = _searchTerm.toLowerCase();
      
      return name.contains(searchLower) ||
             phone.contains(searchLower) ||
             email.contains(searchLower) ||
             city.contains(searchLower) ||
             country.contains(searchLower);
    }).toList();
  }

  void _createSale(Map<String, dynamic> contact) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateSaleScreenV2(
          contact: Contact.fromJson(contact),
        ),
      ),
    );
  }

  void _openProfile(Map<String, dynamic> contact) {
    showDialog(
      context: context,
      builder: (context) => CustomerProfileModal(
        customerId: contact['id'] as int,
        customerName: contact['name'] as String? ?? 'Cliente',
      ),
    );
  }

  void _openWhatsApp(Map<String, dynamic> contact) {
    print('=== BOTÃO WHATSAPP CLICADO ===');
    print('Contact data: $contact');
    final phone = contact['phone']?.toString() ?? '';
    print('Phone extracted: "$phone"');
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este contato não possui número de telefone cadastrado'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Criar objeto Contact a partir dos dados
    final contactObj = Contact(
      id: contact['id'],
      name: contact['name'],
      phone: phone,
      email: contact['email'],
      country: contact['country'],
      state: contact['state'],
      city: contact['city'],
      sourceId: contact['source_id'],
      contactCategoryId: contact['contact_category_id'],
      createdAt: contact['created_at'] != null 
          ? DateTime.parse(contact['created_at']) 
          : null,
      updatedAt: contact['updated_at'] != null 
          ? DateTime.parse(contact['updated_at']) 
          : null,
    );

    showDialog(
      context: context,
      builder: (context) => WhatsAppMessagesModal(contact: contactObj),
    );
  }

  // Função para padronizar InputDecoration
  InputDecoration _buildInputDecoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
    );
  }

  // Função para obter nome do país a partir do código ISO
  String _getCountryName(String countryCode) {
    final countryNames = {
      'BR': 'Brasil',
      'US': 'Estados Unidos',
      'AR': 'Argentina',
      'UY': 'Uruguai',
      'PY': 'Paraguai',
      'CL': 'Chile',
      'PE': 'Peru',
      'BO': 'Bolívia',
      'CO': 'Colômbia',
      'VE': 'Venezuela',
      'EC': 'Equador',
      'GY': 'Guiana',
      'SR': 'Suriname',
      'GF': 'Guiana Francesa',
      'FK': 'Ilhas Malvinas',
    };
    return countryNames[countryCode] ?? countryCode;
  }

  // Função para construir estatísticas de países
  Widget _buildCountryStats() {
    // Agrupar contatos por país
    final countryStats = <String, int>{};
    for (final contact in _filteredContacts) {
      final country = contact['country']?.toString() ?? 'Desconhecido';
      countryStats[country] = (countryStats[country] ?? 0) + 1;
    }

    // Ordenar por quantidade (decrescente)
    final sortedCountries = countryStats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Contatos por País',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: sortedCountries.map((entry) {
                final country = entry.key;
                final count = entry.value;
                final isSelected = _selectedCountryForStates == country;
                
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCountryForStates = isSelected ? null : country;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                          : Colors.grey[100],
                      border: Border.all(
                        color: isSelected 
                            ? Theme.of(context).primaryColor
                            : Colors.grey[300]!,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _getCountryFlag(country),
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _getCountryName(country),
                          style: TextStyle(
                            fontWeight: isSelected 
                                ? FontWeight.bold 
                                : FontWeight.normal,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            count.toString(),
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
                );
              }).toList(),
            ),
            // Mostrar estatísticas de estados se um país estiver selecionado
            if (_selectedCountryForStates != null) ...[
              const SizedBox(height: 16),
              _buildStateStats(_selectedCountryForStates!),
            ],
          ],
        ),
      ),
    );
  }

  // Função para construir estatísticas de estados por país
  Widget _buildStateStats(String country) {
    // Filtrar contatos do país selecionado
    final countryContacts = _filteredContacts
        .where((contact) => contact['country'] == country)
        .toList();

    // Agrupar por estado
    final stateStats = <String, int>{};
    for (final contact in countryContacts) {
      final state = contact['uf']?.toString() ?? 'Desconhecido';
      stateStats[state] = (stateStats[state] ?? 0) + 1;
    }

    // Ordenar por quantidade (decrescente)
    final sortedStates = stateStats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Estados/Regiões em ${_getCountryName(country)}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: sortedStates.map((entry) {
            final state = entry.key;
            final count = entry.value;
            
            return Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                border: Border.all(color: Colors.blue[200]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    state,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      count.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // Função para obter código do país a partir do telefone
  String? _getCountryCodeFromPhone(String phone) {
    // Implementação simples para extrair código do país
    if (phone.startsWith('+55')) return 'BR';
    if (phone.startsWith('+1')) return 'US';
    if (phone.startsWith('+44')) return 'GB';
    if (phone.startsWith('+33')) return 'FR';
    if (phone.startsWith('+49')) return 'DE';
    if (phone.startsWith('+34')) return 'ES';
    if (phone.startsWith('+39')) return 'IT';
    if (phone.startsWith('+351')) return 'PT';
    if (phone.startsWith('+54')) return 'AR';
    if (phone.startsWith('+52')) return 'MX';
    return null;
  }

  // Função para formatar telefone
  String _formatPhone(String phone, String? country) {
    return PhoneUtils.formatPhone(phone);
  }

  // Função para visualizar detalhes do contato
  void _viewContactDetails(Map<String, dynamic> contact) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detalhes do Contato'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Nome', contact['name']),
              _buildDetailRow('Email', contact['email']),
              _buildDetailRow('Telefone', contact['phone']),
              _buildDetailRow('Gênero', contact['gender']),
              _buildDetailRow('Endereço', contact['address']),
              _buildDetailRow('Cidade', contact['city']),
              _buildDetailRow('UF', contact['uf']),
              _buildDetailRow('País', contact['country']),
              _buildDetailRow('CEP', contact['zip_code']),
              _buildDetailRow('Criado em', contact['created_at']),
              _buildDetailRow('Atualizado em', contact['updated_at']),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value?.toString() ?? 'N/A'),
          ),
        ],
      ),
    );
  }

  // Função para editar contato
  void _editContact(Map<String, dynamic> contact) {
    final nameController = TextEditingController(text: contact['name']);
    final phoneController = TextEditingController(text: contact['phone']);
    final emailController = TextEditingController(text: contact['email']);
    final genderController = TextEditingController(text: contact['gender']);
    final addressController = TextEditingController(text: contact['address']);
    final cityController = TextEditingController(text: contact['city']);
    final ufController = TextEditingController(text: contact['uf']);
    final countryController = TextEditingController(text: contact['country']);
    final zipCodeController = TextEditingController(text: contact['zip_code']);
    
    final sources = ref.read(sourcesProvider);
    final accounts = ref.read(accountsProvider);
    final categories = ref.read(contactCategoriesProvider);
    
    int? selectedSourceId = contact['source_id'];
    int? selectedAccountId = contact['account_id'];
    int? selectedCategoryId = contact['contact_category_id'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Contato'),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: _buildInputDecoration('Nome'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  decoration: _buildInputDecoration('Telefone'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  decoration: _buildInputDecoration('Email'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: genderController,
                  decoration: _buildInputDecoration('Gênero'),
                ),
                const SizedBox(height: 12),
                sources.when(
                  data: (sourcesList) => DropdownButtonFormField<int>(
                    initialValue: selectedSourceId,
                    decoration: _buildInputDecoration('Origem'),
                    items: sourcesList.map((source) {
                      return DropdownMenuItem<int>(
                        value: source.id,
                        child: Text(source.name ?? ''),
                      );
                    }).toList(),
                    onChanged: (value) {
                      selectedSourceId = value;
                    },
                  ),
                  loading: () => const CircularProgressIndicator(),
                  error: (error, stack) => Text('Erro: $error'),
                ),
                const SizedBox(height: 12),
                accounts.when(
                  data: (accountsList) => DropdownButtonFormField<int>(
                    initialValue: selectedAccountId,
                    decoration: _buildInputDecoration('Tipo de Conta'),
                    items: accountsList.map((account) {
                      return DropdownMenuItem<int>(
                        value: account.id,
                        child: Text(account.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      selectedAccountId = value;
                    },
                  ),
                  loading: () => const CircularProgressIndicator(),
                  error: (error, stack) => Text('Erro: $error'),
                ),
                const SizedBox(height: 12),
                categories.when(
                  data: (categoriesList) => DropdownButtonFormField<int>(
                    initialValue: selectedCategoryId,
                    decoration: _buildInputDecoration('Tipo de Contato'),
                    items: categoriesList.map((category) {
                      return DropdownMenuItem<int>(
                        value: category.id,
                        child: Text(category.name ?? ''),
                      );
                    }).toList(),
                    onChanged: (value) {
                      selectedCategoryId = value;
                    },
                  ),
                  loading: () => const CircularProgressIndicator(),
                  error: (error, stack) => Text('Erro: $error'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: addressController,
                  decoration: _buildInputDecoration('Endereço'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: cityController,
                  decoration: _buildInputDecoration('Cidade'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: ufController,
                  decoration: _buildInputDecoration('UF'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: countryController,
                  decoration: _buildInputDecoration('País'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: zipCodeController,
                  decoration: _buildInputDecoration('CEP'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _client.from('contact').update({
                  'name': nameController.text,
                  'phone': phoneController.text,
                  'email': emailController.text,
                  'gender': genderController.text,
                  'address': addressController.text,
                  'city': cityController.text,
                  'uf': ufController.text,
                  'country': countryController.text,
                  'zip_code': zipCodeController.text,
                  'source_id': selectedSourceId,
                  'account_id': selectedAccountId,
                  'contact_category_id': selectedCategoryId,
                  'updated_at': DateTime.now().toUtc().toIso8601String(),
                }).eq('id', contact['id']);
                
                Navigator.of(context).pop();
                _fetchContacts();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Contato atualizado com sucesso!')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erro ao atualizar contato: $e')),
                );
              }
            },
            child: const Text('Atualizar'),
          ),
        ],
      ),
    );
  }

  // Função para excluir contato
  void _deleteContact(Map<String, dynamic> contact) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text('Tem certeza que deseja excluir o contato "${contact['name']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _client.from('contact').delete().eq('id', contact['id']);
                Navigator.of(context).pop();
                _fetchContacts();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Contato excluído com sucesso!')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erro ao excluir contato: $e')),
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

  // Função para adicionar novo contato
  void _addNewContact() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final genderController = TextEditingController();
    final addressController = TextEditingController();
    final cityController = TextEditingController();
    final ufController = TextEditingController();
    final countryController = TextEditingController();
    final zipCodeController = TextEditingController();
    
    final sources = ref.read(sourcesProvider);
    final accounts = ref.read(accountsProvider);
    final categories = ref.read(contactCategoriesProvider);
    
    int? selectedSourceId;
    int? selectedAccountId;
    int? selectedCategoryId;
    String? detectedCountry;
    String? detectedState;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Adicionar Novo Contato'),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: _buildInputDecoration('Nome'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneController,
                    decoration: _buildInputDecoration('Telefone'),
                    onChanged: (value) {
                      // Detectar país e estado pelo telefone
                      if (value.isNotEmpty) {
                        final country = _getCountryCodeFromPhone(value);
                        if (country != null) {
                          setDialogState(() {
                            detectedCountry = country;
                            countryController.text = country;
                            // Se for Brasil, tentar detectar estado
                            if (country == 'BR') {
                              final state = PhoneUtils.getStateFromPhone(value);
                              if (state != null) {
                                detectedState = state;
                                ufController.text = state;
                              }
                            }
                          });
                        }
                      }
                    },
                  ),
                  // Mostrar bandeira e estado detectados
                  if (detectedCountry != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(_getCountryFlag(detectedCountry!)),
                        const SizedBox(width: 8),
                        Text('País detectado: ${_getCountryName(detectedCountry!)}'),
                        if (detectedState != null) ...[
                          const SizedBox(width: 16),
                          Text('Estado: $detectedState'),
                        ],
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailController,
                    decoration: _buildInputDecoration('Email'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: genderController,
                    decoration: _buildInputDecoration('Gênero'),
                  ),
                  const SizedBox(height: 12),
                  sources.when(
                    data: (sourcesList) => DropdownButtonFormField<int>(
                      initialValue: selectedSourceId,
                      decoration: _buildInputDecoration('Origem'),
                      items: sourcesList.map((source) {
                        return DropdownMenuItem<int>(
                          value: source.id,
                          child: Text(source.name ?? ''),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedSourceId = value;
                        });
                      },
                    ),
                    loading: () => const CircularProgressIndicator(),
                    error: (error, stack) => Text('Erro: $error'),
                  ),
                  const SizedBox(height: 12),
                  accounts.when(
                    data: (accountsList) => DropdownButtonFormField<int>(
                      initialValue: selectedAccountId,
                      decoration: _buildInputDecoration('Tipo de Conta'),
                      items: accountsList.map((account) {
                        return DropdownMenuItem<int>(
                          value: account.id,
                          child: Text(account.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedAccountId = value;
                        });
                      },
                    ),
                    loading: () => const CircularProgressIndicator(),
                    error: (error, stack) => Text('Erro: $error'),
                  ),
                  const SizedBox(height: 12),
                  categories.when(
                    data: (categoriesList) => DropdownButtonFormField<int>(
                      initialValue: selectedCategoryId,
                      decoration: _buildInputDecoration('Tipo de Contato'),
                      items: categoriesList.map((category) {
                        return DropdownMenuItem<int>(
                          value: category.id,
                          child: Text(category.name ?? ''),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedCategoryId = value;
                        });
                      },
                    ),
                    loading: () => const CircularProgressIndicator(),
                    error: (error, stack) => Text('Erro: $error'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: addressController,
                    decoration: _buildInputDecoration('Endereço'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: cityController,
                    decoration: _buildInputDecoration('Cidade'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: ufController,
                    decoration: _buildInputDecoration('UF'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: countryController,
                    decoration: _buildInputDecoration('País'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: zipCodeController,
                    decoration: _buildInputDecoration('CEP'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Nome é obrigatório')),
                  );
                  return;
                }
                
                try {
                  await _client.from('contact').insert({
                    'name': nameController.text,
                    'phone': phoneController.text,
                    'email': emailController.text,
                    'gender': genderController.text,
                    'address': addressController.text,
                    'city': cityController.text,
                    'uf': ufController.text,
                    'country': countryController.text,
                    'zip_code': zipCodeController.text,
                    'source_id': selectedSourceId,
                    'account_id': selectedAccountId,
                    'contact_category_id': selectedCategoryId,
                    'created_at': DateTime.now().toUtc().toIso8601String(),
                    'updated_at': DateTime.now().toUtc().toIso8601String(),
                  });
                  
                  Navigator.of(context).pop();
                  _fetchContacts();
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Contato criado com sucesso!')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro ao criar contato: $e')),
                  );
                }
              },
              child: const Text('Criar'),
            ),
          ],
        ),
      ),
    );
  }

  // Função para abrir modal do WhatsApp Leads (genérico)
  void _abrirModalWhatsAppLeads() {
    // Criar um contato genérico para mostrar todos os leads
    final genericContact = Contact(
      id: 0,
      name: 'Todos os Leads',
      phone: '', // Vazio para buscar todos
      email: null,
      country: null,
      state: null,
      city: null,
      sourceId: null,
      contactCategoryId: null,
      createdAt: null,
      updatedAt: null,
    );

    showDialog(
      context: context,
      builder: (context) => WhatsAppMessagesModal(contact: genericContact),
    );
  }

  // Função para construir visualização em planilha
  Widget _buildSpreadsheetView() {
    final columns = [
      'Nome',
      'Telefone',
      'Email',
      'Gênero',
      'Origem',
      'Cidade',
      'UF',
      'País',
      'CEP',
      'Tipo de Conta',
      'Categoria',
      'Ações',
    ];

    return Card(
      child: Column(
        children: [
          // Cabeçalho
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(
                bottom: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Scrollbar(
              controller: _horizontalScrollController,
              child: SingleChildScrollView(
                controller: _horizontalScrollController,
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: columns.map((column) {
                    return Container(
                      width: 150,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border(
                          right: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                      child: Text(
                        column,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          // Conteúdo
          Expanded(
            child: Scrollbar(
              controller: _horizontalScrollController,
              child: SingleChildScrollView(
                controller: _horizontalScrollController,
                scrollDirection: Axis.horizontal,
                child: Column(
                  children: _filteredContacts.map((contact) {
                    return Container(
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.grey[200]!),
                        ),
                      ),
                      child: Row(
                        children: [
                          // Nome
                          _buildCell(contact['name'] ?? '', 150),
                          // Telefone
                          _buildCell(contact['phone'] ?? '', 150),
                          // Email
                          _buildCell(contact['email'] ?? '', 150),
                          // Gênero
                          _buildCell(contact['gender'] ?? '', 150),
                          // Origem
                          _buildCell(
                            contact['source'] != null 
                                ? contact['source']['name'] ?? ''
                                : '',
                            150,
                          ),
                          // Cidade
                          _buildCell(contact['city'] ?? '', 150),
                          // UF
                          _buildCell(contact['uf'] ?? '', 150),
                          // País
                          _buildCell(contact['country'] ?? '', 150),
                          // CEP
                          _buildCell(contact['zip_code'] ?? '', 150),
                          // Tipo de Conta
                          _buildCell(
                            contact['account'] != null 
                                ? contact['account']['name'] ?? ''
                                : '',
                            150,
                          ),
                          // Categoria
                          _buildCell(
                            contact['contact_category'] != null 
                                ? contact['contact_category']['name'] ?? ''
                                : '',
                            150,
                          ),
                          // Ações
                          Container(
                            width: 150,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              border: Border(
                                right: BorderSide(color: Colors.grey[300]!),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.visibility, size: 16),
                                  onPressed: () => _viewContactDetails(contact),
                                  tooltip: 'Visualizar',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 16),
                                  onPressed: () => _editContact(contact),
                                  tooltip: 'Editar',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, size: 16),
                                  onPressed: () => _deleteContact(contact),
                                  tooltip: 'Excluir',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCell(String content, double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Text(
        content,
        style: const TextStyle(fontSize: 13),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreenLayout(
      title: 'Contatos',
      child: Column(
        children: [
          // Barra de pesquisa e controles
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: StandardSearchBar(
                          onChanged: (value) {
                            setState(() {
                              _searchTerm = value;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: Icon(_visualizarComoCartao 
                            ? Icons.table_chart 
                            : Icons.view_agenda),
                        onPressed: () {
                          setState(() {
                            _visualizarComoCartao = !_visualizarComoCartao;
                          });
                        },
                        tooltip: _visualizarComoCartao 
                            ? 'Visualizar como planilha' 
                            : 'Visualizar como cartões',
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: _addNewContact,
                        tooltip: 'Adicionar novo contato',
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: _fetchContacts,
                        tooltip: 'Atualizar lista',
                      ),
                      ElevatedButton.icon(
                        onPressed: _abrirModalWhatsAppLeads,
                        icon: const Icon(Icons.message),
                        label: const Text('WhatsApp Leads'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Estatísticas de países
          _buildCountryStats(),
          // Lista de contatos
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _visualizarComoCartao
                    ? ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredContacts.length,
                        itemBuilder: (context, index) {
                          final contact = _filteredContacts[index];
                          final source = contact['source'];
                          final account = contact['account'];
                          final category = contact['contact_category'];
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ExpansionTile(
                              leading: CircleAvatar(
                                backgroundColor: source != null && source['color'] != null
                                    ? Color(int.parse(source['color'].replaceFirst('#', '0xFF')))
                                    : Colors.grey,
                                child: Text(
                                  contact['name']?.toString().substring(0, 1).toUpperCase() ?? '?',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      contact['name'] ?? 'Nome não informado',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  if (contact['phone'] != null) ...[
                                    Text(
                                      _getCountryFlag(contact['country'] ?? ''),
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _formatPhone(contact['phone'], contact['country']),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (account != null)
                                    Text(
                                      'Conta: ${account['name']}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  if (category != null)
                                    Text(
                                      'Categoria: ${category['name']}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                ],
                              ),
                              trailing: PopupMenuButton<String>(
                                onSelected: (value) {
                                  switch (value) {
                                    case 'view':
                                      _viewContactDetails(contact);
                                      break;
                                    case 'profile':
                                      _openProfile(contact);
                                      break;
                                    case 'edit':
                                      _editContact(contact);
                                      break;
                                    case 'delete':
                                      _deleteContact(contact);
                                      break;
                                    case 'sale':
                                      _createSale(contact);
                                      break;
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'view',
                                    child: ListTile(
                                      leading: Icon(Icons.visibility),
                                      title: Text('Visualizar'),
                                      dense: true,
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'profile',
                                    child: ListTile(
                                      leading: Icon(Icons.person),
                                      title: Text('Perfil Completo'),
                                      dense: true,
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: ListTile(
                                      leading: Icon(Icons.edit),
                                      title: Text('Editar'),
                                      dense: true,
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: ListTile(
                                      leading: Icon(Icons.delete),
                                      title: Text('Excluir'),
                                      dense: true,
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'sale',
                                    child: ListTile(
                                      leading: Icon(Icons.shopping_cart),
                                      title: Text('Nova Venda'),
                                      dense: true,
                                    ),
                                  ),
                                ],
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (contact['email'] != null)
                                        Text('Email: ${contact['email']}'),
                                      if (contact['city'] != null)
                                        Text('Cidade: ${contact['city']}'),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          ElevatedButton.icon(
                                            onPressed: () => _createSale(contact),
                                            icon: const Icon(Icons.shopping_cart),
                                            label: const Text('Nova Venda'),
                                          ),
                                          const SizedBox(width: 8),
                                          OutlinedButton.icon(
                                            onPressed: () => _viewContactDetails(contact),
                                            icon: const Icon(Icons.visibility),
                                            label: const Text('Detalhes'),
                                          ),
                                          const SizedBox(width: 8),
                                          OutlinedButton.icon(
                                            onPressed: () => _openProfile(contact),
                                            icon: const Icon(Icons.person),
                                            label: const Text('Perfil'),
                                          ),
                                          const SizedBox(width: 8),
                                          OutlinedButton.icon(
                                            onPressed: () => _openWhatsApp(contact),
                                            icon: const Icon(Icons.message),
                                            label: const Text('WhatsApp'),
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
                      )
                    : _buildSpreadsheetView(),
          ),
        ],
      ),
    );
  }
}
