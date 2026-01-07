import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'quotation_service.dart';

/// Callback type for action execution
typedef ActionExecutor = Future<bool> Function(PreTripAction action);

/// Pre-trip action types
enum PreTripActionType {
  call,
  email,
  whatsapp,
}

/// Configuration for pre-trip action scheduling
class PreTripActionConfig {
  /// Hours before travel date for each action type
  final Map<PreTripActionType, List<int>> hoursBeforeTravel;
  
  /// Maximum retry attempts
  final int maxRetries;
  
  /// Retry delay in minutes
  final int retryDelayMinutes;
  
  /// Auto-retry on failure
  final bool autoRetry;

  const PreTripActionConfig({
    this.hoursBeforeTravel = const {
      PreTripActionType.whatsapp: [48, 2],
      PreTripActionType.call: [24],
      PreTripActionType.email: [72],
    },
    this.maxRetries = 3,
    this.retryDelayMinutes = 60,
    this.autoRetry = true,
  });
}

/// Message template for pre-trip communications
class MessageTemplate {
  final String id;
  final PreTripActionType actionType;
  final String subject;
  final String bodyTemplate;
  final Map<String, String> placeholders;

  const MessageTemplate({
    required this.id,
    required this.actionType,
    required this.subject,
    required this.bodyTemplate,
    this.placeholders = const {},
  });

  /// Replace placeholders in body template
  String formatBody(Map<String, String> values) {
    var body = bodyTemplate;
    for (final entry in values.entries) {
      body = body.replaceAll('{${entry.key}}', entry.value);
    }
    return body;
  }
}

/// Service for managing and executing pre-trip actions
class PreTripActionService {
  SupabaseClient get _client => Supabase.instance.client;
  
  final QuotationService _quotationService;
  final PreTripActionConfig _config;
  
  Timer? _pollingTimer;
  bool _isProcessing = false;
  
  /// Callbacks for different action types
  ActionExecutor? onCallAction;
  ActionExecutor? onEmailAction;
  ActionExecutor? onWhatsAppAction;

  PreTripActionService({
    QuotationService? quotationService,
    PreTripActionConfig config = const PreTripActionConfig(),
  }) : _quotationService = quotationService ?? QuotationService(),
       _config = config;

  // =====================================================
  // MESSAGE TEMPLATES
  // =====================================================

  /// Default templates for different action types
  static const List<MessageTemplate> defaultTemplates = [
    MessageTemplate(
      id: 'whatsapp_confirmation_48h',
      actionType: PreTripActionType.whatsapp,
      subject: 'Confirmação de Viagem',
      bodyTemplate: '''Olá {client_name}! 👋

Sua viagem está confirmada para *{travel_date}*.

📍 *Detalhes:*
• Serviço: {service_description}
• Local de partida: {pickup_location}
• Horário: {pickup_time}
• Veículo: {vehicle}

📱 Em caso de dúvidas, responda esta mensagem ou ligue para {company_phone}.

Boa viagem! 🚗✨

_Equipe LeCotour_''',
    ),
    MessageTemplate(
      id: 'whatsapp_reminder_2h',
      actionType: PreTripActionType.whatsapp,
      subject: 'Lembrete - Sua viagem é em 2 horas!',
      bodyTemplate: '''⏰ *Lembrete de Viagem*

Olá {client_name}!

Sua viagem está programada para daqui a *2 horas*!

🚗 Nosso motorista {driver_name} estará no local combinado às {pickup_time}.

📍 Local: {pickup_location}

Se precisar de algo, estamos à disposição! 📱

_Equipe LeCotour_''',
    ),
    MessageTemplate(
      id: 'email_confirmation_72h',
      actionType: PreTripActionType.email,
      subject: 'Confirmação de Reserva - {quotation_number}',
      bodyTemplate: '''Prezado(a) {client_name},

Confirmamos sua reserva conforme detalhes abaixo:

DETALHES DA VIAGEM
-------------------
Data: {travel_date}
Serviço: {service_description}
Passageiros: {passenger_count}
Local de partida: {pickup_location}
Horário: {pickup_time}
Veículo: {vehicle}

VALOR TOTAL: {total_formatted}

Em caso de dúvidas ou necessidade de alterações, entre em contato conosco.

Atenciosamente,
Equipe LeCotour
{company_phone}
{company_email}''',
    ),
    MessageTemplate(
      id: 'call_script_24h',
      actionType: PreTripActionType.call,
      subject: 'Ligação de Confirmação',
      bodyTemplate: '''SCRIPT DE LIGAÇÃO - CONFIRMAÇÃO 24H

Cliente: {client_name}
Telefone: {client_phone}
Cotação: {quotation_number}

---

"Olá, {client_name}! Aqui é [SEU NOME] da LeCotour.

Estou ligando para confirmar sua viagem amanhã, dia {travel_date}.

[CONFIRMAR DETALHES:]
- Horário de partida: {pickup_time}
- Local de partida: {pickup_location}
- Número de passageiros: {passenger_count}

Está tudo certo? Precisa de alguma alteração?

[SE CONFIRMADO:]
Perfeito! Nosso motorista {driver_name} estará no local no horário combinado.
O número de contato dele é: {driver_phone}

Tem mais alguma dúvida?

[ENCERRAMENTO:]
Ótimo! Desejamos uma excelente viagem. Até breve!"

---
OBSERVAÇÕES DO CLIENTE:
{notes}''',
    ),
  ];

