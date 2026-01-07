import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:state_notifier/state_notifier.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'operation_history_provider.dart';

class Operation {
  final int id;
  final int saleId;
  final int saleItemId;
  final int? serviceId;
  final String? serviceName;
  final int customerId;
  final String customerName;
  final String? customerPhone;
  final String? customerEmail;
  final int? driverId;
  final String? driverName;
  final String? driverPhone;
  final int? carId;
  final String? carName;
  final String? licensePlate;
  final String status;
  final String priority;
  final DateTime scheduledDate;
  final DateTime? actualStartTime;
  final DateTime? actualEndTime;
  final String? pickupLocation;
  final String? dropoffLocation;
  final int numberOfPassengers;
  final int luggageCount;
  final double? serviceValueUsd;
  final int? productId;
  final String? productName;
  final double? productValueUsd;
  final int? quantity;
  final double driverCommissionUsd;
  final bool whatsappMessageSent;
  final bool googleCalendarEventCreated;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? flightNumber;
  final String? flightStatus;
  final DateTime? scheduledDepartureTime;
  final DateTime? scheduledArrivalTime;
  final String? departureAirportCode;
  final String? arrivalAirportCode;
  final String? commissionPaymentStatus;
  final double? totalCommissionUsd;
  final bool? customerIsVip;
  final int? customerAgencyId;
  final String? customerAgencyName;
  final String? customerAgencyEmail;
  final String? customerAgencyPhone;
  final String? customerAgencyCity;
  final double? customerAgencyCommissionRate;
  final String? customerAccountType;
  final String? createdByUserId;
  final String? createdByUserName;
  final String? createdByUserEmail;
  final String? assignedByUserId;
  final String? assignedByUserName;
  final String? assignedByUserEmail;
  final String? saleUserId;
  final String? saleUserName;
  final String? saleUserEmail;

  Operation({
    required this.id,
    required this.saleId,
    required this.saleItemId,
    this.serviceId,
    this.serviceName,
    required this.customerId,
    required this.customerName,
    this.customerPhone,
    this.customerEmail,
    this.driverId,
    this.driverName,
    this.driverPhone,
    this.carId,
    this.carName,
    this.licensePlate,
    required this.status,
    required this.priority,
    required this.scheduledDate,
    this.actualStartTime,
    this.actualEndTime,
    this.pickupLocation,
    this.dropoffLocation,
    required this.numberOfPassengers,
    required this.luggageCount,
    this.serviceValueUsd,
    this.productId,
    this.productName,
    this.productValueUsd,
    this.quantity,
    required this.driverCommissionUsd,
    required this.whatsappMessageSent,
    required this.googleCalendarEventCreated,
    required this.createdAt,
    required this.updatedAt,
    this.flightNumber,
    this.flightStatus,
    this.scheduledDepartureTime,
    this.scheduledArrivalTime,
    this.departureAirportCode,
    this.arrivalAirportCode,
    this.commissionPaymentStatus,
    this.totalCommissionUsd,
    this.customerIsVip,
    this.customerAgencyId,
    this.customerAgencyName,
    this.customerAgencyEmail,
    this.customerAgencyPhone,
    this.customerAgencyCity,
    this.customerAgencyCommissionRate,
    this.customerAccountType,
    this.createdByUserId,
    this.createdByUserName,
    this.createdByUserEmail,
    this.assignedByUserId,
    this.assignedByUserName,
    this.assignedByUserEmail,
    this.saleUserId,
    this.saleUserName,
    this.saleUserEmail,
  });

