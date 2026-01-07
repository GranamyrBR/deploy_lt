import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/operation_history.dart';
import '../providers/operation_history_provider.dart';

class OperationTimelineCompact extends ConsumerStatefulWidget {
  final int operationId;
  final int maxItems;
  final bool showViewAllButton;
  final VoidCallback? onViewAll;

  const OperationTimelineCompact({
    Key? key,
    required this.operationId,
    this.maxItems = 3,
    this.showViewAllButton = true,
    this.onViewAll,
  }) : super(key: key);

  @override
  ConsumerState<OperationTimelineCompact> createState() => _OperationTimelineCompactState();
}

class _OperationTimelineCompactState extends ConsumerState<OperationTimelineCompact> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(operationHistoryProvider.notifier).loadOperationHistory(widget.operationId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final historyState = ref.watch(operationHistoryProvider);
    final history = historyState.historyByOperation[widget.operationId] ?? [];

    if (historyState.isLoading) {
      return const SizedBox(
        height: 100,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (historyState.error != null) {
      return Container(
        height: 100,
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 24,
              ),
              const SizedBox(height: 8),
              Text(
                'Erro ao carregar timeline',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (history.isEmpty) {
      return Container(
        height: 100,
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.timeline,
                color: Colors.grey,
                size: 24,
              ),
              const SizedBox(height: 8),
              Text(
                'Nenhum histórico',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final displayHistory = history.take(widget.maxItems).toList();
    final hasMore = history.length > widget.maxItems;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.timeline,
                  size: 20,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Atividades Recentes',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (widget.showViewAllButton && hasMore)
                  TextButton(
                    onPressed: widget.onViewAll,
                    child: const Text('Ver Todas'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Timeline items
            ...displayHistory.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isLast = index == displayHistory.length - 1;
              return _buildCompactTimelineItem(item, isLast);
            }).toList(),
            
            // Show more indicator
            if (hasMore && !widget.showViewAllButton)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    const SizedBox(width: 24), // Align with timeline
                    Text(
                      '+ ${history.length - widget.maxItems} mais atividades',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactTimelineItem(OperationHistory item, bool isLast) {
    final actionInfo = _getActionInfo(item.actionType);
    
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator
          Column(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: actionInfo.color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 1,
                  ),
                ),
                child: Icon(
                  actionInfo.icon,
                  color: Colors.white,
                  size: 10,
                ),
              ),
              if (!isLast)
                Container(
                  width: 1,
                  height: 24,
                  color: Colors.grey[300],
                  margin: const EdgeInsets.symmetric(vertical: 2),
                ),
            ],
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and time
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          actionInfo.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Text(
                        _formatCompactDateTime(item.performedAt),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  // Description
                  Text(
                    _getCompactActionDescription(item),
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  ActionInfo _getActionInfo(String actionType) {
    switch (actionType) {
      case 'created':
        return ActionInfo(
          title: 'Criada',
          icon: Icons.add_circle,
          color: Colors.blue,
        );
      case 'status_changed':
        return ActionInfo(
          title: 'Status Alterado',
          icon: Icons.swap_horiz,
          color: Colors.orange,
        );
      case 'driver_assigned':
        return ActionInfo(
          title: 'Motorista Designado',
          icon: Icons.person_add,
          color: Colors.green,
        );
      case 'driver_unassigned':
        return ActionInfo(
          title: 'Motorista Removido',
          icon: Icons.person_remove,
          color: Colors.red,
        );
      case 'scheduled':
        return ActionInfo(
          title: 'Reagendada',
          icon: Icons.schedule,
          color: Colors.purple,
        );
      case 'started':
        return ActionInfo(
          title: 'Iniciada',
          icon: Icons.play_arrow,
          color: Colors.green,
        );
      case 'completed':
        return ActionInfo(
          title: 'Concluída',
          icon: Icons.check_circle,
          color: Colors.green[700]!,
        );
      case 'cancelled':
        return ActionInfo(
          title: 'Cancelada',
          icon: Icons.cancel,
          color: Colors.red,
        );
      case 'note_added':
        return ActionInfo(
          title: 'Nota Adicionada',
          icon: Icons.note_add,
          color: Colors.indigo,
        );
      case 'location_updated':
        return ActionInfo(
          title: 'Localização Atualizada',
          icon: Icons.location_on,
          color: Colors.amber,
        );
      case 'flight_info_updated':
        return ActionInfo(
          title: 'Voo Atualizado',
          icon: Icons.flight,
          color: Colors.cyan,
        );
      default:
        return ActionInfo(
          title: 'Ação Realizada',
          icon: Icons.info,
          color: Colors.grey,
        );
    }
  }

  String _getCompactActionDescription(OperationHistory item) {
    switch (item.actionType) {
      case 'created':
        return 'Operação criada no sistema';
      case 'status_changed':
        return 'De "${item.oldValue}" para "${item.newValue}"';
      case 'driver_assigned':
        return 'Motorista: ${item.newValue}';
      case 'driver_unassigned':
        return 'Motorista removido: ${item.oldValue}';
      case 'scheduled':
        return 'Data/hora alterada';
      case 'started':
        return 'Operação iniciada';
      case 'completed':
        return 'Operação concluída';
      case 'cancelled':
        return 'Operação cancelada';
      case 'note_added':
        return 'Nova nota: "${item.newValue}"';
      case 'location_updated':
        return 'Localização atualizada';
      case 'flight_info_updated':
        return 'Informações de voo atualizadas';
      default:
        return item.newValue ?? 'Ação realizada';
    }
  }

  String _formatCompactDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Agora';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays == 1) {
      return 'Ontem';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return DateFormat('dd/MM').format(dateTime);
    }
  }
}

class ActionInfo {
  final String title;
  final IconData icon;
  final Color color;

  ActionInfo({
    required this.title,
    required this.icon,
    required this.color,
  });
}