  /// Get template by ID
  MessageTemplate? getTemplate(String templateId) {
    return defaultTemplates.where((t) => t.id == templateId).firstOrNull;
  }

  /// Get templates by action type
  List<MessageTemplate> getTemplatesByType(PreTripActionType actionType) {
    return defaultTemplates.where((t) => t.actionType == actionType).toList();
  }

  // =====================================================
  // ACTION QUEUE MANAGEMENT
  // =====================================================

  /// Get pending actions from database
  Future<List<PreTripAction>> getPendingActions({int limit = 50}) async {
    return _quotationService.getPendingActions(limit: limit);
  }

  /// Get actions scheduled for the next N hours
  Future<List<PreTripAction>> getUpcomingActions({int hoursAhead = 24}) async {
    try {
      final response = await _client
        .from('pre_trip_action')
        .select('''
          *,
          quotation:quotation_id(
            id, quotation_number, client_name, client_phone, client_email,
            travel_date, pickup_location, vehicle, driver, passenger_count
          )
        ''')
        .eq('status', 'pending')
        .gte('scheduled_at', DateTime.now().toUtc().toIso8601String())
        .lte('scheduled_at', DateTime.now().add(Duration(hours: hoursAhead)).toIso8601String())
        .order('scheduled_at');
      
      return (response as List).map((e) {
        final data = Map<String, dynamic>.from(e);
        // Merge quotation data into action
        final quotation = data['quotation'] as Map<String, dynamic>?;
        if (quotation != null) {
          data['client_name'] = quotation['client_name'];
          data['client_phone'] = quotation['client_phone'];
          data['client_email'] = quotation['client_email'];
          data['travel_date'] = quotation['travel_date'];
          data['quotation_number'] = quotation['quotation_number'];
        }
        return PreTripAction.fromJson(data);
      }).toList();
    } catch (e) {
      print('Erro ao buscar ações futuras: $e');
      return [];
    }
  }

  /// Get action statistics
  Future<Map<String, dynamic>> getActionStats() async {
    try {
      final response = await _client
        .from('pre_trip_action')
        .select('status, action_type')
        .gte('created_at', DateTime.now().subtract(const Duration(days: 30)).toIso8601String());
      
      final actions = response as List;
      
      final total = actions.length;
      final pending = actions.where((a) => a['status'] == 'pending').length;
      final done = actions.where((a) => a['status'] == 'done').length;
      final failed = actions.where((a) => a['status'] == 'failed').length;
      
      final byType = <String, int>{};
      for (final action in actions) {
        final type = action['action_type'] as String;
        byType[type] = (byType[type] ?? 0) + 1;
      }
      
      return {
        'total': total,
        'pending': pending,
        'done': done,
        'failed': failed,
        'success_rate': total > 0 ? (done / total * 100).toStringAsFixed(2) : '0.00',
        'by_type': byType,
      };
    } catch (e) {
      print('Erro ao buscar estatísticas: $e');
      return {};
    }
  }

  // =====================================================
  // ACTION SCHEDULING
  // =====================================================

