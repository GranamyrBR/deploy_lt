import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/enhanced_quotation_model.dart';

/// Filters for searching quotations
class QuotationFilter {
  final int? id;
  final int? clientId;
  final int? agencyId;
  final String? status;
  final String? type;
  final DateTime? fromDate;
  final DateTime? toDate;
  final DateTime? travelDateFrom;
  final DateTime? travelDateTo;
  final String? createdBy;
  final String? assignedTo;
  final bool? isExpired;
  final int limit;
  final int offset;

  const QuotationFilter({
    this.id,
    this.clientId,
    this.agencyId,
    this.status,
    this.type,
    this.fromDate,
    this.toDate,
    this.travelDateFrom,
    this.travelDateTo,
    this.createdBy,
    this.assignedTo,
    this.isExpired,
    this.limit = 50,
    this.offset = 0,
  });

  Map<String, dynamic> toParams() => {
    'p_id': id,
    'p_client_id': clientId,
    'p_agency_id': agencyId,
    'p_status': status,
    'p_type': type,
    'p_from': fromDate?.toIso8601String(),
    'p_to': toDate?.toIso8601String(),
    'p_travel_from': travelDateFrom?.toIso8601String(),
    'p_travel_to': travelDateTo?.toIso8601String(),
    'p_created_by': createdBy,
    'p_limit': limit,
    'p_offset': offset,
  };
}

/// Result of a quotation save operation
class QuotationSaveResult {
  final int id;
  final bool success;
  final String? errorMessage;

  QuotationSaveResult({
    required this.id,
    required this.success,
    this.errorMessage,
  });

  factory QuotationSaveResult.fromJson(Map<String, dynamic> json) {
    return QuotationSaveResult(
      id: json['id'] as int? ?? 0,
      success: json['success'] as bool? ?? false,
      errorMessage: json['error'] as String?,
    );
  }
}

/// Full quotation details including items and metadata
class QuotationFull {
  final Map<String, dynamic> quotation;
  final List<Map<String, dynamic>> items;
  final List<Map<String, dynamic>> versions;
  final List<Map<String, dynamic>> pendingActions;
  final Map<String, dynamic>? client;
  final Map<String, dynamic>? agency;

  QuotationFull({
    required this.quotation,
    required this.items,
    required this.versions,
    required this.pendingActions,
    this.client,
    this.agency,
  });

