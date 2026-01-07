import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../design/design_tokens.dart';
import '../providers/seller_board_provider.dart';
import '../utils/currency_utils.dart';
import 'package:intl/intl.dart';
import '../widgets/sales_timeline_widget.dart';
import '../widgets/enhanced_quotation_dialog.dart';
import '../widgets/quotation_management_dialog.dart';

class SellerKanbanScreen extends ConsumerWidget {
  const SellerKanbanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final board = ref.watch(sellerBoardProvider);
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.98),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeaderSection(),
            const SizedBox(height: 32),
            _KanbanSection(board: board, ref: ref),
            const SizedBox(height: 32),
            _TodoSection(board: board, ref: ref),
          ],
        ),
      ),
    );
  }
}

class _HeaderSection extends StatelessWidget {
  const _HeaderSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final dateFormat = DateFormat('EEEE, d \'de\' MMMM', 'pt_BR');
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.1),
            theme.colorScheme.secondary.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.dashboard_rounded,
              size: 32,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dashboard do Vendedor',
                  style: DesignTokens.titleLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dateFormat.format(now),
                  style: DesignTokens.bodyMedium.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.tertiary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.trending_up_rounded,
                  size: 16,
                  color: theme.colorScheme.tertiary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Performance Ativa',
                  style: DesignTokens.bodySmall.copyWith(
                    color: theme.colorScheme.tertiary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KanbanSection extends StatelessWidget {
  final SellerBoardState board;
  final WidgetRef ref;
  const _KanbanSection({required this.board, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.contact_page_rounded,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Funil de Vendas',
              style: DesignTokens.titleLarge.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const Spacer(),
            _ActionButton(
              icon: Icons.add_rounded,
              label: 'Novo Lead',
              onTap: () => _showAddLeadDialog(context),
            ),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 320,
          child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: board.kanbanColumns.map((col) {
                return Expanded(
                  child: _BoardColumnWidget(
                    title: col.name,
                    items: col.items,
                    columnColor: _getColumnColor(col.key),
                    onAccept: (itemId, toIndex) {
                      ref.read(sellerBoardProvider.notifier).moveKanbanItem(
                        itemId, 
                        _findColumnKeyForItem(board.kanbanColumns, itemId), 
                        col.key, 
                        toIndex
                      );
                    },
                  ),
                );
              }).toList(),
            ),
        ),
      ],
    );
  }

  Color _getColumnColor(String key) {
    switch (key) {
      case 'leads':
        return Colors.blue;
      case 'qualified':
        return Colors.orange;
      case 'proposal':
        return Colors.purple;
      case 'won':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  void _showAddLeadDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adicionar Novo Lead'),
        content: const Text('Funcionalidade de adicionar novo lead será implementada'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Implement add lead functionality
              Navigator.of(context).pop();
            },
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
  }

  String _findColumnKeyForItem(List<BoardColumn> cols, String itemId) {
    for (final c in cols) {
      if (c.items.any((i) => i.id == itemId)) return c.key;
    }
    return cols.first.key;
  }
}

class _TodoSection extends StatefulWidget {
  final SellerBoardState board;
  final WidgetRef ref;
  const _TodoSection({required this.board, required this.ref});

  @override
  State<_TodoSection> createState() => _TodoSectionState();
}

