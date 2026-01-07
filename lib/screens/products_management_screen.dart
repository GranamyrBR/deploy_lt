import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/product_categories_provider.dart';
import '../providers/products_provider.dart';
import '../models/product_category.dart';
import '../models/product.dart';
import '../widgets/base_screen_layout.dart';

class ProductsManagementScreen extends ConsumerStatefulWidget {
  const ProductsManagementScreen({super.key});

  @override
  ConsumerState<ProductsManagementScreen> createState() => _ProductsManagementScreenState();
}

class _ProductsManagementScreenState extends ConsumerState<ProductsManagementScreen> {
  final _searchController = TextEditingController();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  
  // Categoria selecionada
  int? _selectedCategoryId;
  
  List<Product> _filteredProducts = [];
  Product? _selectedProduct;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      // A filtragem será feita no Consumer
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }



  void _showProductDialog([Product? product]) {
    _isEditing = product != null;
    if (_isEditing) {
      _nameController.text = product!.name;
      _descriptionController.text = product.description ?? '';
      _priceController.text = product.pricePerUnit.toString();
      _stockController.text = '0'; // Campo stock não existe no modelo real
      _selectedCategoryId = product.categoryId;
      _selectedProduct = product;
    } else {
      _nameController.clear();
      _descriptionController.clear();
      _priceController.clear();
      _stockController.clear();
      _selectedCategoryId = null;
      _selectedProduct = null;
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
          _isEditing ? 'Editar Produto' : 'Adicionar Novo Produto',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        content: SizedBox(
          width: 600,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome do Produto *',
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
                    labelText: 'Descrição',
                    border: OutlineInputBorder(),
                    filled: true,
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
              Consumer(
                builder: (context, ref, child) {
                  final productCategoriesAsync = ref.watch(productCategoriesProvider);
                  return productCategoriesAsync.when(
                    data: (categories) => DropdownButtonFormField<int>(
                      value: _selectedCategoryId,
                      decoration: const InputDecoration(
                        labelText: 'Categoria',
                        border: OutlineInputBorder(),
                      ),
                      items: categories.map((category) {
                        return DropdownMenuItem<int>(
                          value: category.categoryId,
                          child: Text(category.name),
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
                    loading: () => const LinearProgressIndicator(),
                    error: (error, stack) => Text('Erro ao carregar categorias: $error'),
                  );
                },
              ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(
                    labelText: 'Preço (USD) *',
                    border: OutlineInputBorder(),
                    filled: true,
                    prefixText: 'U\$ ',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Preço é obrigatório';
                    }
                    final price = double.tryParse(value);
                    if (price == null || price <= 0) {
                      return 'Preço deve ser maior que zero';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: _saveProduct,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              _isEditing ? 'Atualizar' : 'Criar',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _saveProduct() {
    if (_nameController.text.isEmpty || _priceController.text.isEmpty || _selectedCategoryId == null) {
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

    // TODO: Implementar salvamento real no banco de dados
    // Por enquanto, apenas fechar o diálogo
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_isEditing ? 'Produto atualizado com sucesso!' : 'Produto criado com sucesso!')),
    );
    
    // Invalidar o provider para recarregar os dados
    ref.invalidate(productsProvider);
  }

  void _deleteProduct(Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text('Tem certeza que deseja excluir o produto "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implementar exclusão real no banco de dados
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Produto excluído com sucesso!')),
              );
              // Invalidar o provider para recarregar os dados
              ref.invalidate(productsProvider);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _toggleProductStatus(Product product) {
    // TODO: Implementar alteração de status real no banco de dados
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Status do produto "${product.name}" alterado!')),
    );
    // Invalidar o provider para recarregar os dados
    ref.invalidate(productsProvider);
  }



  @override
  Widget build(BuildContext context) {
    return BaseScreenLayout(
      title: 'Gerenciamento de Produtos',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'Atualizar Categorias',
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Atualizar Categorias'),
                content: const Text('Isso atualizará as categorias de todos os produtos com base nas categorias selecionadas. Deseja continuar?'),
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Atualizando categorias...')),
              );
              // Recarregar categorias e produtos
              ref.invalidate(productCategoriesProvider);
              ref.invalidate(productsProvider);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Categorias atualizadas com sucesso!')),
              );
            }
          },
        ),
        IconButton(
          icon: const Icon(Icons.add),
          tooltip: 'Adicionar Produto',
          onPressed: () => _showProductDialog(),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Produtos',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showProductDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('Novo Produto'),
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
            SizedBox(
              width: 400,
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  labelText: 'Buscar produtos...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Card(
                child: Column(
                  children: [
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
                    Expanded(
                      child: Consumer(
                        builder: (context, ref, child) {
                          final productsAsync = ref.watch(productsProvider);
                          return productsAsync.when(
                            data: (products) {
                              final query = _searchController.text.toLowerCase();
                              final filteredProducts = products.where((product) {
                                return product.name.toLowerCase().contains(query) ||
                                       (product.description?.toLowerCase().contains(query) ?? false);
                              }).toList();
                              filteredProducts.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
                              if (filteredProducts.isEmpty) {
                                return const Center(child: Text('Nenhum produto encontrado'));
                              }
                              return ListView.builder(
                                itemCount: filteredProducts.length,
                                itemBuilder: (context, index) {
                                  final product = filteredProducts[index];
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
                                            product.name,
                                            style: const TextStyle(fontWeight: FontWeight.w500),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 3,
                                          child: Text(
                                            product.description ?? 'Sem descrição',
                                            style: TextStyle(color: Colors.grey[600]),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Consumer(
                                            builder: (context, ref, child) {
                                              final productCategoriesAsync = ref.watch(productCategoriesProvider);
                                              return productCategoriesAsync.when(
                                                data: (categories) {
                                                  final category = categories.firstWhere(
                                                    (cat) => cat.categoryId == product.categoryId,
                                                    orElse: () => ProductCategory(categoryId: 0, name: 'N/A'),
                                                  );
                                                  return Text(
                                                    category.name,
                                                    style: TextStyle(color: Colors.grey[600]),
                                                  );
                                                },
                                                loading: () => const Text('...'),
                                                error: (error, stack) => const Text('Erro'),
                                              );
                                            },
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            'U\$${product.pricePerUnit.toStringAsFixed(2)}',
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
                                              color: product.activeForSale ? Colors.green[100] : Colors.red[100],
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              product.activeForSale ? 'Ativo' : 'Inativo',
                                              style: TextStyle(
                                                color: product.activeForSale ? Colors.green[800] : Colors.red[800],
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
                                                onPressed: () => _showProductDialog(product),
                                                icon: const Icon(Icons.edit, color: Colors.blue),
                                                tooltip: 'Editar',
                                              ),
                                              IconButton(
                                                onPressed: () => _toggleProductStatus(product),
                                                icon: Icon(
                                                  product.activeForSale ? Icons.visibility_off : Icons.visibility,
                                                  color: product.activeForSale ? Colors.orange : Colors.green,
                                                ),
                                                tooltip: product.activeForSale ? 'Desativar' : 'Ativar',
                                              ),
                                              IconButton(
                                                onPressed: () => _deleteProduct(product),
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
                              );
                            },
                            loading: () => const Center(child: CircularProgressIndicator()),
                            error: (error, stack) => Center(child: Text('Erro ao carregar produtos: $error')),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
