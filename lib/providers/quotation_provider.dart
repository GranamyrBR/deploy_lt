import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:state_notifier/state_notifier.dart';

import '../models/enhanced_quotation_model.dart';
import '../services/quotation_service.dart';

// =====================================================
// QUOTATION SERVICE PROVIDER
// =====================================================

final quotationServiceProvider = Provider<QuotationService>((ref) {
  return QuotationService();
});

// =====================================================
// QUOTATION STATE
// =====================================================

class QuotationState {
  final List<Map<String, dynamic>> quotations;
  final Map<String, dynamic>? selectedQuotation;
  final QuotationFull? selectedQuotationFull;
  final List<Map<String, dynamic>> quotationItems;
  final SmartSuggestions? suggestions;
  final QuotationStats? stats;
  final bool isLoading;
  final bool isSaving;
  final String? error;
  final String? successMessage;
  final QuotationFilter currentFilter;
  final String searchQuery;

  const QuotationState({
    this.quotations = const [],
    this.selectedQuotation,
    this.selectedQuotationFull,
    this.quotationItems = const [],
    this.suggestions,
    this.stats,
    this.isLoading = false,
    this.isSaving = false,
    this.error,
    this.successMessage,
    this.currentFilter = const QuotationFilter(),
    this.searchQuery = '',
  });

