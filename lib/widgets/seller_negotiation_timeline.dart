import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/sale.dart';
import '../providers/sales_provider.dart';

/// Widget de timeline para negociações do vendedor
class SellerNegotiationTimeline extends ConsumerStatefulWidget {
  final String sellerId;
  
  const SellerNegotiationTimeline({
    super.key,
    required this.sellerId,
  });

  @override
  ConsumerState<SellerNegotiationTimeline> createState() => _SellerNegotiationTimelineState();
}

class _SellerNegotiationTimelineState extends ConsumerState<SellerNegotiationTimeline> {
  @override
  void initState() {
    super.initState();
    // Carrega as vendas do vendedor
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(salesProvider.notifier).fetchSales();
    });
  }

  @override
  Widget build(BuildContext context) {
    final sales = ref.watch(salesProvider);
    
    // Filtra vendas do vendedor atual e em negociação
    final sellerSales = sales.where((sale) => 
      sale.userId == widget.sellerId && 
      (sale.status == 'negociacao' || sale.status == 'proposta')
    ).toList();
    
    if (sellerSales.isEmpty) {
      return _buildEmptyState();
    }
    
    return _buildTimeline(sellerSales);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.handshake,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhuma negociação ativa',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Você não tem negociações em andamento no momento',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(List<Sale> sales) {
    // Ordena por data de criação (mais recente primeiro)
    sales.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.timeline,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                'Negociações em Andamento',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${sales.length} ativas',
                  style: TextStyle(
                    color: Colors.orange[800],
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(),
        // Lista de negociações com timeline
        Flexible(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: sales.length,
            itemBuilder: (context, index) {
              final sale = sales[index];
              return _buildNegotiationItem(sale, index == sales.length - 1);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNegotiationItem(Sale sale, bool isLast) {
    final daysInNegotiation = DateTime.now().difference(sale.createdAt).inDays;
    final statusColor = _getStatusColor(sale.status ?? '');
    final statusIcon = _getStatusIcon(sale.status ?? '');
    
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Linha do timeline
          Column(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  statusIcon,
                  size: 10,
                  color: Colors.white,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: Colors.grey[300],
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          // Conteúdo
          Expanded(
            child: Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Venda #${sale.id}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                sale.contactName ?? 'Cliente não identificado',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            _getStatusDisplayName(sale.status ?? ''),
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          'Há $daysInNegotiation dias',
                          style: TextStyle(
                            color: daysInNegotiation > 7 ? Colors.orange : Colors.grey[600],
                            fontSize: 12,
                            fontWeight: daysInNegotiation > 7 ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        const Spacer(),
                        Icon(Icons.attach_money, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          'R\$ ${sale.totalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    if (sale.notes?.isNotEmpty == true) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          sale.notes!,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _showNegotiationDetails(sale),
                            icon: const Icon(Icons.visibility, size: 16),
                            label: const Text('Detalhes'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              textStyle: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _showNegotiationActions(sale),
                            icon: const Icon(Icons.edit, size: 16),
                            label: const Text('Ações'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              textStyle: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'proposta':
        return Colors.blue;
      case 'negociacao':
        return Colors.orange;
      case 'pagamento':
        return Colors.green;
      case 'finalizado':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'proposta':
        return Icons.description;
      case 'negociacao':
        return Icons.handshake;
      case 'pagamento':
        return Icons.payment;
      case 'finalizado':
        return Icons.check_circle;
      default:
        return Icons.circle;
    }
  }

  String _getStatusDisplayName(String status) {
    switch (status.toLowerCase()) {
      case 'proposta':
        return 'Proposta Enviada';
      case 'negociacao':
        return 'Em Negociação';
      case 'pagamento':
        return 'Aguardando Pagamento';
      case 'finalizado':
        return 'Finalizada';
      default:
        return status;
    }
  }

  void _showNegotiationDetails(Sale sale) {
    // Implementar navegação para detalhes da venda
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Detalhes da venda #${sale.id}')),
    );
  }

  void _showNegotiationActions(Sale sale) {
    // Implementar modal de ações de negociação
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Ações para venda #${sale.id}')),
    );
  }
}