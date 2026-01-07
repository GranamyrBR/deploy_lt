import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/service_category.dart';
import '../widgets/base_app_bar.dart';
import '../design/design_tokens.dart';
import '../utils/responsive_utils.dart';
import '../providers/auth_provider.dart';

class ServicesAndProductsScreen extends ConsumerStatefulWidget {
  const ServicesAndProductsScreen({super.key});

  @override
  ConsumerState<ServicesAndProductsScreen> createState() => _ServicesAndProductsScreenState();
}

class _ServicesAndProductsScreenState extends ConsumerState<ServicesAndProductsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<ServiceCategory> _serviceCategories = ServiceCategory.predefinedCategories;
  List<Map<String, dynamic>> _products = [];
  
  // Controllers para formulários
  final _serviceCategoryFormKey = GlobalKey<FormState>();
  final _productFormKey = GlobalKey<FormState>();
  final _serviceNameController = TextEditingController();
  final _serviceDescriptionController = TextEditingController();
  final _serviceColorController = TextEditingController();
  final _serviceIconController = TextEditingController();
  final _productNameController = TextEditingController();
  final _productDescriptionController = TextEditingController();
  final _productPriceController = TextEditingController();
  final _productCategoryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMockProducts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _serviceNameController.dispose();
    _serviceDescriptionController.dispose();
    _serviceColorController.dispose();
    _serviceIconController.dispose();
    _productNameController.dispose();
    _productDescriptionController.dispose();
    _productPriceController.dispose();
    _productCategoryController.dispose();
    super.dispose();
  }

  void _loadMockProducts() {
    _products = [
      {
        'id': '1',
        'name': 'Transfer Aeroporto',
        'description': 'Serviço de transfer do aeroporto para hotel',
        'price': 50.0,
        'category': 'Transporte',
        'isActive': true,
      },
      {
        'id': '2',
        'name': 'City Tour',
        'description': 'Tour pela cidade com guia especializado',
        'price': 120.0,
        'category': 'Turismo',
        'isActive': true,
      },
      {
        'id': '3',
        'name': 'Seguro Viagem',
        'description': 'Cobertura completa para viagens internacionais',
        'price': 25.0,
        'category': 'Seguro',
        'isActive': true,
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);
    final userName = authState.user?.name ?? 'Usuário';

    return Scaffold(
      appBar: BaseAppBar(
        title: 'Gerenciamento de Serviços e Produtos',
        showBackButton: false,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                const Icon(Icons.person, size: 18),
                const SizedBox(width: 6),
                Text(
                  userName,
                  style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Tab Bar
          Container(
            color: theme.colorScheme.surface,
            child: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(
                  icon: Icon(Icons.room_service),
                  text: 'Categorias de Serviços',
                ),
                Tab(
                  icon: Icon(Icons.inventory),
                  text: 'Produtos',
                ),
              ],
            ),
          ),
          // Tab Bar View
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildServiceCategoriesTab(isMobile, theme),
                _buildProductsTab(isMobile, theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCategoriesTab(bool isMobile, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Header com botão de adicionar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Categorias de Serviços',
                style: theme.textTheme.headlineSmall,
              ),
              ElevatedButton.icon(
                onPressed: () => _showServiceCategoryDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Nova Categoria'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Lista de categorias
          Expanded(
            child: ListView.builder(
              itemCount: _serviceCategories.length,
              itemBuilder: (context, index) {
                final category = _serviceCategories[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Color(int.parse((category.color ?? '#2196F3').replaceFirst('#', '0xFF'))),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getIconData(category.icon ?? 'room_service'),
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    title: Text(category.name),
                    subtitle: Text(category.description ?? ''),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Switch(
                          value: category.isActive,
                          onChanged: (value) {
                            setState(() {
                              _serviceCategories[index] = category.copyWith(isActive: value);
                            });
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _showServiceCategoryDialog(category: category, index: index),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _deleteServiceCategory(index),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsTab(bool isMobile, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Header com botão de adicionar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Produtos',
                style: theme.textTheme.headlineSmall,
              ),
              ElevatedButton.icon(
                onPressed: () => _showProductDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Novo Produto'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Lista de produtos
          Expanded(
            child: ListView.builder(
              itemCount: _products.length,
              itemBuilder: (context, index) {
                final product = _products[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.primary,
                      child: Text(
                        product['name'][0],
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(product['name']),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(product['description']),
                        Text(
                          'Categoria: ${product['category']} • Preço: R\$ ${product['price'].toStringAsFixed(2)}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Switch(
                          value: product['isActive'],
                          onChanged: (value) {
                            setState(() {
                              _products[index]['isActive'] = value;
                            });
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _showProductDialog(product: product, index: index),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _deleteProduct(index),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showServiceCategoryDialog({ServiceCategory? category, int? index}) {
    if (category != null) {
      _serviceNameController.text = category.name;
      _serviceDescriptionController.text = category.description ?? '';
      _serviceColorController.text = category.color ?? '#2196F3';
      _serviceIconController.text = category.icon ?? 'room_service';
    } else {
      _serviceNameController.clear();
      _serviceDescriptionController.clear();
      _serviceColorController.text = '#2196F3';
      _serviceIconController.text = 'room_service';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(category == null ? 'Nova Categoria de Serviço' : 'Editar Categoria'),
        content: Form(
          key: _serviceCategoryFormKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _serviceNameController,
                decoration: const InputDecoration(labelText: 'Nome'),
                validator: (value) => value?.isEmpty == true ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _serviceDescriptionController,
                decoration: const InputDecoration(labelText: 'Descrição'),
                maxLines: 3,
                validator: (value) => value?.isEmpty == true ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _serviceColorController,
                decoration: const InputDecoration(
                  labelText: 'Cor (hex)',
                  hintText: '#2196F3',
                ),
                validator: (value) => value?.isEmpty == true ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _serviceIconController,
                decoration: const InputDecoration(
                  labelText: 'Ícone',
                  hintText: 'room_service',
                ),
                validator: (value) => value?.isEmpty == true ? 'Campo obrigatório' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => _saveServiceCategory(category, index),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void _showProductDialog({Map<String, dynamic>? product, int? index}) {
    if (product != null) {
      _productNameController.text = product['name'];
      _productDescriptionController.text = product['description'];
      _productPriceController.text = product['price'].toString();
      _productCategoryController.text = product['category'];
    } else {
      _productNameController.clear();
      _productDescriptionController.clear();
      _productPriceController.clear();
      _productCategoryController.clear();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(product == null ? 'Novo Produto' : 'Editar Produto'),
        content: Form(
          key: _productFormKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _productNameController,
                decoration: const InputDecoration(labelText: 'Nome'),
                validator: (value) => value?.isEmpty == true ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _productDescriptionController,
                decoration: const InputDecoration(labelText: 'Descrição'),
                maxLines: 3,
                validator: (value) => value?.isEmpty == true ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _productPriceController,
                decoration: const InputDecoration(labelText: 'Preço'),
                keyboardType: TextInputType.number,
                validator: (value) => value?.isEmpty == true ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _productCategoryController,
                decoration: const InputDecoration(labelText: 'Categoria'),
                validator: (value) => value?.isEmpty == true ? 'Campo obrigatório' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => _saveProduct(product, index),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void _saveServiceCategory(ServiceCategory? existingCategory, int? index) {
    if (_serviceCategoryFormKey.currentState?.validate() == true) {
      final newCategory = ServiceCategory(
        id: existingCategory?.id ?? DateTime.now().millisecondsSinceEpoch,
        name: _serviceNameController.text,
        description: _serviceDescriptionController.text,
        color: _serviceColorController.text,
        icon: _serviceIconController.text,
        isActive: existingCategory?.isActive ?? true,
        createdAt: existingCategory?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      setState(() {
        if (index != null) {
          _serviceCategories[index] = newCategory;
        } else {
          _serviceCategories.add(newCategory);
        }
      });

      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(index != null ? 'Categoria atualizada!' : 'Categoria criada!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _saveProduct(Map<String, dynamic>? existingProduct, int? index) {
    if (_productFormKey.currentState?.validate() == true) {
      final newProduct = {
        'id': existingProduct?['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        'name': _productNameController.text,
        'description': _productDescriptionController.text,
        'price': double.tryParse(_productPriceController.text) ?? 0.0,
        'category': _productCategoryController.text,
        'isActive': existingProduct?['isActive'] ?? true,
      };

      setState(() {
        if (index != null) {
          _products[index] = newProduct;
        } else {
          _products.add(newProduct);
        }
      });

      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(index != null ? 'Produto atualizado!' : 'Produto criado!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _deleteServiceCategory(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: const Text('Tem certeza que deseja excluir esta categoria?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _serviceCategories.removeAt(index);
              });
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Categoria excluída!'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  void _deleteProduct(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: const Text('Tem certeza que deseja excluir este produto?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _products.removeAt(index);
              });
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Produto excluído!'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'room_service':
        return Icons.room_service;
      case 'flight':
        return Icons.flight;
      case 'directions_car':
        return Icons.directions_car;
      case 'hotel':
        return Icons.hotel;
      case 'restaurant':
        return Icons.restaurant;
      case 'local_activity':
        return Icons.local_activity;
      case 'security':
        return Icons.security;
      case 'business':
        return Icons.business;
      case 'support_agent':
        return Icons.support_agent;
      case 'tour':
        return Icons.tour;
      default:
        return Icons.room_service;
    }
  }
}
