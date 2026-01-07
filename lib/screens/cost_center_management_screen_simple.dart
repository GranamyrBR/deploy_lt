import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cost_center.dart';
import '../providers/cost_center_provider.dart';
import '../widgets/cost_center_card.dart';
import '../widgets/cost_center_kpi_dashboard.dart';
import '../widgets/cost_center_temporal_dashboard.dart';
import '../widgets/cost_center_advanced_charts.dart';
import '../widgets/cost_center_comprehensive_charts.dart';
import '../widgets/cost_center_enhanced_charts.dart';
import '../widgets/expense_modal.dart';

class CostCenterManagementScreen extends ConsumerStatefulWidget {
  const CostCenterManagementScreen({super.key});

  @override
  ConsumerState<CostCenterManagementScreen> createState() =>
      _CostCenterManagementScreenState();
}

class _CostCenterManagementScreenState
    extends ConsumerState<CostCenterManagementScreen>
    with TickerProviderStateMixin {
  String _selectedFilter = 'all';
  int _selectedTabIndex = 0;

  final List<Map<String, String>> _filters = [
    {'value': 'all', 'label': 'Todos'},
    {'value': 'over_budget', 'label': 'Acima do Orçamento'},
    {'value': 'under_budget', 'label': 'Dentro do Orçamento'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(costCenterProvider.notifier).loadCostCenters();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Centros de Custo'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_business),
            onPressed: () => _showAddCostCenterModal(context),
            tooltip: 'Adicionar centro de custo',
          ),
        ],
        bottom: TabBar(
          controller: TabController(
              length: 6, vsync: this, initialIndex: _selectedTabIndex),
          onTap: (index) => setState(() => _selectedTabIndex = index),
          tabs: const [
            Tab(icon: Icon(Icons.list), text: 'Lista'),
            Tab(icon: Icon(Icons.analytics), text: 'KPI Dashboard'),
            Tab(icon: Icon(Icons.trending_up), text: 'Tendências'),
            Tab(icon: Icon(Icons.show_chart), text: 'Avançado'),
            Tab(icon: Icon(Icons.radar), text: 'Compreensivo'),
            Tab(icon: Icon(Icons.speed), text: 'Aprimorado'),
          ],
          isScrollable: true,
        ),
      ),
      body: Consumer(
        builder: (context, ref, child) {
          final provider = ref.watch(costCenterProvider);
          final costCenters = provider.costCenters;

          if (_selectedTabIndex == 1) {
            return RefreshIndicator(
              onRefresh: () =>
                  ref.read(costCenterProvider.notifier).loadCostCenters(),
              child: SingleChildScrollView(
                child: CostCenterKpiDashboard(
                  costCenters: costCenters,
                ),
              ),
            );
          }

          if (_selectedTabIndex == 2) {
            return RefreshIndicator(
              onRefresh: () =>
                  ref.read(costCenterProvider.notifier).loadCostCenters(),
              child: CostCenterTemporalDashboard(
                costCenters: costCenters,
              ),
            );
          }

          if (_selectedTabIndex == 3) {
            return RefreshIndicator(
              onRefresh: () =>
                  ref.read(costCenterProvider.notifier).loadCostCenters(),
              child: CostCenterAdvancedCharts(
                costCenters: costCenters,
              ),
            );
          }

          if (_selectedTabIndex == 4) {
            return RefreshIndicator(
              onRefresh: () =>
                  ref.read(costCenterProvider.notifier).loadCostCenters(),
              child: CostCenterComprehensiveCharts(
                costCenters: costCenters,
              ),
            );
          }

          if (_selectedTabIndex == 5) {
            return RefreshIndicator(
              onRefresh: () =>
                  ref.read(costCenterProvider.notifier).loadCostCenters(),
              child: CostCenterEnhancedCharts(
                costCenters: costCenters,
              ),
            );
          }

          // Lista Tab
          final totalBudget = provider.totalBudget;
          final totalUtilized = provider.totalUtilized;
          final overallUtilizationPercentage = provider.overallUtilizationPercentage;

          final filteredCostCenters = costCenters.where((costCenter) {
            switch (_selectedFilter) {
              case 'over_budget':
                return costCenter.isOverBudget;
              case 'under_budget':
                return !costCenter.isOverBudget;
              default:
                return true;
            }
          }).toList();

          return RefreshIndicator(
            onRefresh: () =>
                ref.read(costCenterProvider.notifier).loadCostCenters(),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Card(
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Resumo Geral',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildSummaryCard(
                                        'Orçamento Total',
                                        'R\$ ${totalBudget.toStringAsFixed(2)}',
                                        Icons.account_balance_wallet,
                                        Colors.blue,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _buildSummaryCard(
                                        'Total Utilizado',
                                        'R\$ ${totalUtilized.toStringAsFixed(2)}',
                                        Icons.money_off,
                                        Colors.orange,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _buildSummaryCard(
                                        'Saldo Disponível',
                                        'R\$ ${(totalBudget - totalUtilized).toStringAsFixed(2)}',
                                        Icons.savings,
                                        Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'Utilização Geral',
                                          style: TextStyle(fontSize: 16),
                                        ),
                                        Text(
                                          '${overallUtilizationPercentage.toStringAsFixed(1)}%',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: overallUtilizationPercentage > 90
                                                ? Colors.red
                                                : overallUtilizationPercentage > 70
                                                    ? Colors.orange
                                                    : Colors.green,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: overallUtilizationPercentage / 100,
                                        backgroundColor: Colors.grey[300],
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          overallUtilizationPercentage > 90
                                              ? Colors.red
                                              : overallUtilizationPercentage > 70
                                                  ? Colors.orange
                                                  : Colors.green,
                                        ),
                                        minHeight: 8,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: TextField(
                                        decoration: const InputDecoration(
                                          labelText: 'Buscar centro de custo',
                                          hintText: 'Nome ou descrição',
                                          border: OutlineInputBorder(),
                                          prefixIcon: Icon(Icons.search),
                                        ),
                                        onChanged: (value) {
                                          provider.setSearchQuery(value);
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: DropdownButtonFormField<String>(
                                        initialValue: _selectedFilter,
                                        decoration: const InputDecoration(
                                          labelText: 'Filtro',
                                          border: OutlineInputBorder(),
                                        ),
                                        items: _filters.map((filter) {
                                          return DropdownMenuItem<String>(
                                            value: filter['value']!,
                                            child: Text(filter['label']!),
                                          );
                                        }).toList(),
                                        onChanged: (value) {
                                          if (value != null) {
                                            setState(() => _selectedFilter = value);
                                          }
                                        },
                                        hint: const Text('Selecione um filtro'),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    IconButton(
                                      onPressed: () {
                                        provider.clearFilters();
                                        setState(() => _selectedFilter = 'all');
                                      },
                                      icon: const Icon(Icons.clear),
                                      tooltip: 'Limpar filtros',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                if (provider.isLoading)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (provider.error.isNotEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Erro ao carregar dados',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            provider.error,
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => provider.loadCostCenters(),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Tentar novamente'),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (filteredCostCenters.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.business,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Nenhum centro de custo encontrado',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Crie seu primeiro centro de custo para começar',
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () => _showAddCostCenterModal(context),
                            icon: const Icon(Icons.add_business),
                            label: const Text('Adicionar Centro de Custo'),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ..._buildCostCentersList(provider, filteredCostCenters),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 20),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCostCentersList(
    CostCenterProvider provider,
    List<CostCenter> costCenters,
  ) {
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            '${costCenters.length} centro${costCenters.length > 1 ? 's' : ''} de custo${costCenters.length > 1 ? 's' : ''}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ),
      ),
      SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final costCenter = costCenters[index];
            return CostCenterCard(
              costCenter: costCenter,
              onEdit: () => _showEditCostCenterModal(context, costCenter),
              onDelete: () => _confirmDeleteCostCenter(context, costCenter),
              onAddExpense: () => _showAddExpenseModal(context, costCenter),
              // onViewDetails: () => _showCostCenterDetails(context, costCenter),  // Comentado - parâmetro não existe
            );
          },
          childCount: costCenters.length,
        ),
      ),
    ];
  }

  void _showAddCostCenterModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adicionar Centro de Custo'),
        content: _CostCenterForm(
          onSave: (name, description, code, budget, responsible, department) {
            final costCenter = CostCenter(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              name: name,
              description: description,
              code: code,
              budget: budget,
              utilized: 0,
              responsible: responsible,
              department: department,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              expenses: const [],
            );
            ref.read(costCenterProvider.notifier).addCostCenter(costCenter);
            Navigator.of(context).pop();
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  void _showEditCostCenterModal(BuildContext context, CostCenter costCenter) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Centro de Custo'),
        content: _CostCenterForm(
          initialName: costCenter.name,
          initialDescription: costCenter.description,
          initialCode: costCenter.code,
          initialBudget: costCenter.budget,
          initialResponsible: costCenter.responsible,
          initialDepartment: costCenter.department,
          onSave: (name, description, code, budget, responsible, department) {
            final updatedCostCenter = costCenter.copyWith(
              name: name,
              description: description,
              code: code,
              budget: budget,
              responsible: responsible,
              department: department,
              updatedAt: DateTime.now(),
            );
            ref
                .read(costCenterProvider.notifier)
                .updateCostCenter(updatedCostCenter);
            Navigator.of(context).pop();
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteCostCenter(BuildContext context, CostCenter costCenter) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text(
            'Tem certeza que deseja excluir o centro de custo "${costCenter.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(costCenterProvider.notifier).deleteCostCenter(costCenter.id);
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  void _showAddExpenseModal(BuildContext context, CostCenter costCenter) {
    showDialog(
      context: context,
      builder: (context) => ExpenseModal(
        costCenterId: costCenter.id,
        onSave: () {  // Alterado para VoidCallback
          // ref.read(costCenterProvider.notifier).addExpense(costCenter.id, expense);
        },
      ),
    );
  }

  void _showCostCenterDetails(BuildContext context, CostCenter costCenter) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(costCenter.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Descrição', costCenter.description),
              _buildDetailRow('Código', costCenter.code),
              _buildDetailRow('Departamento', costCenter.department),
              _buildDetailRow('Responsável', costCenter.responsible),
              _buildDetailRow(
                  'Orçamento', 'R\$ ${costCenter.budget.toStringAsFixed(2)}'),
              _buildDetailRow(
                  'Gasto', 'R\$ ${costCenter.utilized.toStringAsFixed(2)}'),
              _buildDetailRow('Disponível',
                  'R\$ ${costCenter.remainingBudget.toStringAsFixed(2)}'),
              _buildDetailRow('Utilização',
                  '${costCenter.utilizationPercentage.toStringAsFixed(1)}%'),
              const SizedBox(height: 16),
              Text(
                'Despesas (${costCenter.expenseCount})',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (costCenter.expenses.isEmpty)
                Text(
                  'Nenhuma despesa registrada',
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                )
              else
                Column(
                  children: costCenter.expenses.take(5).map((expense) {
                    return ListTile(
                      dense: true,
                      title: Text(expense.description),
                      subtitle: Text(
                          'R\$ ${expense.amount.toStringAsFixed(2)} - ${expense.category}'),
                      trailing: Text(
                        '${expense.date.day}/${expense.date.month}/${expense.date.year}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    );
                  }).toList(),
                ),
              if (costCenter.expenseCount > 5)
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child:
                      Text('Ver todas as ${costCenter.expenseCount} despesas'),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              _showAddExpenseModal(context, costCenter);
            },
            icon: const Icon(Icons.add),
            label: const Text('Adicionar Despesa'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(value),
        ],
      ),
    );
  }
}

class _CostCenterForm extends StatefulWidget {
  final String? initialName;
  final String? initialDescription;
  final String? initialCode;
  final double? initialBudget;
  final String? initialResponsible;
  final String? initialDepartment;
  final Function(String, String, String, double, String, String) onSave;

  const _CostCenterForm({
    this.initialName,
    this.initialDescription,
    this.initialCode,
    this.initialBudget,
    this.initialResponsible,
    this.initialDepartment,
    required this.onSave,
  });

  @override
  State<_CostCenterForm> createState() => _CostCenterFormState();
}

class _CostCenterFormState extends State<_CostCenterForm> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _codeController;
  late final TextEditingController _budgetController;
  late final TextEditingController _responsibleController;
  late final TextEditingController _departmentController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _descriptionController = TextEditingController(text: widget.initialDescription);
    _codeController = TextEditingController(text: widget.initialCode);
    _budgetController = TextEditingController(
        text: widget.initialBudget?.toStringAsFixed(2) ?? '');
    _responsibleController = TextEditingController(text: widget.initialResponsible);
    _departmentController = TextEditingController(text: widget.initialDepartment);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _codeController.dispose();
    _budgetController.dispose();
    _responsibleController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nome',
              hintText: 'Nome do centro de custo',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Descrição',
              hintText: 'Descrição detalhada',
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _codeController,
            decoration: const InputDecoration(
              labelText: 'Código',
              hintText: 'Código único',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _budgetController,
            decoration: const InputDecoration(
              labelText: 'Orçamento',
              hintText: '0.00',
              prefixText: 'R\$ ',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _responsibleController,
            decoration: const InputDecoration(
              labelText: 'Responsável',
              hintText: 'Nome do responsável',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _departmentController,
            decoration: const InputDecoration(
              labelText: 'Departamento',
              hintText: 'Departamento',
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              if (_nameController.text.isEmpty ||
                  _budgetController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Por favor, preencha todos os campos obrigatórios'),
                  ),
                );
                return;
              }

              final budget = double.tryParse(_budgetController.text) ?? 0.0;
              if (budget <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('O orçamento deve ser maior que zero'),
                  ),
                );
                return;
              }

              widget.onSave(
                _nameController.text,
                _descriptionController.text,
                _codeController.text,
                budget,
                _responsibleController.text,
                _departmentController.text,
              );
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }
}