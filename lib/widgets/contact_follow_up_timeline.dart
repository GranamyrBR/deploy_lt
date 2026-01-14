import 'package:flutter/material.dart';
import '../models/contact_task.dart';
import '../services/contact_task_service.dart';
import 'contact_task_dialog.dart';

/// Timeline compacta de follow-ups para área expandida do card de contato
class ContactFollowUpTimeline extends StatefulWidget {
  final int contactId;
  final int maxItems;

  const ContactFollowUpTimeline({
    super.key,
    required this.contactId,
    this.maxItems = 5,
  });

  @override
  State<ContactFollowUpTimeline> createState() => _ContactFollowUpTimelineState();
}

class _ContactFollowUpTimelineState extends State<ContactFollowUpTimeline> {
  final ContactTaskService _taskService = ContactTaskService();
  List<ContactTask> _tasks = [];
  bool _loading = true;
  int _totalTasks = 0;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() => _loading = true);
    
    final tasks = await _taskService.getContactTasks(
      widget.contactId,
      limit: widget.maxItems,
    );
    
    final counts = await _taskService.getTaskCountsByStatus(widget.contactId);
    final total = counts.values.fold(0, (sum, count) => sum + count);

    setState(() {
      _tasks = tasks;
      _totalTasks = total;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header com botão de adicionar
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Follow-ups',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => ContactTaskDialog(
                    contactId: widget.contactId,
                    onSaved: _loadTasks,
                  ),
                );
              },
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Novo Follow-up', style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                minimumSize: Size.zero,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),

        // Lista de tarefas
        if (_tasks.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Icon(Icons.task_alt, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 8),
                  Text(
                    'Nenhum follow-up cadastrado',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _tasks.length,
            itemBuilder: (context, index) {
              final task = _tasks[index];
              final isLast = index == _tasks.length - 1;
              return _buildTaskItem(task, isLast);
            },
          ),

        // Botão "Ver todos" se houver mais tarefas
        if (_totalTasks > widget.maxItems)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Center(
              child: TextButton.icon(
                onPressed: () => _showAllTasks(),
                icon: const Icon(Icons.arrow_forward, size: 16),
                label: Text('Ver todos os $_totalTasks follow-ups'),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTaskItem(ContactTask task, bool isLast) {
    final isOverdue = task.isOverdue;
    final isCompleted = task.isCompleted;
    final isToday = task.dueDate != null &&
        task.dueDate!.year == DateTime.now().year &&
        task.dueDate!.month == DateTime.now().month &&
        task.dueDate!.day == DateTime.now().day;

    Color statusColor;
    IconData statusIcon;
    
    if (isCompleted) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
    } else if (isOverdue) {
      statusColor = Colors.red;
      statusIcon = Icons.error;
    } else if (isToday) {
      statusColor = Colors.orange;
      statusIcon = Icons.radio_button_checked;
    } else {
      statusColor = Colors.blue;
      statusIcon = Icons.radio_button_unchecked;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator
          Column(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: statusColor, width: 2),
                ),
                child: Icon(
                  statusIcon,
                  size: 12,
                  color: statusColor,
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
          
          const SizedBox(width: 12),
          
          // Content - Tudo em uma única linha com separador |
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Tooltip(
                message: task.title,
                child: Row(
                  children: [
                    // Data e horário
                    if (task.dueDate != null) ...[
                      Text(
                        _formatDate(task.dueDate!),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                      // Horário sempre exibido
                      const SizedBox(width: 4),
                      Text(
                        '${task.dueDate!.hour.toString().padLeft(2, '0')}:${task.dueDate!.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text('|', style: TextStyle(color: Colors.grey.shade400)),
                      ),
                    ],
                    
                    // Tipo
                    Text(
                      '${task.taskTypeIcon} ${task.taskTypeLabel}',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                    ),
                    
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text('|', style: TextStyle(color: Colors.grey.shade400)),
                    ),
                    
                    // Título
                    Expanded(
                      child: Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          decoration: isCompleted ? TextDecoration.lineThrough : null,
                          color: isCompleted ? Colors.grey.shade600 : Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    
                    // Responsável
                    if (task.assignedToUserName != null) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text('|', style: TextStyle(color: Colors.grey.shade400)),
                      ),
                      Icon(Icons.person, size: 12, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        task.assignedToUserName!,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                    
                    // Prioridade alta
                    if (task.isHighPriority) ...[
                      const SizedBox(width: 8),
                      Icon(Icons.priority_high, size: 14, color: Colors.red.shade700),
                    ],
                  ],
                ),
              ),
            ),
          ),
          
          // Ações
          if (!isCompleted)
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, size: 16, color: Colors.grey.shade600),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'complete',
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 18),
                      SizedBox(width: 8),
                      Text('Concluir'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, color: Colors.blue, size: 18),
                      SizedBox(width: 8),
                      Text('Editar'),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'complete') {
                  _completeTask(task);
                } else if (value == 'edit') {
                  _editTask(task);
                }
              },
            ),
        ],
      ),
    );
  }

  void _completeTask(ContactTask task) async {
    try {
      final success = await ContactTaskService().completeTask(task.id);
      if (success) {
        _loadTasks();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Tarefa concluída!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao concluir tarefa: $e')),
        );
      }
    }
  }

  void _editTask(ContactTask task) {
    showDialog(
      context: context,
      builder: (context) => ContactTaskDialog(
        contactId: widget.contactId,
        task: task,
        onSaved: () {
          _loadTasks();
        },
      ),
    );
  }

  void _showAllTasks() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('🚧 Visualização completa em desenvolvimento')),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateDay = DateTime(date.year, date.month, date.day);
    
    if (dateDay == today) {
      return 'Hoje';
    } else if (dateDay == today.add(const Duration(days: 1))) {
      return 'Amanhã';
    } else if (dateDay == today.subtract(const Duration(days: 1))) {
      return 'Ontem';
    } else {
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
    }
  }
}
