import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/sales_cancellation_log.dart';
import '../models/sales_cancellation_item.dart';
import '../models/sales_cancellation_payment.dart';
import '../services/sales_cancellation_service.dart';

// =====================================================
// PROVIDERS PARA LOGS DE CANCELAMENTO
// =====================================================

final salesCancellationServiceProvider = Provider<SalesCancellationService>((ref) {
  return SalesCancellationService();
});

// Provider para logs de cancelamento
final salesCancellationLogsProvider = StateNotifierProvider<SalesCancellationLogsNotifier, AsyncValue<List<SalesCancellationLog>>>((ref) {
  return SalesCancellationLogsNotifier(ref.read(salesCancellationServiceProvider));
});

// Provider para um log específico
final salesCancellationLogProvider = FutureProvider.family<SalesCancellationLog?, int>((ref, id) async {
  final service = ref.read(salesCancellationServiceProvider);
  return await service.getCancellationLogById(id);
});

// Provider para itens de um log de cancelamento
final salesCancellationItemsProvider = FutureProvider.family<List<SalesCancellationItem>, int>((ref, cancellationLogId) async {
  final service = ref.read(salesCancellationServiceProvider);
  return await service.getCancellationItems(cancellationLogId);
});

// Provider para pagamentos de um log de cancelamento
final salesCancellationPaymentsProvider = FutureProvider.family<List<SalesCancellationPayment>, int>((ref, cancellationLogId) async {
  final service = ref.read(salesCancellationServiceProvider);
  return await service.getCancellationPayments(cancellationLogId);
});

// Provider para estatísticas de cancelamento
final salesCancellationStatsProvider = FutureProvider.family<Map<String, dynamic>, Map<String, dynamic>>((ref, filters) async {
  final service = ref.read(salesCancellationServiceProvider);
  return await service.getCancellationStats(
    startDate: filters['startDate'] as DateTime?,
    endDate: filters['endDate'] as DateTime?,
    userId: filters['userId'] as String?,
  );
});

// Provider para cancelamentos pendentes de reembolso
final pendingRefundsProvider = FutureProvider<List<SalesCancellationLog>>((ref) async {
  final service = ref.read(salesCancellationServiceProvider);
  return await service.getPendingRefunds();
});

// Provider para cancelamentos por cliente
final contactCancellationsProvider = FutureProvider.family<List<SalesCancellationLog>, int>((ref, contactId) async {
  final service = ref.read(salesCancellationServiceProvider);
  return await service.getCancellationsByContact(contactId);
});

// =====================================================
// NOTIFIER PARA LOGS DE CANCELAMENTO
// =====================================================

class SalesCancellationLogsNotifier extends StateNotifier<AsyncValue<List<SalesCancellationLog>>> {
  final SalesCancellationService _service;

  SalesCancellationLogsNotifier(this._service) : super(const AsyncValue.loading());

