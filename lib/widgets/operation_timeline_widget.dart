import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/operation_history.dart';
import '../providers/operation_history_provider.dart';
import '../utils/timezone_utils.dart';

class OperationTimelineWidget extends ConsumerStatefulWidget {
  final int operationId;
  final bool showHeader;
  final double? maxHeight;

  const OperationTimelineWidget({
    super.key,
    required this.operationId,
    this.showHeader = true,
    this.maxHeight,
  });

  @override
  ConsumerState<OperationTimelineWidget> createState() =>
      _OperationTimelineWidgetState();
}

class _OperationTimelineWidgetState
    extends ConsumerState<OperationTimelineWidget> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(operationHistoryProvider.notifier)
          .loadOperationHistory(widget.operationId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final historyState = ref.watch(operationHistoryProvider);
    final history = historyState.historyByOperation[widget.operationId] ?? [];

    if (historyState.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (historyState.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Erro ao carregar timeline',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              historyState.error!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.red,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref
                    .read(operationHistoryProvider.notifier)
                    .loadOperationHistory(widget.operationId);
              },
              child: const Text('Tentar Novamente'),
            ),
          ],
        ),
      );
    }

    if (history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.timeline,
              color: Colors.grey,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhum histórico encontrado',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey,
                  ),
            ),
          ],
        ),
      );
    }

    Widget timelineContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showHeader) ...[
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.timeline,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Timeline da Operação',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                Text(
                  '${history.length} eventos',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                ),
              ],
            ),
          ),
          const Divider(),
        ],
        Flexible(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: history.length,
            itemBuilder: (context, index) {
              final item = history[index];
              final isLast = index == history.length - 1;
              return _buildTimelineItem(item, isLast);
            },
          ),
        ),
      ],
    );

    if (widget.maxHeight != null) {
      timelineContent = SizedBox(
        height: widget.maxHeight,
        child: timelineContent,
      );
    }

    return timelineContent;
  }

  Widget _buildTimelineItem(OperationHistory item, bool isLast) {
    final actionInfo = _getActionInfo(item.actionType);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: actionInfo.color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: actionInfo.color.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  actionInfo.icon,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 40,
                  color: Colors.grey[300],
                  margin: const EdgeInsets.symmetric(vertical: 4),
                ),
            ],
          ),
          const SizedBox(width: 16),
          // Content
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.grey[200]!,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          actionInfo.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Text(
                        _formatDateTime(item.performedAt),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Description
                  Text(
                    _getActionDescription(item),
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 13,
                    ),
                  ),
                  // Performer info
                  if (item.performedByUserName != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.person,
                          size: 14,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Por: ${item.performedByUserName}',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ],
                  // Additional data
                  if (item.actionData != null &&
                      item.actionData!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildActionData(item.actionData!),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionData(Map<String, dynamic> actionData) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: actionData.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${entry.key}: ',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
                Expanded(
                  child: Text(
                    entry.value.toString(),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  ActionInfo _getActionInfo(String actionType) {
    switch (actionType) {
      case 'created':
        return ActionInfo(
          title: 'Operação Criada',
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
      case 'car_assigned':
        return ActionInfo(
          title: 'Veículo Designado',
          icon: Icons.directions_car,
          color: Colors.teal,
        );
      case 'scheduled':
        return ActionInfo(
          title: 'Agendamento Alterado',
          icon: Icons.schedule,
          color: Colors.purple,
        );
      case 'started':
        return ActionInfo(
          title: 'Operação Iniciada',
          icon: Icons.play_arrow,
          color: Colors.green,
        );
      case 'completed':
        return ActionInfo(
          title: 'Operação Concluída',
          icon: Icons.check_circle,
          color: Colors.green[700]!,
        );
      case 'cancelled':
        return ActionInfo(
          title: 'Operação Cancelada',
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
          title: 'Informações de Voo Atualizadas',
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

  String _getActionDescription(OperationHistory item) {
    switch (item.actionType) {
      case 'created':
        return 'A operação foi criada no sistema';
      case 'status_changed':
        return 'Status alterado de "${item.oldValue ?? 'N/A'}" para "${item.newValue ?? 'N/A'}"';
      case 'driver_assigned':
        return 'Motorista "${item.newValue}" foi designado para esta operação';
      case 'driver_unassigned':
        return 'Motorista "${item.oldValue}" foi removido desta operação';
      case 'scheduled':
        if (item.actionData != null) {
          final oldDate = item.actionData!['old_date_formatted'];
          final newDate = item.actionData!['new_date_formatted'];
          return 'Data alterada de "$oldDate" para "$newDate"';
        }
        return 'Agendamento foi alterado';
      case 'started':
        return 'A operação foi iniciada';
      case 'completed':
        return 'A operação foi concluída com sucesso';
      case 'cancelled':
        return 'A operação foi cancelada';
      case 'note_added':
        return 'Nova nota adicionada: "${item.newValue}"';
      case 'location_updated':
        return 'Informações de localização foram atualizadas';
      case 'flight_info_updated':
        return 'Informações de voo foram atualizadas';
      default:
        return item.newValue ?? 'Ação realizada';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    // Converter para ambos os timezones
    final nycTime = TimezoneUtils.convertToNewYork(dateTime);
    final brazilTime = TimezoneUtils.convertToSaoPaulo(dateTime);

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return 'Hoje às ${DateFormat('HH:mm').format(nycTime)} (NYC) | ${DateFormat('HH:mm').format(brazilTime)} (BR)';
    } else if (difference.inDays == 1) {
      return 'Ontem às ${DateFormat('HH:mm').format(nycTime)} (NYC) | ${DateFormat('HH:mm').format(brazilTime)} (BR)';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} dias atrás - ${DateFormat('HH:mm').format(nycTime)} (NYC) | ${DateFormat('HH:mm').format(brazilTime)} (BR)';
    } else {
      return '${DateFormat('dd/MM/yyyy HH:mm').format(nycTime)} (NYC) | ${DateFormat('HH:mm').format(brazilTime)} (BR)';
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
