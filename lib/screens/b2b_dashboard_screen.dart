import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/b2b_providers.dart';
import '../widgets/base_screen_layout.dart';

class B2BDashboardScreen extends ConsumerWidget {
  const B2BDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(b2bMetricsProvider);
    final performanceAsync = ref.watch(provisionalInvoicePerformanceProvider);

    return BaseScreenLayout(
      title: 'Dashboard B2B',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () {
            ref.invalidate(b2bMetricsProvider);
            ref.invalidate(provisionalInvoicePerformanceProvider);
          },
        ),
      ],
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(b2bMetricsProvider);
          ref.invalidate(provisionalInvoicePerformanceProvider);
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Métricas Gerais
              _buildMetricsOverview(context, metricsAsync),
              const SizedBox(height: 24),
              
              // Performance por Tempo
              _buildTimePerformance(context, metricsAsync),
              const SizedBox(height: 24),
              
              // Lista de Propostas com Performance
              _buildPerformanceList(context, performanceAsync),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricsOverview(BuildContext context, AsyncValue<Map<String, dynamic>> metricsAsync) {
    return metricsAsync.when(
      data: (metrics) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Métricas Gerais',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      'Total Propostas',
                      metrics['total_proposals']?.toString() ?? '0',
                      Icons.description,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      'Pendentes',
                      metrics['pending_proposals']?.toString() ?? '0',
                      Icons.pending,
                      Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      'Aprovadas',
                      metrics['approved_proposals']?.toString() ?? '0',
                      Icons.check_circle,
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      'Convertidas',
                      metrics['converted_proposals']?.toString() ?? '0',
                      Icons.monetization_on,
                      Colors.purple,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      'Taxa Conversão',
                      '${metrics['conversion_rate_percent']?.toStringAsFixed(1) ?? '0'}%',
                      Icons.trending_up,
                      Colors.teal,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      'Valor Total',
                      _formatCurrency(metrics['total_converted_value'] ?? 0),
                      Icons.attach_money,
                      Colors.indigo,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, stack) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Column(
              children: [
                const Icon(Icons.error, size: 48, color: Colors.red),
                const SizedBox(height: 8),
                Text('Erro ao carregar métricas: $error'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimePerformance(BuildContext context, AsyncValue<Map<String, dynamic>> metricsAsync) {
    return metricsAsync.when(
      data: (metrics) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Performance de Tempo',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildTimeMetric(
                'Primeira Visualização',
                metrics['avg_days_to_first_view'] ?? 0,
                Icons.visibility,
                Colors.blue,
              ),
              const SizedBox(height: 8),
              _buildTimeMetric(
                'Aprovação',
                metrics['avg_days_to_approval'] ?? 0,
                Icons.approval,
                Colors.green,
              ),
              const SizedBox(height: 8),
              _buildTimeMetric(
                'Conversão Total',
                metrics['avg_days_to_conversion'] ?? 0,
                Icons.timeline,
                Colors.purple,
              ),
            ],
          ),
        ),
      ),
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, stack) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(child: Text('Erro: $error')),
        ),
      ),
    );
  }

  Widget _buildPerformanceList(BuildContext context, AsyncValue<List<Map<String, dynamic>>> performanceAsync) {
    return performanceAsync.when(
      data: (performanceList) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Propostas Recentes',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              if (performanceList.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('Nenhuma proposta encontrada'),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: performanceList.length,
                  itemBuilder: (context, index) {
                    final item = performanceList[index];
                    return _buildPerformanceItem(context, item);
                  },
                ),
            ],
          ),
        ),
      ),
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, stack) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(child: Text('Erro: $error')),
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTimeMetric(String title, double days, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 14),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${days.toStringAsFixed(1)} dias',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceItem(BuildContext context, Map<String, dynamic> item) {
    final status = item['status'] as String? ?? 'Pending';
    final priority = item['priority_level'] as String? ?? 'normal';
    final daysToApproval = item['days_to_approval'] as double? ?? 0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _getStatusColor(status).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Proposta #${item['invoice_number']}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              _buildStatusChip(status),
              const SizedBox(width: 8),
              _buildPriorityChip(priority),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Conta: ${item['account_name'] ?? 'N/A'}',
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            'Valor: ${_formatCurrency(item['total_amount'] ?? 0)}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (daysToApproval > 0) ...[
            const SizedBox(height: 4),
            Text(
              'Tempo para aprovação: ${daysToApproval.toStringAsFixed(1)} dias',
              style: TextStyle(
                fontSize: 12,
                color: daysToApproval > 7 ? Colors.red : Colors.green,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPriorityChip(String priority) {
    final color = _getPriorityColor(priority);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Text(
        priority.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'converted':
        return Colors.purple;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'urgent':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'normal':
        return Colors.blue;
      case 'low':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _formatCurrency(dynamic value) {
    if (value == null) return 'R\$ 0,00';
    final formatter = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
      decimalDigits: 2,
    );
    return formatter.format(value);
  }


}