  // Buscar logs de cancelamento com filtros
  Future<void> fetchCancellationLogs({
    String? userId,
    String? contactId,
    String? cancellationType,
    String? refundStatus,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    state = const AsyncValue.loading();
    
    try {
      final logs = await _service.getCancellationLogs(
        userId: userId,
        contactId: contactId,
        cancellationType: cancellationType,
        refundStatus: refundStatus,
        startDate: startDate,
        endDate: endDate,
        limit: limit,
      );
      
      state = AsyncValue.data(logs);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // Cancelar uma venda
  Future<void> cancelSale({
    required int saleId,
    required String cancellationReason,
    required String cancelledByUserId,
    required String cancelledByUserName,
    String cancellationType = 'other',
    String? notes,
  }) async {
    try {
      await _service.cancelSale(
        saleId: saleId,
        cancellationReason: cancellationReason,
        cancelledByUserId: cancelledByUserId,
        cancelledByUserName: cancelledByUserName,
        cancellationType: cancellationType,
        notes: notes,
      );
      
      // Recarregar a lista após cancelar
      await fetchCancellationLogs();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // Atualizar status de reembolso
  Future<void> updateRefundStatus({
    required int cancellationLogId,
    required String refundStatus,
    String? refundMethod,
    String? refundTransactionId,
    DateTime? refundDate,
  }) async {
    try {
      await _service.updateRefundStatus(
        cancellationLogId: cancellationLogId,
        refundStatus: refundStatus,
        refundMethod: refundMethod,
        refundTransactionId: refundTransactionId,
        refundDate: refundDate,
      );
      
      // Recarregar a lista após atualizar
      await fetchCancellationLogs();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // Atualizar status de reembolso de um pagamento específico
  Future<void> updatePaymentRefundStatus({
    required int paymentId,
    required String refundStatus,
    String? refundTransactionId,
    DateTime? refundDate,
  }) async {
    try {
      await _service.updatePaymentRefundStatus(
        paymentId: paymentId,
        refundStatus: refundStatus,
        refundTransactionId: refundTransactionId,
        refundDate: refundDate,
      );
      
      // Recarregar a lista após atualizar
      await fetchCancellationLogs();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // Limpar estado
  void clear() {
    state = const AsyncValue.data([]);
  }
}

// =====================================================
// PROVIDERS PARA FILTROS
// =====================================================

// Provider para filtros de cancelamento
final cancellationFiltersProvider = StateProvider<Map<String, dynamic>>((ref) => {});

// Provider para logs filtrados
final filteredCancellationLogsProvider = Provider<AsyncValue<List<SalesCancellationLog>>>((ref) {
  final filters = ref.watch(cancellationFiltersProvider);
  final logsAsync = ref.watch(salesCancellationLogsProvider);
  
  return logsAsync.when(
    data: (logs) {
      // Aplicar filtros adicionais se necessário
      var filteredLogs = logs;
      
      // Filtrar por tipo de cancelamento
      if (filters['cancellationType'] != null) {
        filteredLogs = filteredLogs.where((log) => 
          log.cancellationType == filters['cancellationType']
        ).toList();
      }
      
      // Filtrar por status de reembolso
      if (filters['refundStatus'] != null) {
        filteredLogs = filteredLogs.where((log) => 
          log.refundStatus == filters['refundStatus']
        ).toList();
      }
      
      // Filtrar por cliente
      if (filters['contactId'] != null) {
        filteredLogs = filteredLogs.where((log) => 
          log.contactId == filters['contactId']
        ).toList();
      }
      
      return AsyncValue.data(filteredLogs);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
  );
});

// =====================================================
// PROVIDERS PARA ESTATÍSTICAS EM TEMPO REAL
// =====================================================

// Provider para estatísticas dos logs carregados
final cancellationLogsStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final logsAsync = ref.watch(salesCancellationLogsProvider);
  
  return logsAsync.when(
    data: (logs) {
      if (logs.isEmpty) {
        return {
          'total_cancellations': 0,
          'total_amount_cancelled': 0.0,
          'total_refund_amount': 0.0,
          'avg_amount_cancelled': 0.0,
          'cancellations_by_type': <String, int>{},
          'refunds_by_status': <String, int>{},
        };
      }
      
      final totalCancellations = logs.length;
      final totalAmountCancelled = logs.fold<double>(0, (sum, log) => sum + log.totalAmount);
      final totalRefundAmount = logs.fold<double>(0, (sum, log) => sum + log.refundAmount);
      
      // Por tipo de cancelamento
      final cancellationsByType = <String, int>{};
      for (final log in logs) {
        cancellationsByType[log.cancellationType] = (cancellationsByType[log.cancellationType] ?? 0) + 1;
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
        'avg_amount_cancelled': totalAmountCancelled / totalCancellations,
        'cancellations_by_type': cancellationsByType,
        'refunds_by_status': refundsByStatus,
      };
    },
    loading: () => {
      'total_cancellations': 0,
      'total_amount_cancelled': 0.0,
      'total_refund_amount': 0.0,
      'avg_amount_cancelled': 0.0,
      'cancellations_by_type': <String, int>{},
      'refunds_by_status': <String, int>{},
    },
    error: (_, __) => {
      'total_cancellations': 0,
      'total_amount_cancelled': 0.0,
      'total_refund_amount': 0.0,
      'avg_amount_cancelled': 0.0,
      'cancellations_by_type': <String, int>{},
      'refunds_by_status': <String, int>{},
    },
  );
}); 
