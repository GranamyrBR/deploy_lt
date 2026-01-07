import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/sale.dart';
import '../providers/sales_provider.dart';
import '../widgets/exchange_rate_display.dart';
import '../widgets/base_screen_layout.dart';
import '../widgets/standard_search_bar.dart';
import '../utils/smart_search_mixin.dart';


class PendingSalesScreen extends ConsumerStatefulWidget {
  const PendingSalesScreen({super.key});

  @override
  ConsumerState<PendingSalesScreen> createState() => _PendingSalesScreenState();
}

class _PendingSalesScreenState extends ConsumerState<PendingSalesScreen> with SmartSearchMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = '';
  String _selectedFilter = 'all'; // all, pending, partial, overdue

  @override
  void initState() {
    super.initState();
    // Carregar vendas pendentes ao inicializar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(salesProvider.notifier).fetchPendingSales();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sales = ref.watch(salesProvider);
    final filteredSales = _getFilteredSales(sales);

    return BaseScreenLayout(
      title: 'Vendas Pendentes',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () {
            ref.read(salesProvider.notifier).fetchPendingSales();
          },
          tooltip: 'Atualizar',
        ),
      ],
      searchBar: StandardSearchBar(
        controller: _searchController,
        hintText: 'Buscar por cliente, ID da venda, telefone...',
        onChanged: (value) {
          setState(() {
            _searchTerm = value.trim().toLowerCase();
          });
        },
        onClear: () {
          setState(() {
            _searchTerm = '';
          });
        },
      ),
      child: Column(
        children: [
          // Filtros
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('all', 'Todas', Icons.list),
                  const SizedBox(width: 8),
                  _buildFilterChip('pending', 'Pendentes', Icons.pending),
                  const SizedBox(width: 8),
                  _buildFilterChip('partial', 'Parciais', Icons.payment),
                  const SizedBox(width: 8),
                  _buildFilterChip('overdue', 'Vencidas', Icons.warning),
                ],
              ),
            ),
          ),
          // Cotações de Câmbio
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cotações de Câmbio',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const ExchangeRateDisplay(),
                ],
              ),
            ),
          ),
          
          // Lista de vendas
          Expanded(
            child: filteredSales.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredSales.length,
                    itemBuilder: (context, index) {
                      final sale = filteredSales[index];
                      return _buildSaleCard(sale);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, IconData icon) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isSelected
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).colorScheme.onSurface,
          ),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
      },
      backgroundColor: Theme.of(context).colorScheme.surface,
      selectedColor: Theme.of(context).colorScheme.primary,
      checkmarkColor: Theme.of(context).colorScheme.onPrimary,
      side: BorderSide(
        color: Theme.of(context).colorScheme.outline,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.pending_actions_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhuma venda pendente encontrada',
            style: TextStyle(
              fontSize: 18,
              color: Theme.of(context).colorScheme.outline,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tente ajustar os filtros ou buscar por outros termos',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaleCard(Sale sale) {
    final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header com ID e status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '#${sale.id}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildStatusChip(sale),
                  ],
                ),
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  onSelected: (value) => _handleMenuAction(value, sale),
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
                      value: 'payment',
                      child: Row(
                        children: [
                          Icon(Icons.payment, size: 16),
                          SizedBox(width: 8),
                          Text('Registrar Pagamento'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Informações do cliente
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text(
                    sale.contactName.isNotEmpty
                        ? sale.contactName[0].toUpperCase()
                        : 'C',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sale.contactName.isNotEmpty
                            ? sale.contactName
                            : 'Cliente não informado',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (sale.contactPhone != null && sale.contactPhone!.isNotEmpty)
                        Text(
                          sale.contactPhone!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Informações de valor
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Valor Total',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'USD \$${sale.totalAmountUsd.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        Text(
                          '≈${currencyFormat.format(sale.totalAmountBrl)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Pago',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currencyFormat.format(sale.totalPaidBrl),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: sale.totalPaidUsd > 0 ? Colors.blue : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Restante',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'USD \$${sale.remainingAmountUsd.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: sale.remainingAmount > 0 ? Colors.orange : Colors.green,
                          ),
                        ),
                        Text(
                          '≈${currencyFormat.format(sale.remainingAmountBrl)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Informações adicionais
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vendedor',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    Text(
                      sale.sellerName ?? sale.userName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Data',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    Text(
                      _formatDateTime(sale.createdAt),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (sale.dueDate != null) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Vencimento',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  Text(
                    _formatDate(sale.dueDate!),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: sale.isOverdue ? Colors.red : null,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(Sale sale) {
    Color color;
    String label;
    IconData icon;

    if (sale.isPaid) {
      color = Colors.green;
      label = 'Pago';
      icon = Icons.check_circle;
    } else if (sale.isPartiallyPaid) {
      color = Colors.orange;
      label = 'Parcial';
      icon = Icons.payment;
    } else {
      color = Colors.red;
      label = 'Pendente';
      icon = Icons.pending;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  List<Sale> _getFilteredSales(List<Sale> sales) {
    List<Sale> filtered = sales;

    // Aplicar filtro de status
    switch (_selectedFilter) {
      case 'pending':
        filtered = filtered.where((sale) => !sale.isPaid && !sale.isPartiallyPaid).toList();
        break;
      case 'partial':
        filtered = filtered.where((sale) => sale.isPartiallyPaid).toList();
        break;
      case 'overdue':
        filtered = filtered.where((sale) => sale.isOverdue).toList();
        break;
      case 'all':
      default:
        // Não filtrar por status
        break;
    }

    // Aplicar busca inteligente
    if (_searchTerm.isNotEmpty) {
      filtered = filtered.where((sale) {
        // Converter Sale para Map para usar o mixin
        final saleMap = {
          'id': sale.id,
          'contactName': sale.contactName,
          'contactPhone': sale.contactPhone,
          'sellerName': sale.sellerName,
          'userName': sale.userName,
        };
        
        return smartSearch(
          saleMap, 
          _searchTerm,
          nameField: 'contactName',
          phoneField: 'contactPhone',
          additionalFields: 'sellerName',
        );
      }).toList();
    }

    return filtered;
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatDateTime(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _handleMenuAction(String action, Sale sale) {
    switch (action) {
      case 'view':
        _viewSale(sale);
        break;
      case 'edit':
        _editSale(sale);
        break;
      case 'payment':
        _registerPayment(sale);
        break;
    }
  }

  void _viewSale(Sale sale) {
    // TODO: Implementar visualização detalhada da venda
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Visualizando venda #${sale.id}'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  void _editSale(Sale sale) {
    // TODO: Implementar edição da venda
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Editando venda #${sale.id}'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  void _registerPayment(Sale sale) {
    // TODO: Implementar registro de pagamento
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Registrando pagamento para venda #${sale.id}'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
