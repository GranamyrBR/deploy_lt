import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/operations_provider.dart';
import '../widgets/operation_card.dart';
import '../widgets/base_screen_layout.dart';
import '../widgets/standard_search_bar.dart';
import '../widgets/operation_details_modal.dart';
import '../utils/smart_search_mixin.dart';


class OperationsScreen extends ConsumerStatefulWidget {
  const OperationsScreen({super.key});

  @override
  ConsumerState<OperationsScreen> createState() => _OperationsScreenState();
}

class _OperationsScreenState extends ConsumerState<OperationsScreen> 
    with SmartSearchMixin, SingleTickerProviderStateMixin {
  late TabController _tabController;
  final String _selectedFilter = 'all';
  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(operationsProvider.notifier).loadOperations();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreenLayout(
      title: 'Operações',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () => ref.read(operationsProvider.notifier).loadOperations(),
          tooltip: 'Atualizar',
        ),
      ],
      searchBar: StandardSearchBar(
        controller: _searchController,
        hintText: 'Buscar operações...',
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
          // Tabs para diferentes visualizações
          Container(
            color: Theme.of(context).colorScheme.surface,
            child: TabBar(
              controller: _tabController,
              indicatorColor: Theme.of(context).colorScheme.primary,
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              tabs: const [
                Tab(text: 'Todas'),
                Tab(text: 'Pendentes'),
                Tab(text: 'Em Andamento'),
                Tab(text: 'Concluídas'),
              ],
            ),
          ),
          // Conteúdo principal
          Expanded(
            child: Consumer(
              builder: (context, ref, child) {
                final provider = ref.watch(operationsProvider);
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (provider.error != null) {
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
                          provider.error!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => ref.read(operationsProvider.notifier).loadOperations(),
                          child: const Text('Tentar Novamente'),
                        ),
                      ],
                    ),
                  );
                }
                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOperationsList(provider.allOperations, 'Todas as Operações'),
                    _buildOperationsList(provider.pendingOperations, 'Operações Pendentes'),
                    _buildOperationsList(provider.inProgressOperations, 'Operações em Andamento'),
                    _buildOperationsList(provider.completedOperations, 'Operações Concluídas'),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOperationsList(List<Operation> operations, String title) {
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
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                children: [
                  Icon(Icons.info, color: Colors.blue[600]),
                  const SizedBox(height: 8),
                  Text(
                    'Como criar uma operação:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '1. Cadastre o cliente na tela de Clientes\n'
                    '2. Crie uma venda na tela de Vendas\n'
                    '3. Registre o pagamento (integral ou pendente)\n'
                    '4. A operação será criada automaticamente',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[600],
                    ),
                    textAlign: TextAlign.left,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Header com estatísticas
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey[50],
          child: Row(
            children: [
              Icon(Icons.analytics, color: Colors.blue[600]),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue[600],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${operations.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Lista de operações
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => ref.read(operationsProvider.notifier).loadOperations(),
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: operations.length,
              itemBuilder: (context, index) {
                final operation = operations[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: OperationCard(
                    operation: operation,
                    onTap: () => _showOperationDetails(operation),
                    onStatusChanged: (newStatus) {
                      ref.read(operationsProvider.notifier).updateOperationStatus(
                        operation.id,
                        newStatus,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  void _showOperationDetails(Operation operation) {
    OperationDetailsModal.show(context, operation);
  }
}
