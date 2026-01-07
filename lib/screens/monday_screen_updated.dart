import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../design/design_tokens.dart';
import '../widgets/base_components.dart';
import '../providers/monday_provider_updated.dart';
import '../widgets/base_screen_layout.dart';
import '../widgets/standard_search_bar.dart';
import '../utils/smart_search_mixin.dart';


class MondayScreenUpdated extends ConsumerStatefulWidget {
  const MondayScreenUpdated({super.key});

  @override
  ConsumerState<MondayScreenUpdated> createState() => _MondayScreenUpdatedState();
}

class _MondayScreenUpdatedState extends ConsumerState<MondayScreenUpdated> with SmartSearchMixin {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _selectedStatus = 'all';
  String _searchTerm = '';

  @override
  void initState() {
    super.initState();
    // Carregar todos os registros para o filtro funcionar corretamente
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(mondayPaginationProviderUpdated.notifier).loadAllEntries();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _showDetailPopup(MondayEntryWithReferences entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.person, color: DesignTokens.primaryBlue),
            const SizedBox(width: 8),
            Text('Detalhes do Registro #${entry.contactId}'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Informações principais em grid 2x2
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCompactDetailRow('Nome', entry.name ?? 'Não informado'),
                        _buildCompactDetailRow('Email', entry.email ?? 'Não informado'),
                        _buildCompactDetailRow('Telefone', entry.phone ?? 'Não informado'),
                        _buildCompactDetailRow('Cidade', entry.city ?? 'Não informado'),
                        _buildCompactDetailRow('Gênero', entry.gender ?? 'Não informado'),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCompactDetailRow('Status', entry.status ?? 'Não informado'),
                        _buildCompactDetailRow('Fonte', entry.source ?? 'Não informado'),
                        _buildCompactDetailRow('Conta', entry.account ?? 'Não informado'),
                        _buildCompactDetailRow('Vendedor', entry.vendedor ?? 'Não informado'),
                        _buildCompactDetailRow('Serviços', entry.servicos ?? 'Não informado'),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Datas em linha única
              Row(
                children: [
                  Expanded(
                    child: _buildCompactDetailRow('Data Contato', entry.contactDate ?? 'Não informado'),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildCompactDetailRow('Data Fechamento', entry.closingDate ?? 'Não informado'),
                  ),
                ],
              ),
              
              Row(
                children: [
                  Expanded(
                    child: _buildCompactDetailRow('Dias Viagem', entry.diasViagem ?? 'Não informado'),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildCompactDetailRow('Dia Fechamento', entry.closingDay ?? 'Não informado'),
                  ),
                ],
              ),
              
              Row(
                children: [
                  Expanded(
                    child: _buildCompactDetailRow('Previsão Início', entry.previsaoStart ?? 'Não informado'),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildCompactDetailRow('Previsão Fim', entry.previsaoEnd ?? 'Não informado'),
                  ),
                ],
              ),
              
              Row(
                children: [
                  Expanded(
                    child: _buildCompactDetailRow('ID Monday', entry.mondayId ?? 'Não informado'),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildCompactDetailRow('Tipo Cliente', entry.customerType ?? 'Não informado'),
                  ),
                ],
              ),
              
              // Observações e logs em containers destacados
              if (entry.observacao != null && entry.observacao!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Observação',
                        style: DesignTokens.bodySmall.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        entry.observacao!,
                        style: DesignTokens.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
              
              if (entry.log != null && entry.log!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Log',
                        style: DesignTokens.bodySmall.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        entry.log!,
                        style: DesignTokens.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
              
              if (entry.logAtual != null && entry.logAtual!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Log Atual',
                        style: DesignTokens.bodySmall.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        entry.logAtual!,
                        style: DesignTokens.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: DesignTokens.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: DesignTokens.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactCard(MondayEntryWithReferences entry) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _showDetailPopup(entry),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
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
                          entry.name ?? 'Sem nome',
                          style: DesignTokens.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (entry.email != null && entry.email!.isNotEmpty)
                          Text(
                            entry.email!,
                            style: DesignTokens.bodySmall.copyWith(
                              color: Colors.grey.shade600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        if (entry.phone != null && entry.phone!.isNotEmpty)
                          Text(
                            entry.phone!,
                            style: DesignTokens.bodySmall.copyWith(
                              color: Colors.grey.shade600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(entry.status ?? '').withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _getStatusColor(entry.status ?? '').withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          entry.status ?? 'Sem status',
                          style: DesignTokens.bodySmall.copyWith(
                            color: _getStatusColor(entry.status ?? ''),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (entry.city != null && entry.city!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          entry.city!,
                          style: DesignTokens.bodySmall.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Informações adicionais
              if (entry.source != null || entry.account != null || entry.vendedor != null)
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    if (entry.source != null)
                      _buildInfoChip('Fonte', entry.source!),
                    if (entry.account != null)
                      _buildInfoChip('Conta', entry.account!),
                    if (entry.vendedor != null)
                      _buildInfoChip('Vendedor', entry.vendedor!),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$label: $value',
        style: DesignTokens.bodySmall.copyWith(
          color: Colors.grey.shade700,
          fontSize: 10,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'lead':
        return Colors.blue;
      case 'prospect':
        return Colors.orange;
      case 'negociado':
        return Colors.green;
      case 'lead perdido':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'lead':
        return 'Lead';
      case 'prospect':
        return 'Prospect';
      case 'negociado':
        return 'Negociado';
      case 'lead perdido':
        return 'Lead Perdido';
      default:
        return status;
    }
  }

  List<MondayEntryWithReferences> _getFilteredEntries(List<MondayEntryWithReferences> entries) {
    if (_searchTerm.isEmpty) return entries;
    
    return entries.where((entry) {
      // Converter MondayEntryWithReferences para Map para usar o mixin
      final entryMap = {
        'id': entry.contactId,
        'name': entry.name,
        'email': entry.email,
        'phone': entry.phone,
        'city': entry.city,
        'status': entry.status,
        'source': entry.source,
        'account': entry.account,
        'vendedor': entry.vendedor,
        'servicos': entry.servicos,
      };
      
      return smartSearch(
        entryMap, 
        _searchTerm,
        nameField: 'name',
        phoneField: 'phone',
        emailField: 'email',
        cityField: 'city',
        additionalFields: 'vendedor',
      );
    }).toList();
  }

  Widget _buildStatusFilter(List<MondayEntryWithReferences> entries) {
    final filteredEntries = _getFilteredEntries(entries);
    final statusCounts = ref.watch(mondayStatsProvider);
    
    final statusOptions = ['all', 'lead', 'prospect', 'negociado', 'lead perdido'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: statusOptions.map((status) {
          final count = statusCounts[status] ?? 0;
          final isSelected = _selectedStatus == status;
          final statusColor = _getStatusColor(status);
          
          return FilterChip(
            selected: isSelected,
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _getStatusLabel(status),
                  style: TextStyle(
                    color: isSelected 
                        ? Theme.of(context).colorScheme.onPrimary 
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? Theme.of(context).colorScheme.onPrimary 
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    count.toString(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isSelected 
                          ? Theme.of(context).colorScheme.primary 
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            onSelected: (selected) {
              setState(() {
                _selectedStatus = status;
              });
            },
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            selectedColor: statusColor.withValues(alpha: 0.2),
            checkmarkColor: statusColor,
            side: BorderSide(
              color: isSelected 
                  ? statusColor 
                  : Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildKanbanView() {
    final mondayState = ref.watch(mondayPaginationProviderUpdated);
    final filteredEntries = _getFilteredEntries(mondayState.entries);
    
    final columns = [
      {'status': 'lead', 'title': 'Leads', 'color': Colors.blue},
      {'status': 'prospect', 'title': 'Prospects', 'color': Colors.orange},
      {'status': 'negociado', 'title': 'Negociados', 'color': Colors.green},
      {'status': 'lead perdido', 'title': 'Leads Perdidos', 'color': Colors.red},
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: columns.map((column) {
        final status = column['status'] as String;
        final title = column['title'] as String;
        final color = column['color'] as Color;
        final columnEntries = filteredEntries.where((entry) => 
            entry.status?.toLowerCase() == status).toList();

        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              children: [
                // Header da coluna
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                    border: Border.all(color: color.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: color,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          columnEntries.length.toString(),
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
                
                // Cards da coluna
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerLowest,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(8),
                        bottomRight: Radius.circular(8),
                      ),
                      border: Border.all(color: color.withValues(alpha: 0.3)),
                    ),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: columnEntries.length,
                      itemBuilder: (context, index) {
                        return _buildCompactCard(columnEntries[index]);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildListView() {
    final mondayState = ref.watch(mondayPaginationProviderUpdated);
    final filteredEntries = _getFilteredEntries(mondayState.entries);
    final statusFilteredEntries = _selectedStatus == 'all' 
        ? filteredEntries 
        : filteredEntries.where((entry) => entry.status?.toLowerCase() == _selectedStatus).toList();

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(20),
      itemCount: statusFilteredEntries.length,
      itemBuilder: (context, index) {
        return _buildCompactCard(statusFilteredEntries[index]);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final mondayState = ref.watch(mondayPaginationProviderUpdated);

    return BaseScreenLayout(
      title: 'Monday.com',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () {
            ref.read(mondayPaginationProviderUpdated.notifier).refresh();
          },
        ),
      ],
      searchBar: StandardSearchBar(
        controller: _searchController,
        hintText: 'Buscar por nome, email ou telefone...',
        onChanged: (value) {
          setState(() {
            _searchTerm = value;
          });
          ref.read(mondayPaginationProviderUpdated.notifier).search(value);
        },
        onClear: () {
          setState(() {
            _searchTerm = '';
          });
          ref.read(mondayPaginationProviderUpdated.notifier).search('');
        },
      ),
      child: Column(
        children: [

          // Filtros de status
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildStatusFilter(mondayState.entries),
          ),

          const SizedBox(height: 16),

          // Conteúdo principal
          Expanded(
            child: mondayState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : mondayState.error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Erro ao carregar dados',
                              style: DesignTokens.bodyLarge.copyWith(
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              mondayState.error!,
                              style: DesignTokens.bodySmall.copyWith(
                                color: Colors.grey.shade500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                ref.read(mondayPaginationProviderUpdated.notifier).refresh();
                              },
                              child: const Text('Tentar Novamente'),
                            ),
                          ],
                        ),
                      )
                    : _selectedStatus == 'all'
                        ? _buildKanbanView()
                        : _buildListView(),
          ),
        ],
      ),
    );
  }
} 
