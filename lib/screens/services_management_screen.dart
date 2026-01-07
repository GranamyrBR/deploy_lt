import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/service.dart';
import '../models/service_category.dart';
import '../providers/services_provider.dart';
import '../providers/service_types_provider.dart';
import '../widgets/base_screen_layout.dart';

class ServicesManagementScreen extends ConsumerStatefulWidget {
  const ServicesManagementScreen({super.key});

  @override
  ConsumerState<ServicesManagementScreen> createState() => _ServicesManagementScreenState();
}

class _ServicesManagementScreenState extends ConsumerState<ServicesManagementScreen> {
  final _searchController = TextEditingController();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  Service? _selectedService;
  bool _isEditing = false;
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      ref.read(servicesProvider.notifier).searchServices(query);
    } else {
      ref.read(servicesProvider.notifier).loadServices();
    }
  }

  void _showServiceDialog([Service? service]) {
    if (service != null) {
      _nameController.text = service.name ?? '';
      _descriptionController.text = service.description ?? '';
      _priceController.text = service.price.toString();
      _selectedService = service;
      _selectedCategoryId = service.servicetypeId;
      _isEditing = true;
    } else {
      _clearForm();
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF2A2D3E)
            : const Color(0xFFE8F2FF),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          _isEditing ? 'Editar Serviço' : 'Novo Serviço',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        content: SizedBox(
          width: 600,
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nome do Serviço *',
                      border: OutlineInputBorder(),
                      filled: true,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Nome é obrigatório';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Descrição *',
                      border: OutlineInputBorder(),
                      filled: true,
                    ),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Descrição é obrigatória';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _priceController,
                    decoration: const InputDecoration(
                      labelText: 'Preço (USD) *',
                      border: OutlineInputBorder(),
                      prefixText: 'U\$ ',
                      filled: true,
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Preço é obrigatório';
                      }
                      final price = double.tryParse(value);
                      if (price == null || price <= 0) {
                        return 'Preço deve ser um número válido maior que zero';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Consumer(
                    builder: (context, ref, child) {
                      // Usando o provider otimizado para dropdown
                      final serviceTypesAsync = ref.watch(serviceTypeDropdownProvider);
                      return serviceTypesAsync.when(
                        data: (serviceTypes) => DropdownButtonFormField<int>(
                          value: _selectedCategoryId,
                          decoration: const InputDecoration(
                            labelText: 'Categoria',
                            border: OutlineInputBorder(),
                            filled: true,
                          ),
                          items: serviceTypes.map((category) {
                            return DropdownMenuItem<int>(
                               value: category.id,
                               child: Text(category.name ?? ''),
                             );
                          }).toList(),
                          onChanged: (value) {
                            _selectedCategoryId = value;
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Categoria é obrigatória';
                            }
                            return null;
                          },
                        ),
                        loading: () => const Center(child: SizedBox(height: 2, child: LinearProgressIndicator())),
                        error: (error, stack) => Text('Erro ao carregar categorias: $error'),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey,
            ),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: _saveService,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(_isEditing ? 'Atualizar' : 'Salvar'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveService() async {
    if (_nameController.text.isEmpty || _priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha todos os campos obrigatórios')),
      );
      return;
    }

    final price = double.tryParse(_priceController.text);
    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preço deve ser um número válido maior que zero')),
      );
      return;
    }

    bool success;
    if (_isEditing && _selectedService != null) {
      // Atualizar serviço existente
      success = await ref.read(servicesProvider.notifier).updateService(
        id: _selectedService!.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        price: price,
        servicetypeId: _selectedCategoryId ?? _selectedService!.servicetypeId,
      );
    } else {
      // Criar novo serviço
      success = await ref.read(servicesProvider.notifier).createService(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        price: price,
        servicetypeId: _selectedCategoryId ?? 1,
        isActive: true,
      );
    }

    if (success) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEditing ? 'Serviço atualizado com sucesso!' : 'Serviço criado com sucesso!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao salvar serviço')),
      );
    }
  }

  void _deleteService(Service service) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text('Tem certeza que deseja excluir o serviço "${service.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final success = await ref.read(servicesProvider.notifier).deleteService(service.id);
              Navigator.of(context).pop();
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Serviço excluído com sucesso!')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Erro ao excluir serviço')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleServiceStatus(Service service) async {
    final success = await ref.read(servicesProvider.notifier).updateService(
      id: service.id,
      name: service.name ?? '',
      description: service.description,
      price: service.price,
      servicetypeId: service.servicetypeId,
      isActive: !(service.isActive ?? true),
    );
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status do serviço ${(service.isActive ?? true) ? 'desativado' : 'ativado'} com sucesso!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao alterar status do serviço')),
      );
    }
  }

  void _clearForm() {
    _nameController.clear();
    _descriptionController.clear();
    _priceController.clear();
    _selectedService = null;
    _isEditing = false;
    _selectedCategoryId = null;
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorMessage(String message) {
    final servicesState = ref.read(servicesProvider);
    final errorMessage = servicesState.error ?? message;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errorMessage),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<bool> _showDeleteConfirmation() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: const Text('Tem certeza que deseja excluir este serviço?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final servicesState = ref.watch(servicesProvider);
    
    return BaseScreenLayout(
      title: 'Gerenciamento de Serviços',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'Atualizar Categorias',
          onPressed: () async {
            // Mostrar diálogo de confirmação
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Atualizar Categorias'),
                content: const Text('Isso atualizará as categorias de todos os serviços com base nos tipos de serviço selecionados. Deseja continuar?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancelar'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Atualizar'),
                  ),
                ],
              ),
            ) ?? false;
            
            if (confirm) {
              // Mostrar indicador de progresso
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Atualizando categorias...')),
              );
              
              // Recarregar serviços com categorias atualizadas
              await ref.read(servicesProvider.notifier).refreshWithReload();
              
              // Mostrar mensagem de sucesso
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Categorias atualizadas com sucesso!')),
              );
            }
          },
        ),
        IconButton(
          icon: const Icon(Icons.add),
          tooltip: 'Adicionar Serviço',
          onPressed: () => _showServiceDialog(),
        ),
      ],
      child: Consumer(
        builder: (context, ref, child) {
          final servicesState = ref.watch(servicesProvider);
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header com botão de adicionar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Serviços',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showServiceDialog(),
                    icon: const Icon(Icons.add),
                    label: const Text('Novo Serviço'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3498DB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            
              // Search Bar
              SizedBox(
                width: 400,
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    labelText: 'Buscar serviços...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            
              // Services List
              Expanded(
                child: Card(
                  child: Column(
                    children: [
                      // Header da tabela
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(8),
                            topRight: Radius.circular(8),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Expanded(flex: 3, child: Text('Nome', style: TextStyle(fontWeight: FontWeight.bold))),
                            Expanded(flex: 3, child: Text('Descrição', style: TextStyle(fontWeight: FontWeight.bold))),
                            Expanded(flex: 2, child: Text('Categoria', style: TextStyle(fontWeight: FontWeight.bold))),
                            Expanded(flex: 2, child: Text('Preço', style: TextStyle(fontWeight: FontWeight.bold))),
                            Expanded(flex: 1, child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                            Expanded(flex: 2, child: Text('Ações', style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                        ),
                      ),
                    
                      // Lista de serviços
                      Expanded(
                        child: servicesState.isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : servicesState.error != null
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Erro: ${servicesState.error}',
                                          style: const TextStyle(color: Colors.red),
                                        ),
                                        const SizedBox(height: 16),
                                        ElevatedButton(
                                          onPressed: () => ref.read(servicesProvider.notifier).refresh(),
                                          child: const Text('Tentar Novamente'),
                                        ),
                                      ],
                                    ),
                                  )
                                : servicesState.services.isEmpty
                                    ? const Center(
                                        child: Text('Nenhum serviço encontrado'),
                                      )
                                    : ListView.builder(
                                        itemCount: servicesState.services.length,
                                        itemBuilder: (context, index) {
                                          final service = servicesState.services[index];
                                          return Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              border: Border(
                                                bottom: BorderSide(color: Colors.grey[300]!),
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  flex: 3,
                                                  child: Text(
                                                    service.name ?? '',
                                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 3,
                                                  child: Text(
                                                    service.description ?? '',
                                                    style: TextStyle(color: Colors.grey[600]),
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 2,
                                                  child: Text(
                                                    service.category ?? 'Sem categoria',
                                                    style: TextStyle(color: Colors.grey[700]),
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 2,
                                                  child: Text(
                                                    'U\$ ${(service.price ?? 0.0).toStringAsFixed(2)}',
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.green,
                                                    ),
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 1,
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: (service.isActive ?? true) ? Colors.green[100] : Colors.red[100],
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    child: Text(
                                                      (service.isActive ?? true) ? 'Ativo' : 'Inativo',
                                                      style: TextStyle(
                                                        color: (service.isActive ?? true) ? Colors.green[800] : Colors.red[800],
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                      textAlign: TextAlign.center,
                                                    ),
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 2,
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      IconButton(
                                                        onPressed: () => _showServiceDialog(service),
                                                        icon: const Icon(Icons.edit, color: Colors.blue),
                                                        tooltip: 'Editar',
                                                      ),
                                                      IconButton(
                                                        onPressed: () => _toggleServiceStatus(service),
                                                        icon: Icon(
                                                          (service.isActive ?? true) ? Icons.visibility_off : Icons.visibility,
                                                          color: (service.isActive ?? true) ? Colors.orange : Colors.green,
                                                        ),
                                                        tooltip: (service.isActive ?? true) ? 'Desativar' : 'Ativar',
                                                      ),
                                                      IconButton(
                                                        onPressed: () => _deleteService(service),
                                                        icon: const Icon(Icons.delete, color: Colors.red),
                                                        tooltip: 'Excluir',
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
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
