import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/accessibility_provider.dart';
import '../models/service.dart' as db;
import '../models/product.dart' as dbp;
import '../models/lead_tintim.dart';
import '../providers/services_provider.dart';
import '../providers/products_provider.dart';

/// Dialog de seleção de serviços/produtos COM mensagens WhatsApp lado a lado
class ServiceProductSelectionWithWhatsAppDialog extends ConsumerStatefulWidget {
  final List<db.Service> selectedServices;
  final List<dbp.Product> selectedProducts;
  final List<LeadTintim> whatsappMessages;
  final void Function(List<db.Service>, List<dbp.Product>) onSelectionChanged;

  const ServiceProductSelectionWithWhatsAppDialog({
    super.key,
    this.selectedServices = const [],
    this.selectedProducts = const [],
    required this.whatsappMessages,
    required this.onSelectionChanged,
  });

  @override
  ConsumerState<ServiceProductSelectionWithWhatsAppDialog> createState() =>
      _ServiceProductSelectionWithWhatsAppDialogState();
}

class _ServiceProductSelectionWithWhatsAppDialogState
    extends ConsumerState<ServiceProductSelectionWithWhatsAppDialog> {
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
    final size = MediaQuery.of(context).size;
    final isHighContrast = ref.watch(accessibilityProvider);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: size.width * 0.9,
        height: size.height * 0.9,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: Row(
                children: [
                  // Painel WhatsApp (350px)
                  SizedBox(
                    width: 350,
                    child: _buildWhatsAppPanel(context),
                  ),
                  
                  // Divisor
                  Container(width: 2, color: Theme.of(context).dividerColor),
                  
                  // Seleção de Serviços/Produtos
                  Expanded(
                    child: _buildSelectionPanel(context, isHighContrast),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.shade400,
            Colors.blue.shade500,
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.shopping_bag, color: Colors.purple.shade400, size: 24),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Selecionar Serviços e Produtos',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded, color: Colors.white),
            tooltip: 'Fechar',
          ),
        ],
      ),
    );
  }

  Widget _buildWhatsAppPanel(BuildContext context) {
    return Container(
      color: Colors.grey.shade50,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF25D366).withValues(alpha: 0.1),
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                const Icon(Icons.chat, color: Color(0xFF25D366), size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Conversas',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF25D366),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${widget.whatsappMessages.length}',
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
          
          // Info card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700, size: 18),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Consulte as mensagens para selecionar os serviços corretos',
                    style: TextStyle(fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
          
          // Messages list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: widget.whatsappMessages.length,
              itemBuilder: (context, index) {
                final message = widget.whatsappMessages[index];
                final hasMessage = message.message != null && message.message!.isNotEmpty;
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: const Color(0xFF25D366),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: Text(
                                (message.name ?? '?').substring(0, 1).toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  message.name ?? 'Sem nome',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (message.datelast != null)
                                  Text(
                                    _formatDate(message.datelast!),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (hasMessage) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            message.message!,
                            style: const TextStyle(fontSize: 11, height: 1.4),
                            maxLines: 5,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
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

  Widget _buildSelectionPanel(BuildContext context, bool isHighContrast) {
    return Column(
      children: [
        // Search and tabs
        Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Search field
              TextField(
                decoration: InputDecoration(
                  hintText: 'Pesquisar serviços ou produtos...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
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
                    child: _buildTabChip(
                      'Serviços',
                      Icons.build,
                      0,
                      _tempSelectedServices.length,
                      isHighContrast,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTabChip(
                      'Produtos',
                      Icons.inventory_2,
                      1,
                      _tempSelectedProducts.length,
                      isHighContrast,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Content
        Expanded(
          child: _selectedTab == 0
              ? _buildServicesContent(isHighContrast)
              : _buildProductsContent(isHighContrast),
        ),

        // Footer with buttons
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            border: Border(top: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_tempSelectedServices.length} serviços, ${_tempSelectedProducts.length} produtos',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      widget.onSelectionChanged(
                        _tempSelectedServices,
                        _tempSelectedProducts,
                      );
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('Confirmar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabChip(String label, IconData icon, int index, int count, bool isHighContrast) {
    final isSelected = _selectedTab == index;
    return InkWell(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : Colors.grey.shade700,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Theme.of(context).colorScheme.primary : Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildServicesContent(bool isHighContrast) {
    final services = ref.watch(activeServicesProvider);
    
    final filteredServices = services
        .where((service) =>
            (service.name ?? '').toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (service.description ?? '').toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    if (filteredServices.isEmpty) {
      return const Center(child: Text('Nenhum serviço encontrado'));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: filteredServices.length,
      itemBuilder: (context, index) {
        final service = filteredServices[index];
        final isSelected = _tempSelectedServices.any((s) => s.id == service.id);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: CheckboxListTile(
            value: isSelected,
            onChanged: (selected) {
              setState(() {
                if (selected == true) {
                  _tempSelectedServices.add(service);
                } else {
                  _tempSelectedServices.removeWhere((s) => s.id == service.id);
                }
              });
            },
            title: Text(
              service.name ?? '',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (service.description != null)
                  Text(
                    service.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 4),
                Text(
                  'R\$ ${service.price?.toStringAsFixed(2) ?? "0.00"}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            secondary: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.build,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            controlAffinity: ListTileControlAffinity.trailing,
          ),
        );
      },
    );
  }

  Widget _buildProductsContent(bool isHighContrast) {
    final productsAsync = ref.watch(productsProvider);
    
    return productsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Erro: $error')),
      data: (data) {
        final filteredProducts = data
            .where((product) =>
                (product.name).toLowerCase().contains(_searchQuery.toLowerCase()) ||
                (product.description ?? '').toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

        if (filteredProducts.isEmpty) {
          return const Center(child: Text('Nenhum produto encontrado'));
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: filteredProducts.length,
          itemBuilder: (context, index) {
            final product = filteredProducts[index];
            final isSelected = _tempSelectedProducts.any((p) => p.productId == product.productId);

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: CheckboxListTile(
                value: isSelected,
                onChanged: (selected) {
                  setState(() {
                    if (selected == true) {
                      _tempSelectedProducts.add(product);
                    } else {
                      _tempSelectedProducts.removeWhere((p) => p.productId == product.productId);
                    }
                  });
                },
                title: Text(
                  product.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (product.description != null)
                      Text(
                        product.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 4),
                    Text(
                      'R\$ ${product.price?.toStringAsFixed(2) ?? '0.00'}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                secondary: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.inventory_2,
                    color: Colors.orange.shade700,
                  ),
                ),
                controlAffinity: ListTileControlAffinity.trailing,
              ),
            );
          },
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

