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
import '../widgets/cost_center_syncfusion_dashboard.dart';
import '../widgets/expense_modal.dart';
import '../widgets/base_screen_layout.dart';

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
  final String _searchQuery = '';
  int _selectedTabIndex = 0; // 0 para Lista, 1 para KPI Dashboard, 2 para Temporal Dashboard, 3 para Gráficos Avançados, 4 para Gráficos Compreensivos, 5 para Gráficos Aprimorados, 6 para Syncfusion Professional
  late TabController _tabController;

  final List<Map<String, String>> _filters = [
    {'value': 'all', 'label': 'Todos'},
    {'value': 'over_budget', 'label': 'Acima do Orçamento'},
    {'value': 'under_budget', 'label': 'Dentro do Orçamento'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this, initialIndex: _selectedTabIndex);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      setState(() { _selectedTabIndex = _tabController.index; });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(costCenterProvider.notifier).loadCostCenters();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return BaseScreenLayout(
      title: 'Centros de Custo',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'Recarregar dados',
          onPressed: () => ref.read(costCenterProvider.notifier).loadCostCenters(),
        ),
        IconButton(
          icon: const Icon(Icons.add_business),
          tooltip: 'Adicionar centro de custo',
          onPressed: () => _showAddCostCenterModal(context),
        ),
      ],
      child: Consumer(
        builder: (context, ref, child) {
          final provider = ref.watch(costCenterProvider);
          final costCenters = provider.costCenters;
          final labelColor = Theme.of(context).colorScheme.primary;
          final unselectedColor = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7);
          
          // Tab header moved into content to avoid black icons and unify app bar
          final tabHeader = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: labelColor,
                unselectedLabelColor: unselectedColor,
                indicatorColor: labelColor,
                tabs: const [
                  Tab(icon: Icon(Icons.list), text: 'Lista'),
                  Tab(icon: Icon(Icons.analytics), text: 'KPI Dashboard'),
                  Tab(icon: Icon(Icons.trending_up), text: 'Tendências'),
                  Tab(icon: Icon(Icons.show_chart), text: 'Avançado'),
                  Tab(icon: Icon(Icons.radar), text: 'Compreensivo'),
                  Tab(icon: Icon(Icons.speed), text: 'Aprimorado'),
                  Tab(icon: Icon(Icons.pie_chart), text: 'Syncfusion Pro'),
                ],
              ),
              const SizedBox(height: 16),
            ],
          );

          // Render selected tab content
          if (_selectedTabIndex == 1) {
            // KPI Dashboard Tab
            return RefreshIndicator(
              onRefresh: () =>
                  ref.read(costCenterProvider.notifier).loadCostCenters(),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    tabHeader,
                    CostCenterKpiDashboard(costCenters: costCenters),
                  ],
                ),
              ),
            );
          }

          if (_selectedTabIndex == 2) {
            // Temporal Dashboard Tab
            return RefreshIndicator(
              onRefresh: () =>
                  ref.read(costCenterProvider.notifier).loadCostCenters(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    tabHeader,
                    CostCenterTemporalDashboard(costCenters: costCenters),
                  ],
                ),
              ),
            );
          }

          if (_selectedTabIndex == 3) {
            // Advanced Charts Tab
            return RefreshIndicator(
              onRefresh: () =>
                  ref.read(costCenterProvider.notifier).loadCostCenters(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    tabHeader,
                    CostCenterAdvancedCharts(costCenters: costCenters),
                  ],
                ),
              ),
            );
          }

          if (_selectedTabIndex == 4) {
            // Comprehensive Charts Tab
            return RefreshIndicator(
              onRefresh: () =>
                  ref.read(costCenterProvider.notifier).loadCostCenters(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    tabHeader,
                    CostCenterComprehensiveCharts(costCenters: costCenters),
                  ],
                ),
              ),
            );
          }

          if (_selectedTabIndex == 5) {
            // Enhanced Charts Tab
            return RefreshIndicator(
              onRefresh: () =>
                  ref.read(costCenterProvider.notifier).loadCostCenters(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    tabHeader,
                    CostCenterEnhancedCharts(costCenters: costCenters),
                  ],
                ),
              ),
            );
          }

          if (_selectedTabIndex == 6) {
            // Syncfusion Professional Dashboard Tab
            return RefreshIndicator(
              onRefresh: () =>
                  ref.read(costCenterProvider.notifier).loadCostCenters(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    tabHeader,
                    CostCenterSyncfusionDashboard(costCenters: costCenters),
                  ],
                ),
              ),
            );
          }

          // Lista Tab (conteúdo original)
          final totalBudget = provider.totalBudget;
          final totalUtilized = provider.totalUtilized;
          final totalRemaining = provider.totalRemaining;
          final overallUtilizationPercentage =
              provider.overallUtilizationPercentage;

          // Apply local filters
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
                SliverToBoxAdapter(child: tabHeader),
                // Resumo geral
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Card de resumo
                        Card(
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Resumo Geral',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.info_outline),
                                      onPressed: () => _showSummaryInfo(context),
                                      tooltip: 'Informações',
                                    ),
                                  ],
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Utilização Geral',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium,
                                        ),
                                        Text(
                                          '${overallUtilizationPercentage.toStringAsFixed(1)}%',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: overallUtilizationPercentage >
                                                        90
                                                    ? Colors.red
                                                    : overallUtilizationPercentage >
                                                            70
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
                                        value: overallUtilizationPercentage /
                                            100,
                                        backgroundColor: isDarkMode
                                            ? Colors.white.withValues(alpha: 0.1)
                                            : Colors.black.withValues(alpha: 0.1),
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          overallUtilizationPercentage > 90
                                              ? Colors.red
                                              : overallUtilizationPercentage >
                                                      70
                                                  ? Colors.orange
                                                  : Colors.green,
                                        ),
                                        minHeight: 8,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // Filtros e busca
                                Row(
                                  children: [
                                    // Campo de busca
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

                                    // Filtro
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
                                            setState(
                                                () => _selectedFilter = value);
                                          }
                                        },
                                        hint: const Text('Selecione um filtro'),
                                      ),
                                    ),
                                    const SizedBox(width: 16),

                                    // Botão de limpar filtros
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

                // Conteúdo principal
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
                            color:
                                isDarkMode ? Colors.white38 : Colors.grey[400],
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
                  ..._buildCostCentersList(provider, filteredCostCenters, isDarkMode),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildCostCentersList(
    CostCenterProvider provider,
    List<CostCenter> costCenters,
    bool isDarkMode,
  ) {
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            '${costCenters.length} centro${costCenters.length > 1 ? 's' : ''} de custo${costCenters.length > 1 ? 's' : ''}',
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.white54 : Colors.grey[600],
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
              onTap: () =>
                  _showCostCenterDetails(context, costCenter, provider),
              onEdit: () => _showEditCostCenterModal(context, costCenter),
              onDelete: () => _showDeleteCostCenterDialog(context, costCenter),
              onAddExpense: () =>
                  _showAddExpenseModal(context, costCenter, provider),
            );
          },
          childCount: costCenters.length,
        ),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: 32)),
    ];
  }

  void _showCostCenterDetails(
    BuildContext context,
    CostCenter costCenter,
    CostCenterProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(costCenter.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (costCenter.description.isNotEmpty) ...[
                Text(
                  costCenter.description,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
              ],
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
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white54
                        : Colors.grey[600],
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
                    // Navegar para detalhes completos
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
              _showAddExpenseModal(context, costCenter, provider);
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

  void _showSummaryInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Informações do Resumo'),
        content: const Text(
          'Este resumo mostra a visão geral de todos os centros de custo.\n\n'
          '• Orçamento Total: Soma de todos os orçamentos\n'
          '• Total Utilizado: Soma de todos os gastos\n'
          '• Saldo Disponível: Orçamento total menos gastos\n'
          '• Utilização Geral: Percentual de orçamento utilizado',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendi'),
          ),
        ],
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

  void _showDeleteCostCenterDialog(
      BuildContext context, CostCenter costCenter) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Centro de Custo'),
        content: Text(
            'Tem certeza que deseja excluir o centro de custo "${costCenter.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              ref
                  .read(costCenterProvider.notifier)
                  .deleteCostCenter(costCenter.id);
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  void _showAddExpenseModal(BuildContext context, CostCenter costCenter,
      CostCenterProvider provider) {
    showDialog(
      context: context,
      builder: (context) => ExpenseModal(
        costCenterId: costCenter.id,
        onSave: () => provider.loadCostCenters(),
      ),
    ).then((result) {
      if (result != null && result is Expense) {
        provider.addExpense(costCenter.id, result);
      }
    });
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
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _codeController;
  late TextEditingController _budgetController;
  late TextEditingController _responsibleController;
  late TextEditingController _departmentController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _descriptionController =
        TextEditingController(text: widget.initialDescription ?? '');
    _codeController = TextEditingController(text: widget.initialCode ?? '');
    _budgetController = TextEditingController(
        text: widget.initialBudget?.toStringAsFixed(2) ?? '0.00');
    _responsibleController =
        TextEditingController(text: widget.initialResponsible ?? '');
    _departmentController =
        TextEditingController(text: widget.initialDepartment ?? '');
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

  void _handleSave() {
    if (_formKey.currentState!.validate()) {
      widget.onSave(
        _nameController.text.trim(),
        _descriptionController.text.trim(),
        _codeController.text.trim(),
        double.tryParse(_budgetController.text) ?? 0.0,
        _responsibleController.text.trim(),
        _departmentController.text.trim(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nome *',
                hintText: 'Ex: Marketing, TI, RH',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Por favor, insira o nome';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _codeController,
              decoration: const InputDecoration(
                labelText: 'Código *',
                hintText: 'Ex: CC-001',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Por favor, insira o código';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descrição',
                hintText: 'Descreva o propósito deste centro de custo',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _budgetController,
              decoration: const InputDecoration(
                labelText: 'Orçamento *',
                hintText: '0.00',
                border: OutlineInputBorder(),
                prefixText: 'R\$ ',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Por favor, insira o orçamento';
                }
                if (double.tryParse(value) == null) {
                  return 'Por favor, insira um número válido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _responsibleController,
              decoration: const InputDecoration(
                labelText: 'Responsável *',
                hintText: 'Nome do responsável',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Por favor, insira o responsável';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _departmentController,
              decoration: const InputDecoration(
                labelText: 'Departamento *',
                hintText: 'Ex: Financeiro, Operações',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Por favor, insira o departamento';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _handleSave,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }
}