  QuotationState copyWith({
    List<Map<String, dynamic>>? quotations,
    Map<String, dynamic>? selectedQuotation,
    QuotationFull? selectedQuotationFull,
    List<Map<String, dynamic>>? quotationItems,
    SmartSuggestions? suggestions,
    QuotationStats? stats,
    bool? isLoading,
    bool? isSaving,
    String? error,
    String? successMessage,
    QuotationFilter? currentFilter,
    String? searchQuery,
    bool clearSelected = false,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return QuotationState(
      quotations: quotations ?? this.quotations,
      selectedQuotation: clearSelected ? null : (selectedQuotation ?? this.selectedQuotation),
      selectedQuotationFull: clearSelected ? null : (selectedQuotationFull ?? this.selectedQuotationFull),
      quotationItems: clearSelected ? [] : (quotationItems ?? this.quotationItems),
      suggestions: suggestions ?? this.suggestions,
      stats: stats ?? this.stats,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
      currentFilter: currentFilter ?? this.currentFilter,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  // Computed properties
  int get totalQuotations => quotations.length;
  
  int get draftCount => quotations.where((q) => q['status'] == 'draft').length;
  int get sentCount => quotations.where((q) => q['status'] == 'sent').length;
  int get viewedCount => quotations.where((q) => q['status'] == 'viewed').length;
  int get acceptedCount => quotations.where((q) => q['status'] == 'accepted').length;
  int get rejectedCount => quotations.where((q) => q['status'] == 'rejected').length;
  int get expiredCount => quotations.where((q) => q['status'] == 'expired').length;
  int get cancelledCount => quotations.where((q) => q['status'] == 'cancelled').length;

  List<Map<String, dynamic>> get filteredQuotations {
    if (searchQuery.isEmpty) return quotations;
    
    final query = searchQuery.toLowerCase();
    return quotations.where((q) {
      final clientName = (q['client_name'] as String?)?.toLowerCase() ?? '';
      final clientEmail = (q['client_email'] as String?)?.toLowerCase() ?? '';
      final quotationNumber = (q['quotation_number'] as String?)?.toLowerCase() ?? '';
      final notes = (q['notes'] as String?)?.toLowerCase() ?? '';
      
      return clientName.contains(query) ||
             clientEmail.contains(query) ||
             quotationNumber.contains(query) ||
             notes.contains(query);
    }).toList();
  }

  List<Map<String, dynamic>> getByStatus(String status) {
    return quotations.where((q) => q['status'] == status).toList();
  }
}

// =====================================================
// QUOTATION NOTIFIER
// =====================================================

class QuotationNotifier extends StateNotifier<QuotationState> {
  final QuotationService _service;

  QuotationNotifier(this._service) : super(const QuotationState()) {
    loadQuotations();
  }

  // =====================================================
  // LOAD OPERATIONS
  // =====================================================

  /// Load all quotations with optional filter
  Future<void> loadQuotations({QuotationFilter? filter}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    
    try {
      final quotations = await _service.getQuotations(filter: filter ?? state.currentFilter);
      state = state.copyWith(
        quotations: quotations,
        currentFilter: filter ?? state.currentFilter,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao carregar cotações: $e',
      );
    }
  }

  /// Load quotations by client ID
  Future<void> loadByClient(int clientId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    
    try {
      final quotations = await _service.getByClient(clientId);
      state = state.copyWith(
        quotations: quotations,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao carregar cotações do cliente: $e',
      );
    }
  }

  /// Load quotations by status
  Future<void> loadByStatus(String status) async {
    state = state.copyWith(isLoading: true, clearError: true);
    
    try {
      final quotations = await _service.getByStatus(status);
      state = state.copyWith(
        quotations: quotations,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao carregar cotações: $e',
      );
    }
  }

  /// Load expiring quotations
  Future<void> loadExpiring({int daysAhead = 3}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    
    try {
      final quotations = await _service.getExpiring(daysAhead: daysAhead);
      state = state.copyWith(
        quotations: quotations,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao carregar cotações expirando: $e',
      );
    }
  }

  /// Load a single quotation by ID
  Future<void> selectQuotation(int id) async {
    state = state.copyWith(isLoading: true, clearError: true);
    
    try {
      final quotationFull = await _service.getById(id);
      
      if (quotationFull != null) {
        state = state.copyWith(
          selectedQuotation: quotationFull.quotation,
          selectedQuotationFull: quotationFull,
          quotationItems: quotationFull.items,
          isLoading: false,
        );
        
        // Load suggestions for this quotation
        await loadSuggestions(quotationId: id);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Cotação não encontrada',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao carregar cotação: $e',
      );
    }
  }

  /// Clear selected quotation
  void clearSelection() {
    state = state.copyWith(clearSelected: true);
  }

  /// Load quotation statistics
  Future<void> loadStats({DateTime? fromDate, DateTime? toDate, String? userId}) async {
    try {
      final stats = await _service.getStats(
        fromDate: fromDate,
        toDate: toDate,
        userId: userId,
      );
      state = state.copyWith(stats: stats);
    } catch (e) {
      print('Erro ao carregar estatísticas: $e');
    }
  }

  // =====================================================
  // CREATE OPERATIONS
  // =====================================================

  /// Create a new quotation
  Future<QuotationSaveResult> createQuotation(Quotation quotation) async {
    state = state.copyWith(isSaving: true, clearError: true, clearSuccess: true);
    
    try {
      // Validate first
      final validationError = _service.validateQuotation(quotation);
      if (validationError != null) {
        state = state.copyWith(
          isSaving: false,
          error: validationError,
        );
        return QuotationSaveResult(id: 0, success: false, errorMessage: validationError);
      }
      
      final result = await _service.saveQuotation(quotation);
      
      if (result.success) {
        state = state.copyWith(
          isSaving: false,
          successMessage: 'Cotação ${quotation.quotationNumber} criada com sucesso!',
        );
        
        // Reload quotations
        await loadQuotations();
      } else {
        state = state.copyWith(
          isSaving: false,
          error: result.errorMessage ?? 'Erro ao criar cotação',
        );
      }
      
      return result;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: 'Erro ao criar cotação: $e',
      );
      return QuotationSaveResult(id: 0, success: false, errorMessage: e.toString());
    }
  }

  /// Duplicate an existing quotation
  Future<int?> duplicateQuotation(int quotationId, {String? createdBy}) async {
    state = state.copyWith(isSaving: true, clearError: true);
    
    try {
      final newId = await _service.duplicateQuotation(quotationId, createdBy: createdBy);
      
      state = state.copyWith(
        isSaving: false,
        successMessage: 'Cotação duplicada com sucesso!',
      );
      
      await loadQuotations();
      return newId;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: 'Erro ao duplicar cotação: $e',
      );
      return null;
    }
  }

  // =====================================================
  // UPDATE OPERATIONS
  // =====================================================

  /// Update quotation with patch data
  Future<bool> updateQuotation(int id, {
    String? status,
    String? notes,
    String? specialRequests,
    String? hotel,
    String? vehicle,
    String? driver,
    int? passengerCount,
    DateTime? travelDate,
    DateTime? returnDate,
    DateTime? expirationDate,
    double? discountAmount,
    String? updatedBy,
  }) async {
    state = state.copyWith(isSaving: true, clearError: true);
    
    try {
      final success = await _service.update(
        id,
        status: status,
        notes: notes,
        specialRequests: specialRequests,
        hotel: hotel,
        vehicle: vehicle,
        driver: driver,
        passengerCount: passengerCount,
        travelDate: travelDate,
        returnDate: returnDate,
        expirationDate: expirationDate,
        discountAmount: discountAmount,
        updatedBy: updatedBy,
      );
      
      if (success) {
        state = state.copyWith(
          isSaving: false,
          successMessage: 'Cotação atualizada com sucesso!',
        );
        
        // Reload current quotation if selected
        if (state.selectedQuotation?['id'] == id) {
          await selectQuotation(id);
        }
        
        await loadQuotations();
      } else {
        state = state.copyWith(
          isSaving: false,
          error: 'Erro ao atualizar cotação',
        );
      }
      
      return success;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: 'Erro ao atualizar cotação: $e',
      );
      return false;
    }
  }

