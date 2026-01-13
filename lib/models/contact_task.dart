/// Modelo para tarefas e follow-ups de contatos B2C
class ContactTask {
  final int id;
  final int contactId;
  final String? assignedToUserId;
  final String? assignedToUserName;
  final String taskType;
  final String title;
  final String? description;
  final DateTime? dueDate;
  final DateTime? completedAt;
  final String? completionNotes;
  final String priority;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;

  ContactTask({
    required this.id,
    required this.contactId,
    this.assignedToUserId,
    this.assignedToUserName,
    required this.taskType,
    required this.title,
    this.description,
    this.dueDate,
    this.completedAt,
    this.completionNotes,
    required this.priority,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
  });

  factory ContactTask.fromJson(Map<String, dynamic> json) {
    return ContactTask(
      id: json['id'] as int,
      contactId: json['contact_id'] as int,
      assignedToUserId: json['assigned_to_user_id'] as String?,
      assignedToUserName: json['assigned_to_user_name'] as String?,
      taskType: json['task_type'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      dueDate: json['due_date'] != null 
          ? DateTime.parse(json['due_date'] as String)
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      completionNotes: json['completion_notes'] as String?,
      priority: json['priority'] as String? ?? 'normal',
      status: json['status'] as String? ?? 'pending',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      createdBy: json['created_by'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'contact_id': contactId,
      'assigned_to_user_id': assignedToUserId,
      'task_type': taskType,
      'title': title,
      'description': description,
      'due_date': dueDate?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'completion_notes': completionNotes,
      'priority': priority,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'created_by': createdBy,
    };
  }

  // Helpers
  bool get isOverdue {
    if (dueDate == null || status == 'completed' || status == 'cancelled') {
      return false;
    }
    return dueDate!.isBefore(DateTime.now());
  }

  bool get isPending => status == 'pending';
  bool get isCompleted => status == 'completed';
  bool get isInProgress => status == 'in_progress';
  bool get isCancelled => status == 'cancelled';

  bool get isHighPriority => priority == 'high' || priority == 'urgent';
  bool get isUrgent => priority == 'urgent';

  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'Pendente';
      case 'in_progress':
        return 'Em Progresso';
      case 'completed':
        return 'Concluído';
      case 'cancelled':
        return 'Cancelado';
      default:
        return status;
    }
  }

  String get priorityLabel {
    switch (priority) {
      case 'low':
        return 'Baixa';
      case 'normal':
        return 'Normal';
      case 'high':
        return 'Alta';
      case 'urgent':
        return 'Urgente';
      default:
        return priority;
    }
  }

  String get taskTypeLabel {
    switch (taskType) {
      case 'follow_up':
        return 'Follow-up';
      case 'call':
        return 'Ligação';
      case 'email':
        return 'Email';
      case 'whatsapp':
        return 'WhatsApp';
      case 'meeting':
        return 'Reunião';
      case 'visit':
        return 'Visita';
      case 'other':
        return 'Outro';
      default:
        return taskType;
    }
  }

  String get taskTypeIcon {
    switch (taskType) {
      case 'follow_up':
        return '🔔';
      case 'call':
        return '📞';
      case 'email':
        return '📧';
      case 'whatsapp':
        return '💬';
      case 'meeting':
        return '🤝';
      case 'visit':
        return '🚗';
      case 'other':
        return '📋';
      default:
        return '📝';
    }
  }

  ContactTask copyWith({
    int? id,
    int? contactId,
    String? assignedToUserId,
    String? assignedToUserName,
    String? taskType,
    String? title,
    String? description,
    DateTime? dueDate,
    DateTime? completedAt,
    String? completionNotes,
    String? priority,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
  }) {
    return ContactTask(
      id: id ?? this.id,
      contactId: contactId ?? this.contactId,
      assignedToUserId: assignedToUserId ?? this.assignedToUserId,
      assignedToUserName: assignedToUserName ?? this.assignedToUserName,
      taskType: taskType ?? this.taskType,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      completedAt: completedAt ?? this.completedAt,
      completionNotes: completionNotes ?? this.completionNotes,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}