  Operation copyWith({
    int? id,
    int? saleId,
    int? saleItemId,
    int? serviceId,
    String? serviceName,
    int? customerId,
    String? customerName,
    String? customerPhone,
    String? customerEmail,
    int? driverId,
    String? driverName,
    String? driverPhone,
    int? carId,
    String? carName,
    String? licensePlate,
    String? status,
    String? priority,
    DateTime? scheduledDate,
    DateTime? actualStartTime,
    DateTime? actualEndTime,
    String? pickupLocation,
    String? dropoffLocation,
    int? numberOfPassengers,
    int? luggageCount,
    double? serviceValueUsd,
    int? productId,
    String? productName,
    double? productValueUsd,
    int? quantity,
    double? driverCommissionUsd,
    bool? whatsappMessageSent,
    bool? googleCalendarEventCreated,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? flightNumber,
    String? flightStatus,
    DateTime? scheduledDepartureTime,
    DateTime? scheduledArrivalTime,
    String? departureAirportCode,
    String? arrivalAirportCode,
    String? commissionPaymentStatus,
    double? totalCommissionUsd,
    bool? customerIsVip,
    int? customerAgencyId,
    String? customerAgencyName,
    String? customerAgencyEmail,
    String? customerAgencyPhone,
    String? customerAgencyCity,
    double? customerAgencyCommissionRate,
    String? customerAccountType,
    String? createdByUserId,
    String? createdByUserName,
    String? createdByUserEmail,
    String? assignedByUserId,
    String? assignedByUserName,
    String? assignedByUserEmail,
    String? saleUserId,
    String? saleUserName,
    String? saleUserEmail,
  }) {
    return Operation(
      id: id ?? this.id,
      saleId: saleId ?? this.saleId,
      saleItemId: saleItemId ?? this.saleItemId,
      serviceId: serviceId ?? this.serviceId,
      serviceName: serviceName ?? this.serviceName,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerEmail: customerEmail ?? this.customerEmail,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      driverPhone: driverPhone ?? this.driverPhone,
      carId: carId ?? this.carId,
      carName: carName ?? this.carName,
      licensePlate: licensePlate ?? this.licensePlate,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      actualStartTime: actualStartTime ?? this.actualStartTime,
      actualEndTime: actualEndTime ?? this.actualEndTime,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      dropoffLocation: dropoffLocation ?? this.dropoffLocation,
      numberOfPassengers: numberOfPassengers ?? this.numberOfPassengers,
      luggageCount: luggageCount ?? this.luggageCount,
      serviceValueUsd: serviceValueUsd ?? this.serviceValueUsd,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productValueUsd: productValueUsd ?? this.productValueUsd,
      quantity: quantity ?? this.quantity,
      driverCommissionUsd: driverCommissionUsd ?? this.driverCommissionUsd,
      whatsappMessageSent: whatsappMessageSent ?? this.whatsappMessageSent,
      googleCalendarEventCreated: googleCalendarEventCreated ?? this.googleCalendarEventCreated,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      flightNumber: flightNumber ?? this.flightNumber,
      flightStatus: flightStatus ?? this.flightStatus,
      scheduledDepartureTime: scheduledDepartureTime ?? this.scheduledDepartureTime,
      scheduledArrivalTime: scheduledArrivalTime ?? this.scheduledArrivalTime,
      departureAirportCode: departureAirportCode ?? this.departureAirportCode,
      arrivalAirportCode: arrivalAirportCode ?? this.arrivalAirportCode,
      commissionPaymentStatus: commissionPaymentStatus ?? this.commissionPaymentStatus,
      totalCommissionUsd: totalCommissionUsd ?? this.totalCommissionUsd,
      customerIsVip: customerIsVip ?? this.customerIsVip,
      customerAgencyId: customerAgencyId ?? this.customerAgencyId,
      customerAgencyName: customerAgencyName ?? this.customerAgencyName,
      customerAgencyEmail: customerAgencyEmail ?? this.customerAgencyEmail,
      customerAgencyPhone: customerAgencyPhone ?? this.customerAgencyPhone,
      customerAgencyCity: customerAgencyCity ?? this.customerAgencyCity,
      customerAgencyCommissionRate: customerAgencyCommissionRate ?? this.customerAgencyCommissionRate,
      customerAccountType: customerAccountType ?? this.customerAccountType,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      createdByUserName: createdByUserName ?? this.createdByUserName,
      createdByUserEmail: createdByUserEmail ?? this.createdByUserEmail,
      assignedByUserId: assignedByUserId ?? this.assignedByUserId,
      assignedByUserName: assignedByUserName ?? this.assignedByUserName,
      assignedByUserEmail: assignedByUserEmail ?? this.assignedByUserEmail,
      saleUserId: saleUserId ?? this.saleUserId,
      saleUserName: saleUserName ?? this.saleUserName,
      saleUserEmail: saleUserEmail ?? this.saleUserEmail,
    );
  }

