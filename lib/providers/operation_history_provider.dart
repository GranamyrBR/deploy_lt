import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/operation_history.dart';

class OperationHistoryNotifier extends StateNotifier<OperationHistoryState> {
  final _supabase = Supabase.instance.client;

  OperationHistoryNotifier() : super(OperationHistoryState());

  // Carregar histórico de uma operação específica
  Future<void> loadOperationHistory(int operationId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final response = await _supabase
          .from('operation_history')
          .select('''
            id,
            operation_id,
            action_type,
            old_value,
            new_value,
            action_data,
            performed_by_user_id,
            performed_by_user_name,
            performed_at
          ''')
          .eq('operation_id', operationId)
          .order('performed_at', ascending: false);

      final historyList = response
          .map((json) => OperationHistory.fromJson(json))
          .toList();

      state = state.copyWith(
        historyByOperation: {
          ...state.historyByOperation,
          operationId: historyList,
        },
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: 'Erro ao carregar histórico: $e',
        isLoading: false,
      );
      debugPrint('Erro ao carregar histórico da operação: $e');
    }
  }

  // Adicionar entrada no histórico
  Future<bool> addHistoryEntry({
    required int operationId,
    required String actionType,
    String? oldValue,
    String? newValue,
    Map<String, dynamic>? actionData,
    String? performedByUserId,
    String? performedByUserName,
  }) async {
    try {
      final response = await _supabase
          .from('operation_history')
          .insert({
            'operation_id': operationId,
            'action_type': actionType,
            'old_value': oldValue,
            'new_value': newValue,
            'action_data': actionData,
            'performed_by_user_id': performedByUserId,
            'performed_by_user_name': performedByUserName,
            'performed_at': DateTime.now().toUtc().toIso8601String(),
          })
          .select();

      if (response.isNotEmpty) {
        // Recarregar histórico da operação
        await loadOperationHistory(operationId);
        return true;
      }

      return false;
    } catch (e) {
      state = state.copyWith(
        error: 'Erro ao adicionar entrada no histórico: $e',
        isLoading: false,
      );
      debugPrint('Erro ao adicionar entrada no histórico: $e');
      return false;
    }
  }

  // Registrar mudança de status
  Future<bool> recordStatusChange({
    required int operationId,
    required String oldStatus,
    required String newStatus,
    String? performedByUserId,
    String? performedByUserName,
    String? reason,
  }) async {
    return await addHistoryEntry(
      operationId: operationId,
      actionType: 'status_changed',
      oldValue: oldStatus,
      newValue: newStatus,
      actionData: reason != null ? {'reason': reason} : null,
      performedByUserId: performedByUserId,
      performedByUserName: performedByUserName,
    );
  }

  // Registrar atribuição de motorista
  Future<bool> recordDriverAssignment({
    required int operationId,
    required int driverId,
    required String driverName,
    int? carId,
    String? carName,
    String? performedByUserId,
    String? performedByUserName,
  }) async {
    return await addHistoryEntry(
      operationId: operationId,
      actionType: 'driver_assigned',
      newValue: driverName,
      actionData: {
        'driver_id': driverId,
        'driver_name': driverName,
        if (carId != null) 'car_id': carId,
        if (carName != null) 'car_name': carName,
      },
      performedByUserId: performedByUserId,
      performedByUserName: performedByUserName,
    );
  }

  // Registrar mudança de agendamento
  Future<bool> recordScheduleChange({
    required int operationId,
    required DateTime oldDate,
    required DateTime newDate,
    String? performedByUserId,
    String? performedByUserName,
    String? reason,
  }) async {
    return await addHistoryEntry(
      operationId: operationId,
      actionType: 'scheduled',
      oldValue: oldDate.toIso8601String(),
      newValue: newDate.toIso8601String(),
      actionData: {
        'old_date_formatted': oldDate.toString(),
        'new_date_formatted': newDate.toString(),
        if (reason != null) 'reason': reason,
      },
      performedByUserId: performedByUserId,
      performedByUserName: performedByUserName,
    );
  }

  // Registrar mudança de localização
  Future<bool> recordLocationChange({
    required int operationId,
    String? oldPickupLocation,
    String? newPickupLocation,
    String? oldDropoffLocation,
    String? newDropoffLocation,
    String? performedByUserId,
    String? performedByUserName,
    String? reason,
  }) async {
    final changes = <String, dynamic>{};
    
    if (oldPickupLocation != newPickupLocation) {
      changes['pickup_location'] = {
        'old': oldPickupLocation,
        'new': newPickupLocation,
      };
    }
    
    if (oldDropoffLocation != newDropoffLocation) {
      changes['dropoff_location'] = {
        'old': oldDropoffLocation,
        'new': newDropoffLocation,
      };
    }

    if (changes.isEmpty) return true;

    return await addHistoryEntry(
      operationId: operationId,
      actionType: 'location_updated',
      actionData: {
        'changes': changes,
        if (reason != null) 'reason': reason,
      },
      performedByUserId: performedByUserId,
      performedByUserName: performedByUserName,
    );
  }

  // Registrar adição de nota
  Future<bool> recordNoteAdded({
    required int operationId,
    required String noteType, // 'customer_notes', 'driver_notes', 'special_instructions'
    required String noteContent,
    String? performedByUserId,
    String? performedByUserName,
  }) async {
    return await addHistoryEntry(
      operationId: operationId,
      actionType: 'note_added',
      newValue: noteContent,
      actionData: {
        'note_type': noteType,
        'note_content': noteContent,
      },
      performedByUserId: performedByUserId,
      performedByUserName: performedByUserName,
    );
  }

  // Registrar informações de voo atualizadas
  Future<bool> recordFlightInfoUpdate({
    required int operationId,
    String? oldFlightNumber,
    String? newFlightNumber,
    DateTime? oldDepartureTime,
    DateTime? newDepartureTime,
    DateTime? oldArrivalTime,
    DateTime? newArrivalTime,
    String? performedByUserId,
    String? performedByUserName,
    String? reason,
  }) async {
    final changes = <String, dynamic>{};
    
    if (oldFlightNumber != newFlightNumber) {
      changes['flight_number'] = {
        'old': oldFlightNumber,
        'new': newFlightNumber,
      };
    }
    
    if (oldDepartureTime != newDepartureTime) {
      changes['departure_time'] = {
        'old': oldDepartureTime?.toIso8601String(),
        'new': newDepartureTime?.toIso8601String(),
      };
    }
    
    if (oldArrivalTime != newArrivalTime) {
      changes['arrival_time'] = {
        'old': oldArrivalTime?.toIso8601String(),
        'new': newArrivalTime?.toIso8601String(),
      };
    }

    if (changes.isEmpty) return true;

    return await addHistoryEntry(
      operationId: operationId,
      actionType: 'flight_info_updated',
      actionData: {
        'changes': changes,
        if (reason != null) 'reason': reason,
      },
      performedByUserId: performedByUserId,
      performedByUserName: performedByUserName,
    );
  }

  // Obter histórico de uma operação
  List<OperationHistory> getOperationHistory(int operationId) {
    return state.historyByOperation[operationId] ?? [];
  }

  // Limpar erro
  void clearError() {
    state = state.copyWith(error: null);
  }

  // Limpar histórico de uma operação
  void clearOperationHistory(int operationId) {
    final updatedHistory = Map<int, List<OperationHistory>>.from(state.historyByOperation);
    updatedHistory.remove(operationId);
    state = state.copyWith(historyByOperation: updatedHistory);
  }
}

class OperationHistoryState {
  final Map<int, List<OperationHistory>> historyByOperation;
  final bool isLoading;
  final String? error;

  OperationHistoryState({
    this.historyByOperation = const {},
    this.isLoading = false,
    this.error,
  });

  OperationHistoryState copyWith({
    Map<int, List<OperationHistory>>? historyByOperation,
    bool? isLoading,
    String? error,
  }) {
    return OperationHistoryState(
      historyByOperation: historyByOperation ?? this.historyByOperation,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// Provider do Riverpod
final operationHistoryProvider = StateNotifierProvider<OperationHistoryNotifier, OperationHistoryState>((ref) {
  return OperationHistoryNotifier();
});
