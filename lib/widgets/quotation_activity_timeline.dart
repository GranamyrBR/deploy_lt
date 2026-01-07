import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/activity_log_model.dart';

/// Widget para exibir timeline de atividades de uma cotação
/// Mostra histórico completo de ações, follow-ups e mudanças
class QuotationActivityTimeline extends StatelessWidget {
  final List<ActivityLog> activities;
  final List<QuotationFollowUp> followUps;

  const QuotationActivityTimeline({
    Key? key,
    required this.activities,
    required this.followUps,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Combina atividades e follow-ups em uma única lista ordenada
    final allItems = <_TimelineItem>[];
    
    // Adiciona atividades
    for (var activity in activities) {
      allItems.add(_TimelineItem(
        date: activity.createdAt,
        type: 'activity',
        data: activity,
      ));
    }
    
    // Adiciona follow-ups
    for (var followUp in followUps) {
      allItems.add(_TimelineItem(
        date: followUp.scheduledDate,
        type: 'followup',
        data: followUp,
      ));
    }
    
    // Ordena por data (mais recente primeiro)
    allItems.sort((a, b) => b.date.compareTo(a.date));

    if (allItems.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: allItems.length,
      itemBuilder: (context, index) {
        final item = allItems[index];
        final isLast = index == allItems.length - 1;
        
        if (item.type == 'activity') {
          return _buildActivityItem(
            context,
            item.data as ActivityLog,
            isLast,
          );
        } else {
          return _buildFollowUpItem(
            context,
            item.data as QuotationFollowUp,
            isLast,
          );
        }
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhuma atividade registrada',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'As ações realizadas nesta cotação aparecerão aqui',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(BuildContext context, ActivityLog activity, bool isLast) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline visual
          Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getActionColor(activity.actionType).withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _getActionColor(activity.actionType),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    activity.actionIcon,
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: Colors.grey.shade300,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          
          // Conteúdo
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 20),
              child: Card(
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Usuário e data
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: _getActionColor(activity.actionType),
                            child: Text(
                              activity.userName.substring(0, 1).toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  activity.userName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  _formatDateTime(activity.createdAt),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getActionColor(activity.actionType).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              activity.actionTypeName,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _getActionColor(activity.actionType),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // Descrição
                      Text(
                        activity.actionDescription,
                        style: const TextStyle(fontSize: 14),
                      ),
                      
                      // Detalhes (old_value / new_value)
                      if (activity.oldValue != null || activity.newValue != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (activity.oldValue != null) ...[
                                const Text(
                                  'Antes:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatJsonValue(activity.oldValue!),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                              if (activity.oldValue != null && activity.newValue != null)
                                const SizedBox(height: 8),
                              if (activity.newValue != null) ...[
                                const Text(
                                  'Depois:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatJsonValue(activity.newValue!),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFollowUpItem(BuildContext context, QuotationFollowUp followUp, bool isLast) {
    final isOverdue = followUp.isOverdue;
    final isCompleted = followUp.status == 'completed';
    
    Color statusColor;
    if (isCompleted) {
      statusColor = Colors.green;
    } else if (isOverdue) {
      statusColor = Colors.red;
    } else {
      statusColor = Colors.orange;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline visual
          Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: statusColor,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    followUp.typeIcon,
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: Colors.grey.shade300,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          
          // Conteúdo
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 20),
              child: Card(
                elevation: 1,
                color: isOverdue && !isCompleted
                    ? Colors.red.shade50
                    : null,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: statusColor,
                            child: Text(
                              followUp.assignedName.substring(0, 1).toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  followUp.assignedName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  _formatDateTime(followUp.scheduledDate),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              followUp.statusName,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // Título
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _getPriorityColor(followUp.priority).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              followUp.priority.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: _getPriorityColor(followUp.priority),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              followUp.title,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      // Descrição
                      if (followUp.description != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          followUp.description!,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                      
                      // Resultado (se concluído)
                      if (isCompleted && followUp.result != null) ...[
                        const SizedBox(height: 12),
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
                              Row(
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    size: 16,
                                    color: Colors.green.shade700,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Resultado:',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green.shade900,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                followUp.result!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green.shade800,
                                ),
                              ),
                              if (followUp.completedDate != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Concluído em ${_formatDateTime(followUp.completedDate!)}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.green.shade600,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                      
                      // Alerta de atraso
                      if (isOverdue && !isCompleted) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.warning,
                                size: 16,
                                color: Colors.red.shade700,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Follow-up atrasado! Realize o contato urgentemente.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.red.shade900,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getActionColor(String actionType) {
    switch (actionType) {
      case 'create':
        return Colors.green;
      case 'update':
      case 'update_value':
        return Colors.blue;
      case 'delete':
        return Colors.red;
      case 'status_change':
        return Colors.purple;
      case 'send_email':
      case 'send_whatsapp':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'low':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'high':
        return Colors.red;
      case 'urgent':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _formatDateTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inMinutes < 1) {
      return 'Agora mesmo';
    } else if (diff.inHours < 1) {
      return 'Há ${diff.inMinutes} min';
    } else if (diff.inDays < 1) {
      return 'Há ${diff.inHours}h';
    } else if (diff.inDays < 7) {
      return 'Há ${diff.inDays} dias';
    } else {
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    }
  }

  String _formatJsonValue(Map<String, dynamic> json) {
    return json.entries
        .map((e) => '${e.key}: ${e.value}')
        .join(', ');
  }
}

/// Item interno para ordenação da timeline
class _TimelineItem {
  final DateTime date;
  final String type; // 'activity' or 'followup'
  final dynamic data;

  _TimelineItem({
    required this.date,
    required this.type,
    required this.data,
  });
}