  factory Operation.fromJson(Map<String, dynamic> json) {
    return Operation(
      id: json['id'],
      saleId: json['sale_id'],
      saleItemId: json['sale_item_id'],
      serviceId: json['service_id'],
      serviceName: json['service']?['name'],
      productId: json['product_id'],
      productName: json['product']?['name'],
      customerId: json['customer_id'],
      customerName: json['contact']?['name'] ?? 'Cliente não especificado',
      customerPhone: json['contact']?['phone'],
      customerEmail: json['contact']?['email'],
      driverId: json['driver_id'],
      driverName: json['driver']?['name'],
      driverPhone: json['driver']?['phone'],
      carId: json['car_id'],
      carName: json['car'] != null && json['car']['make'] != null && json['car']['model'] != null 
          ? '${json['car']['make']} ${json['car']['model']}' 
          : null,
      licensePlate: json['car']?['license_plate'],
      status: json['status'] ?? 'pending',
      priority: json['priority'] ?? 'normal',
      scheduledDate: json['scheduled_date'] != null 
          ? DateTime.parse(json['scheduled_date']) 
          : DateTime.now(), // Valor padrão se scheduled_date for null
      actualStartTime: json['actual_start_time'] != null 
          ? DateTime.parse(json['actual_start_time']) 
          : null,
      actualEndTime: json['actual_end_time'] != null 
          ? DateTime.parse(json['actual_end_time']) 
          : null,
      pickupLocation: json['pickup_location'],
      dropoffLocation: json['dropoff_location'],
      numberOfPassengers: json['number_of_passengers'] ?? 1,
      luggageCount: json['luggage_count'] ?? 0,
      serviceValueUsd: json['service_value_usd'] != null ? (json['service_value_usd'] as num).toDouble() : null,
      productValueUsd: json['product_value_usd'] != null ? (json['product_value_usd'] as num).toDouble() : null,
      quantity: json['quantity'],
      driverCommissionUsd: (json['driver_commission_usd'] ?? 0.0).toDouble(),
      whatsappMessageSent: json['whatsapp_message_sent'] ?? false,
      googleCalendarEventCreated: json['google_calendar_event_created'] ?? false,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : DateTime.now(),
      flightNumber: json['flight_number'],
      flightStatus: json['flight_status'],
      scheduledDepartureTime: json['scheduled_departure_time'] != null 
          ? DateTime.parse(json['scheduled_departure_time']) 
          : null,
      scheduledArrivalTime: json['scheduled_arrival_time'] != null 
          ? DateTime.parse(json['scheduled_arrival_time']) 
          : null,
      departureAirportCode: json['departure_airport_code'],
      arrivalAirportCode: json['arrival_airport_code'],
      commissionPaymentStatus: json['commission_payment_status'],
      totalCommissionUsd: json['total_commission_usd'] != null 
          ? (json['total_commission_usd'] as num).toDouble() 
          : null,
      customerIsVip: json['contact']?['is_vip'],
      customerAgencyId: json['contact']?['account_id'],
      customerAgencyName: json['contact']?['account']?['name'],
      customerAgencyEmail: json['contact']?['account']?['email'],
      customerAgencyPhone: json['contact']?['account']?['phone'],
      customerAgencyCity: null, // city_name column does not exist in account table
      customerAgencyCommissionRate: null, // commission_rate column does not exist in account table
      customerAccountType: json['contact']?['account']?['account_category']?['account_type'],
      createdByUserId: json['created_by_user']?['id']?.toString(),
      createdByUserName: json['created_by_user']?['username'],
      createdByUserEmail: json['created_by_user']?['email'],
      assignedByUserId: json['assigned_by_user']?['id']?.toString(),
      assignedByUserName: json['assigned_by_user']?['username'],
      assignedByUserEmail: json['assigned_by_user']?['email'],
      saleUserId: json['sale']?['seller']?['id']?.toString(),
      saleUserName: json['sale']?['seller']?['username'],
      saleUserEmail: json['sale']?['seller']?['email'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sale_id': saleId,
      'sale_item_id': saleItemId,
      'service_id': serviceId,
      'product_id': productId,
      'customer_id': customerId,
      'driver_id': driverId,
      'car_id': carId,
      'status': status,
      'priority': priority,
      'scheduled_date': scheduledDate.toIso8601String(),
      'actual_start_time': actualStartTime?.toIso8601String(),
      'actual_end_time': actualEndTime?.toIso8601String(),
      'pickup_location': pickupLocation,
      'dropoff_location': dropoffLocation,
      'number_of_passengers': numberOfPassengers,
      'luggage_count': luggageCount,
      'service_value_usd': serviceValueUsd,
      'product_value_usd': productValueUsd,
      'quantity': quantity,
      'driver_commission_usd': driverCommissionUsd,
      'whatsapp_message_sent': whatsappMessageSent,
      'google_calendar_event_created': googleCalendarEventCreated,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'flight_number': flightNumber,
      'flight_status': flightStatus,
      'scheduled_departure_time': scheduledDepartureTime?.toIso8601String(),
      'scheduled_arrival_time': scheduledArrivalTime?.toIso8601String(),
      'departure_airport_code': departureAirportCode,
      'arrival_airport_code': arrivalAirportCode,
      'commission_payment_status': commissionPaymentStatus,
      'total_commission_usd': totalCommissionUsd,
    };
  }

  // Getters para status
  bool get isPending => status == 'pending';
  bool get isAssigned => status == 'assigned';
  bool get isInProgress => status == 'in_progress';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
  
  // Getters para informações do cliente
  bool get isVipCustomer => customerIsVip ?? false;
  String get vipStatusText => isVipCustomer ? 'VIP' : 'Regular';
  bool get hasAgency => customerAgencyId != null;
  String get agencyDisplayName => customerAgencyName ?? 'Sem agência';
  String get agencyContactInfo {
    if (!hasAgency) return 'N/A';
    final parts = <String>[];
    if (customerAgencyEmail != null) parts.add(customerAgencyEmail!);
    if (customerAgencyPhone != null) parts.add(customerAgencyPhone!);
    if (customerAgencyCity != null) parts.add(customerAgencyCity!);
    return parts.isNotEmpty ? parts.join(' • ') : 'Sem informações';
  }
  
  bool get hasDriver => driverId != null && driverName != null;
  bool get hasCar => carId != null && carName != null;
  bool get hasFlightData => flightNumber != null;
  
  String get statusText {
    switch (status) {
      case 'pending':
        return 'Pendente';
      case 'assigned':
        return 'Designada';
      case 'in_progress':
        return 'Em Andamento';
      case 'completed':
        return 'Concluída';
      case 'cancelled':
        return 'Cancelada';
      default:
        return 'Desconhecido';
    }
  }

  String get priorityText {
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
        return 'Normal';
    }
  }
}

