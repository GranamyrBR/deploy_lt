import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:lecotour_dashboard/models/agency.dart';
  import 'package:lecotour_dashboard/providers/agency_provider.dart';
  import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
  import '../widgets/base_screen_layout.dart';
  import '../widgets/standard_search_bar.dart';
  import '../utils/smart_search_mixin.dart';
  import '../utils/flag_utils.dart';
  import 'package:supabase_flutter/supabase_flutter.dart';
  import 'package:lecotour_dashboard/models/department.dart';
  import 'package:lecotour_dashboard/models/position.dart';
  import 'agency_details_screen.dart';


class AgenciesScreen extends ConsumerStatefulWidget {
  const AgenciesScreen({super.key});

  @override
  ConsumerState<AgenciesScreen> createState() => _AgenciesScreenState();
}

class _AgenciesScreenState extends ConsumerState<AgenciesScreen> with SmartSearchMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _countryController = TextEditingController();
  final _zipController = TextEditingController();
  final _websiteController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _commissionRateController = TextEditingController();
  bool _isSubmitting = false;
  bool _visualizarComoCartao = false;

  String _buscaNome = '';
  String _buscaEmail = '';
  String _buscaCidade = '';
  String _buscaTelefone = '';
  
  // Campo de busca unificado
  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = '';

  @override
  void initState() {
    super.initState();
    
    // Adicionar listener para mudanças no campo de busca
    _searchController.addListener(() {
      final newSearchTerm = _searchController.text.trim().toLowerCase();
      setState(() {
        _searchTerm = newSearchTerm;
      });
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    _zipController.dispose();
    _websiteController.dispose();
    _contactPersonController.dispose();
    _commissionRateController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _showAddAgencyDialog() {
    // Reset form
    _formKey.currentState?.reset();
    _nameController.clear();
    _emailController.clear();
    _phoneController.clear();
    _addressController.clear();
    _cityController.clear();
    _stateController.clear();
    _countryController.clear();
    _zipController.clear();
    _websiteController.clear();
    _contactPersonController.clear();
    _commissionRateController.clear();
    _isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF2A2D3E)
              : const Color(0xFFE8F2FF),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Adicionar Nova Agência',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          content: SizedBox(
            width: 600,
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: _buildModernInputDecoration('Nome da Agência *'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Nome é obrigatório';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _emailController,
                            decoration: _buildModernInputDecoration('Email', hintText: 'exemplo@agencia.com'),
                            keyboardType: TextInputType.emailAddress,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9@._-]')),
                            ],
                            validator: (value) {
                              if (value != null && value.isNotEmpty) {
                                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                  return 'Email inválido';
                                }
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _phoneController,
                            decoration: _buildModernInputDecoration('Telefone', hintText: '+1 (555) 123-4567'),
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              PhoneInputFormatter(
                                allowEndlessPhone: true,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      decoration: _buildModernInputDecoration('Endereço'),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _cityController,
                            decoration: _buildModernInputDecoration('Cidade'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _stateController,
                            decoration: _buildModernInputDecoration('Estado'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _countryController,
                            decoration: _buildModernInputDecoration('País'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _zipController,
                            decoration: _buildModernInputDecoration('CEP'),
                            inputFormatters: [
                              MaskedInputFormatter('#####-###'),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _websiteController,
                            decoration: _buildModernInputDecoration('Website', hintText: 'https://www.agencia.com'),
                            keyboardType: TextInputType.url,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _contactPersonController,
                            decoration: _buildModernInputDecoration('Pessoa de Contato'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _commissionRateController,
                      decoration: _buildModernInputDecoration('Taxa de Comissão (%)', hintText: '10.5', suffixText: '%'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final rate = double.tryParse(value);
                          if (rate == null || rate < 0 || rate > 100) {
                            return 'Taxa deve ser entre 0 e 100';
                          }
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: _isSubmitting ? null : () async {
                if (_formKey.currentState!.validate()) {
                  setDialogState(() {
                    _isSubmitting = true;
                  });

                  final success = await ref.read(agencyProvider.notifier).addAgency(
                    name: _nameController.text,
                    email: _emailController.text,
                    phone: _phoneController.text,
                    address: _addressController.text,
                    cityName: _cityController.text,
                    stateCode: _stateController.text,
                    countryCode: _countryController.text,
                    zipCode: _zipController.text,
                    website: _websiteController.text,
                    contactPerson: _contactPersonController.text,
                    commissionRate: _commissionRateController.text.isNotEmpty 
                        ? double.tryParse(_commissionRateController.text) 
                        : null,
                  );

                  if (success) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Agência adicionada com sucesso!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                    Navigator.of(context).pop();
                  } else {
                    setDialogState(() {
                      _isSubmitting = false;
                    });
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(ref.read(agencyProvider).errorMessage ?? 'Erro ao adicionar agência'),
                          backgroundColor: Colors.red,
                        ),
                      );
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
              child: _isSubmitting 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditAgencyDialog(Agency agency) {
    // Preencher formulário com dados da agência
    _nameController.text = agency.name;
    _emailController.text = agency.email ?? '';
    _phoneController.text = agency.phone ?? '';
    _addressController.text = agency.address ?? '';
    _cityController.text = agency.cityName ?? '';
    _stateController.text = agency.stateCode ?? '';
    _countryController.text = agency.countryCode ?? '';
    _zipController.text = agency.zipCode ?? '';
    _websiteController.text = agency.website ?? '';
    _contactPersonController.text = agency.contactPerson ?? '';
    _commissionRateController.text = agency.commissionRate?.toString() ?? '';
    _isSubmitting = false;

    bool editIsActive = agency.isActive;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF2A2D3E)
              : const Color(0xFFE8F2FF),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Editar Agência',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          content: SizedBox(
            width: 600,
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: _buildModernInputDecoration('Nome da Agência *'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Nome é obrigatório';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _emailController,
                            decoration: _buildModernInputDecoration('Email', hintText: 'exemplo@agencia.com'),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value != null && value.isNotEmpty) {
                                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                  return 'Email inválido';
                                }
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _phoneController,
                            decoration: _buildModernInputDecoration('Telefone', hintText: '+1 (555) 123-4567'),
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              PhoneInputFormatter(
                                allowEndlessPhone: true,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      decoration: _buildModernInputDecoration('Endereço'),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _cityController,
                            decoration: _buildModernInputDecoration('Cidade'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _stateController,
                            decoration: _buildModernInputDecoration('Estado'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _countryController,
                            decoration: _buildModernInputDecoration('País'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _zipController,
                            decoration: _buildModernInputDecoration('CEP'),
                            inputFormatters: [
                              MaskedInputFormatter('#####-###'),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _websiteController,
                            decoration: _buildModernInputDecoration('Website', hintText: 'https://www.agencia.com'),
                            keyboardType: TextInputType.url,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _contactPersonController,
                            decoration: _buildModernInputDecoration('Pessoa de Contato'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _commissionRateController,
                      decoration: _buildModernInputDecoration('Taxa de Comissão (%)', hintText: '10.5', suffixText: '%'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final rate = double.tryParse(value);
                          if (rate == null || rate < 0 || rate > 100) {
                            return 'Taxa deve ser entre 0 e 100';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            editIsActive ? Icons.check_circle : Icons.cancel,
                            color: editIsActive 
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.error,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Agência Ativa',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                          Switch(
                            value: editIsActive,
                            onChanged: (value) {
                              setDialogState(() {
                                editIsActive = value;
                              });
                            },
                            activeColor: Theme.of(context).colorScheme.primary,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: _isSubmitting ? null : () async {
                if (_formKey.currentState!.validate()) {
                  setDialogState(() {
                    _isSubmitting = true;
                  });

                  final success = await ref.read(agencyProvider.notifier).updateAgency(
                    agencyId: agency.id,
                    name: _nameController.text,
                    email: _emailController.text,
                    phone: _phoneController.text,
                    address: _addressController.text,
                    cityName: _cityController.text,
                    stateCode: _stateController.text,
                    countryCode: _countryController.text,
                    zipCode: _zipController.text,
                    website: _websiteController.text,
                    contactPerson: _contactPersonController.text,
                    commissionRate: _commissionRateController.text.isNotEmpty 
                        ? double.tryParse(_commissionRateController.text) 
                        : null,
                    isActive: editIsActive,
                  );

                  if (success) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Agência atualizada com sucesso!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                    Navigator.of(context).pop();
                  } else {
                    setDialogState(() {
                      _isSubmitting = false;
                    });
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(ref.read(agencyProvider).errorMessage ?? 'Erro ao atualizar agência'),
                          backgroundColor: Colors.red,
                        ),
                      );
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
              child: _isSubmitting 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Atualizar'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(Agency agency) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text('Tem certeza que deseja excluir a agência "${agency.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              
              final success = await ref.read(agencyProvider.notifier).deleteAgency(agency.id);
              
              if (success) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Agência excluída com sucesso!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(ref.read(agencyProvider).errorMessage ?? 'Erro ao excluir agência'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final agencyState = ref.watch(agencyProvider);
    final agencies = agencyState.agencies;

    // Filtrar agências usando busca inteligente
    final filteredAgencies = agencies.where((agency) {
      if (_searchTerm.isEmpty) return true;
      
      // Converter Agency para Map para usar o mixin
      final agencyMap = {
        'id': agency.id,
        'name': agency.name,
        'email': agency.email,
        'phone': agency.phone,
        'cityName': agency.cityName,
      };
      
      return smartSearch(
        agencyMap, 
        _searchTerm,
        nameField: 'name',
        phoneField: 'phone',
        emailField: 'email',
        cityField: 'cityName',
      );
    }).toList();

    final bool isMobile = MediaQuery.of(context).size.width < 600;

    return BaseScreenLayout(
      title: 'Gerenciamento de Agências',
      actions: [
        IconButton(
          icon: Icon(
              _visualizarComoCartao ? Icons.view_list : Icons.credit_card),
          tooltip: _visualizarComoCartao
              ? 'Visualizar como lista'
              : 'Visualizar como cartões',
          onPressed: () {
            setState(() {
              _visualizarComoCartao = !_visualizarComoCartao;
            });
          },
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () =>
              ref.read(agencyProvider.notifier).fetchAgencies(),
          tooltip: 'Atualizar Dados',
        ),
        IconButton(
          icon: const Icon(Icons.add_circle_outline),
          onPressed: _showAddAgencyDialog,
          tooltip: 'Adicionar Agência',
        ),
        IconButton(
          icon: const Icon(Icons.bug_report),
          tooltip: 'Abrir Dialog Teste',
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => _DialogDropdownsTeste(),
            );
          },
        ),
      ],
      searchBar: StandardSearchBar(
        controller: _searchController,
        hintText: 'Buscar por nome, email, cidade, telefone...',
        onChanged: (v) {
          setState(() => _searchTerm = v.trim().toLowerCase());
        },
      ),
      child: agencyState.isLoading && agencies.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : agencyState.errorMessage != null && agencies.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Erro: ${agencyState.errorMessage}'),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () => ref
                            .read(agencyProvider.notifier)
                            .fetchAgencies(),
                        child: const Text('Tentar Novamente'),
                      )
                    ],
                  ),
                )
              : filteredAgencies.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Nenhuma agência encontrada.'),
                          const SizedBox(height: 16),
                          Text('Termo de busca: "$_searchTerm"'),
                          Text('Total de agências: ${agencies.length}'),
                          Text('Agências filtradas: ${filteredAgencies.length}'),
                          if (agencies.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text('Primeira agência: ${agencies.first.name}'),
                          ],
                        ],
                      ),
                    )
                  : _visualizarComoCartao
                      ? _buildAgenciesGrid(filteredAgencies, isMobile)
                      : _buildAgenciesList(filteredAgencies)
    );
  }

  Widget _buildAgenciesGrid(List<Agency> agencies, bool isMobile) {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isMobile ? 1 : 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: isMobile ? 0.8 : 1.2,
      ),
      itemCount: agencies.length,
      itemBuilder: (context, index) {
        final agency = agencies[index];
        return InkWell(
          onTap: () {
            showDialog(
              context: context,
              barrierDismissible: true,
              builder: (_) => AlertDialog(
                contentPadding: EdgeInsets.zero,
                content: SizedBox(
                  width: isMobile ? 360 : 1000,
                  height: isMobile ? 600 : 700,
                  child: AgencyDetailsScreen(agency: agency),
                ),
              ),
            );
          },
          child: Card(
            elevation: 2,
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF2A2D3E) // Azul escuro para dark mode
                : const Color(0xFFE8F2FF), // Azul claro para light mode
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                              Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(isMobile ? 8 : 12),
                  decoration: BoxDecoration(
                    color: agency.isActive 
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.red.withValues(alpha: 0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: isMobile ? 16 : 20,
                      backgroundColor: agency.isActive 
                          ? Colors.green
                          : Colors.red,
                      child: Text(
                        agency.name.isNotEmpty ? agency.name[0].toUpperCase() : '?',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Inter',
                          fontSize: isMobile ? 14 : 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            agency.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: isMobile ? 14 : 16,
                              fontFamily: 'Inter',
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            agency.isActive ? 'Ativa' : 'Inativa',
                            style: TextStyle(
                              color: agency.isActive 
                                  ? Colors.green.shade700
                                  : Colors.red.shade700,
                              fontSize: isMobile ? 12 : 14,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        switch (value) {
                          case 'edit':
                            _showEditAgencyDialog(agency);
                            break;
                          case 'delete':
                            _showDeleteConfirmation(agency);
                            break;
                          case 'toggle':
                            ref.read(agencyProvider.notifier).toggleAgencyStatus(agency.id);
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, color: Theme.of(context).colorScheme.onSurface),
                              const SizedBox(width: 8),
                              Text('Editar', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'toggle',
                          child: Row(
                            children: [
                              Icon(
                                agency.isActive ? Icons.block : Icons.check_circle,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                agency.isActive ? 'Desativar' : 'Ativar',
                                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
                              const SizedBox(width: 8),
                              Text('Excluir', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(isMobile ? 8 : 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (agency.email != null && agency.email!.isNotEmpty)
                        _buildInfoRow(Icons.email, agency.email!),
                      if (agency.phone != null && agency.phone!.isNotEmpty)
                        _buildInfoRow(Icons.phone, agency.phone!),
                      if (agency.cityName != null && agency.cityName!.isNotEmpty)
                        _buildInfoRow(Icons.location_city, agency.cityName!),
                      if (agency.commissionRate != null)
                        _buildInfoRow(Icons.percent, '${agency.commissionRate}%'),
                      if (agency.contactPerson != null && agency.contactPerson!.isNotEmpty)
                        _buildInfoRow(Icons.person, agency.contactPerson!),
                    ],
                  ),
                ),
              ),
            ],
          ),
          ),
        );
      },
    );
  }

  Widget _buildAgenciesList(List<Agency> agencies) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;
    return ListView.builder(
      padding: EdgeInsets.all(isMobile ? 8.0 : 16.0),
      itemCount: agencies.length,
      itemBuilder: (context, index) {
        final agency = agencies[index];

        return Card(
          key: ValueKey(agency.id),
          margin: const EdgeInsets.only(bottom: 16.0),
          elevation: 2,
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF2A2D3E) // Azul escuro para dark mode
              : const Color(0xFFE8F2FF), // Azul claro para light mode
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            onTap: () {
              showDialog(
                context: context,
                barrierDismissible: true,
                builder: (_) => AlertDialog(
                  contentPadding: EdgeInsets.zero,
                  content: SizedBox(
                    width: isMobile ? 360 : 1000,
                    height: isMobile ? 600 : 700,
                    child: AgencyDetailsScreen(agency: agency),
                  ),
                ),
              );
            },
            leading: CircleAvatar(
              radius: isMobile ? 18 : 20,
              backgroundColor: agency.isActive 
                  ? Colors.green
                  : Colors.red,
              child: Text(
                agency.name.isNotEmpty ? agency.name[0].toUpperCase() : '?',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: isMobile ? 14 : 16,
                ),
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    agency.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: isMobile ? 14 : 16,
                      fontFamily: 'Inter',
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 6 : 8, vertical: isMobile ? 2 : 4),
                  decoration: BoxDecoration(
                    color: agency.isActive 
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: agency.isActive 
                          ? Colors.green.withValues(alpha: 0.3)
                          : Colors.red.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    agency.isActive ? 'Ativa' : 'Inativa',
                    style: TextStyle(
                      color: agency.isActive 
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                      fontSize: isMobile ? 12 : 14,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (agency.email != null && agency.email!.isNotEmpty)
                    Text('Email: ${_formatEmail(agency.email!)}', style: TextStyle(color: Colors.orange[700], fontSize: isMobile ? 12 : 14, fontFamily: 'Inter')),
                  if (agency.phone != null && agency.phone!.isNotEmpty)
                    Row(
                      children: [
                        if (_getCountryCodeFromPhone(agency.phone!) != null)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Image.network(
                              FlagUtils.getFlagUrl(_getCountryCodeFromPhone(agency.phone!)!, width: isMobile ? 20 : 24, height: isMobile ? 15 : 18),
                              width: isMobile ? 20 : 24,
                              height: isMobile ? 15 : 18,
                              errorBuilder: (context, error, stackTrace) => SizedBox(width: isMobile ? 20 : 24, height: isMobile ? 15 : 18),
                            ),
                          ),
                        Expanded(
                          child: Text('Telefone: ${_formatPhone(agency.phone!)}', style: TextStyle(color: Colors.orange[700], fontSize: isMobile ? 12 : 14, fontFamily: 'Inter')),
                        ),
                      ],
                    ),
                  if (agency.fullAddress.isNotEmpty)
                    Text('Endereço: ${agency.fullAddress}', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: isMobile ? 12 : 14, fontFamily: 'Inter'), maxLines: 2, overflow: TextOverflow.ellipsis),
                  if (agency.website != null && agency.website!.isNotEmpty)
                    Text('Website: ${agency.website!}', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: isMobile ? 12 : 14, fontFamily: 'Inter'), maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (agency.contactPerson != null && agency.contactPerson!.isNotEmpty)
                    Text('Contato: ${agency.contactPerson!}', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: isMobile ? 12 : 14, fontFamily: 'Inter'), maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (agency.commissionRate != null)
                    Text('Comissão: ${agency.commissionRate}%', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: isMobile ? 12 : 14, fontFamily: 'Inter')),
                ],
              ),
            ),
            trailing: isMobile 
              ? PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _showEditAgencyDialog(agency);
                        break;
                      case 'toggle':
                        ref.read(agencyProvider.notifier).toggleAgencyStatus(agency.id);
                        break;
                      case 'delete':
                        _showDeleteConfirmation(agency);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, color: Theme.of(context).colorScheme.onSurface),
                          const SizedBox(width: 8),
                          Text('Editar', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'toggle',
                      child: Row(
                        children: [
                          Icon(
                            agency.isActive ? Icons.block : Icons.check_circle,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            agency.isActive ? 'Desativar' : 'Ativar',
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
                          const SizedBox(width: 8),
                          Text('Excluir', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                        ],
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, color: Theme.of(context).colorScheme.onSurface),
                      onPressed: () => _showEditAgencyDialog(agency),
                      tooltip: 'Editar agência',
                    ),
                    IconButton(
                      icon: Icon(
                        agency.isActive ? Icons.block : Icons.check_circle,
                        color: agency.isActive 
                            ? Theme.of(context).colorScheme.error
                            : Theme.of(context).colorScheme.primary,
                      ),
                      onPressed: () => ref.read(agencyProvider.notifier).toggleAgencyStatus(agency.id),
                      tooltip: agency.isActive ? 'Desativar agência' : 'Ativar agência',
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
                      onPressed: () => _showDeleteConfirmation(agency),
                      tooltip: 'Excluir agência',
                    ),
                  ],
                ),
            isThreeLine: true,
          ),
        );
      },
    );
  }

  // Função auxiliar para criar decoração moderna dos campos de formulário
  InputDecoration _buildModernInputDecoration(String labelText, {String? hintText, String? suffixText}) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      suffixText: suffixText,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
      ),
      filled: true,
      fillColor: Theme.of(context).colorScheme.surface,
      labelStyle: TextStyle(color: Theme.of(context).colorScheme.primary),
      hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7)),
    );
  }

  // Função para formatar telefone
  String _formatPhone(String phone) {
    print('Formatando telefone: $phone'); // Debug
    final digits = phone.replaceAll(RegExp(r'[^\d+]'), '');
    print('Dígitos extraídos: $digits'); // Debug
    

    
    // Verificar números americanos primeiro (para evitar conflito com números brasileiros)
    if (digits.startsWith('+1') && digits.length == 12) {
      // EUA: +1 (555) 123-4567 (10 dígitos após o +1)
      final formatted = '+1 (${digits.substring(2, 5)}) ${digits.substring(5, 8)}-${digits.substring(8)}';
      print('EUA: $formatted'); // Debug
      return formatted;
         } else if (digits.startsWith('1') && digits.length == 11) {
       // EUA sem o +: 1 (555) 123-4567 (10 dígitos após o 1)
       final formatted = '1 (${digits.substring(1, 4)}) ${digits.substring(4, 7)}-${digits.substring(7)}';
       print('EUA sem +: $formatted'); // Debug
       return formatted;
     }
    
    if (digits.startsWith('+55')) {
      // Brasil com +: +55 (11) 99999-9999 ou +55 (11) 9999-9999
      if (digits.length == 13) {
        final formatted = '+55 (${digits.substring(3, 5)}) ${digits.substring(5, 10)}-${digits.substring(10)}';
        print('Brasil +55 13 dígitos: $formatted'); // Debug
        return formatted;
      } else if (digits.length == 12) {
        final formatted = '+55 (${digits.substring(3, 5)}) ${digits.substring(5, 9)}-${digits.substring(9)}';
        print('Brasil +55 12 dígitos: $formatted'); // Debug
        return formatted;
      }
    } else if (digits.startsWith('55') && digits.length == 13) {
      // Brasil sem +: 55 (11) 99999-9999
      final formatted = '+55 (${digits.substring(2, 4)}) ${digits.substring(4, 9)}-${digits.substring(9)}';
      print('Brasil 55 13 dígitos: $formatted'); // Debug
      return formatted;
    } else if (digits.startsWith('55') && digits.length == 12) {
      // Brasil sem +: 55 (11) 9999-9999
      final formatted = '+55 (${digits.substring(2, 4)}) ${digits.substring(4, 8)}-${digits.substring(8)}';
      print('Brasil 55 12 dígitos: $formatted'); // Debug
      return formatted;
    } else if (digits.length == 11) {
      // Brasil sem DDI: (11) 99999-9999
      final formatted = '(${digits.substring(0, 2)}) ${digits.substring(2, 7)}-${digits.substring(7)}';
      print('Brasil 11 dígitos sem DDI: $formatted'); // Debug
      return formatted;
    } else if (digits.length == 10) {
      // Brasil sem DDI: (11) 9999-9999
      final formatted = '(${digits.substring(0, 2)}) ${digits.substring(2, 6)}-${digits.substring(6)}';
      print('Brasil 10 dígitos sem DDI: $formatted'); // Debug
      return formatted;
    }
    // Para outros casos, retorna o número original
    print('Formato não reconhecido, retornando original: $phone'); // Debug
    return phone;
  }

  // Função para extrair o código ISO do país a partir do DDI do telefone
  String? _getCountryCodeFromPhone(String phone) {
    return FlagUtils.getCountryIsoCodeFromPhone(phone);
  }

  // Função para formatar email (deixa como está, mas pode adicionar validação visual)
  String _formatEmail(String email) {
    // Email já está formatado, apenas retorna
    return email.toLowerCase();
  }

  Widget _buildInfoRow(IconData icon, String text) {
    // Determinar se é email ou telefone para aplicar cor laranja e formatação
    final bool isEmailOrPhone = icon == Icons.email || icon == Icons.phone;
    
    // Aplicar formatação
    String formattedText = text;
    if (icon == Icons.phone) {
      formattedText = _formatPhone(text);
    } else if (icon == Icons.email) {
      formattedText = _formatEmail(text);
    }
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              formattedText,
              style: TextStyle(
                fontSize: 14,
                fontFamily: 'Inter',
                color: isEmailOrPhone 
                    ? Colors.orange[700] // Cor laranja para email e telefone
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
} 

// Dialog de teste com dropdowns reais
class _DialogDropdownsTeste extends StatefulWidget {
  @override
  State<_DialogDropdownsTeste> createState() => _DialogDropdownsTesteState();
}

class _DialogDropdownsTesteState extends State<_DialogDropdownsTeste> {
  bool loading = true;
  List<Department> departments = [];
  List<Position> positions = [];
  Department? selectedDepartment;
  Position? selectedPosition;

  @override
  void initState() {
    super.initState();
    _fetchDropdowns();
  }

  Future<void> _fetchDropdowns() async {
    setState(() => loading = true);
    try {
      final supabase = Supabase.instance.client;
      final deptRaw = await supabase.from('department').select('id, name, description, is_active, created_at, updated_at').order('name');
      final posRaw = await supabase.from('position').select('id, name, description, category, hierarchy_level, is_active, created_at, updated_at').order('name');
      departments = (deptRaw as List).map((json) => Department.fromJson(json)).toList();
      positions = (posRaw as List).map((json) => Position.fromJson(json)).toList();
      selectedDepartment = departments.isNotEmpty ? departments.first : null;
      selectedPosition = positions.isNotEmpty ? positions.first : null;
    } catch (e) {
      // ignore
    }
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Dialog de Teste com Dropdowns'),
      content: loading
          ? const SizedBox(height: 120, child: Center(child: CircularProgressIndicator()))
          : SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<Department>(
                    value: departments.contains(selectedDepartment) ? selectedDepartment : null,
                    decoration: const InputDecoration(labelText: 'Departamento'),
                    items: departments.map((d) => DropdownMenuItem(
                      value: d,
                      child: Text(d.name),
                    )).toList(),
                    onChanged: (v) => setState(() => selectedDepartment = v),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<Position>(
                    value: positions.contains(selectedPosition) ? selectedPosition : null,
                    decoration: const InputDecoration(labelText: 'Cargo'),
                    items: positions.map((p) => DropdownMenuItem(
                      value: p,
                      child: Text(p.name),
                    )).toList(),
                    onChanged: (v) => setState(() => selectedPosition = v),
                  ),
                ],
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fechar'),
        ),
      ],
    );
  }
}
