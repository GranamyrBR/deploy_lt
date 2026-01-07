import 'package:supabase_flutter/supabase_flutter.dart';

class CustomerAnalyticsService {
  SupabaseClient get _supabase => Supabase.instance.client;

  /// Obtém dados completos de análise de um cliente específico
  Future<Map<String, dynamic>> getCustomerAnalytics(int customerId) async {
    try {
      // Buscar dados básicos do cliente
      final customerData = await _getCustomerBasicData(customerId);
      
      // Buscar dados de vendas
      final salesData = await _getCustomerSalesData(customerId);
      
      // Buscar dados de operações
      final operationsData = await _getCustomerOperationsData(customerId);
      
      // Buscar ratings e feedback
      final ratingsData = await _getCustomerRatingsData(customerId);
      
      // Calcular métricas
      final metrics = await _calculateCustomerMetrics(customerId, salesData, operationsData);
      
      // Buscar dados comparativos
      final comparativeData = await _getComparativeMetrics(customerId, customerData['account_id']);
      
      return {
        'customer': customerData,
        'sales': salesData,
        'operations': operationsData,
        'ratings': ratingsData,
        'metrics': metrics,
        'comparative': comparativeData,
        'lastUpdated': DateTime.now().toUtc().toIso8601String(),
      };
    } catch (e) {
      print('Erro ao obter analytics do cliente $customerId: $e');
      rethrow;
    }
  }

  /// Busca dados básicos do cliente
  Future<Map<String, dynamic>> _getCustomerBasicData(int customerId) async {
    final response = await _supabase
        .from('contact')
        .select('''
          id, name, email, phone, address, city, state, country,
          gender, is_vip, created_at, updated_at,
          account:account_id(id, name, contact_name, domain, logo_url),
          source:source_id(id, name),
          category:contact_category_id(id, name)
        ''')
        .eq('id', customerId)
        .single();
    
    return response;
  }

  /// Busca dados de vendas do cliente
  Future<Map<String, dynamic>> _getCustomerSalesData(int customerId) async {
    final salesResponse = await _supabase
        .from('sale')
        .select('''
          id, sale_number, total_amount, total_amount_usd, payment_method,
          status, payment_status, sale_date, created_at, notes,
          currency:currency_id(currency_code, currency_name),
          created_by:created_by_user_id(id, username),
          items:sale_item(sales_item_id, quantity, unit_price_at_sale, subtotal,
            product:product_id(product_id, name, price_per_unit),
            service:service_id(id, name, price)
          )
        ''')
        .eq('customer_id', customerId)
        .order('sale_date', ascending: false);

    // Calcular estatísticas de vendas
    double totalSpent = 0;
    double totalSpentUSD = 0;
    int totalSales = salesResponse.length;
    int completedSales = 0;
    int pendingSales = 0;
    Map<String, int> paymentMethods = {};
    Map<String, int> salesByStatus = {};
    
    for (final sale in salesResponse) {
      totalSpent += (sale['total_amount'] ?? 0).toDouble();
      totalSpentUSD += (sale['total_amount_usd'] ?? 0).toDouble();
      
      final status = sale['status'] ?? 'unknown';
      salesByStatus[status] = (salesByStatus[status] ?? 0) + 1;
      
      if (status == 'completed') completedSales++;
      if (status == 'pending') pendingSales++;
      
      final paymentMethod = sale['payment_method'] ?? 'unknown';
      paymentMethods[paymentMethod] = (paymentMethods[paymentMethod] ?? 0) + 1;
    }

    return {
      'sales': salesResponse,
      'statistics': {
        'totalSales': totalSales,
        'completedSales': completedSales,
        'pendingSales': pendingSales,
        'totalSpent': totalSpent,
        'totalSpentUSD': totalSpentUSD,
        'averageOrderValue': totalSales > 0 ? totalSpentUSD / totalSales : 0,
        'paymentMethods': paymentMethods,
        'salesByStatus': salesByStatus,
      }
    };
  }

