import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/customer_analytics_service.dart';

class CustomerProfileView extends StatefulWidget {
  final int customerId;
  final String customerName;
  final CustomerAnalyticsService? analyticsService;
  final bool? highContrast;

  const CustomerProfileView({
    super.key,
    required this.customerId,
    required this.customerName,
    this.analyticsService,
    this.highContrast,
  });

  @override
  State<CustomerProfileView> createState() => _CustomerProfileViewState();
}

class _CustomerProfileViewState extends State<CustomerProfileView>
    with TickerProviderStateMixin {
  late final CustomerAnalyticsService _analyticsService;
  Map<String, dynamic>? _customerData;
  bool _isLoading = true;
  String? _errorMessage;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _analyticsService = widget.analyticsService ?? CustomerAnalyticsService();
    _tabController = TabController(length: 5, vsync: this);
    _loadCustomerData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomerData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      final data = await _analyticsService.getCustomerAnalytics(widget.customerId);
      setState(() {
        _customerData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao carregar dados do cliente: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hc = widget.highContrast == true;
    return Column(
      children: [
        _buildHeader(context),
        if (_isLoading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else if (_errorMessage != null)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(fontSize: 16, color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: _loadCustomerData, child: const Text('Tentar Novamente')),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: Column(
              children: [
                _buildTabBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOverviewTab(),
                      _buildSalesTab(),
                      _buildOperationsTab(),
                      _buildRatingsTab(),
                      _buildComparativeTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    final customer = _customerData?['customer'];
    final isVip = customer?['is_vip'] ?? false;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: widget.highContrast == true
            ? const LinearGradient(colors: [Colors.black, Colors.black])
            : LinearGradient(
                colors: isVip
                    ? [Colors.amber[700]!, Colors.amber[500]!]
                    : [theme.colorScheme.primary, theme.colorScheme.primaryContainer],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: widget.highContrast == true ? Colors.white : Colors.white.withValues(alpha: 0.2),
            child: Text(
              widget.customerName.isNotEmpty ? widget.customerName[0].toUpperCase() : 'C',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: widget.highContrast == true ? Colors.black : Colors.white),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        widget.customerName,
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: widget.highContrast == true ? Colors.white : Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isVip) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.amber[300], borderRadius: BorderRadius.circular(12)),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star, size: 16, color: Colors.white),
                            SizedBox(width: 4),
                            Text('VIP', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(customer?['email'] ?? 'Email não informado', style: TextStyle(fontSize: 14, color: widget.highContrast == true ? Colors.white : Colors.white.withValues(alpha: 0.9))),
                if (customer?['account']?['name'] != null) ...[
                  const SizedBox(height: 4),
                  Text('Agência: ${customer['account']['name']}', style: TextStyle(fontSize: 14, color: widget.highContrast == true ? Colors.white : Colors.white.withValues(alpha: 0.9))),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[300]!, width: 1)),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: widget.highContrast == true ? Colors.white : Colors.blue[700],
        unselectedLabelColor: widget.highContrast == true ? Colors.white70 : Colors.grey[600],
        indicatorColor: widget.highContrast == true ? Colors.white : Colors.blue[700],
        indicatorWeight: 3,
        tabs: const [
          Tab(icon: Icon(Icons.dashboard), text: 'Visão Geral'),
          Tab(icon: Icon(Icons.shopping_cart), text: 'Vendas'),
          Tab(icon: Icon(Icons.directions_car), text: 'Operações'),
          Tab(icon: Icon(Icons.star), text: 'Avaliações'),
          Tab(icon: Icon(Icons.analytics), text: 'Comparativo'),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold));
  }

  Widget _buildInfoGrid(List<Widget> children) {
    return LayoutBuilder(builder: (context, constraints) {
      final isWide = constraints.maxWidth > 800;
      final crossAxisCount = isWide ? 4 : 2;
      return GridView.count(
        crossAxisCount: crossAxisCount,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 3.2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        children: children,
      );
    });
  }

  Widget _buildInfoCard(String title, String value, IconData icon) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, color: Colors.blue[600]),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(value),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
                  Text(value),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsGrid(List<Widget> children) {
    return LayoutBuilder(builder: (context, constraints) {
      final isWide = constraints.maxWidth > 800;
      final crossAxisCount = isWide ? 4 : 2;
      return GridView.count(
        crossAxisCount: crossAxisCount,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 3.2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        children: children,
      );
    });
  }

  Widget _buildOverviewTab() {
    final customer = _customerData!['customer'];
    final metrics = _customerData!['metrics'];
    final salesStats = _customerData!['sales']['statistics'];
    final operationsStats = _customerData!['operations']['statistics'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Informações Pessoais'),
          const SizedBox(height: 16),
          _buildInfoGrid([
            _buildInfoCard('Telefone', customer['phone'] ?? 'Não informado', Icons.phone),
            _buildInfoCard('Cidade', customer['city'] ?? 'Não informada', Icons.location_city),
            _buildInfoCard('Estado', customer['state'] ?? 'Não informado', Icons.map),
            _buildInfoCard('País', customer['country'] ?? 'Não informado', Icons.public),
          ]),
          const SizedBox(height: 32),
          _buildSectionTitle('Métricas Principais'),
          const SizedBox(height: 16),
          _buildMetricsGrid([
            _buildMetricCard('Valor Total Gasto', '\$${NumberFormat('#,##0.00').format(salesStats['totalSpentUSD'])}', Icons.attach_money, Colors.green),
            _buildMetricCard('Total de Vendas', '${salesStats['totalSales']}', Icons.shopping_bag, Colors.blue),
            _buildMetricCard('Operações Realizadas', '${operationsStats['totalOperations']}', Icons.directions_car, Colors.orange),
            _buildMetricCard('Avaliação Média', '${operationsStats['averageCustomerRating'].toStringAsFixed(1)}/5', Icons.star, Colors.amber),
          ]),
          const SizedBox(height: 32),
          _buildSectionTitle('Histórico'),
          const SizedBox(height: 16),
          _buildInfoGrid([
            _buildInfoCard('Cliente Desde', metrics['firstPurchase'] != null ? DateFormat('dd/MM/yyyy').format(DateTime.parse(metrics['firstPurchase'])) : 'Não informado', Icons.calendar_today),
            _buildInfoCard('Última Compra', metrics['lastPurchase'] != null ? DateFormat('dd/MM/yyyy').format(DateTime.parse(metrics['lastPurchase'])) : 'Não informado', Icons.schedule),
            _buildInfoCard('Frequência de Compra', '${metrics['purchaseFrequency'].toStringAsFixed(1)}/mês', Icons.repeat),
            _buildInfoCard('Taxa de Conclusão', '${(metrics['completionRate'] * 100).toStringAsFixed(1)}%', Icons.check_circle),
          ]),
        ],
      ),
    );
  }

  Widget _buildSalesTab() {
    final sales = _customerData!['sales']['sales'] as List;
    final salesStats = _customerData!['sales']['statistics'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Estatísticas de Vendas'),
          const SizedBox(height: 16),
          Wrap(spacing: 12, runSpacing: 12, children: [
            _buildMetricCard('Total de Vendas', '${salesStats['totalSales']}', Icons.shopping_cart, Colors.blue),
            _buildMetricCard('Total Gasto (USD)', '\$${NumberFormat('#,##0.00').format(salesStats['totalSpentUSD'])}', Icons.attach_money, Colors.green),
            _buildMetricCard('Ticket Médio', '\$${NumberFormat('#,##0.00').format(salesStats['averageOrderValue'])}', Icons.request_quote, Colors.teal),
          ]),
          const SizedBox(height: 24),
          _buildSectionTitle('Últimas Vendas'),
          const SizedBox(height: 12),
          ...sales.take(10).map((sale) => Card(
                elevation: 1,
                child: ListTile(
                  leading: const Icon(Icons.receipt_long),
                  title: Text('Venda #${sale['sale_number'] ?? sale['id']}'),
                  subtitle: Text('Status: ${sale['status'] ?? 'N/A'}'),
                  trailing: Text('\$${(sale['total_amount_usd'] ?? 0).toStringAsFixed(2)}'),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildOperationsTab() {
    final operations = _customerData!['operations']['operations'] as List;
    final operationsStats = _customerData!['operations']['statistics'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Operações Recentes'),
          const SizedBox(height: 12),
          ...operations.take(10).map((op) => Card(
                elevation: 1,
                child: ListTile(
                  leading: const Icon(Icons.directions_car),
                  title: Text('Operação #${op['id']} • ${op['status'] ?? 'N/A'}'),
                  subtitle: Text('${op['pickup_location'] ?? ''} → ${op['dropoff_location'] ?? ''}'),
                  trailing: Text('\$${(op['service_value_usd'] ?? 0).toStringAsFixed(2)}'),
                ),
              )),
          const SizedBox(height: 24),
          Wrap(spacing: 12, runSpacing: 12, children: [
            _buildMetricCard('Concluídas', '${operationsStats['completedOperations']}', Icons.check_circle, Colors.green),
            _buildMetricCard('Canceladas', '${operationsStats['cancelledOperations']}', Icons.cancel, Colors.red),
            _buildMetricCard('Avaliação Média', '${operationsStats['averageCustomerRating'].toStringAsFixed(1)}', Icons.star, Colors.amber),
          ]),
        ],
      ),
    );
  }

  Widget _buildRatingsTab() {
    final ratingsData = _customerData!['ratings'];
    final allRatings = ratingsData['allRatings'] as List;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Feedbacks dos Clientes'),
          const SizedBox(height: 12),
          ...allRatings.take(10).map((r) => Card(
                elevation: 1,
                child: ListTile(
                  leading: const Icon(Icons.rate_review),
                  title: Text('Operação #${r['id']} • Nota: ${r['customer_rating'] ?? 'N/A'}'),
                  subtitle: Text(r['customer_feedback'] ?? 'Sem comentário'),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildComparativeTab() {
    final comparative = _customerData!['comparative'];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Comparativo com Clientes da Agência'),
          const SizedBox(height: 12),
          Card(
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(comparative.toString()),
            ),
          ),
        ],
      ),
    );
  }
}