class OperationsNotifier extends StateNotifier<OperationsState> {
  SupabaseClient get _supabase => Supabase.instance.client;
  final Ref _ref;

  OperationsNotifier(this._ref) : super(OperationsState());

  // Carregar todas as operações
  Future<void> loadOperations() async {
    try {
      print('DEBUG: Iniciando carregamento de operações...');
      state = state.copyWith(isLoading: true, error: null);

      print('DEBUG: Executando query no Supabase...');
      final response = await _supabase
          .from('operation')
          .select('''
            *,
            contact:customer_id(
              name,
              phone,
              email,
              account_id,
              is_vip,
              account:account_id(
                name,
                email,
                phone,
                account_category:chave_id(
                  account_type
                )
              )
            ),
            service:service_id(
              name
            ),
            driver:driver_id(
              name,
              phone
            ),
            car:car_id(
              make,
              model,
              license_plate
            ),
            created_by_user:created_by_user_id(
              id,
              username,
              email
            ),
            assigned_by_user:assigned_by_user_id(
              id,
              username,
              email
            ),
            sale:sale_id(
              user_id,
              seller:user_id(
                id,
                username,
                email
              )
            )
          ''')
          .order('scheduled_date', ascending: false);

      print('DEBUG: Query executada com sucesso. Resposta recebida: ${response.length} registros');
      print('DEBUG: Primeiro registro (se existir): ${response.isNotEmpty ? response.first : 'Nenhum registro'}');

      print('DEBUG: Convertendo resposta para objetos Operation...');
      final operations = <Operation>[];
      for (int i = 0; i < (response as List).length; i++) {
        try {
          final json = response[i];
          print('DEBUG: Processando operação $i: ID=${json['id']}');
          final operation = Operation.fromJson(json);
          operations.add(operation);
          print('DEBUG: Operação $i convertida com sucesso');
        } catch (e) {
          print('DEBUG: Erro ao converter operação $i: $e');
          print('DEBUG: JSON da operação com erro: ${response[i]}');
        }
      }

      print('DEBUG: Conversão concluída. ${operations.length} operações processadas com sucesso');

      state = state.copyWith(
        allOperations: operations,
        isLoading: false,
      );

      print('DEBUG: Estado atualizado com sucesso');

    } catch (e) {
      print('DEBUG: Erro capturado no loadOperations: $e');
      print('DEBUG: Stack trace: ${StackTrace.current}');
      state = state.copyWith(
        error: 'Erro ao carregar operações: $e',
        isLoading: false,
      );
      debugPrint('Erro ao carregar operações: $e');
    }
  }

