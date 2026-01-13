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
              onPressed: () => _showCreateTaskDialog(),
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
          
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Data e tipo
                  Row(
                    children: [
                      if (task.dueDate != null) ...[
                        Text(
                          _formatDate(task.dueDate!),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          task.taskTypeIcon + ' ' + task.taskTypeLabel,
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                      if (task.isHighPriority) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            task.priorityLabel,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.red.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Título
                  Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      decoration: isCompleted ? TextDecoration.lineThrough : null,
                      color: isCompleted ? Colors.grey.shade600 : null,
                    ),
                  ),
                  
                  // Responsável
                  if (task.assignedToUserName != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
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
                    ),
                  ],
                  
                  // Ações
                  if (!isCompleted) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        InkWell(
                          onTap: () => _completeTask(task),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check, size: 12, color: Colors.green.shade700),
                                const SizedBox(width: 4),
                                Text(
                                  'Concluir',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.green.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () => _editTask(task),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.edit, size: 12, color: Colors.blue.shade700),
                                const SizedBox(width: 4),
                                Text(
                                  'Editar',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.blue.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDate = DateTime(date.year, date.month, date.day);

    if (taskDate == today) {
      return 'HOJE';
    } else if (taskDate == today.add(const Duration(days: 1))) {
      return 'AMANHÃ';
    } else if (taskDate == today.subtract(const Duration(days: 1))) {
      return 'ONTEM';
    } else {
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _completeTask(ContactTask task) async {
    final success = await _taskService.completeTask(task.id);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Tarefa concluída!')),
      );
      _loadTasks();
    }
  }

  void _editTask(ContactTask task) {
    showDialog(
      context: context,
      builder: (context) => ContactTaskDialog(
        contactId: widget.contactId,
        task: task,
        onSaved: _loadTasks,
      ),
    );
  }

  void _showCreateTaskDialog() {
    showDialog(
      context: context,
      builder: (context) => ContactTaskDialog(
        contactId: widget.contactId,
        onSaved: _loadTasks,
      ),
    );
  }

  void _showAllTasks() {
    // TODO: Implementar tela com todas as tarefas
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('🚧 Tela de todas as tarefas em desenvolvimento')),
    );
  }
}
