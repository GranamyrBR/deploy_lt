import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/sale.dart';
import '../providers/sales_provider.dart';

import '../widgets/base_screen_layout.dart';
import '../utils/smart_search_mixin.dart';
import 'create_sale_screen_v2.dart';
import 'create_operation_from_sale_screen.dart';

import '../widgets/add_payment_modal.dart';
import '../widgets/agency_details_modal.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SalesScreen extends ConsumerStatefulWidget {
  const SalesScreen({super.key});

  @override
  ConsumerState<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends ConsumerState<SalesScreen> with SmartSearchMixin {
  String? currentUserId;
  
  // Campo de busca
  final TextEditingController _searchController = TextEditingController();
  final String _searchTerm = '';

  @override
  void initState() {
    super.initState();
    // Seta o usuário logado no provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = Supabase.instance.client.auth.currentUser?.id;
      currentUserId = uid;
      if (uid != null) {
        ref.read(salesProvider.notifier).setCurrentUserId(uid);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final salesAsync = ref.watch(salesProvider);
    final loaded = ref.watch(salesLoadedProvider);
    
    return BaseScreenLayout(
      title: 'Vendas',
      actions: [
        IconButton(
          onPressed: () => _showFilterDialog(context),
          icon: const Icon(Icons.filter_list),
        ),
        IconButton(
          onPressed: _createNewSale,
          icon: const Icon(Icons.add),
        ),
      ],
      child: !loaded
          ? _buildLoadingState()
          : _buildSalesList(salesAsync),
    );
  }

  void _createNewSale() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateSaleScreenV2(),
      ),
    ).then((result) {
      if (result == true) {
        // Recarregar a lista de vendas
        ref.read(salesProvider.notifier).fetchSalesForUser();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nova venda criada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatDateTime(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  List<Sale> _getFilteredSales(List<Sale> sales) {
    if (_searchTerm.isEmpty) {
      return sales;
    }
    
    return sales.where((sale) {
      // Converter Sale para Map para usar o mixin
      final saleMap = {
        'id': sale.id,
        'contactName': sale.contactName,
        'contactPhone': sale.contactPhone,
        'sellerName': sale.sellerName,
        'userName': sale.userName,
        'status': sale.status,
        'itemsSummary': sale.itemsSummary,
      };
      
      return smartSearch(
        saleMap, 
        _searchTerm,
        nameField: 'contactName',
        phoneField: 'contactPhone',
        additionalFields: 'itemsSummary',
      );
    }).toList();
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Carregando vendas...',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.outline,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Otimizando consultas para melhor performance',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
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

  Widget _buildSalesList(List<Sale> sales) {
    return _getFilteredSales(sales).isEmpty
        ? _buildEmptyState()
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _getFilteredSales(sales).length,
            itemBuilder: (context, index) {
              final saleItem = _getFilteredSales(sales)[index];
              return _buildSaleCard(saleItem);
            },
          );
  }

  Widget _buildSaleCard(Sale sale) {
    final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(12),
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
                    const PopupMenuItem(
                      value: 'create_operation',
                      child: Row(
                        children: [
                          Icon(Icons.assignment, size: 16),
                          SizedBox(width: 8),
                          Text('Criar Operação'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'fix_status',
                      child: Row(
                        children: [
                          Icon(Icons.build, size: 16),
                          SizedBox(width: 8),
                          Text('Corrigir Status'),
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
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              sale.contactName.isNotEmpty
                                  ? sale.contactName
                                  : 'Cliente não informado',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (sale.isVipCustomer)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.amber.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.star,
                                    size: 12,
                                    color: Colors.amber[700],
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    'VIP',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.amber[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      if (sale.contactPhone != null && sale.contactPhone!.isNotEmpty)
                        Text(
                          sale.contactPhone!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      if (sale.hasAgency)
                         Padding(
                           padding: const EdgeInsets.only(top: 4),
                           child: InkWell(
                             onTap: () => _showAgencyDetails(context, sale),
                             borderRadius: BorderRadius.circular(4),
                             child: Container(
                               padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                               child: Row(
                                 children: [
                                   Icon(
                                     Icons.business,
                                     size: 12,
                                     color: Theme.of(context).colorScheme.primary,
                                   ),
                                   const SizedBox(width: 4),
                                   Expanded(
                                     child: Text(
                                       'Agência: ${sale.agencyDisplayName}',
                                       style: TextStyle(
                                         fontSize: 12,
                                         color: Theme.of(context).colorScheme.primary,
                                         fontWeight: FontWeight.w500,
                                       ),
                                     ),
                                   ),
                                   Icon(
                                     Icons.info_outline,
                                     size: 12,
                                     color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
                                   ),
                                 ],
                               ),
                             ),
                           ),
                       ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const SizedBox(height: 12),
            // Seção de itens da venda
            if (sale.hasItems) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Icon(
                            Icons.shopping_bag_outlined,
                            size: 14,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Itens da Venda (${sale.itemsCount})',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ...sale.itemsDescriptionList.asMap().entries.map((entry) {
                      final index = entry.key;
                      final itemDescription = entry.value;
                      final isLast = index == sale.itemsDescriptionList.length - 1;
                      
                      return Padding(
                        padding: EdgeInsets.only(bottom: isLast ? 0 : 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 4,
                              height: 4,
                              margin: const EdgeInsets.only(top: 7, right: 10),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
                                shape: BoxShape.circle,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                itemDescription,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.85),
                                  height: 1.4,
                                  fontWeight: FontWeight.w400,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            // Informações de valor
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.15),
                  width: 1,
                ),
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
                          'USD \$${sale.totalPaidUsd.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: sale.totalPaidUsd > 0 ? Colors.blue : Colors.grey,
                          ),
                        ),
                        Text(
                          '≈${currencyFormat.format(sale.totalPaidBrl)}',
                          style: TextStyle(
                            fontSize: 11,
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
                            color: sale.remainingAmountUsd > 0 ? Colors.orange : Colors.green,
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
            // Seção de métodos de pagamento
            if (sale.payments.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Métodos de Pagamento',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...sale.payments.map((payment) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Text(
                                       payment.paymentMethodName,
                                       style: const TextStyle(
                                         fontSize: 13,
                                         fontWeight: FontWeight.w500,
                                       ),
                                     ),
                                    ...[
                                    Text(
                                      ' • ${DateFormat('dd/MM/yy').format(payment.paymentDate)}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                      ),
                                    ),
                                  ],
                                  ],
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Exibir cotação do dólar para pagamentos em reais
                                  if (payment.currencyCode == 'BRL' && payment.exchangeRateToUsd != null) ...[
                                    Text(
                                      'USD: R\$ ${(1.0 / payment.exchangeRateToUsd!).toStringAsFixed(2)} • ',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                      ),
                                    ),
                                  ],
                                  Text(
                                    '${payment.currencyCode} \$${payment.amount.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
            ],
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

    // Debug: imprimir status para verificar
    print('DEBUG: Venda #${sale.id} - paymentStatus: ${sale.paymentStatus}');
    print('DEBUG: Venda #${sale.id} - isPaid: ${sale.isPaid}');
    print('DEBUG: Venda #${sale.id} - isPartiallyPaid: ${sale.isPartiallyPaid}');

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
    print('DEBUG: Ação do menu selecionada: $action para venda #${sale.id}');
    
    switch (action) {
      case 'edit':
        print('DEBUG: Executando edição');
        _editSale(sale);
        break;
      case 'payment':
        print('DEBUG: Executando registro de pagamento');
        _registerPayment(sale);
        break;
      case 'create_operation':
        print('DEBUG: Executando criação de operação');
        _createOperation(sale);
        break;
      case 'fix_status':
        print('DEBUG: Executando correção de status');
        _fixSaleStatus(sale);
        break;
      default:
        print('DEBUG: Ação não reconhecida: $action');
    }
  }



  void _editSale(Sale sale) {
    print('DEBUG: Iniciando edição da venda #${sale.id}');
    
    // Navegar para a tela de edição com steps
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateSaleScreenV2(sale: sale),
      ),
    ).then((result) {
      print('DEBUG: Resultado da edição: $result');
      if (result == true) {
        // Recarregar a lista de vendas
        ref.read(salesProvider.notifier).fetchSalesForUser();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Venda #${sale.id} editada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }

  // Função para mapear nome do método de pagamento para ID
  int _getPaymentMethodId(String methodName) {
    switch (methodName) {
      case 'PIX':
        return 1;
      case 'Cartão de Crédito':
        return 2;
      case 'Transferência Bancária':
        return 3;
      case 'Dinheiro':
        return 4;
      case 'Zelle':
        return 5;
      default:
        print('AVISO: Método de pagamento desconhecido: $methodName. Usando PIX como padrão.');
        return 1; // PIX como padrão
    }
  }

  void _registerPayment(Sale sale) async {
    print('DEBUG: Iniciando registro de pagamento para venda #${sale.id}');
    
    try {
      final result = await showDialog<SalePaymentData>(
        context: context,
        builder: (context) => AddPaymentModal(sale: sale),
      );
      
      print('DEBUG: Resultado do modal: $result');
      
      if (result != null) {
        print('DEBUG: Dados do pagamento recebidos');
        print('DEBUG: Método: ${result.paymentMethodName}');
        print('DEBUG: Valor: ${result.amount}');
        print('DEBUG: Moeda: ${result.currencyCode}');

        try {
          // Mapear nome do método de pagamento para ID correto
          final paymentMethodId = _getPaymentMethodId(result.paymentMethodName);
          print('DEBUG: Método ${result.paymentMethodName} mapeado para ID: $paymentMethodId');
          
          // Mapear SalePaymentData para o formato do banco de dados
          final paymentData = {
            'sales_id': sale.id,
            'payment_method_id': paymentMethodId,
            'amount': result.amount,
            'currency_id': result.currencyCode == 'USD' ? 1 : 2,
            'payment_date': result.paymentDate.toIso8601String(),
            'transaction_id': result.transactionId,
            'is_advance_payment': result.isAdvancePayment,
            'exchange_rate_to_usd': result.exchangeRateToUsd,
            'amount_in_brl': result.amountInBrl,
            'amount_in_usd': result.amountInUsd,
          };

          final response = await Supabase.instance.client.from('sale_payment').insert(paymentData).select();

          // Após inserir o pagamento, recalcular o total pago e atualizar o status da venda
          final totalPaidResponse = await Supabase.instance.client
              .from('sale_payment')
              .select('amount_in_usd')
              .eq('sales_id', sale.id);
          
          double totalPaid = 0;
          for (var row in totalPaidResponse) {
            totalPaid += (row['amount_in_usd'] as num?) ?? 0.0;
          }

          String newPaymentStatus = 'pending';
          String newStatus = 'pending';

          // Debug: imprimir valores para verificar
          print('DEBUG: Venda #${sale.id}');
          print('DEBUG: totalPaid = $totalPaid');
          print('DEBUG: sale.totalAmountUsd = ${sale.totalAmountUsd}');
          print('DEBUG: Diferença = ${sale.totalAmountUsd - totalPaid}');

          // Usar tolerância maior e verificar se está realmente pago
          if (totalPaid >= sale.totalAmountUsd - 0.05) { // Tolerância de 5 centavos
            newPaymentStatus = 'paid'; // Usar 'paid' em vez de 'Pago' para compatibilidade
            newStatus = 'completed';
            print('DEBUG: Status alterado para PAGO');
          } else if (totalPaid > 0) {
            newPaymentStatus = 'partial'; // Usar 'partial' em vez de 'Parcial'
            print('DEBUG: Status alterado para PARCIAL');
          } else {
            newPaymentStatus = 'pending'; // Usar 'pending' em vez de 'Pendente'
            print('DEBUG: Status mantido como PENDENTE');
          }

          await Supabase.instance.client
              .from('sale')
              .update({'payment_status': newPaymentStatus, 'status': newStatus})
              .eq('id', sale.id);

          print('DEBUG: Status atualizado no banco - payment_status: $newPaymentStatus, status: $newStatus');

          // Invalidar o provider para forçar o recarregamento da lista de vendas
          ref.invalidate(salesProvider);
          
          // Forçar recarregamento imediato
          await ref.read(salesProvider.notifier).fetchSalesForUser();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pagamento registrado com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao registrar pagamento: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('DEBUG: Erro ao abrir modal de pagamento: $e');
    }
  }

  void _createOperation(Sale sale) {
    // Verificar se a venda está paga ou tem pagamento parcial
    // Usar totalPaidUsd em vez de totalPaid para garantir consistência
    if (sale.totalPaidUsd == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('É necessário ter um pagamento registrado para criar uma operação'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Navegar para a tela de criação de operação a partir da venda
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateOperationFromSaleScreen(sale: sale),
      ),
    ).then((result) {
      if (result == true) {
        // Recarregar a lista de vendas
        ref.read(salesProvider.notifier).fetchSalesForUser();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Operação criada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }




  // Método para corrigir o status de uma venda específica
  Future<void> _fixSaleStatus(Sale sale) async {
    print('DEBUG: Iniciando correção de status para venda #${sale.id}');
    
    try {
      // Recalcular o total pago
      final totalPaidResponse = await Supabase.instance.client
          .from('sale_payment')
          .select('amount_in_usd')
          .eq('sales_id', sale.id);
      
      double totalPaid = 0;
      for (var row in totalPaidResponse) {
        totalPaid += (row['amount_in_usd'] as num?) ?? 0.0;
      }

      String newPaymentStatus = 'pending';
      String newStatus = 'pending';

      if (totalPaid >= sale.totalAmountUsd - 0.05) {
        newPaymentStatus = 'paid';
        newStatus = 'completed';
      } else if (totalPaid > 0) {
        newPaymentStatus = 'partial';
      }

      await Supabase.instance.client
          .from('sale')
          .update({'payment_status': newPaymentStatus, 'status': newStatus})
          .eq('id', sale.id);

      // Recarregar dados
      ref.invalidate(salesProvider);
      await ref.read(salesProvider.notifier).fetchSalesForUser();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Status da venda #${sale.id} corrigido!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao corrigir status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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

  void _showAgencyDetails(BuildContext context, Sale sale) {
    AgencyDetailsModal.show(
      context,
      agencyName: sale.agencyDisplayName ?? 'Agência não especificada',
      agencyEmail: sale.customerAgencyEmail,
      agencyPhone: sale.customerAgencyPhone,
      agencyCity: sale.customerAgencyCity,
      commissionRate: sale.customerAgencyCommissionRate,
    );
  }
}