  // Buscar operação por ID
  Operation? getOperationById(int id) {
    try {
      return state.allOperations.firstWhere((op) => op.id == id);
    } catch (e) {
      return null;
    }
  }

  // Atualizar status de uma operação
  Future<bool> updateOperationStatus(int operationId, String newStatus) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      // Buscar o status atual antes da atualização
      final currentOperation = getOperationById(operationId);
      final oldStatus = currentOperation?.status;

      final response = await _supabase
          .from('operation')
          .update({
            'status': newStatus,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', operationId)
          .select();

      if (response.isNotEmpty) {
        // Registrar no histórico
        if (oldStatus != null && oldStatus != newStatus) {
          await _ref.read(operationHistoryProvider.notifier).recordStatusChange(
            operationId: operationId,
            oldStatus: oldStatus,
            newStatus: newStatus,
          );
        }

        // Atualizar a lista local
        await loadOperations();
        return true;
      }

      return false;
    } catch (e) {
      state = state.copyWith(
        error: 'Erro ao atualizar status: $e',
        isLoading: false,
      );
      debugPrint('Erro ao atualizar status: $e');
      return false;
    }
  }

  // Designar driver para operação
  Future<bool> assignDriver(int operationId, int driverId, int carId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final response = await _supabase
          .from('operation')
          .update({
            'driver_id': driverId,
            'car_id': carId,
            'status': 'assigned',
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', operationId)
          .select();

      if (response.isNotEmpty) {
        // Buscar informações do motorista para o histórico
        final driverResponse = await _supabase
            .from('driver')
            .select('name')
            .eq('id', driverId)
            .single();
        
        final driverName = driverResponse['name'] as String;
        
        // Registrar designação no histórico
        await _ref.read(operationHistoryProvider.notifier).recordDriverAssignment(
          operationId: operationId,
          driverId: driverId,
          driverName: driverName,
          carId: carId,
        );
        
        await loadOperations();
        return true;
      }

      return false;
    } catch (e) {
      state = state.copyWith(
        error: 'Erro ao designar driver: $e',
        isLoading: false,
      );
      debugPrint('Erro ao designar driver: $e');
      return false;
    }
  }

  // Iniciar operação
  Future<bool> startOperation(int operationId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final response = await _supabase
          .from('operation')
          .update({
            'status': 'in_progress',
            'actual_start_time': DateTime.now().toUtc().toIso8601String(),
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', operationId)
          .select();

      if (response.isNotEmpty) {
        await loadOperations();
        return true;
      }

      return false;
    } catch (e) {
      state = state.copyWith(
        error: 'Erro ao iniciar operação: $e',
        isLoading: false,
      );
      debugPrint('Erro ao iniciar operação: $e');
      return false;
    }
  }

  // Concluir operação
  Future<bool> completeOperation(int operationId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final response = await _supabase
          .from('operation')
          .update({
            'status': 'completed',
            'actual_end_time': DateTime.now().toUtc().toIso8601String(),
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', operationId)
          .select();

      if (response.isNotEmpty) {
        await loadOperations();
        return true;
      }

      return false;
    } catch (e) {
      state = state.copyWith(
        error: 'Erro ao concluir operação: $e',
        isLoading: false,
      );
      debugPrint('Erro ao concluir operação: $e');
      return false;
    }
  }

  // Cancelar operação
  Future<bool> cancelOperation(int operationId, String reason) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final response = await _supabase
          .from('operation')
          .update({
            'status': 'cancelled',
            'driver_notes': 'Cancelada: $reason',
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', operationId)
          .select();

      if (response.isNotEmpty) {
        await loadOperations();
        return true;
      }

      return false;
    } catch (e) {
      state = state.copyWith(
        error: 'Erro ao cancelar operação: $e',
        isLoading: false,
      );
      debugPrint('Erro ao cancelar operação: $e');
      return false;
    }
  }

  // Buscar operações por filtro
  List<Operation> getOperationsByFilter(String filter) {
    switch (filter) {
      case 'pending':
        return state.pendingOperations;
      case 'in_progress':
        return state.inProgressOperations;
      case 'completed':
        return state.completedOperations;
      case 'urgent':
        return state.allOperations.where((op) => op.priority == 'urgent').toList();
      case 'today':
        final today = DateTime.now();
        return state.allOperations.where((op) => 
          op.scheduledDate.year == today.year &&
          op.scheduledDate.month == today.month &&
          op.scheduledDate.day == today.day
        ).toList();
      default:
        return state.allOperations;
    }
  }

  // Estatísticas
  Map<String, int> get statistics {
    return {
      'total': state.allOperations.length,
      'pending': state.pendingOperations.length,
      'in_progress': state.inProgressOperations.length,
      'completed': state.completedOperations.length,
      'cancelled': state.allOperations.where((op) => op.isCancelled).length,
      'urgent': state.allOperations.where((op) => op.priority == 'urgent').length,
    };
  }

  // Criar nova operação
  Future<bool> createOperation(Operation operation) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final response = await _supabase
          .from('operation')
          .insert({
            'sale_id': operation.saleId,
            'sale_item_id': operation.saleItemId,
            'service_id': operation.serviceId,
            'customer_id': operation.customerId,
            'driver_id': operation.driverId,
            'car_id': operation.carId,
            'status': operation.status,
            'priority': operation.priority,
            'scheduled_date': operation.scheduledDate.toIso8601String(),
            'pickup_location': operation.pickupLocation,
            'dropoff_location': operation.dropoffLocation,
            'number_of_passengers': operation.numberOfPassengers,
            'luggage_count': operation.luggageCount,
            'service_value_usd': operation.serviceValueUsd,
            'driver_commission_usd': operation.driverCommissionUsd,
            'whatsapp_message_sent': operation.whatsappMessageSent,
            'google_calendar_event_created': operation.googleCalendarEventCreated,
            'created_at': operation.createdAt.toIso8601String(),
            'updated_at': operation.updatedAt.toIso8601String(),
          })
          .select();

      if (response.isNotEmpty) {
        await loadOperations();
        return true;
      }

      return false;
    } catch (e) {
      state = state.copyWith(
        error: 'Erro ao criar operação: $e',
        isLoading: false,
      );
      debugPrint('Erro ao criar operação: $e');
      return false;
    }
  }

  // Atualizar operação completa (para mudanças de clientes)
  Future<bool> updateOperation(int operationId, {
    DateTime? scheduledDate,
    String? pickupLocation,
    String? dropoffLocation,
    int? numberOfPassengers,
    int? luggageCount,
    String? flightNumber,
    DateTime? scheduledDepartureTime,
    DateTime? scheduledArrivalTime,
    String? departureAirportCode,
    String? arrivalAirportCode,
    String? customerNotes,
    String? specialInstructions,
    String? priority,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };

      if (scheduledDate != null) updateData['scheduled_date'] = scheduledDate.toIso8601String();
      if (pickupLocation != null) updateData['pickup_location'] = pickupLocation;
      if (dropoffLocation != null) updateData['dropoff_location'] = dropoffLocation;
      if (numberOfPassengers != null) updateData['number_of_passengers'] = numberOfPassengers;
      if (luggageCount != null) updateData['luggage_count'] = luggageCount;
      if (flightNumber != null) updateData['flight_number'] = flightNumber;
      if (scheduledDepartureTime != null) updateData['scheduled_departure_time'] = scheduledDepartureTime.toIso8601String();
      if (scheduledArrivalTime != null) updateData['scheduled_arrival_time'] = scheduledArrivalTime.toIso8601String();
      if (departureAirportCode != null) updateData['departure_airport_code'] = departureAirportCode;
      if (arrivalAirportCode != null) updateData['arrival_airport_code'] = arrivalAirportCode;
      if (customerNotes != null) updateData['customer_notes'] = customerNotes;
      if (specialInstructions != null) updateData['special_instructions'] = specialInstructions;
      if (priority != null) updateData['priority'] = priority;

      final response = await _supabase
          .from('operation')
          .update(updateData)
          .eq('id', operationId)
          .select();

      if (response.isNotEmpty) {
        await loadOperations();
        return true;
      }

      return false;
    } catch (e) {
      state = state.copyWith(
        error: 'Erro ao atualizar operação: $e',
        isLoading: false,
      );
      debugPrint('Erro ao atualizar operação: $e');
      return false;
    }
  }