  /// Schedule a new action manually
  Future<int?> scheduleAction({
    required int quotationId,
    required PreTripActionType actionType,
    required DateTime scheduledAt,
    int priority = 1,
    String? notes,
    String? contactPhone,
    String? contactEmail,
  }) async {
    try {
      final response = await _client
        .from('pre_trip_action')
        .insert({
          'quotation_id': quotationId,
          'action_type': actionType.name,
          'scheduled_at': scheduledAt.toIso8601String(),
          'priority': priority,
          'notes': notes,
          'contact_phone': contactPhone,
          'contact_email': contactEmail,
          'status': 'pending',
        })
        .select('id')
        .single();
      
      return response['id'] as int?;
    } catch (e) {
      print('Erro ao agendar ação: $e');
      return null;
    }
  }

  /// Schedule multiple actions for a quotation
  Future<List<int>> scheduleActionsForQuotation({
    required int quotationId,
    required DateTime travelDate,
    String? clientPhone,
    String? clientEmail,
  }) async {
    final actionIds = <int>[];
    
    for (final entry in _config.hoursBeforeTravel.entries) {
      for (final hours in entry.value) {
        final scheduledAt = travelDate.subtract(Duration(hours: hours));
        
        // Only schedule if in the future
        if (scheduledAt.isAfter(DateTime.now())) {
          final id = await scheduleAction(
            quotationId: quotationId,
            actionType: entry.key,
            scheduledAt: scheduledAt,
            contactPhone: clientPhone,
            contactEmail: clientEmail,
          );
          
          if (id != null) {
            actionIds.add(id);
          }
        }
      }
    }
    
    return actionIds;
  }

  /// Reschedule a failed action
  Future<bool> rescheduleAction(int actionId, DateTime newScheduledAt) async {
    try {
      await _client
        .from('pre_trip_action')
        .update({
          'scheduled_at': newScheduledAt.toIso8601String(),
          'status': 'pending',
          'retry_count': 0,
          'error_message': null,
        })
        .eq('id', actionId);
      return true;
    } catch (e) {
      print('Erro ao reagendar ação: $e');
      return false;
    }
  }

  /// Cancel a scheduled action
  Future<bool> cancelAction(int actionId) async {
    try {
      await _client
        .from('pre_trip_action')
        .delete()
        .eq('id', actionId)
        .eq('status', 'pending');
      return true;
    } catch (e) {
      print('Erro ao cancelar ação: $e');
      return false;
    }
  }

  // =====================================================
  // ACTION EXECUTION
  // =====================================================

  /// Execute a single action
  Future<bool> executeAction(PreTripAction action) async {
    try {
      bool success = false;
      
      switch (action.actionType) {
        case 'call':
          if (onCallAction != null) {
            success = await onCallAction!(action);
          } else {
            // Default: just mark as done (manual call)
            success = true;
            print('📞 LIGAÇÃO AGENDADA:');
            print('   Cliente: ${action.clientName}');
            print('   Telefone: ${action.clientPhone}');
            print('   Cotação: ${action.quotationNumber}');
          }
          break;
          
        case 'email':
          if (onEmailAction != null) {
            success = await onEmailAction!(action);
          } else {
            // Default: log email action
            success = await _sendEmailNotification(action);
          }
          break;
          
        case 'whatsapp':
          if (onWhatsAppAction != null) {
            success = await onWhatsAppAction!(action);
          } else {
            // Default: log whatsapp action
            success = await _sendWhatsAppNotification(action);
          }
          break;
          
        default:
          print('Tipo de ação desconhecido: ${action.actionType}');
          success = false;
      }
      
      if (success) {
        await _quotationService.completeAction(action.id, executedBy: 'system');
      } else if (_config.autoRetry) {
        await _quotationService.failAction(
          action.id, 
          'Falha na execução automática',
          retry: true,
        );
      }
      
      return success;
    } catch (e) {
      print('Erro ao executar ação ${action.id}: $e');
      await _quotationService.failAction(action.id, e.toString(), retry: _config.autoRetry);
      return false;
    }
  }