class _TodoSectionState extends State<_TodoSection> {
  bool _showTimelineView = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.check_circle_rounded,
                size: 20,
                color: Theme.of(context).colorScheme.tertiary,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Tarefas do Vendedor',
              style: DesignTokens.titleLarge.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const Spacer(),
            // Toggle entre Kanban e Timeline
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () => setState(() => _showTimelineView = false),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: !_showTimelineView 
                            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.view_kanban,
                            size: 16,
                            color: !_showTimelineView 
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Kanban',
                            style: TextStyle(
                              fontSize: 12,
                              color: !_showTimelineView 
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => setState(() => _showTimelineView = true),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _showTimelineView 
                            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.timeline,
                            size: 16,
                            color: _showTimelineView 
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Timeline',
                            style: TextStyle(
                              fontSize: 12,
                              color: _showTimelineView 
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _ActionButton(
              icon: Icons.add_rounded,
              label: 'Nova Tarefa',
              onTap: () => _showAddTaskDialog(context),
            ),
          ],
        ),
        const SizedBox(height: 20),
        // Conteúdo baseado na visualização selecionada
        _showTimelineView ? _buildTimelineView() : _buildKanbanView(),
      ],
    );
  }

  Widget _buildKanbanView() {
    return SizedBox(
      height: 280,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: widget.board.todoColumns.map((col) {
          return Expanded(
            child: _BoardColumnWidget(
              title: col.name,
              items: col.items,
              columnColor: _getTodoColumnColor(col.key),
              onAccept: (itemId, toIndex) {
                  widget.ref.read(sellerBoardProvider.notifier).moveTodoItem(
                    itemId, 
                    _findColumnKeyForItem(widget.board.todoColumns, itemId), 
                    col.key, 
                    toIndex
                  );
                },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTimelineView() {
    // Converter tarefas do kanban para items de timeline
    final timelineActivities = _convertTasksToTimelineActivities();
    
    return Container(
      height: 600,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          // Timeline horizontal de progresso
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Progresso das Vendas',
                  style: DesignTokens.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                SalesTimelineWidget(
                  steps: const [
                    TimelineStep(
                      title: 'Lead',
                      description: 'Cliente identificado',
                      icon: Icons.person_add,
                    ),
                    TimelineStep(
                      title: 'Proposta',
                      description: 'Orçamento enviado',
                      icon: Icons.description,
                    ),
                    TimelineStep(
                      title: 'Negociação',
                      description: 'Em processo',
                      icon: Icons.handshake,
                    ),
                    TimelineStep(
                      title: 'Pagamento',
                      description: 'Confirmado',
                      icon: Icons.payment,
                    ),
                    TimelineStep(
                      title: 'Finalizado',
                      description: 'Venda concluída',
                      icon: Icons.check_circle,
                    ),
                  ],
                  currentStep: 2, // Valor dinâmico pode ser ajustado baseado nas tarefas
                ),
              ],
            ),
          ),
          const Divider(),
          // Timeline vertical de atividades
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Histórico de Atividades',
                    style: DesignTokens.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: timelineActivities.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.timeline_outlined,
                                  size: 48,
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Nenhuma atividade recente',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ActivityTimeline(activities: timelineActivities),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<ActivityItem> _convertTasksToTimelineActivities() {
    final activities = <ActivityItem>[];
    
    // Converter tarefas de cada coluna em atividades da timeline
    for (final column in widget.board.todoColumns) {
      for (final task in column.items) {
        activities.add(ActivityItem(
          title: task.title,
          description: task.subtitle, // Usar subtitle em vez de description
          time: DateFormat('HH:mm - dd/MM/yyyy', 'pt_BR').format(DateTime.now()),
          icon: _getIconForColumn(column.key),
          color: _getTodoColumnColor(column.key),
        ));
      }
    }
    
    // Ordenar por data (mais recente primeiro)
    activities.sort((a, b) => b.time.compareTo(a.time));
    
    return activities.take(10).toList(); // Limitar a 10 atividades mais recentes
  }

  IconData _getIconForColumn(String columnKey) {
    switch (columnKey) {
      case 'todo':
        return Icons.pending_actions;
      case 'doing':
        return Icons.play_arrow;
      case 'done':
        return Icons.check_circle;
      default:
        return Icons.task;
    }
  }

  Color _getTodoColumnColor(String key) {
    switch (key) {
      case 'todo':
        return Colors.red;
      case 'doing':
        return Colors.amber;
      case 'done':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  void _showAddTaskDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adicionar Nova Tarefa'),
        content: const Text('Funcionalidade de adicionar nova tarefa será implementada'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Implement add task functionality
              Navigator.of(context).pop();
            },
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
  }

  String _findColumnKeyForItem(List<BoardColumn> cols, String itemId) {
    for (final c in cols) {
      if (c.items.any((i) => i.id == itemId)) return c.key;
    }
    return cols.first.key;
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: DesignTokens.bodySmall.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BoardColumnWidget extends StatelessWidget {
  final String title;
  final List<BoardItem> items;
  final Color columnColor;
  final void Function(String itemId, int toIndex) onAccept;
  const _BoardColumnWidget({
    required this.title, 
    required this.items, 
    required this.columnColor,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: columnColor.withValues(alpha: 0.08),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                border: Border(
                  bottom: BorderSide(
                    color: columnColor.withValues(alpha: 0.2),
                    width: 2,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: columnColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: DesignTokens.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: columnColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      items.length.toString(),
                      style: DesignTokens.bodySmall.copyWith(
                        color: columnColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: DragTarget<String>(
                onAcceptWithDetails: (details) {
                  onAccept(details.data, items.length);
                },
                onWillAcceptWithDetails: (details) {
                  return true;
                },
                builder: (context, candidateData, rejectedData) {
                  return Container(
                    decoration: BoxDecoration(
                      color: candidateData.isNotEmpty
                          ? columnColor.withValues(alpha: 0.1)
                          : Colors.transparent,
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(16),
                      ),
                      border: candidateData.isNotEmpty
                          ? Border.all(
                              color: columnColor.withValues(alpha: 0.3),
                              width: 2,
                            )
                          : null,
                    ),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return Draggable<String>(
                          data: item.id,
                          feedback: _CardFeedback(item: item, columnColor: columnColor),
                          childWhenDragging: Opacity(
                            opacity: 0.5,
                            child: _BoardCard(item: item, columnColor: columnColor),
                          ),
                          child: DragTarget<String>(
                            onAcceptWithDetails: (details) {
                              onAccept(details.data, index);
                            },
                            onWillAcceptWithDetails: (details) {
                              return true;
                            },
                            builder: (context, candidateData, rejectedData) {
                              return Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: candidateData.isNotEmpty
                                      ? Border.all(
                                          color: columnColor.withValues(alpha: 0.5),
                                          width: 2,
                                          style: BorderStyle.solid,
                                        )
                                      : null,
                                ),
                                child: _BoardCard(item: item, columnColor: columnColor),
                              );
                            },
                          ),
                        );
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
  }
}

class _BoardCard extends StatelessWidget {
  final BoardItem item;
  final Color columnColor;
  const _BoardCard({required this.item, required this.columnColor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.1),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.shadow.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: columnColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getItemIcon(item.subtitle),
                    size: 16,
                    color: columnColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: DesignTokens.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.subtitle,
                        style: DesignTokens.bodySmall.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.drag_indicator_rounded,
                  size: 16,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ],
            ),
            if (item.value > 0) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        CurrencyUtils.formatCompactCurrency(item.value),
                        style: DesignTokens.bodySmall.copyWith(
                          color: const Color(0xFF10B981),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildQuotationButton(context, item),
                ],
              ),
            ] else ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: _buildQuotationButton(context, item),
              ),
            ],
          ],
      ),
    );
  }

  IconData _getItemIcon(String subtitle) {
    if (subtitle.toLowerCase().contains('whatsapp')) {
      return Icons.chat_bubble_rounded;
    } else if (subtitle.toLowerCase().contains('email')) {
      return Icons.email_rounded;
    } else if (subtitle.toLowerCase().contains('telefone')) {
      return Icons.phone_rounded;
    } else {
      return Icons.person_rounded;
    }
  }

  Widget _buildQuotationButton(BuildContext context, BoardItem item) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _showQuotationDialog(context, item),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.description,
                size: 14,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 4),
              Text(
                'Cotação',
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showQuotationDialog(BuildContext context, BoardItem item) {
    showDialog(
      context: context,
      builder: (context) => EnhancedQuotationDialog(
        leadId: item.id,
        leadTitle: item.title,
      ),
    ).then((quotation) {
      if (quotation != null) {
        // Use a timer to avoid widget lifecycle issues
        Timer(const Duration(milliseconds: 100), () {
          showDialog(
            context: context,
            builder: (context) => QuotationManagementDialog(
              quotation: quotation,
              onQuotationUpdated: () {
                // Handle quotation updates if needed
              },
            ),
          );
        });
      }
    });
  }
}

class _CardFeedback extends StatelessWidget {
  final BoardItem item;
  final Color columnColor;
  const _CardFeedback({required this.item, required this.columnColor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Material(
      color: Colors.transparent,
      child: Opacity(
        opacity: 0.95,
        child: Container(
          width: 260,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: columnColor.withValues(alpha: 0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withValues(alpha: 0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: columnColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.title,
                  style: DesignTokens.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                Icons.drag_indicator_rounded,
                size: 16,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}