  /// Busca dados de operações do cliente
  Future<Map<String, dynamic>> _getCustomerOperationsData(int customerId) async {
    final operationsResponse = await _supabase
        .from('operation')
        .select('''
          id, status, priority, scheduled_date, actual_start_time, actual_end_time,
          pickup_location, dropoff_location, number_of_passengers, luggage_count,
          service_value_usd, customer_rating, customer_feedback, driver_rating, driver_feedback,
          special_instructions, customer_notes, driver_notes, created_at,
          driver:driver_id(id, name, phone),
          car:car_id(id, make, model, year, license_plate, color),
          service:service_id(id, name, description),
          product:product_id(product_id, name, site_url)
        ''')
        .eq('customer_id', customerId)
        .order('scheduled_date', ascending: false);

    // Calcular estatísticas de operações
    int totalOperations = operationsResponse.length;
    int completedOperations = 0;
    int cancelledOperations = 0;
    double totalServiceValue = 0;
    List<int> customerRatings = [];
    List<int> driverRatings = [];
    Map<String, int> visitedLocations = {};
    Map<String, int> operationsByStatus = {};
    Set<int> uniqueDrivers = {};
    Set<int> uniqueCars = {};
    
    for (final operation in operationsResponse) {
      final status = operation['status'] ?? 'unknown';
      operationsByStatus[status] = (operationsByStatus[status] ?? 0) + 1;
      
      if (status == 'completed') completedOperations++;
      if (status == 'cancelled') cancelledOperations++;
      
      totalServiceValue += (operation['service_value_usd'] ?? 0).toDouble();
      
      if (operation['customer_rating'] != null) {
        customerRatings.add(operation['customer_rating']);
      }
      
      if (operation['driver_rating'] != null) {
        driverRatings.add(operation['driver_rating']);
      }
      
      // Locais visitados
      final pickup = operation['pickup_location'];
      final dropoff = operation['dropoff_location'];
      if (pickup != null) {
        visitedLocations[pickup] = (visitedLocations[pickup] ?? 0) + 1;
      }
      if (dropoff != null) {
        visitedLocations[dropoff] = (visitedLocations[dropoff] ?? 0) + 1;
      }
      
      // Motoristas e carros únicos
      if (operation['driver_id'] != null) {
        uniqueDrivers.add(operation['driver_id']);
      }
      if (operation['car_id'] != null) {
        uniqueCars.add(operation['car_id']);
      }
    }

    double avgCustomerRating = customerRatings.isNotEmpty 
        ? customerRatings.reduce((a, b) => a + b) / customerRatings.length 
        : 0;
    
    double avgDriverRating = driverRatings.isNotEmpty 
        ? driverRatings.reduce((a, b) => a + b) / driverRatings.length 
        : 0;

    return {
      'operations': operationsResponse,
      'statistics': {
        'totalOperations': totalOperations,
        'completedOperations': completedOperations,
        'cancelledOperations': cancelledOperations,
        'totalServiceValue': totalServiceValue,
        'averageCustomerRating': avgCustomerRating,
        'averageDriverRating': avgDriverRating,
        'uniqueDriversCount': uniqueDrivers.length,
        'uniqueCarsCount': uniqueCars.length,
        'visitedLocations': visitedLocations,
        'operationsByStatus': operationsByStatus,
        'customerRatingsCount': customerRatings.length,
        'driverRatingsCount': driverRatings.length,
      }
    };
  }

  /// Busca dados de ratings e feedback
  Future<Map<String, dynamic>> _getCustomerRatingsData(int customerId) async {
    final ratingsResponse = await _supabase
        .from('operation')
        .select('''
          id, customer_rating, customer_feedback, driver_rating, driver_feedback,
          scheduled_date, service_value_usd,
          driver:driver_id(id, name),
          service:service_id(id, name)
        ''')
        .eq('customer_id', customerId)
        .not('customer_rating', 'is', null)
        .order('scheduled_date', ascending: false);

    // Agrupar ratings por motorista
    Map<int, List<Map<String, dynamic>>> ratingsByDriver = {};
    Map<int, double> avgRatingsByDriver = {};
    
    for (final rating in ratingsResponse) {
      final driverId = rating['driver_id'];
      if (driverId != null) {
        if (!ratingsByDriver.containsKey(driverId)) {
          ratingsByDriver[driverId] = [];
        }
        ratingsByDriver[driverId]!.add(rating);
      }
    }
    
    // Calcular média por motorista
    ratingsByDriver.forEach((driverId, ratings) {
      final customerRatings = ratings
          .where((r) => r['customer_rating'] != null)
          .map((r) => r['customer_rating'] as int)
          .toList();
      
      if (customerRatings.isNotEmpty) {
        avgRatingsByDriver[driverId] = 
            customerRatings.reduce((a, b) => a + b) / customerRatings.length;
      }
    });

    return {
      'allRatings': ratingsResponse,
      'ratingsByDriver': ratingsByDriver,
      'avgRatingsByDriver': avgRatingsByDriver,
    };
  }