  // Deletar operação
  Future<bool> deleteOperation(int operationId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final response = await _supabase
          .from('operation')
          .delete()
          .eq('id', operationId)
          .select();

      if (response.isNotEmpty) {
        await loadOperations();
        return true;
      }

      return false;
    } catch (e) {
      state = state.copyWith(
        error: 'Erro ao deletar operação: $e',
        isLoading: false,
      );
      debugPrint('Erro ao deletar operação: $e');
      return false;
    }
  }

  // Atualizar informações de voo (para mudanças frequentes)
  Future<bool> updateFlightInfo(int operationId, {
    String? flightNumber,
    DateTime? scheduledDepartureTime,
    DateTime? scheduledArrivalTime,
    String? departureAirportCode,
    String? arrivalAirportCode,
    String? flightStatus,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };

      if (flightNumber != null) updateData['flight_number'] = flightNumber;
      if (scheduledDepartureTime != null) updateData['scheduled_departure_time'] = scheduledDepartureTime.toIso8601String();
      if (scheduledArrivalTime != null) updateData['scheduled_arrival_time'] = scheduledArrivalTime.toIso8601String();
      if (departureAirportCode != null) updateData['departure_airport_code'] = departureAirportCode;
      if (arrivalAirportCode != null) updateData['arrival_airport_code'] = arrivalAirportCode;
      if (flightStatus != null) updateData['flight_status'] = flightStatus;

      final response = await _supabase
          .from('operation')
          .update(updateData)
          .eq('id', operationId)
          .select();

      if (response.isNotEmpty) {
        await loadOperations();
        return true;
      }

      return false;
    } catch (e) {
      state = state.copyWith(
        error: 'Erro ao atualizar informações de voo: $e',
        isLoading: false,
      );
      debugPrint('Erro ao atualizar informações de voo: $e');
      return false;
    }
  }

  // Atualizar locais de pickup e dropoff
  Future<bool> updateLocations(int operationId, {
    String? pickupLocation,
    String? dropoffLocation,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };

      if (pickupLocation != null) updateData['pickup_location'] = pickupLocation;
      if (dropoffLocation != null) updateData['dropoff_location'] = dropoffLocation;

      final response = await _supabase
          .from('operation')
          .update(updateData)
          .eq('id', operationId)
          .select();

      if (response.isNotEmpty) {
        await loadOperations();
        return true;
      }

      return false;
    } catch (e) {
      state = state.copyWith(
        error: 'Erro ao atualizar locais: $e',
        isLoading: false,
      );
      debugPrint('Erro ao atualizar locais: $e');
      return false;
    }
  }

  // Limpar erro
  void clearError() {
    state = state.copyWith(error: null);
  }
}

class OperationsState {
  final List<Operation> allOperations;
  final bool isLoading;
  final String? error;

  OperationsState({
    this.allOperations = const [],
    this.isLoading = false,
    this.error,
  });

  List<Operation> get pendingOperations => 
      allOperations.where((op) => op.isPending || op.isAssigned).toList();
  List<Operation> get inProgressOperations => 
      allOperations.where((op) => op.isInProgress).toList();
  List<Operation> get completedOperations => 
      allOperations.where((op) => op.isCompleted).toList();

  OperationsState copyWith({
    List<Operation>? allOperations,
    bool? isLoading,
    String? error,
  }) {
    return OperationsState(
      allOperations: allOperations ?? this.allOperations,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// Provider do Riverpod
final operationsProvider = StateNotifierProvider<OperationsNotifier, OperationsState>((ref) {
  return OperationsNotifier(ref);
});
