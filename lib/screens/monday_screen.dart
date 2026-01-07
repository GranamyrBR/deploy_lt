import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../design/design_tokens.dart';
import '../widgets/base_components.dart';
import '../providers/monday_provider.dart';
import '../models/monday_entry.dart';
import '../widgets/base_screen_layout.dart';
import '../widgets/standard_search_bar.dart';
import '../utils/smart_search_mixin.dart';


class MondayScreen extends ConsumerStatefulWidget {
  const MondayScreen({super.key});

  @override
  ConsumerState<MondayScreen> createState() => _MondayScreenState();
}

class _MondayScreenState extends ConsumerState<MondayScreen> with SmartSearchMixin {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _selectedStatus = 'all';
  String _searchTerm = '';

  @override
  void initState() {
    super.initState();
    // Carregar todos os registros para o filtro funcionar corretamente
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(mondayPaginationProvider.notifier).loadAllEntries();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _showDetailPopup(MondayEntry entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.person, color: DesignTokens.primaryBlue),
            const SizedBox(width: 8),
            Text('Detalhes do Registro #${entry.id}'),
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
                        _buildCompactDetailRow('Telefone', entry.telefone ?? 'Não informado'),
                        _buildCompactDetailRow('Cidade', entry.cidade ?? 'Não informado'),
                        _buildCompactDetailRow('Sexo', entry.sexo ?? 'Não informado'),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCompactDetailRow('Status', entry.contactCategoryName ?? 'Não informado'),
                        _buildCompactDetailRow('Tipo', entry.tipo ?? 'Não informado'),
                        _buildCompactDetailRow('Vendedor', entry.vendedor ?? 'Não informado'),
                        _buildCompactDetailRow('Serviços', entry.servicos ?? 'Não informado'),
                        _buildCompactDetailRow('Fonte', entry.font ?? 'Não informado'),
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
                    child: _buildCompactDetailRow('Data Contato', entry.dataContato ?? 'Não informado'),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildCompactDetailRow('Data Fechamento', entry.dataFechamento ?? 'Não informado'),
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
                    child: _buildCompactDetailRow('Dia Fechamento', entry.diaFechamento ?? 'Não informado'),
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
                    child: _buildCompactDetailRow('Contas', entry.contas ?? 'Não informado'),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildCompactDetailRow('ID Monday', entry.idMonday ?? 'Não informado'),
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
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: DesignTokens.bodySmall.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
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

  @override
  Widget build(BuildContext context) {
    final mondayState = ref.watch(mondayPaginationProvider);
    final countAsync = ref.watch(mondayCountProvider);

    return BaseScreenLayout(
      title: 'Tabela Monday',
      actions: [
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () => _showCreateDialog(),
          tooltip: 'Adicionar novo registro',
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () {
            ref.read(mondayPaginationProvider.notifier).loadAllEntries();
            ref.invalidate(mondayCountProvider);
          },
          tooltip: 'Atualizar',
        ),
      ],
      searchBar: StandardSearchBar(
        controller: _searchController,
        hintText: 'Buscar por nome, email, telefone, cidade, vendedor...',
        onChanged: (v) {
          setState(() {
            _searchTerm = v.trim().toLowerCase();
          });
        },
      ),
      child: Column(
        children: [
          // Informações de contagem
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                countAsync.when(
                  data: (count) => Text(
                    'Total: $count | Carregados: ${_getFilteredEntries(mondayState.entries).length}',
                    style: DesignTokens.bodyMedium.copyWith(
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  loading: () => CircularProgressIndicator(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  error: (_, __) => Text(
                    'Erro ao contar registros',
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    'Todos os registros carregados',
                    style: DesignTokens.bodySmall.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Layout Kanban
          Expanded(
            child: mondayState.error != null
                ? _buildErrorWidget(mondayState.error!)
                : mondayState.entries.isEmpty && !mondayState.isLoading
                    ? const Center(
                        child: Text('Nenhum registro encontrado'),
                      )
                    : _selectedStatus == 'all'
                        ? _buildKanbanView(mondayState)
                        : _buildListView(mondayState),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilter(MondayPaginationState state) {
    final filteredEntries = _getFilteredEntries(state.entries);
    
    // Calcular contagens em tempo real
    final statusCounts = {
      'all': filteredEntries.length,
      'Lead': filteredEntries.where((e) => e.contactCategoryName?.toLowerCase() == 'lead').length,
      'Prospect': filteredEntries.where((e) => e.contactCategoryName?.toLowerCase() == 'prospect').length,
      'Negociado': filteredEntries.where((e) => e.contactCategoryName?.toLowerCase() == 'negociado').length,
      'Lead Perdido': filteredEntries.where((e) => e.contactCategoryName?.toLowerCase() == 'lead perdido').length,
    };

    final status = ['all', 'Lead', 'Prospect', 'Negociado', 'Lead Perdido'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: status.map((status) {
          final count = statusCounts[status] ?? 0;
          final isSelected = _selectedStatus == status;
          final statusColor = _getStatusColor(status);
          final isAll = status == 'all';
          return FilterChip(
            selected: isSelected,
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _getStatusLabel(status),
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : (isAll ? Theme.of(context).colorScheme.onSurface : statusColor),
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.15)
                        : (isAll ? Theme.of(context).colorScheme.surfaceContainerHighest : statusColor.withValues(alpha: 0.08)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    count.toString(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? Colors.white
                          : (isAll ? Theme.of(context).colorScheme.onSurface : statusColor),
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
            backgroundColor: isAll
                ? Theme.of(context).colorScheme.surfaceContainerHighest
                : statusColor.withValues(alpha: isSelected ? 0.8 : 0.15),
            selectedColor: statusColor,
            checkmarkColor: isAll ? Theme.of(context).colorScheme.primary : Colors.white,
            side: BorderSide(
              color: isSelected
                  ? statusColor
                  : (isAll ? Theme.of(context).colorScheme.outline.withValues(alpha: 0.5) : statusColor.withValues(alpha: 0.5)),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildKanbanView(MondayPaginationState state) {
    final filteredEntries = _getFilteredEntries(state.entries);
    final columns = [
      {'status': 'lead', 'title': 'Leads', 'color': const Color(0xFF3B82F6)},
      {'status': 'prospect', 'title': 'Prospects', 'color': const Color(0xFFF59E0B)},
      {'status': 'negociado', 'title': 'Negociados', 'color': const Color(0xFF10B981)},
      {'status': 'lead perdido', 'title': 'Leads Perdidos', 'color': const Color(0xFFEF4444)},
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: columns.map((column) {
        final status = column['status'] as String;
        final title = column['title'] as String;
        final color = column['color'] as Color;
        final columnEntries = filteredEntries.where((entry) => 
            entry.contactCategoryName?.toLowerCase() == status).toList();

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
                
                // Cards da coluna com DragTarget
                Expanded(
                  child: DragTarget<MondayEntry>(
                    onWillAcceptWithDetails: (data) => data != null,
                    onAcceptWithDetails: (details) {
                      _moveCardToCategory(details.data, status);
                    },
                    builder: (context, candidateData, rejectedData) {
                      return Container(
                        decoration: BoxDecoration(
                          color: candidateData.isNotEmpty 
                              ? color.withValues(alpha: 0.05)
                              : Theme.of(context).colorScheme.surfaceContainerLowest,
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(8),
                            bottomRight: Radius.circular(8),
                          ),
                          border: Border.all(
                            color: candidateData.isNotEmpty 
                                ? color.withValues(alpha: 0.5)
                                : color.withValues(alpha: 0.3),
                            width: candidateData.isNotEmpty ? 2 : 1,
                          ),
                        ),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: columnEntries.length,
                          itemBuilder: (context, index) {
                            return _buildDraggableCard(columnEntries[index]);
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDraggableCard(MondayEntry entry) {
    final statusColor = _getStatusColor(entry.contactCategoryName);
    
    return Draggable<MondayEntry>(
      data: entry,
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 280,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: statusColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                entry.name ?? 'Sem nome',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (entry.email != null) ...[
                const SizedBox(height: 4),
                Text(
                  entry.email!,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
      childWhenDragging: Container(
        margin: const EdgeInsets.only(bottom: 8),
        child: Card(
          elevation: 1,
          color: Colors.grey.shade200,
          child: Container(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 12,
                  width: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      child: _buildCompactCard(entry),
    );
  }

  Future<void> _moveCardToCategory(MondayEntry entry, String newCategory) async {
    try {
      // Determinar o ID da nova categoria
      int? newCategoryId;
      switch (newCategory.toLowerCase()) {
        case 'lead':
          newCategoryId = 12;
          break;
        case 'prospect':
          newCategoryId = 13;
          break;
        case 'negociado':
          newCategoryId = 14;
          break;
        case 'lead perdido':
          newCategoryId = 15;
          break;
      }

      if (newCategoryId == null) {
        throw Exception('Categoria inválida: $newCategory');
      }

      // Atualizar no banco de dados
      await Supabase.instance.client
          .from('monday')
          .update({'contact_category_id': newCategoryId})
          .eq('contact_id', entry.id);

      // Aguardar um pouco para garantir que a atualização foi processada
      await Future.delayed(const Duration(milliseconds: 500));

      // Recarregar todos os dados para atualizar as contagens
      await ref.read(mondayPaginationProvider.notifier).loadAllEntries();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${entry.name ?? 'Registro'} movido para $newCategory'),
            backgroundColor: _getStatusColor(newCategory),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao mover card: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildListView(MondayPaginationState state) {
    final filteredEntries = _getFilteredEntries(state.entries);
    final statusFilteredEntries = _selectedStatus == 'all' 
        ? filteredEntries 
        : filteredEntries.where((entry) => entry.contactCategoryName?.toLowerCase() == _selectedStatus.toLowerCase()).toList();

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(20),
      itemCount: statusFilteredEntries.length,
      itemBuilder: (context, index) {
        return _buildCompactCard(statusFilteredEntries[index]);
      },
    );
  }

  Widget _buildCompactCard(MondayEntry entry) {
            final statusColor = _getStatusColor(entry.contactCategoryName);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Card(
        elevation: 2,
        color: Theme.of(context).colorScheme.surface,
        child: InkWell(
          onTap: () => _showDetailPopup(entry),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: statusColor.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header com ID, status e botões de ação
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '#${entry.id} - ${entry.name ?? 'Sem nome'}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Botões de ação
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert, 
                        size: 20,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                      onSelected: (value) => _handleAction(value, entry),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 18, color: Theme.of(context).colorScheme.onSurface),
                              const SizedBox(width: 8),
                              Text('Editar', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 18, color: Theme.of(context).colorScheme.error),
                              const SizedBox(width: 8),
                              Text('Excluir', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Informações principais em grid
                Row(
                  children: [
                    // Coluna esquerda
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow('Email', entry.email ?? '-'),
                          _buildInfoRow('Telefone', entry.telefone ?? '-'),
                          _buildInfoRow('Cidade', entry.cidade ?? '-'),
                        ],
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Coluna direita
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow('Tipo', entry.tipo ?? '-'),
                          _buildInfoRow('Vendedor', entry.vendedor ?? '-'),
                          _buildInfoRow('Data', entry.dataContato ?? '-'),
                        ],
                      ),
                    ),
                  ],
                ),
                
                // Serviços em linha única
                if (entry.servicos != null && entry.servicos!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.work, 
                          size: 16,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            entry.servicos!,
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                // Status discreto no final
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Data de contato se disponível
                    if (entry.dataContato != null && entry.dataContato!.isNotEmpty)
                      Expanded(
                        child: Text(
                          'Contato: ${entry.dataContato}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    
                    // Status discreto
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          entry.contactCategoryName ?? 'N/A',
                          style: TextStyle(
                            fontSize: 10,
                            color: statusColor,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
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
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: DesignTokens.spacing16),
          Text(
            'Erro ao carregar dados',
            style: DesignTokens.titleLarge.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: DesignTokens.spacing8),
          Text(
            error,
            style: DesignTokens.bodyMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: DesignTokens.spacing16),
          ModernButton(
            text: 'Tentar Novamente',
            onPressed: () {
              ref.read(mondayPaginationProvider.notifier).refresh();
            },
            variant: ButtonVariant.primary,
            size: ButtonSize.medium,
            icon: Icons.refresh,
          ),
        ],
      ),
    );
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'all': return 'Todos';
      case 'Lead': return 'Leads';
      case 'Prospect': return 'Prospects';
      case 'Negociado': return 'Negociados';
      case 'Lead Perdido': return 'Leads Perdidos';
      default: return status;
    }
  }

  Color _getStatusColor(String? status) {
    if (status == null) return Colors.grey.shade400;
    switch (status.toLowerCase()) {
      case 'lead':
        return const Color(0xFF3B82F6); // Azul mais suave
      case 'prospect':
        return const Color(0xFFF59E0B); // Laranja mais suave
      case 'negociado':
        return const Color(0xFF10B981); // Verde mais suave
      case 'lead perdido':
        return const Color(0xFFEF4444); // Vermelho mais suave
      default:
        return Colors.grey.shade400;
    }
  }

  void _handleAction(String value, MondayEntry entry) {
    switch (value) {
      case 'edit':
        _showEditDialog(entry);
        break;
      case 'delete':
        _showDeleteConfirmation(entry);
        break;
    }
  }

  void _showDeleteConfirmation(MondayEntry entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Confirmar Exclusão'),
          ],
        ),
        content: Text(
          'Tem certeza que deseja excluir o registro #${entry.id} - ${entry.name ?? 'Sem nome'}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteEntry(entry);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteEntry(MondayEntry entry) async {
    try {
      await Supabase.instance.client
          .from('monday')
          .delete()
          .eq('id', entry.id);

      // Atualizar a lista
      ref.read(mondayPaginationProvider.notifier).refresh();
      ref.invalidate(mondayCountProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registro #${entry.id} excluído com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao excluir registro: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showEditDialog(MondayEntry entry) {
    final nameController = TextEditingController(text: entry.name);
    final emailController = TextEditingController(text: entry.email);
    final telefoneController = TextEditingController(text: entry.telefone);
    final cidadeController = TextEditingController(text: entry.cidade);
    final servicosController = TextEditingController(text: entry.servicos);
    final observacaoController = TextEditingController(text: entry.observacao);
    final vendedorController = TextEditingController(text: entry.vendedor);
    final dataContatoController = TextEditingController(text: entry.dataContato);
    final dataFechamentoController = TextEditingController(text: entry.dataFechamento);
    
    String selectedStatus = entry.contactCategoryName ?? 'Lead';
    String selectedTipo = entry.tipo ?? '';
    String selectedSexo = entry.sexo ?? '';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.edit, color: DesignTokens.primaryBlue),
              const SizedBox(width: 8),
              Text('Editar Registro #${entry.id}'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Informações básicas
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: telefoneController,
                        decoration: const InputDecoration(
                          labelText: 'Telefone',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: cidadeController,
                        decoration: const InputDecoration(
                          labelText: 'Cidade',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedSexo.isNotEmpty ? selectedSexo : null,
                        decoration: const InputDecoration(
                          labelText: 'Sexo',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'M', child: Text('Masculino')),
                          DropdownMenuItem(value: 'F', child: Text('Feminino')),
                        ],
                        onChanged: (value) => setState(() => selectedSexo = value ?? ''),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedStatus.isNotEmpty ? selectedStatus : null,
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Lead', child: Text('Lead')),
                          DropdownMenuItem(value: 'Prospect', child: Text('Prospect')),
                          DropdownMenuItem(value: 'Negociado', child: Text('Negociado')),
                          DropdownMenuItem(value: 'Lead Perdido', child: Text('Lead Perdido')),
                        ],
                        onChanged: (value) => setState(() => selectedStatus = value ?? 'Lead'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: selectedTipo.isNotEmpty ? TextEditingController(text: selectedTipo) : TextEditingController(),
                        decoration: const InputDecoration(
                          labelText: 'Tipo',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) => selectedTipo = value,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: vendedorController,
                        decoration: const InputDecoration(
                          labelText: 'Vendedor',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: dataContatoController,
                        decoration: const InputDecoration(
                          labelText: 'Data Contato',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                TextField(
                  controller: servicosController,
                  decoration: const InputDecoration(
                    labelText: 'Serviços',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                
                TextField(
                  controller: observacaoController,
                  decoration: const InputDecoration(
                    labelText: 'Observação',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                
                TextField(
                  controller: dataFechamentoController,
                  decoration: const InputDecoration(
                    labelText: 'Data Fechamento',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _updateEntry(
                  entry,
                  nameController.text,
                  emailController.text,
                  telefoneController.text,
                  cidadeController.text,
                  selectedSexo,
                  selectedStatus,
                  selectedTipo,
                  vendedorController.text,
                  dataContatoController.text,
                  dataFechamentoController.text,
                  servicosController.text,
                  observacaoController.text,
                );
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateEntry(
    MondayEntry entry,
    String name,
    String email,
    String telefone,
    String cidade,
    String sexo,
    String status,
    String tipo,
    String vendedor,
    String dataContato,
    String dataFechamento,
    String servicos,
    String observacao,
  ) async {
    try {
      await Supabase.instance.client
          .from('monday')
          .update({
            'name': name.isEmpty ? null : name,
            'email': email.isEmpty ? null : email,
            'telefone': telefone.isEmpty ? null : telefone,
            'cidade': cidade.isEmpty ? null : cidade,
            'sexo': sexo.isEmpty ? null : sexo,
            'contact_category_id': _getContactCategoryId(status),
            'tipo': tipo.isEmpty ? null : tipo,
            'vendedor': vendedor.isEmpty ? null : vendedor,
            'dataContato': dataContato.isEmpty ? null : dataContato,
            'dataFechamento': dataFechamento.isEmpty ? null : dataFechamento,
            'servicos': servicos.isEmpty ? null : servicos,
            'observacao': observacao.isEmpty ? null : observacao,
          })
          .eq('id', entry.id);

      // Atualizar a lista
      ref.read(mondayPaginationProvider.notifier).refresh();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registro #${entry.id} atualizado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar registro: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showCreateDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final telefoneController = TextEditingController();
    final cidadeController = TextEditingController();
    final servicosController = TextEditingController();
    final observacaoController = TextEditingController();
    final vendedorController = TextEditingController();
    final dataContatoController = TextEditingController();
    final dataFechamentoController = TextEditingController();
    
    String selectedStatus = 'Lead';
    String selectedTipo = '';
    String selectedSexo = '';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.add, color: DesignTokens.primaryBlue),
              SizedBox(width: 8),
              Text('Novo Registro'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Informações básicas
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: telefoneController,
                        decoration: const InputDecoration(
                          labelText: 'Telefone',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: cidadeController,
                        decoration: const InputDecoration(
                          labelText: 'Cidade',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedSexo.isNotEmpty ? selectedSexo : null,
                        decoration: const InputDecoration(
                          labelText: 'Sexo',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'M', child: Text('Masculino')),
                          DropdownMenuItem(value: 'F', child: Text('Feminino')),
                        ],
                        onChanged: (value) => setState(() => selectedSexo = value ?? ''),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedStatus.isNotEmpty ? selectedStatus : null,
                        decoration: const InputDecoration(
                          labelText: 'Status *',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Lead', child: Text('Lead')),
                          DropdownMenuItem(value: 'Prospect', child: Text('Prospect')),
                          DropdownMenuItem(value: 'Negociado', child: Text('Negociado')),
                          DropdownMenuItem(value: 'Lead Perdido', child: Text('Lead Perdido')),
                        ],
                        onChanged: (value) => setState(() => selectedStatus = value ?? 'Lead'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: selectedTipo.isNotEmpty ? TextEditingController(text: selectedTipo) : TextEditingController(),
                        decoration: const InputDecoration(
                          labelText: 'Tipo',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) => selectedTipo = value,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: vendedorController,
                        decoration: const InputDecoration(
                          labelText: 'Vendedor',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: dataContatoController,
                        decoration: const InputDecoration(
                          labelText: 'Data Contato',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                TextField(
                  controller: servicosController,
                  decoration: const InputDecoration(
                    labelText: 'Serviços',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                
                TextField(
                  controller: observacaoController,
                  decoration: const InputDecoration(
                    labelText: 'Observação',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                
                TextField(
                  controller: dataFechamentoController,
                  decoration: const InputDecoration(
                    labelText: 'Data Fechamento',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Nome é obrigatório!'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                
                Navigator.of(context).pop();
                _createEntry(
                  nameController.text,
                  emailController.text,
                  telefoneController.text,
                  cidadeController.text,
                  selectedSexo,
                  selectedStatus,
                  selectedTipo,
                  vendedorController.text,
                  dataContatoController.text,
                  dataFechamentoController.text,
                  servicosController.text,
                  observacaoController.text,
                );
              },
              child: const Text('Criar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createEntry(
    String name,
    String email,
    String telefone,
    String cidade,
    String sexo,
    String status,
    String tipo,
    String vendedor,
    String dataContato,
    String dataFechamento,
    String servicos,
    String observacao,
  ) async {
    try {
      await Supabase.instance.client
          .from('monday')
          .insert({
            'name': name,
            'email': email.isEmpty ? null : email,
            'telefone': telefone.isEmpty ? null : telefone,
            'cidade': cidade.isEmpty ? null : cidade,
            'sexo': sexo.isEmpty ? null : sexo,
            'contact_category_id': _getContactCategoryId(status),
            'tipo': tipo.isEmpty ? null : tipo,
            'vendedor': vendedor.isEmpty ? null : vendedor,
            'dataContato': dataContato.isEmpty ? null : dataContato,
            'dataFechamento': dataFechamento.isEmpty ? null : dataFechamento,
            'servicos': servicos.isEmpty ? null : servicos,
            'observacao': observacao.isEmpty ? null : observacao,
          });

      // Atualizar a lista
      ref.read(mondayPaginationProvider.notifier).refresh();
      ref.invalidate(mondayCountProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registro criado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao criar registro: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  int? _getContactCategoryId(String status) {
    switch (status.toLowerCase()) {
      case 'lead':
        return 12; // ID da categoria 'lead' no banco
      case 'prospect':
        return 13; // ID da categoria 'prospect' no banco
      case 'negociado':
        return 14; // ID da categoria 'negociado' no banco
      case 'lead perdido':
        return 15; // ID da categoria 'lead perdido' no banco
      default:
        return 12; // Default para 'lead'
    }
  }

  List<MondayEntry> _getFilteredEntries(List<MondayEntry> entries) {
    if (_searchTerm.isEmpty) {
      return entries;
    }
    
    return entries.where((entry) {
      // Converter MondayEntry para Map para usar o mixin
      final entryMap = {
        'id': entry.id,
        'name': entry.name,
        'email': entry.email,
        'telefone': entry.telefone,
        'cidade': entry.cidade,
        'vendedor': entry.vendedor,
        'tipo': entry.tipo,
        'servicos': entry.servicos,
        'font': entry.font,
        'contactCategoryName': entry.contactCategoryName,
        'observacao': entry.observacao,
        'idMonday': entry.idMonday,
      };
      
      return smartSearch(
        entryMap, 
        _searchTerm,
        nameField: 'name',
        phoneField: 'telefone',
        emailField: 'email',
        cityField: 'cidade',
        additionalFields: 'vendedor',
      );
    }).toList();
  }
} 
