import 'package:flutter/material.dart';
import '../models/contact_task.dart';
import '../services/contact_task_service.dart';

/// Modal para criar ou editar tarefa/follow-up de contato
class ContactTaskDialog extends StatefulWidget {
  final int contactId;
  final ContactTask? task; // null = criar, preenchido = editar
  final VoidCallback? onSaved;

  const ContactTaskDialog({
    super.key,
    required this.contactId,
    this.task,
    this.onSaved,
  });

  @override
  State<ContactTaskDialog> createState() => _ContactTaskDialogState();
}

class _ContactTaskDialogState extends State<ContactTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  final _taskService = ContactTaskService();
  
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  
  String _taskType = 'follow_up';
  String _priority = 'normal';
  DateTime? _dueDate;
  TimeOfDay? _dueTime;
  bool _loading = false;

  final List<Map<String, dynamic>> _taskTypes = [
    {'value': 'follow_up', 'label': 'Follow-up', 'icon': Icons.notifications_active},
    {'value': 'call', 'label': 'Ligação', 'icon': Icons.phone},
    {'value': 'email', 'label': 'Email', 'icon': Icons.email},
    {'value': 'whatsapp', 'label': 'WhatsApp', 'icon': Icons.chat},
    {'value': 'meeting', 'label': 'Reunião', 'icon': Icons.groups},
    {'value': 'visit', 'label': 'Visita', 'icon': Icons.directions_car},
    {'value': 'other', 'label': 'Outro', 'icon': Icons.more_horiz},
  ];

  final List<Map<String, dynamic>> _priorities = [
    {'value': 'low', 'label': 'Baixa', 'color': Colors.blue},
    {'value': 'normal', 'label': 'Normal', 'color': Colors.grey},
    {'value': 'high', 'label': 'Alta', 'color': Colors.orange},
    {'value': 'urgent', 'label': 'Urgente', 'color': Colors.red},
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descriptionController = TextEditingController(text: widget.task?.description ?? '');
    
    if (widget.task != null) {
      _taskType = widget.task!.taskType;
      _priority = widget.task!.priority;
      _dueDate = widget.task!.dueDate;
      if (_dueDate != null) {
        _dueTime = TimeOfDay(hour: _dueDate!.hour, minute: _dueDate!.minute);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.task != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 700),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[900] : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Premium com Gradiente (igual ao das cotações)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [Colors.blue.shade900, Colors.purple.shade900]
                      : [Colors.blue.shade600, Colors.purple.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isEditing ? Icons.edit : Icons.alarm_add,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    isEditing ? 'Editar Follow-up' : 'Novo Follow-up',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                    tooltip: 'Fechar',
                  ),
                ],
              ),
            ),

            // Body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tipo de tarefa
                      Text(
                        'Tipo de Tarefa',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _taskTypes.map((type) {
                          final isSelected = _taskType == type['value'];
                          return ChoiceChip(
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(type['icon'] as IconData, size: 16),
                                const SizedBox(width: 4),
                                Text(type['label'] as String),
                              ],
                            ),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _taskType = type['value'] as String);
                              }
                            },
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 20),

                      // Título
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Título *',
                          hintText: 'Ex: Ligar para confirmar interesse',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Título é obrigatório';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Descrição
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Descrição',
                          hintText: 'Detalhes adicionais...',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),

                      const SizedBox(height: 20),

                      // Data e Hora
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Data',
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                OutlinedButton.icon(
                                  onPressed: _selectDate,
                                  icon: const Icon(Icons.calendar_today, size: 18),
                                  label: Text(
                                    _dueDate == null
                                        ? 'Selecionar data'
                                        : _formatDate(_dueDate!),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size(double.infinity, 48),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hora',
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                OutlinedButton.icon(
                                  onPressed: _dueDate == null ? null : _selectTime,
                                  icon: const Icon(Icons.access_time, size: 18),
                                  label: Text(
                                    _dueTime == null
                                        ? 'Selecionar hora'
                                        : _dueTime!.format(context),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size(double.infinity, 48),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Prioridade
                      Text(
                        'Prioridade',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: _priorities.map((priority) {
                          final isSelected = _priority == priority['value'];
                          return ChoiceChip(
                            label: Text(priority['label'] as String),
                            selected: isSelected,
                            selectedColor: (priority['color'] as Color).withValues(alpha: 0.3),
                            side: BorderSide(
                              color: isSelected 
                                  ? priority['color'] as Color
                                  : Colors.grey.shade300,
                            ),
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _priority = priority['value'] as String);
                              }
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Footer Premium
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[850] : Colors.grey[100],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _loading ? null : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Cancelar', style: TextStyle(fontSize: 15)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _loading ? null : _save,
                    icon: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Icon(isEditing ? Icons.save : Icons.alarm_add, size: 20),
                    label: Text(
                      isEditing ? 'Salvar Alterações' : 'Criar Follow-up',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      backgroundColor: Colors.orange[600],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
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

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (date != null) {
      setState(() => _dueDate = date);
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _dueTime ?? TimeOfDay.now(),
    );
    
    if (time != null) {
      setState(() => _dueTime = time);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _loading = true);

    try {
      DateTime? finalDueDate;
      if (_dueDate != null) {
        final hour = _dueTime?.hour ?? 9;
        final minute = _dueTime?.minute ?? 0;
        finalDueDate = DateTime(
          _dueDate!.year,
          _dueDate!.month,
          _dueDate!.day,
          hour,
          minute,
        );
      }

      bool success;
      
      if (widget.task == null) {
        // Criar nova tarefa
        final task = await _taskService.createTask(
          contactId: widget.contactId,
          taskType: _taskType,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty 
              ? null 
              : _descriptionController.text.trim(),
          dueDate: finalDueDate,
          priority: _priority,
        );
        success = task != null;
      } else {
        // Atualizar tarefa existente
        success = await _taskService.updateTask(widget.task!.id, {
          'task_type': _taskType,
          'title': _titleController.text.trim(),
          'description': _descriptionController.text.trim().isEmpty 
              ? null 
              : _descriptionController.text.trim(),
          'due_date': finalDueDate?.toIso8601String(),
          'priority': _priority,
        });
      }

      if (success && mounted) {
        Navigator.of(context).pop();
        widget.onSaved?.call();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.task == null 
                  ? '✅ Follow-up criado com sucesso!' 
                  : '✅ Follow-up atualizado!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Erro ao salvar follow-up'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erro: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }
}
