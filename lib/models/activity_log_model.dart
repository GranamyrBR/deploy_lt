import 'package:flutter/foundation.dart';

/// Modelo para logs de atividades do sistema
/// Registra todas as ações dos usuários para auditoria
class ActivityLog {
  final int id;
  final String userId;
  final String userName;
  final String? userEmail;
  
  final String actionType; // 'create', 'update', 'status_change', etc.
  final String entityType; // 'quotation', 'contact', etc.
  final String entityId;
  final String? entityName;
  
  final String actionDescription;
  final Map<String, dynamic>? oldValue;
  final Map<String, dynamic>? newValue;
  final Map<String, dynamic>? metadata;
  
  final DateTime createdAt;

  ActivityLog({
    required this.id,
    required this.userId,
    required this.userName,
    this.userEmail,
    required this.actionType,
    required this.entityType,
    required this.entityId,
    this.entityName,
    required this.actionDescription,
    this.oldValue,
    this.newValue,
    this.metadata,
    required this.createdAt,
  });

  factory ActivityLog.fromJson(Map<String, dynamic> json) {
    return ActivityLog(
      id: json['id'] as int,
      userId: json['user_id'] as String,
      userName: json['user_name'] as String,
      userEmail: json['user_email'] as String?,
      actionType: json['action_type'] as String,
      entityType: json['entity_type'] as String,
      entityId: json['entity_id'] as String,
      entityName: json['entity_name'] as String?,
      actionDescription: json['action_description'] as String,
      oldValue: json['old_value'] != null 
          ? Map<String, dynamic>.from(json['old_value'] as Map)
          : null,
      newValue: json['new_value'] != null
          ? Map<String, dynamic>.from(json['new_value'] as Map)
          : null,
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Retorna um ícone apropriado para o tipo de ação
  String get actionIcon {
    switch (actionType) {
      case 'create':
        return '➕';
      case 'update':
        return '✏️';
      case 'delete':
        return '🗑️';
      case 'status_change':
        return '🔄';
      case 'send_email':
        return '📧';
      case 'send_whatsapp':
        return '💬';
      case 'follow_up':
        return '📞';
      case 'view':
        return '👁️';
      case 'generate_pdf':
        return '📄';
      case 'add_service':
        return '➕';
      case 'add_product':
        return '🛒';
      case 'remove_item':
        return '➖';
      case 'update_value':
        return '💰';
      default:
        return '📝';
    }
  }

  /// Retorna uma descrição amigável do tipo de ação
  String get actionTypeName {
    switch (actionType) {
      case 'create':
        return 'Criou';
      case 'update':
        return 'Atualizou';
      case 'delete':
        return 'Deletou';
      case 'status_change':
        return 'Mudou Status';
      case 'send_email':
        return 'Enviou Email';
      case 'send_whatsapp':
        return 'Enviou WhatsApp';
      case 'follow_up':
        return 'Follow-up';
      case 'view':
        return 'Visualizou';
      case 'generate_pdf':
        return 'Gerou PDF';
      case 'add_service':
        return 'Adicionou Serviço';
      case 'add_product':
        return 'Adicionou Produto';
      case 'remove_item':
        return 'Removeu Item';
      case 'update_value':
        return 'Atualizou Valor';
      default:
        return actionType;
    }
  }
}

/// Modelo para Follow-ups de cotações
class QuotationFollowUp {
  final int id;
  final int quotationId;
  
  final String assignedTo;
  final String assignedName;
  final String? assignedEmail;
  
  final String type; // 'call', 'email', 'whatsapp', 'meeting', 'note'
  final String status; // 'pending', 'completed', 'cancelled'
  final String priority; // 'low', 'medium', 'high', 'urgent'
  
  final DateTime scheduledDate;
  final DateTime? completedDate;
  
  final String title;
  final String? description;
  final String? notes;
  final String? result;
  
  final String createdBy;
  final DateTime createdAt;

  QuotationFollowUp({
    required this.id,
    required this.quotationId,
    required this.assignedTo,
    required this.assignedName,
    this.assignedEmail,
    required this.type,
    required this.status,
    required this.priority,
    required this.scheduledDate,
    this.completedDate,
    required this.title,
    this.description,
    this.notes,
    this.result,
    required this.createdBy,
    required this.createdAt,
  });

  factory QuotationFollowUp.fromJson(Map<String, dynamic> json) {
    return QuotationFollowUp(
      id: json['id'] as int,
      quotationId: json['quotation_id'] as int,
      assignedTo: json['assigned_to'] as String,
      assignedName: json['assigned_name'] as String,
      assignedEmail: json['assigned_email'] as String?,
      type: json['type'] as String,
      status: json['status'] as String,
      priority: json['priority'] as String,
      scheduledDate: DateTime.parse(json['scheduled_date'] as String),
      completedDate: json['completed_date'] != null
          ? DateTime.parse(json['completed_date'] as String)
          : null,
      title: json['title'] as String,
      description: json['description'] as String?,
      notes: json['notes'] as String?,
      result: json['result'] as String?,
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'quotation_id': quotationId,
      'assigned_to': assignedTo,
      'assigned_name': assignedName,
      'assigned_email': assignedEmail,
      'type': type,
      'status': status,
      'priority': priority,
      'scheduled_date': scheduledDate.toIso8601String(),
      'completed_date': completedDate?.toIso8601String(),
      'title': title,
      'description': description,
      'notes': notes,
      'result': result,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Retorna um ícone para o tipo de follow-up
  String get typeIcon {
    switch (type) {
      case 'call':
        return '📞';
      case 'email':
        return '📧';
      case 'whatsapp':
        return '💬';
      case 'meeting':
        return '🤝';
      case 'note':
        return '📝';
      default:
        return '📋';
    }
  }

  /// Retorna uma cor para a prioridade
  String get priorityColor {
    switch (priority) {
      case 'low':
        return 'green';
      case 'medium':
        return 'orange';
      case 'high':
        return 'red';
      case 'urgent':
        return 'purple';
      default:
        return 'grey';
    }
  }

  /// Verifica se está atrasado
  bool get isOverdue {
    return status == 'pending' && scheduledDate.isBefore(DateTime.now());
  }

  /// Retorna a descrição do status
  String get statusName {
    switch (status) {
      case 'pending':
        return isOverdue ? 'Atrasado' : 'Pendente';
      case 'completed':
        return 'Concluído';
      case 'cancelled':
        return 'Cancelado';
      default:
        return status;
    }
  }
}

/// Estatísticas de vendedor
class SellerStats {
  final int totalQuotations;
  final int acceptedQuotations;
  final int pendingQuotations;
  final int rejectedQuotations;
  
  final double totalValue;
  final double acceptedValue;
  final double totalCommission;
  
  final double conversionRate;
  final double avgQuotationValue;
  
  final int followUpsCompleted;
  final int followUpsPending;

  SellerStats({
    required this.totalQuotations,
    required this.acceptedQuotations,
    required this.pendingQuotations,
    required this.rejectedQuotations,
    required this.totalValue,
    required this.acceptedValue,
    required this.totalCommission,
    required this.conversionRate,
    required this.avgQuotationValue,
    required this.followUpsCompleted,
    required this.followUpsPending,
  });

  factory SellerStats.fromJson(Map<String, dynamic> json) {
    return SellerStats(
      totalQuotations: json['total_quotations'] as int? ?? 0,
      acceptedQuotations: json['accepted_quotations'] as int? ?? 0,
      pendingQuotations: json['pending_quotations'] as int? ?? 0,
      rejectedQuotations: json['rejected_quotations'] as int? ?? 0,
      totalValue: (json['total_value'] as num?)?.toDouble() ?? 0.0,
      acceptedValue: (json['accepted_value'] as num?)?.toDouble() ?? 0.0,
      totalCommission: (json['total_commission'] as num?)?.toDouble() ?? 0.0,
      conversionRate: (json['conversion_rate'] as num?)?.toDouble() ?? 0.0,
      avgQuotationValue: (json['avg_quotation_value'] as num?)?.toDouble() ?? 0.0,
      followUpsCompleted: json['follow_ups_completed'] as int? ?? 0,
      followUpsPending: json['follow_ups_pending'] as int? ?? 0,
    );
  }
}

