import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/sale.dart';
import '../models/contact_service.dart';
import '../models/provisional_invoice.dart';
import '../providers/sales_provider.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/exchange_rate_display.dart';
import 'create_sale_screen_v2.dart';
import 'pending_sales_screen.dart';
import '../widgets/base_screen_layout.dart';
import '../widgets/standard_search_bar.dart';
import '../utils/timezone_utils.dart';

class SalesScreen extends ConsumerStatefulWidget {
  const SalesScreen({super.key});

  @override
  ConsumerState<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends ConsumerState<SalesScreen> {
  // Simulação: em produção, obtenha do authProvider
  final String currentUserId = '550e8400-e29b-41d4-a716-446655440101';
  
  // Campo de busca
  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = '';

  @override
  void initState() {
    super.initState();
    // Seta o usuário logado no provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(salesProvider.notifier).setCurrentUserId(currentUserId);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sale = ref.watch(salesProvider);

    return BaseScreenLayout(
      title: 'Minhas Vendas',
      actions: [
        // Botão para nova venda
        IconButton(
          icon: const Icon(Icons.add_shopping_cart),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CreateSaleScreenV2(),
              ),
            );
          },
          tooltip: 'Nova Venda',
        ),
        // Botão para nova venda V2
        IconButton(
          icon: const Icon(Icons.add_shopping_cart),
          onPressed: () {
            ref.read(dashboardPageProvider.notifier).state = DashboardPage.createSaleV2;
          },
          tooltip: 'Nova Venda V2',
        ),
        // Botão para vendas pendentes
        IconButton(
          icon: const Icon(Icons.pending_actions),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const PendingSalesScreen(),
              ),
            );
          },
          tooltip: 'Vendas Pendentes',
        ),
        // Botão para operações
        IconButton(
          icon: const Icon(Icons.assignment),
          onPressed: () {
            ref.read(dashboardPageProvider.notifier).state = DashboardPage.operations;
          },
          tooltip: 'Operações',
        ),
        // Botão para filtros
        IconButton(
          icon: const Icon(Icons.filter_list),
          onPressed: () => _showFilterDialog(context),
          tooltip: 'Filtros',
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
      child: sale.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Nenhuma venda encontrada.', style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            )
          : Column(
              children: [
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
                
                // Lista de vendas em cards
                Expanded(
                  child: _getFilteredSales(sale).isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _getFilteredSales(sale).length,
                          itemBuilder: (context, index) {
                            final saleItem = _getFilteredSales(sale)[index];
                            return _buildSaleCard(saleItem);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  List<Sale> _getFilteredSales(List<Sale> sales) {
    if (_searchTerm.isEmpty) {
      return sales;
    }
    
    return sales.where((sale) {
      final searchLower = _searchTerm.toLowerCase();
      
      // Busca por ID da venda
      if (sale.id.toString().contains(searchLower)) return true;
      
      // Busca por nome do cliente
      if (sale.contactName.toLowerCase().contains(searchLower)) return true;
      
      // Busca por telefone do cliente
      if (sale.contactPhone?.toLowerCase().contains(searchLower) ?? false) return true;
      
      // Busca por nome do vendedor
      if (sale.sellerName?.toLowerCase().contains(searchLower) ?? false) return true;
      if (sale.userName.toLowerCase().contains(searchLower)) return true;
      
      // Busca por status
      if (sale.status?.toLowerCase().contains(searchLower) ?? false) return true;
      
      // Busca por itens da venda
      if (sale.itemsSummary.toLowerCase().contains(searchLower)) return true;
      
      return false;
    }).toList();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhuma venda encontrada',
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
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                color: Theme.of(context).colorScheme.surfaceVariant.withValues(alpha: 0.3),
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
                          currencyFormat.format(sale.totalAmountBrl),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        if (sale.currencyCode != 'BRL')
                          Text(
                            '${sale.currencyCode} ${sale.totalAmount.toStringAsFixed(2)}',
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
                          currencyFormat.format(sale.remainingAmountBrl),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: sale.remainingAmount > 0 ? Colors.orange : Colors.green,
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
                      _formatDate(sale.createdAt),
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

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtros de Vendas'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Todas as Vendas'),
              onTap: () {
                Navigator.pop(context);
                ref.read(salesProvider.notifier).fetchSalesForUser();
              },
            ),
            ListTile(
              title: const Text('Vendas Pendentes'),
              onTap: () {
                Navigator.pop(context);
                ref.read(salesProvider.notifier).fetchPendingSales();
              },
            ),
            ListTile(
              title: const Text('Vendas Pagas'),
              onTap: () {
                Navigator.pop(context);
                ref.read(salesProvider.notifier).fetchSalesWithFilters({'status': 'paid'});
              },
            ),
          ],
        ),
      ),
    );
  }
}

class ContactServicesTab extends ConsumerWidget {
  const ContactServicesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serviceAsync = ref.watch(contactServicesProvider({}));