  /// Update quotation status
  Future<bool> updateStatus(int id, String newStatus, {String? updatedBy}) async {
    return updateQuotation(id, status: newStatus, updatedBy: updatedBy);
  }

  /// Mark quotation as sent
  Future<bool> markAsSent(int id, {String? updatedBy}) async {
    return updateStatus(id, 'sent', updatedBy: updatedBy);
  }

  /// Mark quotation as viewed
  Future<bool> markAsViewed(int id, {String? updatedBy}) async {
    return updateStatus(id, 'viewed', updatedBy: updatedBy);
  }

  /// Mark quotation as accepted
  Future<bool> markAsAccepted(int id, {String? updatedBy}) async {
    return updateStatus(id, 'accepted', updatedBy: updatedBy);
  }

  /// Mark quotation as rejected
  Future<bool> markAsRejected(int id, {String? updatedBy}) async {
    return updateStatus(id, 'rejected', updatedBy: updatedBy);
  }

  /// Mark quotation as cancelled
  Future<bool> markAsCancelled(int id, {String? updatedBy}) async {
    return updateStatus(id, 'cancelled', updatedBy: updatedBy);
  }

  // =====================================================
  // DELETE OPERATIONS
  // =====================================================

  /// Delete a quotation
  Future<bool> deleteQuotation(int id, {bool hardDelete = false}) async {
    state = state.copyWith(isSaving: true, clearError: true);
    
    try {
      final success = await _service.deleteQuotation(id, hardDelete: hardDelete);
      
      if (success) {
        state = state.copyWith(
          isSaving: false,
          successMessage: 'Cotação excluída com sucesso!',
          clearSelected: state.selectedQuotation?['id'] == id,
        );
        
        await loadQuotations();
      } else {
        state = state.copyWith(
          isSaving: false,
          error: 'Erro ao excluir cotação',
        );
      }
      
      return success;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: 'Erro ao excluir cotação: $e',
      );
      return false;
    }
  }

  // =====================================================
  // CONVERSION OPERATIONS
  // =====================================================

  /// Convert quotation to sale
  Future<int?> convertToSale(int quotationId, String userId, {String paymentMethod = 'pending'}) async {
    state = state.copyWith(isSaving: true, clearError: true);
    
    try {
      final saleId = await _service.convertToSale(quotationId, userId, paymentMethod: paymentMethod);
      
      if (saleId != null) {
        state = state.copyWith(
          isSaving: false,
          successMessage: 'Cotação convertida em venda #$saleId!',
        );
        
        await loadQuotations();
      } else {
        state = state.copyWith(
          isSaving: false,
          error: 'Erro ao converter cotação em venda',
        );
      }
      
      return saleId;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: 'Erro ao converter cotação: $e',
      );
      return null;
    }
  }

  // =====================================================
  // SUGGESTIONS
  // =====================================================

  /// Load suggestions for a quotation or client
  Future<void> loadSuggestions({
    int? quotationId,
    int? clientId,
    String? destination,
    String? hotel,
  }) async {
    try {
      final suggestions = await _service.getSmartSuggestions(
        quotationId: quotationId,
        clientId: clientId,
        destination: destination,
        hotel: hotel,
      );
      state = state.copyWith(suggestions: suggestions);
    } catch (e) {
      print('Erro ao carregar sugestões: $e');
    }
  }

  // =====================================================
  // SEARCH AND FILTER
  // =====================================================

  /// Set search query
  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  /// Clear search query
  void clearSearch() {
    state = state.copyWith(searchQuery: '');
  }

  /// Apply filter
  Future<void> applyFilter(QuotationFilter filter) async {
    state = state.copyWith(currentFilter: filter);
    await loadQuotations(filter: filter);
  }

  /// Reset filter
  Future<void> resetFilter() async {
    state = state.copyWith(currentFilter: const QuotationFilter());
    await loadQuotations();
  }

  // =====================================================
  // UTILITY METHODS
  // =====================================================

  /// Clear error message
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Clear success message
  void clearSuccess() {
    state = state.copyWith(clearSuccess: true);
  }

  /// Refresh all data
  Future<void> refresh() async {
    await loadQuotations();
    await loadStats();
  }
}

