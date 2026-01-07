import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/operations_provider.dart';
import '../providers/drivers_provider.dart';
import '../providers/cars_provider.dart';
import '../utils/responsive_utils.dart';
import '../utils/timezone_utils.dart';
import '../widgets/operation_card.dart';
import '../widgets/base_app_bar.dart';
import '../widgets/operation_details_modal.dart';
import '../widgets/digital_clock_widget.dart';
import '../providers/auth_provider.dart';

class OperationsDashboardScreen extends ConsumerStatefulWidget {
  const OperationsDashboardScreen({super.key});

  @override
  ConsumerState<OperationsDashboardScreen> createState() =>
      _OperationsDashboardScreenState();
}

class _OperationsDashboardScreenState
    extends ConsumerState<OperationsDashboardScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _pulseController;
  final String _selectedFilter = 'all';
  bool _showUrgentOnly = false;

  // Estados de filtro
  String? _selectedDriver;
  String? _selectedStatus;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(operationsProvider.notifier).loadOperations();
      ref.read(driversProvider.notifier).loadDrivers();
      ref.read(carsProvider.notifier).loadCars();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final userName = authState.user?.name ?? 'Usuário';
    return Scaffold(
      appBar: BaseAppBar(
        title: 'Dashboard de Operações',
        bottom: _OperationsTabBar(tabController: _tabController),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                const Icon(Icons.person, size: 18),
                const SizedBox(width: 6),
                Text(
                  userName,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(operationsProvider.notifier).loadOperations();
              ref.read(driversProvider.notifier).loadDrivers();
              ref.read(carsProvider.notifier).loadCars();
            },
            tooltip: 'Atualizar',
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context),
            tooltip: 'Filtros',
          ),
        ],
      ),
      body: Consumer(
        builder: (context, ref, child) {
          final operationsState = ref.watch(operationsProvider);
          final driversState = ref.watch(driversProvider);
          final carsState = ref.watch(carsProvider);

          if (operationsState.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (operationsState.error != null) {
            return _buildErrorWidget(context, ref, operationsState.error!);
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(context, ref, operationsState, driversState, carsState),
              _buildOperationsList(
                  context, ref, operationsState.pendingOperations, 'Pendentes'),
              _buildOperationsList(
                  context, ref, operationsState.inProgressOperations, 'Em Andamento'),
              _buildOperationsList(
                  context, ref, operationsState.completedOperations, 'Concluídas'),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showQuickOperationDialog,
        backgroundColor: Colors.orange[600],
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        icon: const Icon(Icons.add),
        label: const Text('Nova Operação'),
      ),
    );
  }

  Widget _buildOverviewTab(BuildContext context, WidgetRef ref, OperationsState operations,
      AsyncValue<List<Driver>> drivers, AsyncValue<List<Car>> cars) {
    final urgentOperations =
        operations.allOperations.where((op) => op.priority == 'high').toList();
    final todayOperations = operations.allOperations
        .where((op) =>
            op.scheduledDate.day == DateTime.now().day &&
            op.scheduledDate.month == DateTime.now().month &&
            op.scheduledDate.year == DateTime.now().year)
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Relógio digital com horários mundiais
          const DigitalClockWidget(),

          const SizedBox(height: 24),

          // Cards de estatísticas removidos para liberar espaço
          // _buildStatsCards(operations, drivers, cars),

          // const SizedBox(height: 24),

          // Operações urgentes
          if (urgentOperations.isNotEmpty) ...[
            _buildUrgentOperationsSection(context, urgentOperations),
            const SizedBox(height: 24),
          ],

          // Operações de hoje
          if (todayOperations.isNotEmpty) ...[
            _buildTodayOperationsSection(context, todayOperations),
            const SizedBox(height: 24),
          ],

          // Timeline de operações
          _buildOperationsTimeline(context, operations.allOperations),

          const SizedBox(height: 24),

          // Próximas operações
          _buildUpcomingOperationsSection(context, operations.allOperations),
        ],
      ),
    );
  }

  Widget _buildStatsCards(OperationsState operations,
      AsyncValue<List<Driver>> drivers, AsyncValue<List<Car>> cars) {
    final pendingCount = operations.pendingOperations.length;
    final inProgressCount = operations.inProgressOperations.length;
    final completedCount = operations.completedOperations.length;
    final urgentCount =
        operations.allOperations.where((op) => op.priority == 'high').length;

    final needsCompact = ResponsiveUtils.needsCompactLayout(context);

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: needsCompact ? 3.0 : 2.5,
      children: [
        _buildStatCard(
          'Pendentes',
          pendingCount.toString(),
          Icons.schedule,
          Colors.orange,
          () => _tabController.animateTo(1),
        ),
        _buildStatCard(
          'Em Andamento',
          inProgressCount.toString(),
          Icons.play_circle,
          Colors.blue,
          () => _tabController.animateTo(2),
        ),
        _buildStatCard(
          'Concluídas',
          completedCount.toString(),
          Icons.check_circle,
          Colors.green,
          () => _tabController.animateTo(3),
        ),
        _buildStatCard(
          'Urgentes',
          urgentCount.toString(),
          Icons.priority_high,
          Colors.red,
          () => _showUrgentOnly = true,
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color,
      VoidCallback? onTap) {
    final needsCompact = ResponsiveUtils.needsCompactLayout(context);

    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding:
              needsCompact ? const EdgeInsets.all(8) : const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: 0.1),
                color.withValues(alpha: 0.05)
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: needsCompact ? 20 : 24, color: color),
              SizedBox(height: needsCompact ? 2 : 4),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
              ),
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUrgentOperationsSection(BuildContext context, List<Operation> urgentOperations) {
    return Card(
      elevation: 4,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [Colors.red[50]!, Colors.red[100]!],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: 1.0 + (0.1 * _pulseController.value),
                        child: Icon(Icons.priority_high,
                            color: Colors.red[600], size: 24),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Operações Urgentes',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.red[700],
                        ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red[600],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${urgentOperations.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...urgentOperations
                  .take(3)
                  .map((operation) => _buildUrgentOperationItem(operation)),
              if (urgentOperations.length > 3)
                TextButton(
                  onPressed: () => _tabController.animateTo(1),
                  child:
                      Text('Ver todas as ${urgentOperations.length} urgentes'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUrgentOperationItem(Operation operation) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.red[600],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  operation.customerName ?? 'Cliente não especificado',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  operation.serviceName ?? operation.productName ?? 'Operação',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                Text(
                  '${DateFormat('HH:mm').format(TimezoneUtils.convertToNewYork(operation.scheduledDate))} (NYC) - ${operation.pickupLocation ?? 'Local não definido'}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.assignment, color: Colors.blue),
            onPressed: () => _assignDriverToOperation(operation),
            tooltip: 'Atribuir motorista',
          ),
        ],
      ),
    );
  }

  Widget _buildTodayOperationsSection(BuildContext context, List<Operation> todayOperations) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.today, color: Colors.blue[600]),
                const SizedBox(width: 8),
                Text(
                  'Operações de Hoje',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(width: 8),
                Text(
                  '(${DateFormat('dd/MM/yyyy').format(DateTime.now())})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue[600],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${todayOperations.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...todayOperations
                .map((operation) => _buildTodayOperationItem(context, operation)),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayOperationItem(BuildContext context, Operation operation) {
    final timeUntil = operation.scheduledDate.difference(DateTime.now());
    final isOverdue = timeUntil.isNegative;
    final isUpcoming = timeUntil.inMinutes <= 30 && timeUntil.inMinutes > 0;

    return GestureDetector(
      onTap: () => OperationDetailsModal.show(context, operation),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isOverdue
              ? Colors.red[50]
              : isUpcoming
                  ? Colors.orange[50]
                  : Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isOverdue
                ? Colors.red[200]!
                : isUpcoming
                    ? Colors.orange[200]!
                    : Colors.grey[200]!,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 40,
              decoration: BoxDecoration(
                color: isOverdue
                    ? Colors.red
                    : isUpcoming
                        ? Colors.orange
                        : Colors.grey,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        operation.customerName ?? 'Cliente não especificado',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getStatusColor(operation.status),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          operation.statusText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    operation.serviceName ?? operation.productName ?? 'Operação',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  Text(
                    '${DateFormat('HH:mm').format(TimezoneUtils.convertToNewYork(operation.scheduledDate))} (NYC) - ${operation.pickupLocation ?? 'Local não definido'}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  if (isOverdue)
                    Text(
                      'ATRASADO há ${timeUntil.inHours.abs()}h ${timeUntil.inMinutes.abs() % 60}min',
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    )
                  else if (isUpcoming)
                    Text(
                      'Em ${timeUntil.inMinutes} minutos',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.assignment, color: Colors.blue),
                  onPressed: () => _assignDriverToOperation(operation),
                  tooltip: 'Atribuir motorista',
                ),
                IconButton(
                  icon: const Icon(Icons.update, color: Colors.green),
                  onPressed: () => _updateOperationStatus(operation),
                  tooltip: 'Atualizar status',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOperationsTimeline(BuildContext context, List<Operation> operations) {
    final recentOperations = operations
        .where((op) => op.updatedAt
            .isAfter(DateTime.now().subtract(const Duration(days: 7))))
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.timeline, color: Colors.purple[600]),
                const SizedBox(width: 8),
                Text(
                  'Timeline de Operações',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (recentOperations.isEmpty)
              Center(
                child: Column(
                  children: [
                    Icon(Icons.timeline, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text(
                      'Nenhuma operação recente',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              )
            else
              Column(
                children: recentOperations
                    .take(5)
                    .map((operation) => _buildTimelineItem(context, operation))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(BuildContext context, Operation operation) {
    return GestureDetector(
      onTap: () => OperationDetailsModal.show(context, operation),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: _getStatusColor(operation.status),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${operation.customerName ?? 'Cliente não especificado'} - ${operation.serviceName ?? operation.productName ?? 'Operação'}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Status: ${operation.statusText}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  Text(
                    DateFormat('dd/MM HH:mm').format(operation.updatedAt),
                    style: TextStyle(color: Colors.grey[500], fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingOperationsSection(BuildContext context, List<Operation> operations) {
    final upcomingOperations = operations
        .where((op) => op.scheduledDate.isAfter(DateTime.now()))
        .toList()
      ..sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.upcoming, color: Colors.green[600]),
                const SizedBox(width: 8),
                Text(
                  'Próximas Operações',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green[600],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${upcomingOperations.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (upcomingOperations.isEmpty)
              Center(
                child: Column(
                  children: [
                    Icon(Icons.upcoming, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text(
                      'Nenhuma operação agendada',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              )
            else
              Column(
                children: upcomingOperations
                    .take(5)
                    .map((operation) => _buildUpcomingOperationItem(context, operation))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingOperationItem(BuildContext context, Operation operation) {
    final daysUntil = operation.scheduledDate.difference(DateTime.now()).inDays;
    final hoursUntil =
        operation.scheduledDate.difference(DateTime.now()).inHours;

    return GestureDetector(
      onTap: () => OperationDetailsModal.show(context, operation),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green[200]!),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    operation.customerName ?? 'Cliente não especificado',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    operation.serviceName ?? operation.productName ?? 'Operação',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  Text(
                    '${DateFormat('dd/MM HH:mm').format(TimezoneUtils.convertToNewYork(operation.scheduledDate))} (NYC) - ${operation.pickupLocation ?? 'Local não definido'}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  Text(
                    daysUntil > 0
                        ? 'Em $daysUntil dias'
                        : hoursUntil > 0
                            ? 'Em $hoursUntil horas'
                            : 'Em breve',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.assignment, color: Colors.blue),
              onPressed: () => _assignDriverToOperation(operation),
              tooltip: 'Atribuir motorista',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOperationsList(BuildContext context, WidgetRef ref, List<Operation> operations, String title) {
    if (operations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhuma operação encontrada',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'As operações são criadas automaticamente através do funil de vendas',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[500],
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: operations.length,
      itemBuilder: (context, index) {
        final operation = operations[index];
        return OperationCard(
          operation: operation,
          onTap: () => _showOperationDetails(context, operation),
          onStatusChanged: (newStatus) => _updateOperationStatus(operation),
        );
      },
    );
  }

  Widget _buildErrorWidget(BuildContext context, WidgetRef ref, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            'Erro ao carregar operações',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () =>
                ref.read(operationsProvider.notifier).loadOperations(),
            child: const Text('Tentar Novamente'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'assigned':
        return Colors.blue;
      case 'in_progress':
        return Colors.purple;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtros'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Filtros aqui
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Aplicar filtros
            },
            child: const Text('Aplicar'),
          ),
        ],
      ),
    );
  }

  void _showQuickOperationDialog() {
    // Implementar criação rápida de operação
  }

  void _assignDriverToOperation(Operation operation) {
    // Implementar atribuição de motorista
  }

  void _updateOperationStatus(Operation operation) {
    // Implementar atualização de status
  }

  void _showOperationDetails(BuildContext context, Operation operation) {
    OperationDetailsModal.show(context, operation);
  }
}

class _OperationsTabBar extends ConsumerWidget implements PreferredSizeWidget {
  final TabController tabController;

  const _OperationsTabBar({required this.tabController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final operationsState = ref.watch(operationsProvider);
    final pendingCount = operationsState.pendingOperations.length;
    final inProgressCount = operationsState.inProgressOperations.length;
    final completedCount = operationsState.completedOperations.length;

    return TabBar(
      controller: tabController,
      indicatorColor: Colors.white,
      tabs: [
        const Tab(child: Text('Visão Geral', style: TextStyle(color: Colors.white))),
        Tab(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Pendentes', style: TextStyle(color: Colors.white)),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$pendingCount',
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
        Tab(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Em Andamento', style: TextStyle(color: Colors.white)),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$inProgressCount',
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
        Tab(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Concluídas', style: TextStyle(color: Colors.white)),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$completedCount',
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
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