    return serviceAsync.when(
      data: (service) => _buildServicesList(context, ref, service),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Erro: $error'),
      ),
    );
  }

  Widget _buildServicesList(BuildContext context, WidgetRef ref, List<ContactService> service) {
    if (service.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.room_service_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Nenhum serviço encontrado',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: service.length,
      itemBuilder: (context, index) {
        final selectedService = service[index];
        return ContactServiceCard(service: selectedService);
      },
    );
  }
}

class ContactServiceCard extends StatelessWidget {
  final ContactService service;
  final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  ContactServiceCard({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    service.serviceName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildStatusChip(service.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Cliente: ${service.contactName}',
              style: const TextStyle(fontSize: 16),
            ),
            if (service.scheduledDate != null) ...[
              const SizedBox(height: 4),
              Text(
                'Data: ${DateFormat('dd/MM/yyyy HH:mm').format(TimezoneUtils.convertToNewYork(service.scheduledDate!))} (NYC)',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
            if (service.finalPrice != null) ...[
              const SizedBox(height: 4),
              Text(
                'Valor: ${currencyFormat.format(service.finalPrice)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
            if (service.pickupLocation != null || service.dropoffLocation != null) ...[
              const SizedBox(height: 8),
              if (service.pickupLocation != null)
                Text(
                  'Coleta: ${service.pickupLocation}',
                  style: const TextStyle(fontSize: 14),
                ),
              if (service.dropoffLocation != null)
                Text(
                  'Entrega: ${service.dropoffLocation}',
                  style: const TextStyle(fontSize: 14),
                ),
            ],
            if (service.specialInstructions != null && service.specialInstructions!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Observações: ${service.specialInstructions}',
                style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String? status) {
    Color color;
    String label;
    
    switch (status?.toLowerCase() ?? '') {
      case 'completed':
        color = Colors.green;
        label = 'Concluído';
        break;
      case 'in_progress':
        color = Colors.blue;
        label = 'Em Andamento';
        break;
      case 'cancelled':
        color = Colors.red;
        label = 'Cancelado';
        break;
      default:
        color = Colors.orange;
        label = 'Agendado';
    }

    return Chip(
      label: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      backgroundColor: color,
    );
  }
}

class InvoicesTab extends ConsumerWidget {
  const InvoicesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoiceAsync = ref.watch(filteredInvoicesProvider);

    return invoiceAsync.when(
      data: (invoice) => _buildInvoicesList(context, ref, invoice),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Erro: $error'),
      ),
    );
  }

  Widget _buildInvoicesList(BuildContext context, WidgetRef ref, List<ProvisionalInvoice> invoice) {
    if (invoice.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Nenhuma fatura encontrada',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: invoice.length,
      itemBuilder: (context, index) {
        final selectedInvoice = invoice[index];
        return InvoiceCard(invoice: selectedInvoice);
      },
    );
  }
}

class InvoiceCard extends StatelessWidget {
  final ProvisionalInvoice invoice;
  final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  InvoiceCard({super.key, required this.invoice});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fatura: ${invoice.invoiceNumber}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Cliente: ${invoice.contactName}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      Text(
                        'Serviço: ${invoice.serviceName}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(invoice.status),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Data: ${invoice.issueDateFormatted}',
                      style: const TextStyle(fontSize: 14),
                    ),
                    if (invoice.dueDateFormatted != null)
                      Text(
                        'Vencimento: ${invoice.dueDateFormatted}',
                        style: const TextStyle(fontSize: 14),
                      ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Total: ${currencyFormat.format(invoice.totalAmount)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    if (invoice.discountAmount > 0)
                      Text(
                        'Desconto: ${currencyFormat.format(invoice.discountAmount)}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.red,
                        ),
                      ),
                    Text(
                      'Líquido: ${currencyFormat.format(invoice.netAmount)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: () => _viewInvoice(context),
                  icon: const Icon(Icons.visibility, color: Colors.blue),
                ),
                IconButton(
                  onPressed: () => _editInvoice(context),
                  icon: const Icon(Icons.edit, color: Colors.orange),
                ),
                IconButton(
                  onPressed: () => _downloadInvoice(context),
                  icon: const Icon(Icons.download, color: Colors.green),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String text;

    switch (status) {
      case 'Pending':
        color = Colors.orange;
        text = 'Pendente';
        break;
      case 'Approved':
        color = Colors.green;
        text = 'Aprovada';
        break;
      case 'Rejected':
        color = Colors.red;
        text = 'Rejeitada';
        break;
      case 'Converted':
        color = Colors.blue;
        text = 'Convertida';
        break;
      default:
        color = Colors.grey;
        text = status;
    }

    return Chip(
      label: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }

  void _viewInvoice(BuildContext context) {
    // TODO: Implementar visualização de fatura
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Visualização de fatura em desenvolvimento')),
    );
  }

  void _editInvoice(BuildContext context) {
    // TODO: Implementar edição de fatura
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edição de fatura em desenvolvimento')),
    );
  }

  void _downloadInvoice(BuildContext context) {
    // TODO: Implementar download de fatura
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Download de fatura em desenvolvimento')),
    );
  }
}