  factory QuotationFull.fromJson(Map<String, dynamic> json) {
    return QuotationFull(
      quotation: Map<String, dynamic>.from(json['quotation'] ?? {}),
      items: (json['items'] as List?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [],
      versions: (json['versions'] as List?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [],
      pendingActions: (json['pending_actions'] as List?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [],
      client: json['client'] != null ? Map<String, dynamic>.from(json['client']) : null,
      agency: json['agency'] != null ? Map<String, dynamic>.from(json['agency']) : null,
    );
  }
}

/// Smart suggestions response
class SmartSuggestions {
  final List<Map<String, dynamic>> byHistory;
  final List<Map<String, dynamic>> byDestination;
  final List<Map<String, dynamic>> byHotel;

  SmartSuggestions({
    required this.byHistory,
    required this.byDestination,
    required this.byHotel,
  });

  factory SmartSuggestions.fromJson(Map<String, dynamic> json) {
    return SmartSuggestions(
      byHistory: (json['by_history'] as List?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [],
      byDestination: (json['by_destination'] as List?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [],
      byHotel: (json['by_hotel'] as List?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [],
    );
  }

  List<Map<String, dynamic>> get all => [...byHistory, ...byDestination, ...byHotel];
  
  bool get isEmpty => byHistory.isEmpty && byDestination.isEmpty && byHotel.isEmpty;
}

/// Pre-trip action data
class PreTripAction {
  final int id;
  final int quotationId;
  final String actionType;
  final DateTime scheduledAt;
  final String? clientName;
  final String? clientPhone;
  final String? clientEmail;
  final DateTime? travelDate;
  final String? quotationNumber;

  PreTripAction({
    required this.id,
    required this.quotationId,
    required this.actionType,
    required this.scheduledAt,
    this.clientName,
    this.clientPhone,
    this.clientEmail,
    this.travelDate,
    this.quotationNumber,
  });

  factory PreTripAction.fromJson(Map<String, dynamic> json) {
    return PreTripAction(
      id: json['id'] as int,
      quotationId: json['quotation_id'] as int,
      actionType: json['action_type'] as String,
      scheduledAt: DateTime.parse(json['scheduled_at'] as String),
      clientName: json['client_name'] as String?,
      clientPhone: json['client_phone'] as String?,
      clientEmail: json['client_email'] as String?,
      travelDate: json['travel_date'] != null ? DateTime.parse(json['travel_date'] as String) : null,
      quotationNumber: json['quotation_number'] as String?,
    );
  }
}

/// Quotation statistics
class QuotationStats {
  final int total;
  final Map<String, int> byStatus;
  final double? totalValueUsd;
  final double? avgValueUsd;
  final double? conversionRate;

  QuotationStats({
    required this.total,
    required this.byStatus,
    this.totalValueUsd,
    this.avgValueUsd,
    this.conversionRate,
  });

  factory QuotationStats.fromJson(Map<String, dynamic> json) {
    final byStatusRaw = json['by_status'] as Map<String, dynamic>?;
    final byStatus = byStatusRaw?.map((k, v) => MapEntry(k, (v as num).toInt())) ?? {};
    
    return QuotationStats(
      total: json['total'] as int? ?? 0,
      byStatus: byStatus,
      totalValueUsd: (json['total_value_usd'] as num?)?.toDouble(),
      avgValueUsd: (json['avg_value_usd'] as num?)?.toDouble(),
      conversionRate: (json['conversion_rate'] as num?)?.toDouble(),
    );
  }
}

/// Service for quotation CRUD operations and business logic
class QuotationService {
  SupabaseClient get _client => Supabase.instance.client;

  // =====================================================
  // CREATE OPERATIONS
  // =====================================================

  /// Save a new quotation with all items
  /// Uses the enhanced save_quotation_v2 RPC for multi-currency support
  Future<QuotationSaveResult> saveQuotation(
    Quotation q, {
    List<Map<String, dynamic>>? luggage,
    List<Map<String, dynamic>>? vehicles,
  }) async {
    try {
      final payload = q.toMap();
      
      // DEBUG: Verificar se quotation_number está no payload
      print('🔍 DEBUG PAYLOAD:');
      print('   quotation_number: ${payload['quotation_number']}');
      print('   client_name: ${payload['client_name']}');
      print('   Keys no payload: ${payload.keys.take(10).join(', ')}');
      
      // Adicionar bagagens se fornecidas
      if (luggage != null && luggage.isNotEmpty) {
        payload['luggage'] = luggage;
      }
      
      // Adicionar veículos se fornecidos
      if (vehicles != null && vehicles.isNotEmpty) {
        payload['vehicles'] = vehicles;
      }
      
      final result = await _client.rpc<dynamic>('save_quotation_v2', params: {'p_quotation': payload});
      
      if (result is Map) {
        return QuotationSaveResult.fromJson(Map<String, dynamic>.from(result));
      }
      
      // Fallback for legacy save_quotation
      final rows = await _client.rpc<dynamic>('save_quotation', params: {'p_quotation': payload});
      if (rows is int) {
        return QuotationSaveResult(id: rows, success: true);
      }
      if (rows is Map && rows['id'] is int) {
        return QuotationSaveResult(id: rows['id'] as int, success: true);
      }
      if (rows is List && rows.isNotEmpty) {
        final first = rows.first;
        if (first is int) return QuotationSaveResult(id: first, success: true);
        if (first is Map && first['id'] != null) {
          return QuotationSaveResult(id: first['id'] as int, success: true);
        }
      }
      
      throw Exception('Unexpected response format');
    } catch (e) {
      return QuotationSaveResult(
        id: 0,
        success: false,
        errorMessage: 'Falha ao salvar cotação: $e',
      );
    }
  }

  /// Duplicate an existing quotation
  Future<int> duplicateQuotation(int quotationId, {String? createdBy}) async {
    try {
      final result = await _client.rpc<dynamic>('duplicate_quotation', params: {
        'p_id': quotationId,
        'p_created_by': createdBy ?? 'system',
      });
      
      if (result is int) return result;
      throw Exception('Falha ao duplicar cotação');
    } catch (e) {
      print('Erro ao duplicar cotação: $e');
      rethrow;
    }
  }

  // =====================================================
  // READ OPERATIONS
  // =====================================================

  /// Get a single quotation by ID with all related data
  Future<QuotationFull?> getById(int id) async {
    try {
      final result = await _client.rpc<dynamic>('get_quotation_full', params: {'p_id': id});
      
      if (result == null) return null;
      return QuotationFull.fromJson(Map<String, dynamic>.from(result));
    } catch (e) {
      print('Erro ao buscar cotação: $e');
      return null;
    }
  }

  /// Search quotations with flexible filters
  Future<List<Map<String, dynamic>>> search({
    int? id, 
    int? clientId, 
    DateTime? from, 
    DateTime? to,
    String? status,
    String? type,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final rows = await _client.rpc<dynamic>('search_quotations', params: {
        'p_id': id,
        'p_client_id': clientId,
        'p_from': from?.toIso8601String(),
        'p_to': to?.toIso8601String(),
      });
      return (rows as List).map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      print('Erro ao buscar cotações: $e');
      return [];
    }
  }

  /// Get all quotations with optional filters using direct query
  Future<List<Map<String, dynamic>>> getQuotations({
    QuotationFilter? filter,
  }) async {
    try {
      var query = _client.from('quotation').select('''
        *,
        contact:client_id(id, name, email, phone),
        agency:agency_id(id, name)
      ''');
      
      if (filter != null) {
        if (filter.id != null) query = query.eq('id', filter.id!);
        if (filter.clientId != null) query = query.eq('client_id', filter.clientId!);
        if (filter.agencyId != null) query = query.eq('agency_id', filter.agencyId!);
        if (filter.status != null) query = query.eq('status', filter.status!);
        if (filter.type != null) query = query.eq('type', filter.type!);
        if (filter.createdBy != null) query = query.eq('created_by', filter.createdBy!);
        if (filter.fromDate != null) {
          query = query.gte('quotation_date', filter.fromDate!.toIso8601String());
        }
        if (filter.toDate != null) {
          query = query.lte('quotation_date', filter.toDate!.toIso8601String());
        }
        if (filter.travelDateFrom != null) {
          query = query.gte('travel_date', filter.travelDateFrom!.toIso8601String());
        }
        if (filter.travelDateTo != null) {
          query = query.lte('travel_date', filter.travelDateTo!.toIso8601String());
        }
        if (filter.isExpired == true) {
          query = query
            .eq('status', 'sent')
            .lt('expiration_date', DateTime.now().toUtc().toIso8601String());
        }
      }
      
      final response = await query
        .order('quotation_date', ascending: false)
        .range(filter?.offset ?? 0, (filter?.offset ?? 0) + (filter?.limit ?? 50) - 1);
      
      return (response as List).map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      print('Erro ao buscar cotações: $e');
      return [];
    }
  }

  /// Get quotations by client ID
  Future<List<Map<String, dynamic>>> getByClient(int clientId, {int limit = 20}) async {
    try {
      final response = await _client
        .from('quotation')
        .select('*')
        .eq('client_id', clientId)
        .order('quotation_date', ascending: false)
        .order('id', ascending: false).limit(limit);
      
      return (response as List).map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      print('Erro ao buscar cotações do cliente: $e');
      return [];
    }
  }

  /// Get quotations by status
  Future<List<Map<String, dynamic>>> getByStatus(String status, {int limit = 50}) async {
    try {
      final response = await _client
        .from('quotation')
        .select('*, contact:client_id(id, name, email, phone)')
        .eq('status', status)
        .order('quotation_date', ascending: false)
        .order('id', ascending: false).limit(limit);
      
      return (response as List).map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      print('Erro ao buscar cotações por status: $e');
      return [];
    }
  }

  /// Get expiring quotations (status=sent with expiration_date approaching)
  Future<List<Map<String, dynamic>>> getExpiring({int daysAhead = 3}) async {
    try {
      final limitDate = DateTime.now().add(Duration(days: daysAhead));
      
      final response = await _client
        .from('quotation')
        .select('*, contact:client_id(id, name, email, phone)')
        .eq('status', 'sent')
        .lt('expiration_date', limitDate.toIso8601String())
        .gt('expiration_date', DateTime.now().toUtc().toIso8601String())
        .order('expiration_date', ascending: true);
      
      return (response as List).map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      print('Erro ao buscar cotações expirando: $e');
      return [];
    }
  }

  /// Get quotation items
  Future<List<Map<String, dynamic>>> getItems(int quotationId) async {
    try {
      final rows = await _client
        .from('quotation_item')
        .select('*, service:service_id(id, name, price), product:product_id(product_id, name, price_per_unit)')
        .eq('quotation_id', quotationId)
        .order('id');
      return (rows as List).map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      print('Erro ao buscar itens da cotação: $e');
      return [];
    }
  }

  /// Get version history for a quotation
  Future<List<Map<String, dynamic>>> getVersionHistory(int quotationId) async {
    try {
      final response = await _client
        .from('quotation_version')
        .select('*')
        .eq('quotation_id', quotationId)
        .order('version_number', ascending: false);
      
      return (response as List).map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      print('Erro ao buscar histórico de versões: $e');
      return [];
    }
  }

  // =====================================================
  // UPDATE OPERATIONS
  // =====================================================

  /// Update quotation with patch data
  Future<bool> update(int id, {
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
    try {
      final patch = <String, dynamic>{};
      if (status != null) patch['status'] = status;
      if (notes != null) patch['notes'] = notes;
      if (specialRequests != null) patch['specialRequests'] = specialRequests;
      if (hotel != null) patch['hotel'] = hotel;
      if (vehicle != null) patch['vehicle'] = vehicle;
      if (driver != null) patch['driver'] = driver;
      if (passengerCount != null) patch['passengerCount'] = passengerCount;
      if (travelDate != null) patch['travelDate'] = travelDate.toIso8601String();
      if (returnDate != null) patch['returnDate'] = returnDate.toIso8601String();
      if (expirationDate != null) patch['expirationDate'] = expirationDate.toIso8601String();
      if (discountAmount != null) patch['discountAmount'] = discountAmount;
      
      final result = await _client.rpc<dynamic>('update_quotation_v2', params: {
        'p_id': id,
        'p_patch': patch,
        'p_updated_by': updatedBy ?? 'system',
      });
      
      if (result is Map) {
        return result['success'] == true;
      }
      return true;
    } catch (e) {
      print('Erro ao atualizar cotação: $e');
      return false;
    }
  }

  /// Update quotation status only
  Future<bool> updateStatus(int id, String newStatus, {String? updatedBy}) async {
    return update(id, status: newStatus, updatedBy: updatedBy);
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

  /// Delete a quotation (soft delete - marks as cancelled)
  Future<bool> deleteQuotation(int id, {bool hardDelete = false}) async {
    try {
      if (hardDelete) {
        await _client.from('quotation').delete().eq('id', id);
      } else {
        await _client.from('quotation')
          .update({'status': 'cancelled', 'updated_at': DateTime.now().toUtc().toIso8601String()})
          .eq('id', id);
      }
      return true;
    } catch (e) {
      print('Erro ao deletar cotação: $e');
      return false;
    }
  }

  // =====================================================
  // CONVERSION OPERATIONS
  // =====================================================

  /// Convert an accepted quotation to a sale
  Future<int?> convertToSale(int quotationId, String userId, {String paymentMethod = 'pending'}) async {
    try {
      final result = await _client.rpc<dynamic>('convert_quotation_to_sale', params: {
        'p_quotation_id': quotationId,
        'p_user_id': userId,
        'p_payment_method': paymentMethod,
      });
      
      if (result is int) return result;
      return null;
    } catch (e) {
      print('Erro ao converter cotação em venda: $e');
      return null;
    }
  }

  // =====================================================
  // SUGGESTIONS
  // =====================================================

  /// Get basic suggestions for a quotation (legacy)
  Future<List<Map<String, dynamic>>> suggestions(int quotationId) async {
    try {
      final out = await _client.rpc<dynamic>('suggest_addons_for_quotation', params: {'p_id': quotationId});
      if (out is List) {
        return out.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      if (out is Map && out['kind'] != null) return [Map<String, dynamic>.from(out)];
      return [];
    } catch (e) {
      print('Erro ao buscar sugestões: $e');
      return [];
    }
  }

  /// Get smart suggestions based on multiple factors
  Future<SmartSuggestions> getSmartSuggestions({
    int? quotationId,
    int? clientId,
    String? destination,
    String? hotel,
  }) async {
    try {
      final result = await _client.rpc<dynamic>('get_smart_suggestions', params: {
        'p_quotation_id': quotationId,
        'p_client_id': clientId,
        'p_destination': destination,
        'p_hotel': hotel,
      });
      
      if (result is Map) {
        return SmartSuggestions.fromJson(Map<String, dynamic>.from(result));
      }
      return SmartSuggestions(byHistory: [], byDestination: [], byHotel: []);
    } catch (e) {
      print('Erro ao buscar sugestões inteligentes: $e');
      return SmartSuggestions(byHistory: [], byDestination: [], byHotel: []);
    }
  }

  /// Get suggestions based on customer purchase history
  Future<List<Map<String, dynamic>>> getSuggestionsByHistory(int clientId) async {
    try {
      final result = await _client.rpc<dynamic>('suggest_services_by_history', params: {
        'p_client_id': clientId,
      });
      
      if (result is List) {
        return result.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      return [];
    } catch (e) {
      print('Erro ao buscar sugestões por histórico: $e');
      return [];
    }
  }

  // =====================================================
  // PRE-TRIP ACTIONS
  // =====================================================

  /// Get pending pre-trip actions
  Future<List<PreTripAction>> getPendingActions({int limit = 50}) async {
    try {
      final result = await _client.rpc<dynamic>('get_pending_pre_trip_actions', params: {
        'p_limit': limit,
      });
      
      if (result is List) {
        return result.map((e) => PreTripAction.fromJson(Map<String, dynamic>.from(e))).toList();
      }
      return [];
    } catch (e) {
      print('Erro ao buscar ações pendentes: $e');
      return [];
    }
  }

  /// Mark a pre-trip action as completed
  Future<bool> completeAction(int actionId, {String? executedBy, String? notes}) async {
    try {
      final result = await _client.rpc<dynamic>('complete_pre_trip_action', params: {
        'p_action_id': actionId,
        'p_executed_by': executedBy ?? 'system',
        'p_notes': notes,
      });
      return result == true;
    } catch (e) {
      print('Erro ao completar ação: $e');
      return false;
    }
  }

  /// Mark a pre-trip action as failed
  Future<bool> failAction(int actionId, String errorMessage, {bool retry = true}) async {
    try {
      final result = await _client.rpc<dynamic>('fail_pre_trip_action', params: {
        'p_action_id': actionId,
        'p_error_message': errorMessage,
        'p_retry': retry,
      });
      return result == true;
    } catch (e) {
      print('Erro ao marcar ação como falha: $e');
      return false;
    }
  }

  // =====================================================
  // STATISTICS & REPORTING
  // =====================================================

  /// Get quotation statistics
  Future<QuotationStats?> getStats({
    DateTime? fromDate,
    DateTime? toDate,
    String? userId,
  }) async {
    try {
      final result = await _client.rpc<dynamic>('get_quotation_stats', params: {
        'p_from_date': fromDate?.toIso8601String(),
        'p_to_date': toDate?.toIso8601String(),
        'p_user_id': userId,
      });
      
      if (result is Map) {
        return QuotationStats.fromJson(Map<String, dynamic>.from(result));
      }
      return null;
    } catch (e) {
      print('Erro ao buscar estatísticas: $e');
      return null;
    }
  }

  /// Get conversion metrics (sent -> accepted rate)
  Future<Map<String, dynamic>> getConversionMetrics({
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      final quotations = await getQuotations(filter: QuotationFilter(
        fromDate: fromDate,
        toDate: toDate,
        limit: 1000,
      ));
      
      final total = quotations.length;
      final sent = quotations.where((q) => q['status'] != 'draft').length;
      final accepted = quotations.where((q) => q['status'] == 'accepted').length;
      final rejected = quotations.where((q) => q['status'] == 'rejected').length;
      final expired = quotations.where((q) => q['status'] == 'expired').length;
      
      return {
        'total': total,
        'sent': sent,
        'accepted': accepted,
        'rejected': rejected,
        'expired': expired,
        'conversion_rate': sent > 0 ? (accepted / sent * 100).toStringAsFixed(2) : '0.00',
        'rejection_rate': sent > 0 ? (rejected / sent * 100).toStringAsFixed(2) : '0.00',
      };
    } catch (e) {
      print('Erro ao calcular métricas de conversão: $e');
      return {};
    }
  }

  // =====================================================
  // TEMPLATES
  // =====================================================

  /// Get quotation templates
  Future<List<Map<String, dynamic>>> getTemplates({bool activeOnly = true}) async {
    try {
      var query = _client.from('quotation_template').select('*');
      if (activeOnly) {
        query = query.eq('is_active', true);
      }
      final response = await query.order('name');
      return (response as List).map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      print('Erro ao buscar templates: $e');
      return [];
    }
  }

  /// Create a new template
  Future<int?> createTemplate({
    required String name,
    required String type,
    String? description,
    List<Map<String, dynamic>>? defaultItems,
    String? defaultNotes,
    String? defaultCancellationPolicy,
    String? defaultPaymentTerms,
    required String createdBy,
  }) async {
    try {
      final response = await _client.from('quotation_template').insert({
        'name': name,
        'type': type,
        'description': description,
        'default_items': defaultItems,
        'default_notes': defaultNotes,
        'default_cancellation_policy': defaultCancellationPolicy,
        'default_payment_terms': defaultPaymentTerms,
        'created_by': createdBy,
      }).select('id').single();
      
      return response['id'] as int?;
    } catch (e) {
      print('Erro ao criar template: $e');
      return null;
    }
  }

  // =====================================================
  // VALIDATION
  // =====================================================

  /// Validate quotation data before saving
  String? validateQuotation(Quotation q) {
    if (q.clientName.isEmpty) {
      return 'Nome do cliente é obrigatório';
    }
    if (q.clientEmail.isEmpty) {
      return 'Email do cliente é obrigatório';
    }
    if (!_isValidEmail(q.clientEmail)) {
      return 'Email do cliente inválido';
    }
    if (q.items.isEmpty) {
      return 'Cotação deve ter pelo menos um item';
    }
    if (q.passengerCount <= 0) {
      return 'Número de passageiros deve ser maior que zero';
    }
    if (q.subtotal < 0) {
      return 'Subtotal não pode ser negativo';
    }
    if (q.total < 0) {
      return 'Total não pode ser negativo';
    }
    return null; // Valid
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
}