// =====================================================
// PROVIDERS
// =====================================================

/// Main quotation state provider
final quotationProvider = StateNotifierProvider<QuotationNotifier, QuotationState>((ref) {
  final service = ref.watch(quotationServiceProvider);
  return QuotationNotifier(service);
});

/// Quotation list provider (for simple list access)
final quotationListProvider = Provider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(quotationProvider).quotations;
});

/// Filtered quotation list provider
final filteredQuotationListProvider = Provider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(quotationProvider).filteredQuotations;
});

/// Quotation by status provider
final quotationByStatusProvider = Provider.family<List<Map<String, dynamic>>, String>((ref, status) {
  return ref.watch(quotationProvider).getByStatus(status);
});

/// Selected quotation provider
final selectedQuotationProvider = Provider<Map<String, dynamic>?>((ref) {
  return ref.watch(quotationProvider).selectedQuotation;
});

/// Quotation items provider
final quotationItemsProvider = Provider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(quotationProvider).quotationItems;
});

/// Quotation suggestions provider
final quotationSuggestionsProvider = Provider<SmartSuggestions?>((ref) {
  return ref.watch(quotationProvider).suggestions;
});

/// Quotation statistics provider
final quotationStatsProvider = Provider<QuotationStats?>((ref) {
  return ref.watch(quotationProvider).stats;
});

/// Loading state provider
final quotationLoadingProvider = Provider<bool>((ref) {
  return ref.watch(quotationProvider).isLoading;
});

/// Saving state provider
final quotationSavingProvider = Provider<bool>((ref) {
  return ref.watch(quotationProvider).isSaving;
});

/// Error message provider
final quotationErrorProvider = Provider<String?>((ref) {
  return ref.watch(quotationProvider).error;
});

/// Success message provider
final quotationSuccessProvider = Provider<String?>((ref) {
  return ref.watch(quotationProvider).successMessage;
});

// =====================================================
// PRE-TRIP ACTIONS PROVIDER
// =====================================================

class PreTripActionsState {
  final List<PreTripAction> actions;
  final bool isLoading;
  final String? error;

  const PreTripActionsState({
    this.actions = const [],
    this.isLoading = false,
    this.error,
  });

  PreTripActionsState copyWith({
    List<PreTripAction>? actions,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return PreTripActionsState(
      actions: actions ?? this.actions,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  int get pendingCount => actions.where((a) => a.scheduledAt.isBefore(DateTime.now())).length;
  int get upcomingCount => actions.where((a) => a.scheduledAt.isAfter(DateTime.now())).length;
}

class PreTripActionsNotifier extends StateNotifier<PreTripActionsState> {
  final QuotationService _service;

  PreTripActionsNotifier(this._service) : super(const PreTripActionsState()) {
    loadActions();
  }

  Future<void> loadActions({int limit = 50}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    
    try {
      final actions = await _service.getPendingActions(limit: limit);
      state = state.copyWith(
        actions: actions,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao carregar ações pendentes: $e',
      );
    }
  }

  Future<bool> completeAction(int actionId, {String? executedBy, String? notes}) async {
    try {
      final success = await _service.completeAction(actionId, executedBy: executedBy, notes: notes);
      if (success) {
        await loadActions();
      }
      return success;
    } catch (e) {
      state = state.copyWith(error: 'Erro ao completar ação: $e');
      return false;
    }
  }

  Future<bool> failAction(int actionId, String errorMessage, {bool retry = true}) async {
    try {
      final success = await _service.failAction(actionId, errorMessage, retry: retry);
      if (success) {
        await loadActions();
      }
      return success;
    } catch (e) {
      state = state.copyWith(error: 'Erro ao marcar ação como falha: $e');
      return false;
    }
  }
}

/// Pre-trip actions provider
final preTripActionsProvider = StateNotifierProvider<PreTripActionsNotifier, PreTripActionsState>((ref) {
  final service = ref.watch(quotationServiceProvider);
  return PreTripActionsNotifier(service);
});

/// Pending actions count provider
final pendingActionsCountProvider = Provider<int>((ref) {
  return ref.watch(preTripActionsProvider).pendingCount;
});
