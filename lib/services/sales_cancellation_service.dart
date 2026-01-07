import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/sales_cancellation_log.dart';
import '../models/sales_cancellation_item.dart';
import '../models/sales_cancellation_payment.dart';

class SalesCancellationService {
  SupabaseClient get _client => Supabase.instance.client;

  // =====================================================
  // CANCELAR VENDA
  // =====================================================

  Future<int> cancelSale({
    required int saleId,
    required String cancellationReason,
    required String cancelledByUserId,
    required String cancelledByUserName,
    String cancellationType = 'other',
    String? notes,
  }) async {
    try {
      final response = await _client.rpc('cancel_sale', params: {
        'p_sale_id': saleId,
        'p_cancellation_reason': cancellationReason,
        'p_cancelled_by_user_id': cancelledByUserId,
        'p_cancelled_by_user_name': cancelledByUserName,
        'p_cancellation_type': cancellationType,
        'p_notes': notes,
      });

      return response as int;
    } catch (e) {
      print('Erro ao cancelar venda: $e');
      rethrow;
    }
  }

  // =====================================================
  // BUSCAR LOGS DE CANCELAMENTO
  // =====================================================

  Future<List<SalesCancellationLog>> getCancellationLogs({
    String? userId,
    String? contactId,
    String? cancellationType,
    String? refundStatus,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    try {
      var query = _client
          .from('sales_cancellation_logs_complete')
          .select();

      // Aplicar filtros
      if (userId != null) {
        query = query.eq('user_id', userId);
      }
      if (contactId != null) {
        query = query.eq('contact_id', contactId);
      }
      if (cancellationType != null) {
        query = query.eq('cancellation_type', cancellationType);
      }
      if (refundStatus != null) {
        query = query.eq('refund_status', refundStatus);
      }
      if (startDate != null) {
        query = query.gte('cancelled_at', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('cancelled_at', endDate.toIso8601String());
      }

      // Aplicar ordenação e limite
      final response = await query.order('cancelled_at', ascending: false).limit(limit ?? 100);
      
      return (response as List)
          .map((json) => SalesCancellationLog.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Erro ao buscar logs de cancelamento: $e');
      rethrow;
    }
  }

  Future<SalesCancellationLog?> getCancellationLogById(int id) async {
    try {
      final response = await _client
          .from('sales_cancellation_logs_complete')
          .select()
          .eq('id', id)
          .single();

      return SalesCancellationLog.fromJson(response);
    } catch (e) {
      print('Erro ao buscar log de cancelamento: $e');
      return null;
    }
  }

  Future<SalesCancellationLog?> getCancellationLogBySaleId(int saleId) async {
    try {
      final response = await _client
          .from('sales_cancellation_logs_complete')
          .select()
          .eq('sale_id', saleId)
          .single();

      return SalesCancellationLog.fromJson(response);
    } catch (e) {
      print('Erro ao buscar log de cancelamento por venda: $e');
      return null;
    }
  }

  // =====================================================
  // BUSCAR ITENS CANCELADOS
  // =====================================================

  Future<List<SalesCancellationItem>> getCancellationItems(int cancellationLogId) async {
    try {
      final response = await _client
          .from('sales_cancellation_items')
          .select()
          .eq('cancellation_log_id', cancellationLogId)
          .order('created_at');

      return (response as List)
          .map((json) => SalesCancellationItem.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Erro ao buscar itens cancelados: $e');
      return [];
    }
  }

  // =====================================================
  // BUSCAR PAGAMENTOS CANCELADOS
  // =====================================================

  Future<List<SalesCancellationPayment>> getCancellationPayments(int cancellationLogId) async {
    try {
      final response = await _client
          .from('sales_cancellation_payments')
          .select()
          .eq('cancellation_log_id', cancellationLogId)
          .order('payment_date');

      return (response as List)
          .map((json) => SalesCancellationPayment.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Erro ao buscar pagamentos cancelados: $e');
      return [];
    }
  }

  // =====================================================
  // ATUALIZAR STATUS DE REEMBOLSO
  // =====================================================

  Future<void> updateRefundStatus({
    required int cancellationLogId,
    required String refundStatus,
    String? refundMethod,
    String? refundTransactionId,
    DateTime? refundDate,
  }) async {
    try {
      final updateData = {
        'refund_status': refundStatus,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };

      if (refundMethod != null) {
        updateData['refund_method'] = refundMethod;
      }
      if (refundTransactionId != null) {
        updateData['refund_transaction_id'] = refundTransactionId;
      }
      if (refundDate != null) {
        updateData['refund_date'] = refundDate.toIso8601String();
      }

      await _client
          .from('sales_cancellation_logs')
          .update(updateData)
          .eq('id', cancellationLogId);
    } catch (e) {
      print('Erro ao atualizar status de reembolso: $e');
      rethrow;
    }
  }

  Future<void> updatePaymentRefundStatus({
    required int paymentId,
    required String refundStatus,
    String? refundTransactionId,
    DateTime? refundDate,
  }) async {
    try {
      final updateData = {
        'refund_status': refundStatus,
      };

      if (refundTransactionId != null) {
        updateData['refund_transaction_id'] = refundTransactionId;
      }
      if (refundDate != null) {
        updateData['refund_date'] = refundDate.toIso8601String();
      }

      await _client
          .from('sales_cancellation_payments')
          .update(updateData)
          .eq('id', paymentId);
    } catch (e) {
      print('Erro ao atualizar status de reembolso do pagamento: $e');
      rethrow;
    }
  }

  // =====================================================
  // ESTATÍSTICAS DE CANCELAMENTO
  // =====================================================

  Future<Map<String, dynamic>> getCancellationStats({
    DateTime? startDate,
    DateTime? endDate,
    String? userId,
  }) async {
    try {
      var query = _client
          .from('sales_cancellation_logs_complete')
          .select('cancellation_type, total_amount, refund_amount, refund_status');

      // Aplicar filtros
      if (startDate != null) {
        query = query.gte('cancelled_at', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('cancelled_at', endDate.toIso8601String());
      }
      if (userId != null) {
        query = query.eq('user_id', userId);
      }

      final response = await query;
      final logs = (response as List)
          .map((json) => SalesCancellationLog.fromJson(json as Map<String, dynamic>))
          .toList();

      // Calcular estatísticas
      final totalCancellations = logs.length;
      final totalAmountCancelled = logs.fold<double>(0, (sum, log) => sum + log.totalAmount);
      final totalRefundAmount = logs.fold<double>(0, (sum, log) => sum + log.refundAmount);
      
      // Por tipo de cancelamento
      final cancellationsByType = <String, int>{};
      final amountsByType = <String, double>{};
      
      for (final log in logs) {
        cancellationsByType[log.cancellationType] = (cancellationsByType[log.cancellationType] ?? 0) + 1;
        amountsByType[log.cancellationType] = (amountsByType[log.cancellationType] ?? 0) + log.totalAmount;
      }

      // Por status de reembolso
      final refundsByStatus = <String, int>{};
      for (final log in logs) {
        if (log.refundRequired) {
          refundsByStatus[log.refundStatus] = (refundsByStatus[log.refundStatus] ?? 0) + 1;
        }
      }

      return {
        'total_cancellations': totalCancellations,
        'total_amount_cancelled': totalAmountCancelled,
        'total_refund_amount': totalRefundAmount,
        'cancellations_by_type': cancellationsByType,
        'amounts_by_type': amountsByType,
        'refunds_by_status': refundsByStatus,
        'avg_amount_cancelled': totalCancellations > 0 ? totalAmountCancelled / totalCancellations : 0,
      };
    } catch (e) {
      print('Erro ao buscar estatísticas de cancelamento: $e');
      rethrow;
    }
  }

  // =====================================================
  // BUSCAR CANCELAMENTOS QUE PRECISAM DE REEMBOLSO
  // =====================================================

  Future<List<SalesCancellationLog>> getPendingRefunds() async {
    try {
      final response = await _client
          .from('sales_cancellation_logs_complete')
          .select()
          .eq('refund_required', true)
          .eq('refund_status', 'pending')
          .order('cancelled_at', ascending: false);

      return (response as List)
          .map((json) => SalesCancellationLog.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Erro ao buscar cancelamentos pendentes de reembolso: $e');
      rethrow;
    }
  }

  // =====================================================
  // BUSCAR CANCELAMENTOS POR CLIENTE
  // =====================================================

  Future<List<SalesCancellationLog>> getCancellationsByContact(int contactId) async {
    try {
      final response = await _client
          .from('sales_cancellation_logs_complete')
          .select()
          .eq('contact_id', contactId)
          .order('cancelled_at', ascending: false);

      return (response as List)
          .map((json) => SalesCancellationLog.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Erro ao buscar cancelamentos por cliente: $e');
      rethrow;
    }
  }
} 