  /// Calcula métricas do cliente
  Future<Map<String, dynamic>> _calculateCustomerMetrics(int customerId, 
      Map<String, dynamic> salesData, Map<String, dynamic> operationsData) async {
    
    final salesStats = salesData['statistics'] as Map<String, dynamic>;
    final operationsStats = operationsData['statistics'] as Map<String, dynamic>;
    
    // Calcular frequência de compras
    final sales = salesData['sales'] as List;
    DateTime? firstSale;
    DateTime? lastSale;
    
    if (sales.isNotEmpty) {
      final sortedSales = List.from(sales)
        ..sort((a, b) => DateTime.parse(a['sale_date'])
            .compareTo(DateTime.parse(b['sale_date'])));
      
      firstSale = DateTime.parse(sortedSales.first['sale_date']);
      lastSale = DateTime.parse(sortedSales.last['sale_date']);
    }
    
    // Calcular lifetime value
    final lifetimeValue = salesStats['totalSpentUSD'] as double;
    
    // Calcular frequência (vendas por mês)
    double purchaseFrequency = 0;
    if (firstSale != null && lastSale != null && sales.length > 1) {
      final daysBetween = lastSale.difference(firstSale).inDays;
      if (daysBetween > 0) {
        purchaseFrequency = (sales.length - 1) / (daysBetween / 30.44); // vendas por mês
      }
    }
    
    // Calcular taxa de conclusão
    final completionRate = operationsStats['totalOperations'] > 0 
        ? (operationsStats['completedOperations'] as int) / (operationsStats['totalOperations'] as int)
        : 0.0;
    
    // Calcular satisfação geral
    final avgRating = operationsStats['averageCustomerRating'] as double;
    
    return {
      'lifetimeValue': lifetimeValue,
      'purchaseFrequency': purchaseFrequency,
      'completionRate': completionRate,
      'averageRating': avgRating,
      'firstPurchase': firstSale?.toIso8601String(),
      'lastPurchase': lastSale?.toIso8601String(),
      'customerSince': firstSale != null 
          ? DateTime.now().difference(firstSale).inDays 
          : 0,
    };
  }

  /// Busca métricas comparativas
  Future<Map<String, dynamic>> _getComparativeMetrics(int customerId, int? accountId) async {
    try {
      // Métricas gerais de todos os clientes
      final allCustomersMetrics = await _getAllCustomersMetrics();
      
      // Métricas da agência (se aplicável)
      Map<String, dynamic>? agencyMetrics;
      if (accountId != null) {
        agencyMetrics = await _getAgencyCustomersMetrics(accountId);
      }
      
      return {
        'allCustomers': allCustomersMetrics,
        'agency': agencyMetrics,
      };
    } catch (e) {
      print('Erro ao buscar métricas comparativas: $e');
      return {
        'allCustomers': {},
        'agency': null,
      };
    }
  }

