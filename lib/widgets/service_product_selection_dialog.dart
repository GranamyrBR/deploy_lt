import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/accessibility_provider.dart';
import '../models/service.dart' as db;
import '../models/product.dart' as dbp;
import '../providers/services_provider.dart';
import '../providers/products_provider.dart';

class ServiceProductSelectionDialog extends ConsumerStatefulWidget {
  final List<db.Service> selectedServices;
  final List<dbp.Product> selectedProducts;
  final Function(List<db.Service>, List<dbp.Product>) onSelectionChanged;

  const ServiceProductSelectionDialog({
    Key? key,
    this.selectedServices = const [],
    this.selectedProducts = const [],
    required this.onSelectionChanged,
  }) : super(key: key);

  @override
  ConsumerState<ServiceProductSelectionDialog> createState() =>
      _ServiceProductSelectionDialogState();
}

class _ServiceProductSelectionDialogState
    extends ConsumerState<ServiceProductSelectionDialog> {
  String _searchQuery = '';
  int _selectedTab = 0; // 0 for services, 1 for products
  List<db.Service> _tempSelectedServices = [];
  List<dbp.Product> _tempSelectedProducts = [];

  @override
  void initState() {
    super.initState();
    _tempSelectedServices = List.from(widget.selectedServices);
    _tempSelectedProducts = List.from(widget.selectedProducts);
  }

  @override
  Widget build(BuildContext context) {
    final isHighContrast = ref.watch(accessibilityProvider);
    return AlertDialog(
      title: const Text('Selecionar Serviços e Produtos'),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
          maxWidth: 700,
        ),
        child: SizedBox(
          width: double.maxFinite,
          child: Column(
            children: [
              // Search field
              TextField(
                decoration: InputDecoration(
                  hintText: 'Pesquisar...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Tabs
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Serviços'),
                      selected: _selectedTab == 0,
                      selectedColor: isHighContrast ? Colors.black : null,
                      labelStyle: TextStyle(
                          color: isHighContrast && _selectedTab == 0
                              ? Colors.white
                              : null),
                      onSelected: (selected) {
                        setState(() {
                          _selectedTab = 0;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Produtos'),
                      selected: _selectedTab == 1,
                      selectedColor: isHighContrast ? Colors.black : null,
                      labelStyle: TextStyle(
                          color: isHighContrast && _selectedTab == 1
                              ? Colors.white
                              : null),
                      onSelected: (selected) {
                        setState(() {
                          _selectedTab = 1;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Content based on selected tab
              Expanded(
                child: _selectedTab == 0
                    ? _buildServicesList()
                    : _buildProductsList(),
              ),

              // Summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest
                      .withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Serviços: ${_tempSelectedServices.length}'),
                    Text('Produtos: ${_tempSelectedProducts.length}'),
                    Text('Total: \$${_calculateTotal().toStringAsFixed(2)}'),
                  ],
                ),
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
          onPressed: () {
            widget.onSelectionChanged(
                _tempSelectedServices, _tempSelectedProducts);
            Navigator.of(context).pop();
          },
          child: const Text('Confirmar'),
        ),
      ],
    );
  }

  Widget _buildServicesList() {
    final services = ref.watch(activeServicesProvider);
    final isHighContrast = ref.watch(accessibilityProvider);
    final filtered = services
        .where((service) =>
            _searchQuery.isEmpty ||
            (service.name ?? '')
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            (service.description ?? '')
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()))
        .toList();

    if (filtered.isEmpty) {
      return const Center(child: Text('Nenhum serviço encontrado'));
    }

    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final service = filtered[index];
        final isSelected = _tempSelectedServices.any((s) => s.id == service.id);

        return Card(
          elevation: isSelected ? 4 : 1,
          color: isSelected
              ? (isHighContrast
                  ? Colors.black
                  : Theme.of(context).colorScheme.primaryContainer)
              : (isHighContrast ? Colors.black : null),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isHighContrast
                  ? Colors.black
                  : Theme.of(context).colorScheme.tertiary,
              child: Icon(
                Icons.construction,
                color: isHighContrast
                    ? Colors.white
                    : Theme.of(context).colorScheme.onTertiary,
              ),
            ),
            title: Text(service.name ?? 'Serviço',
                style: TextStyle(color: isHighContrast ? Colors.white : null)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if ((service.description ?? '').isNotEmpty)
                  Text(service.description!,
                      style: TextStyle(
                          color: isHighContrast ? Colors.white : null)),
                const SizedBox(height: 4),
                if ((service.category ?? '').isNotEmpty)
                  Chip(
                    label: Text(service.category!),
                    backgroundColor: isHighContrast
                        ? Colors.black
                        : Theme.of(context).colorScheme.secondaryContainer,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                const SizedBox(height: 4),
                Text(
                  service.price != null
                      ? 'Preço: \$${service.price!.toStringAsFixed(2)}'
                      : 'Preço: N/A',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isHighContrast ? Colors.white : null),
                ),
              ],
            ),
            trailing: isSelected
                ? Icon(
                    Icons.check_circle,
                    color: isHighContrast
                        ? Colors.white
                        : Theme.of(context).colorScheme.primary,
                  )
                : null,
            onTap: () {
              setState(() {
                if (isSelected) {
                  _tempSelectedServices.removeWhere((s) => s.id == service.id);
                } else {
                  _tempSelectedServices.add(service);
                }
              });
            },
          ),
        );
      },
    );
  }

  Widget _buildProductsList() {
    final productsAsync = ref.watch(productsProvider);
    final isHighContrast = ref.watch(accessibilityProvider);
    return productsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('Erro ao carregar produtos')),
      data: (data) {
        final products = data
            .where((product) =>
                _searchQuery.isEmpty ||
                product.name
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase()) ||
                (product.description ?? '')
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase()) ||
                (product.category ?? '')
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase()))
            .toList();

        if (products.isEmpty) {
          return const Center(child: Text('Nenhum produto encontrado'));
        }

        return ListView.builder(
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            final isSelected = _tempSelectedProducts
                .any((p) => p.productId == product.productId);

            return Card(
              elevation: isSelected ? 4 : 1,
              color: isSelected
                  ? (isHighContrast
                      ? Colors.black
                      : Theme.of(context).colorScheme.primaryContainer)
                  : (isHighContrast ? Colors.black : null),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isHighContrast
                      ? Colors.black
                      : Theme.of(context).colorScheme.tertiary,
                  child: Icon(
                    Icons.inventory,
                    color: isHighContrast
                        ? Colors.white
                        : Theme.of(context).colorScheme.onTertiary,
                  ),
                ),
                title: Text(product.name,
                    style:
                        TextStyle(color: isHighContrast ? Colors.white : null)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if ((product.description ?? '').isNotEmpty)
                      Text(product.description!,
                          style: TextStyle(
                              color: isHighContrast ? Colors.white : null)),
                    const SizedBox(height: 4),
                    if ((product.category ?? '').isNotEmpty)
                      Chip(
                        label: Text(product.category!),
                        backgroundColor: isHighContrast
                            ? Colors.black
                            : Theme.of(context).colorScheme.secondaryContainer,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    const SizedBox(height: 4),
                    Text(
                      'Preço: \$${product.pricePerUnit.toStringAsFixed(2)}',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isHighContrast ? Colors.white : null),
                    ),
                  ],
                ),
                trailing: isSelected
                    ? Icon(
                        Icons.check_circle,
                        color: isHighContrast
                            ? Colors.white
                            : Theme.of(context).colorScheme.primary,
                      )
                    : null,
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _tempSelectedProducts
                          .removeWhere((p) => p.productId == product.productId);
                    } else {
                      _tempSelectedProducts.add(product);
                    }
                  });
                },
              ),
            );
          },
        );
      },
    );
  }

  IconData _getServiceIcon() {
    return Icons.construction;
  }

  IconData _getProductIcon() {
    return Icons.inventory;
  }

  double _calculateTotal() {
    double total = 0;
    for (final service in _tempSelectedServices) {
      total += service.price ?? 0.0;
    }
    for (final product in _tempSelectedProducts) {
      total += product.pricePerUnit;
    }
    return total;
  }

  String _getProductCategoryDisplayName(String? category) {
    return category ?? '';
  }
}
