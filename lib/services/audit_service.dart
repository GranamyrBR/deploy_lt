import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/activity_log_model.dart';

/// Serviço para registrar e consultar logs de auditoria
class AuditService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Registra uma atividade no log
  Future<int> logActivity({
    required String userId,
    required String userName,
    String? userEmail,
    required String actionType,
    required String entityType,
    required String entityId,
    String? entityName,
    required String actionDescription,
    Map<String, dynamic>? oldValue,
    Map<String, dynamic>? newValue,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final result = await _supabase.rpc<int>(
        'log_activity',
        params: {
          'p_user_id': userId,
          'p_user_name': userName,
          'p_user_email': userEmail,
          'p_action_type': actionType,
          'p_entity_type': entityType,
          'p_entity_id': entityId,
          'p_entity_name': entityName,
          'p_action_description': actionDescription,
          'p_old_value': oldValue,
          'p_new_value': newValue,
          'p_metadata': metadata,
        },
      );

      return result;
    } catch (e) {
      print('Erro ao registrar log: $e');
      rethrow;
    }
  }

  /// Busca os logs de atividade de uma cotação
  Future<List<ActivityLog>> getQuotationActivityLogs(String quotationId) async {
    try {
      final response = await _supabase.rpc<List<dynamic>>(
        'get_quotation_activity_logs',
        params: {'p_quotation_id': quotationId},
      );

      return (response as List)
          .map((json) => ActivityLog.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Erro ao buscar logs de atividade: $e');
      return [];
    }
  }

  /// Busca os logs de atividade de um usuário
  Future<List<ActivityLog>> getUserActivityLogs(String userId, {int limit = 100}) async {
    try {
      final response = await _supabase.rpc<List<dynamic>>(
        'get_user_activity_logs',
        params: {
          'p_user_id': userId,
          'p_limit': limit,
        },
      );

      return (response as List)
          .map((json) => ActivityLog.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Erro ao buscar logs do usuário: $e');
      return [];
    }
  }

  /// Cria um follow-up
  Future<int> createFollowUp({
    required int quotationId,
    required String assignedTo,
    required String assignedName,
    String? assignedEmail,
    required String type,
    required String priority,
    required DateTime scheduledDate,
    required String title,
    String? description,
    required String createdBy,
  }) async {
    try {
      final result = await _supabase.rpc<int>(
        'create_follow_up',
        params: {
          'p_quotation_id': quotationId,
          'p_assigned_to': assignedTo,
          'p_assigned_name': assignedName,
          'p_assigned_email': assignedEmail,
          'p_type': type,
          'p_priority': priority,
          'p_scheduled_date': scheduledDate.toIso8601String(),
          'p_title': title,
          'p_description': description,
          'p_created_by': createdBy,
        },
      );

      return result;
    } catch (e) {
      print('Erro ao criar follow-up: $e');
      rethrow;
    }
  }

  /// Busca os follow-ups de uma cotação
  Future<List<QuotationFollowUp>> getQuotationFollowUps(int quotationId) async {
    try {
      final response = await _supabase.rpc<List<dynamic>>(
        'get_quotation_follow_ups',
        params: {'p_quotation_id': quotationId},
      );

      return (response as List)
          .map((json) => QuotationFollowUp.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Erro ao buscar follow-ups: $e');
      return [];
    }
  }

  /// Completa um follow-up
  Future<void> completeFollowUp({
    required int followUpId,
    required String result,
    required String completedBy,
  }) async {
    try {
      await _supabase.rpc<void>(
        'complete_follow_up',
        params: {
          'p_follow_up_id': followUpId,
          'p_result': result,
          'p_completed_by': completedBy,
        },
      );
    } catch (e) {
      print('Erro ao completar follow-up: $e');
      rethrow;
    }
  }

  /// Busca estatísticas de um vendedor
  Future<SellerStats> getSellerStats(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final response = await _supabase.rpc<Map<String, dynamic>>(
        'get_seller_stats',
        params: {
          'p_user_id': userId,
          'p_start_date': startDate?.toIso8601String(),
          'p_end_date': endDate?.toIso8601String(),
        },
      );

      return SellerStats.fromJson(response);
    } catch (e) {
      print('Erro ao buscar estatísticas: $e');
      // Retorna estatísticas vazias em caso de erro
      return SellerStats(
        totalQuotations: 0,
        acceptedQuotations: 0,
        pendingQuotations: 0,
        rejectedQuotations: 0,
        totalValue: 0,
        acceptedValue: 0,
        totalCommission: 0,
        conversionRate: 0,
        avgQuotationValue: 0,
        followUpsCompleted: 0,
        followUpsPending: 0,
      );
    }
  }

  /// Busca todos os follow-ups pendentes de um usuário
  Future<List<QuotationFollowUp>> getUserPendingFollowUps(String userId) async {
    try {
      final response = await _supabase
          .from('quotation_follow_up')
          .select()
          .eq('assigned_to', userId)
          .eq('status', 'pending')
          .order('scheduled_date', ascending: true);

      return (response as List)
          .map((json) => QuotationFollowUp.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Erro ao buscar follow-ups pendentes: $e');
      return [];
    }
  }

  /// Busca follow-ups atrasados de um usuário
  Future<List<QuotationFollowUp>> getUserOverdueFollowUps(String userId) async {
    try {
      final now = DateTime.now().toUtc().toIso8601String();
      final response = await _supabase
          .from('quotation_follow_up')
          .select()
          .eq('assigned_to', userId)
          .eq('status', 'pending')
          .lt('scheduled_date', now)
          .order('scheduled_date', ascending: true);

      return (response as List)
          .map((json) => QuotationFollowUp.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Erro ao buscar follow-ups atrasados: $e');
      return [];
    }
  }
}