  /// Process all pending actions
  Future<Map<String, int>> processPendingActions() async {
    if (_isProcessing) {
      return {'skipped': 1, 'processed': 0, 'success': 0, 'failed': 0};
    }
    
    _isProcessing = true;
    int processed = 0;
    int success = 0;
    int failed = 0;
    
    try {
      final actions = await getPendingActions();
      
      for (final action in actions) {
        processed++;
        final result = await executeAction(action);
        if (result) {
          success++;
        } else {
          failed++;
        }
        
        // Small delay between actions
        await Future<void>.delayed(const Duration(milliseconds: 500));
      }
    } finally {
      _isProcessing = false;
    }
    
    return {
      'processed': processed,
      'success': success,
      'failed': failed,
    };
  }

  // =====================================================
  // DEFAULT ACTION IMPLEMENTATIONS
  // =====================================================

  /// Send email notification (stub - integrate with email service)
  Future<bool> _sendEmailNotification(PreTripAction action) async {
    print('📧 EMAIL AGENDADO:');
    print('   Para: ${action.clientEmail}');
    print('   Assunto: Confirmação de viagem - ${action.quotationNumber}');
    
    // TODO: Integrate with actual email service
    // Example:
    // await emailService.send(
    //   to: action.clientEmail,
    //   subject: 'Confirmação de viagem',
    //   body: template.formatBody(values),
    // );
    
    return true; // Simulate success
  }

  /// Send WhatsApp notification (stub - integrate with WhatsApp service)
  Future<bool> _sendWhatsAppNotification(PreTripAction action) async {
    print('📱 WHATSAPP AGENDADO:');
    print('   Para: ${action.clientPhone}');
    print('   Cotação: ${action.quotationNumber}');
    
    // TODO: Integrate with actual WhatsApp service
    // Example:
    // await whatsAppService.sendMessage(
    //   phone: action.clientPhone,
    //   message: template.formatBody(values),
    // );
    
    return true; // Simulate success
  }

  // =====================================================
  // POLLING / SCHEDULER
  // =====================================================

  /// Start automatic polling for pending actions
  void startPolling({Duration interval = const Duration(minutes: 5)}) {
    stopPolling();
    
    _pollingTimer = Timer.periodic(interval, (_) async {
      print('🔄 Verificando ações pendentes...');
      final result = await processPendingActions();
      print('   Processadas: ${result['processed']}, Sucesso: ${result['success']}, Falha: ${result['failed']}');
    });
    
    print('✅ Polling iniciado (intervalo: ${interval.inMinutes} minutos)');
  }

  /// Stop automatic polling
  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    print('⏹️ Polling parado');
  }

  /// Check if polling is active
  bool get isPolling => _pollingTimer?.isActive ?? false;

  // =====================================================
  // UTILITY METHODS
  // =====================================================

  /// Build context for message templates
  Map<String, String> buildTemplateContext(PreTripAction action, Map<String, dynamic>? quotationData) {
    return {
      'client_name': action.clientName ?? quotationData?['client_name'] ?? 'Cliente',
      'client_phone': action.clientPhone ?? quotationData?['client_phone'] ?? '',
      'client_email': action.clientEmail ?? quotationData?['client_email'] ?? '',
      'quotation_number': action.quotationNumber ?? quotationData?['quotation_number'] ?? '',
      'travel_date': _formatDate(action.travelDate ?? DateTime.now()),
      'pickup_time': _formatTime(action.travelDate ?? DateTime.now()),
      'pickup_location': quotationData?['pickup_location'] ?? quotationData?['origin'] ?? 'A definir',
      'vehicle': quotationData?['vehicle'] ?? 'Van executiva',
      'driver_name': quotationData?['driver'] ?? 'Nosso motorista',
      'driver_phone': quotationData?['driver_phone'] ?? '',
      'passenger_count': quotationData?['passenger_count']?.toString() ?? '1',
      'service_description': quotationData?['service_description'] ?? 'Transfer',
      'total_formatted': _formatCurrency(quotationData?['total'] ?? 0),
      'notes': quotationData?['notes'] ?? '',
      'company_phone': '+1 (555) 123-4567',
      'company_email': 'contato@lecotour.com',
    };
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatCurrency(num value) {
    return 'USD ${value.toStringAsFixed(2)}';
  }

  /// Dispose resources
  void dispose() {
    stopPolling();
  }
}