  /// Busca métricas de todos os clientes
  Future<Map<String, dynamic>> _getAllCustomersMetrics() async {
    // Buscar estatísticas agregadas de vendas
    final salesStats = await _supabase
        .from('sale')
        .select('customer_id, total_amount_usd, status')
        .not('total_amount_usd', 'is', null);
    
    // Buscar estatísticas agregadas de operações
    final operationsStats = await _supabase
        .from('operation')
        .select('customer_id, customer_rating, status, service_value_usd');
    
    // Calcular métricas agregadas
    final customerSpending = <int, double>{};
    final customerSalesCount = <int, int>{};
    
    for (final sale in salesStats) {
      final customerId = sale['customer_id'] as int;
      final amount = (sale['total_amount_usd'] ?? 0).toDouble();
      
      customerSpending[customerId] = (customerSpending[customerId] ?? 0) + amount;
      customerSalesCount[customerId] = (customerSalesCount[customerId] ?? 0) + 1;
    }
    
    final spendingValues = customerSpending.values.toList()..sort();
    final salesCountValues = customerSalesCount.values.toList()..sort();
    
    // Calcular percentis
    final avgSpending = spendingValues.isNotEmpty 
        ? spendingValues.reduce((a, b) => a + b) / spendingValues.length 
        : 0;
    
    final medianSpending = spendingValues.isNotEmpty 
        ? _calculateMedian(spendingValues) 
        : 0;
    
    final avgSalesCount = salesCountValues.isNotEmpty 
        ? salesCountValues.reduce((a, b) => a + b) / salesCountValues.length 
        : 0;
    
    return {
      'averageSpending': avgSpending,
      'medianSpending': medianSpending,
      'averageSalesCount': avgSalesCount,
      'totalCustomers': customerSpending.length,
    };
  }

  /// Busca métricas dos clientes de uma agência específica
  Future<Map<String, dynamic>> _getAgencyCustomersMetrics(int accountId) async {
    // Buscar clientes da agência
    final agencyCustomers = await _supabase
        .from('contact')
        .select('id')
        .eq('account_id', accountId);
    
    final customerIds = agencyCustomers.map((c) => c['id'] as int).toList();
    
    if (customerIds.isEmpty) {
      return {
        'averageSpending': 0,
        'averageSalesCount': 0,
        'totalCustomers': 0,
      };
    }
    
    // Buscar vendas dos clientes da agência
    final salesStats = await _supabase
        .from('sale')
        .select('customer_id, total_amount_usd')
        .inFilter('customer_id', customerIds)
        .not('total_amount_usd', 'is', null);
    
    final customerSpending = <int, double>{};
    final customerSalesCount = <int, int>{};
    
    for (final sale in salesStats) {
      final customerId = sale['customer_id'] as int;
      final amount = (sale['total_amount_usd'] ?? 0).toDouble();
      
      customerSpending[customerId] = (customerSpending[customerId] ?? 0) + amount;
      customerSalesCount[customerId] = (customerSalesCount[customerId] ?? 0) + 1;
    }
    
    final avgSpending = customerSpending.values.isNotEmpty 
        ? customerSpending.values.reduce((a, b) => a + b) / customerSpending.values.length 
        : 0;
    
    final avgSalesCount = customerSalesCount.values.isNotEmpty 
        ? customerSalesCount.values.reduce((a, b) => a + b) / customerSalesCount.values.length 
        : 0;
    
    return {
      'averageSpending': avgSpending,
      'averageSalesCount': avgSalesCount,
      'totalCustomers': customerIds.length,
    };
  }

  /// Calcula a mediana de uma lista de números
  double _calculateMedian(List<double> values) {
    if (values.isEmpty) return 0;
    
    final sorted = List<double>.from(values)..sort();
    final middle = sorted.length ~/ 2;
    
    if (sorted.length % 2 == 0) {
      return (sorted[middle - 1] + sorted[middle]) / 2;
    } else {
      return sorted[middle];
    }
  }

  /// Busca histórico de interações do cliente
  Future<List<Map<String, dynamic>>> getCustomerInteractionHistory(int customerId) async {
    try {
      final interactions = await _supabase
          .from('operation_history')
          .select('''
            id, action_type, old_value, new_value, action_data,
            performed_at, performed_by_user_name,
            operation:operation_id(id, scheduled_date, pickup_location, dropoff_location)
          ''')
          .eq('operation.customer_id', customerId)
          .order('performed_at', ascending: false)
          .order('id', ascending: false).limit(50);
      
      return List<Map<String, dynamic>>.from(interactions);
    } catch (e) {
      print('Erro ao buscar histórico de interações: $e');
      return [];
    }
  }
}
