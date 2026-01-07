import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/provisional_invoice_item.dart';
import '../models/contact.dart';
import '../models/contact_service.dart';
import '../models/provisional_invoice.dart';
import '../services/sales_service.dart';
import '../models/sale_item.dart';
import '../models/sale.dart';
import '../models/sale_item_detail.dart';
import '../models/currency.dart';
import '../models/service.dart';
import '../models/user_roles.dart';
import 'auth_provider.dart';
import 'exchange_rate_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// =====================================================
// SALES SERVICE PROVIDER
// =====================================================

final salesServiceProvider = Provider<SalesService>((ref) {
  return SalesService();
});

// =====================================================
// CURRENCIES
// =====================================================

final currenciesProvider = FutureProvider<List<Currency>>((ref) async {
  final service = ref.watch(salesServiceProvider);
  return service.getCurrencies();
});

final currencyProvider = FutureProvider.family<Currency?, int>((ref, currencyId) async {
  final service = ref.watch(salesServiceProvider);
  return service.getCurrencyById(currencyId);
});

// =====================================================
// SALES
// =====================================================

class SalesNotifier extends StateNotifier<List<Sale>> {
  SalesNotifier(this._ref) : super([]);
  
  final Ref _ref;
  final SalesService _salesService = SalesService();
  String? _currentUserId;

  void setCurrentUser(String userId) {
    _currentUserId = userId;
  }

  // Método de compatibilidade para manter código existente
  void setCurrentUserId(String userId) {
    setCurrentUser(userId);
  }

  // Método para buscar dados do cliente
  Future<Map<String, dynamic>?> _fetchCustomerData(int customerId) async {
    if (customerId == 0) return null;
    
    final supabase = Supabase.instance.client;
    try {
      final response = await supabase
          .from('contact')
          .select('name, email, phone')
          .eq('id', customerId)
          .single();
      
      return response;
    } catch (e) {
      print('Erro ao buscar dados do cliente $customerId: $e');
      return null;
    }
  }

  // Método auxiliar para buscar itens de uma venda específica
  Future<List<SaleItemDetail>> _fetchSaleItems(int saleId) async {
    final supabase = Supabase.instance.client;
    
    try {
      print('DEBUG: Buscando itens para venda $saleId');
      
      // Primeiro, buscar os itens da venda
      final response = await supabase
          .from('sale_item')
          .select('*')
          .eq('sales_id', saleId);

      print('DEBUG: Resposta da query para venda $saleId: ${response.length} itens');
      print('DEBUG: Dados brutos: $response');

      final items = <SaleItemDetail>[];
      
      for (final itemData in response) {
        String itemName = 'Item sem nome';
        
        // Buscar nome do serviço se service_id existir
        if (itemData['service_id'] != null) {
          try {
            final serviceResponse = await supabase
                .from('service')
                .select('name')
                .eq('id', itemData['service_id'])
                .single();
            itemName = serviceResponse['name'] ?? 'Serviço sem nome';
          } catch (e) {
            print('DEBUG: Erro ao buscar serviço ${itemData['service_id']}: $e');
          }
        }
        // Buscar nome do produto se product_id existir
        else if (itemData['product_id'] != null) {
          try {
            final productResponse = await supabase
                .from('product')
                .select('name')
                .eq('product_id', itemData['product_id'])
                .single();
            itemName = productResponse['name'] ?? 'Produto sem nome';
          } catch (e) {
            print('DEBUG: Erro ao buscar produto ${itemData['product_id']}: $e');
          }
        }
        
        print('DEBUG: Processando item: $itemName');
        
        // Criar o mapa com os dados necessários
        final itemMap = Map<String, dynamic>.from(itemData);
        itemMap['item_name'] = itemName;
        
        items.add(SaleItemDetail.fromJson(itemMap));
      }
      
      print('DEBUG: Total de itens processados para venda $saleId: ${items.length}');
      return items;
    } catch (e) {
      print('Erro ao buscar itens da venda $saleId: $e');
      return [];
    }
  }

  // Método para buscar todas as vendas do usuário (versão otimizada)
  Future<void> fetchSales() async {
    if (_currentUserId == null) {
      print('SalesProvider: _currentUserId é null, não buscando vendas');
      _ref.read(salesLoadedProvider.notifier).state = true;
      return;
    }
    final supabase = Supabase.instance.client;
    
    try {
      print('SalesProvider: Buscando vendas para usuário $_currentUserId');
      
      // Verificar permissões do usuário atual
      final currentAuthState = _ref.read(authProvider);
      final currentUser = currentAuthState.user;
      
      var query = supabase.from('sale').select('*');
      
      // Filtrar por vendedor se o usuário não tiver permissão para ver todas as vendas
      if (currentUser != null && !currentUser.hasPermission(UserRoles.VIEW_ALL_SALES)) {
        // Vendedor só pode ver suas próprias vendas
        query = query.eq('user_id', _currentUserId!);
      }
      
      final response = await query.order('created_at', ascending: false);

      print('SalesProvider: Resposta recebida: ${response.length} vendas');

      // Otimização: Buscar todos os clientes de uma vez
      final customerIds = <int>{};
      final userIds = <String>{};
      final saleIds = <int>{};
      
      for (final saleData in response) {
        if (saleData['customer_id'] != null) {
          customerIds.add(saleData['customer_id']);
        }
        if (saleData['user_id'] != null) {
          userIds.add(saleData['user_id']);
        }
        saleIds.add(saleData['id']);
      }

      // Buscar todos os clientes de uma vez
      Map<int, Map<String, dynamic>> customersData = {};
      if (customerIds.isNotEmpty) {
        try {
          final customersResponse = await supabase
              .from('contact')
              .select('id, name, email, phone, is_vip, account_id, account!account_id(name, email, phone, account_category!chave_id(account_type))')
              .inFilter('id', customerIds.toList());
          
          for (final customer in customersResponse) {
            customersData[customer['id']] = customer;
          }
        } catch (e) {
          print('Erro ao buscar dados dos clientes: $e');
        }
      }

      // Buscar todos os vendedores de uma vez
      Map<String, Map<String, dynamic>> usersData = {};
      if (userIds.isNotEmpty) {
        try {
          final usersResponse = await supabase
              .from('user')
              .select('id, username, email')
              .inFilter('id', userIds.toList());
          
          for (final user in usersResponse) {
            usersData[user['id']] = user;
          }
        } catch (e) {
          print('Erro ao buscar dados dos vendedores: $e');
        }
      }

      // Buscar todos os pagamentos de uma vez com JOIN para payment_method
      Map<int, List<Map<String, dynamic>>> paymentsData = {};
      if (saleIds.isNotEmpty) {
        try {
          final paymentsResponse = await supabase
              .from('sale_payment')
              .select('*, payment_method!payment_method_id(method_name)')
              .inFilter('sales_id', saleIds.toList());
          
          for (final payment in paymentsResponse) {
            final saleId = payment['sales_id'];
            paymentsData.putIfAbsent(saleId, () => []).add(payment);
          }
        } catch (e) {
          print('Erro ao buscar pagamentos: $e');
        }
      }

      // Buscar todos os itens de uma vez
      Map<int, List<Map<String, dynamic>>> itemsData = {};
      Set<int> serviceIds = {};
      Set<int> productIds = {};
      
      if (saleIds.isNotEmpty) {
        try {
          final itemsResponse = await supabase
              .from('sale_item')
              .select('*')
              .inFilter('sales_id', saleIds.toList());
          
          for (final item in itemsResponse) {
            final saleId = item['sales_id'];
            itemsData.putIfAbsent(saleId, () => []).add(item);
            
            // Coletar IDs de serviços e produtos para busca em lote
            if (item['service_id'] != null) {
              serviceIds.add(item['service_id']);
            }
            if (item['product_id'] != null) {
              productIds.add(item['product_id']);
            }
          }
        } catch (e) {
          print('Erro ao buscar itens: $e');
        }
      }

      // Buscar todos os serviços de uma vez
      Map<int, String> servicesData = {};
      if (serviceIds.isNotEmpty) {
        try {
          final servicesResponse = await supabase
              .from('service')
              .select('id, name')
              .inFilter('id', serviceIds.toList());
          
          for (final service in servicesResponse) {
            servicesData[service['id']] = service['name'] ?? 'Serviço sem nome';
          }
        } catch (e) {
          print('Erro ao buscar serviços: $e');
        }
      }

      // Buscar todos os produtos de uma vez
      Map<int, String> productsData = {};
      if (productIds.isNotEmpty) {
        try {
          final productsResponse = await supabase
              .from('product')
              .select('product_id, name')
              .inFilter('product_id', productIds.toList());
          
          for (final product in productsResponse) {
            productsData[product['product_id']] = product['name'] ?? 'Produto sem nome';
          }
        } catch (e) {
          print('Erro ao buscar produtos: $e');
        }
      }

      // Parse dos dados para List<Sale>
      final sales = <Sale>[];
      for (int i = 0; i < response.length; i++) {
        try {
          final saleData = response[i];
          
          // Adicionar dados do cliente
          if (saleData['customer_id'] != null && customersData.containsKey(saleData['customer_id'])) {
            final customer = customersData[saleData['customer_id']]!;
            saleData['customer_name'] = customer['name'];
            saleData['customer_email'] = customer['email'];
            saleData['customer_phone'] = customer['phone'];
            saleData['customer_is_vip'] = customer['is_vip'];
            saleData['customer_agency_id'] = customer['account_id'];
            
            // Mapear account_type string para ID numérico
            final accountType = customer['account']?['account_category']?['account_type'];
            int? accountTypeId;
            if (accountType != null) {
              switch (accountType.toString().toLowerCase()) {
                case 'pessoa física':
                case 'pessoa fisica':
                  accountTypeId = 1;
                  break;
                case 'agências':
                case 'agencias':
                  accountTypeId = 2;
                  break;
                default:
                  accountTypeId = null;
              }
            }
            saleData['customer_account_type_id'] = accountTypeId;
            
            // Adicionar dados da agência se existir
            if (customer['account'] != null) {
              saleData['customer_agency_name'] = customer['account']['name'];
            }
          } else {
            saleData['customer_name'] = 'Cliente não encontrado';
          }
          
          // Adicionar dados do vendedor
          if (saleData['user_id'] != null && usersData.containsKey(saleData['user_id'])) {
            final user = usersData[saleData['user_id']]!;
            saleData['seller_name'] = user['username'];
            saleData['seller_email'] = user['email'];
          } else {
            saleData['seller_name'] = 'Vendedor não encontrado';
          }
          
          // Calcular totais de pagamentos usando dados já carregados
          try {
            final payments = paymentsData[saleData['id']] ?? [];
            
            // REGRA: Tudo é baseado em USD (moeda da empresa)
            // Os pagamentos têm suas taxas travadas no momento do pagamento
            double totalPaidUsd = 0.0;
            double totalPaidBrl = 0.0;
            
            for (final payment in payments) {
              // Usar valores já convertidos que foram travados no momento do pagamento
              final amountInUsd = payment['amount_in_usd'] ?? 0.0;
              final amountInBrl = payment['amount_in_brl'] ?? 0.0;
              
              totalPaidUsd += amountInUsd;
              totalPaidBrl += amountInBrl;
            }
            
            // Venda sempre em USD
            final totalAmountUsd = saleData['total_amount_usd'] ?? saleData['total_amount'] ?? 0.0;
            final saleExchangeRate = saleData['exchange_rate_to_usd'] ?? 5.50; // Cotação da venda
            
            // Calcular valor restante sempre em USD (valor principal)
            final remainingAmountUsd = totalAmountUsd - totalPaidUsd;
            
            // Para exibição: valor total da venda em BRL (usando cotação da venda)
            final totalAmountBrl = totalAmountUsd * saleExchangeRate;
            
            // Para exibição: valor restante em BRL (usando cotação ATUAL apenas como referência)
            // IMPORTANTE: O saldo oficial é sempre em USD, BRL é apenas indicativo
            final currentExchangeRate = _ref.read(tourismDollarRateProvider); // Cotação atual dinâmica
            final remainingAmountBrl = remainingAmountUsd * currentExchangeRate;
            
            // Adicionar campos calculados ao saleData
            saleData['total_paid'] = totalPaidUsd; // Valor principal sempre em USD
            saleData['total_paid_brl'] = totalPaidBrl; // Para exibição
            saleData['total_paid_usd'] = totalPaidUsd; // Redundante mas necessário
            saleData['remaining_amount'] = remainingAmountUsd; // Valor principal sempre em USD
            saleData['remaining_amount_brl'] = remainingAmountBrl; // Para exibição
            saleData['remaining_amount_usd'] = remainingAmountUsd; // Redundante mas necessário
            
            // Garantir que total_amount_brl está definido
            if (saleData['total_amount_brl'] == null) {
              saleData['total_amount_brl'] = totalAmountBrl;
            }
            
            // IMPORTANTE: Incluir os dados dos pagamentos no saleData para que sejam passados para o modelo Sale
            saleData['payments'] = payments;
            saleData['sale_payment'] = payments; // Compatibilidade com diferentes chaves
            
            print('SalesProvider: Venda ${saleData['id']} (USD \$${totalAmountUsd.toStringAsFixed(2)}) - Pago: USD \$${totalPaidUsd.toStringAsFixed(2)} (R\$${totalPaidBrl.toStringAsFixed(2)} travado), Restante oficial: USD \$${remainingAmountUsd.toStringAsFixed(2)} (≈R\$${remainingAmountBrl.toStringAsFixed(2)} indicativo) - ${payments.length} pagamentos incluídos');
            
          } catch (e) {
            print('Erro ao calcular pagamentos para venda ${saleData['id']}: $e');
            // Definir valores padrão se houver erro
            final totalAmountUsd = saleData['total_amount_usd'] ?? saleData['total_amount'] ?? 0.0;
            saleData['total_paid'] = 0.0;
            saleData['total_paid_brl'] = 0.0;
            saleData['total_paid_usd'] = 0.0;
            saleData['remaining_amount'] = totalAmountUsd;
            saleData['remaining_amount_brl'] = totalAmountUsd * _ref.read(tourismDollarRateProvider);
            saleData['remaining_amount_usd'] = totalAmountUsd;
            // Incluir lista vazia de pagamentos em caso de erro
            saleData['payments'] = [];
            saleData['sale_payment'] = [];
          }
          
          // Processar itens da venda usando dados já carregados
          try {
            final items = itemsData[saleData['id']] ?? [];
            final saleItems = <SaleItemDetail>[];
            
            for (final itemData in items) {
              String itemName = 'Item sem nome';
              
              // Usar dados já carregados
              if (itemData['service_id'] != null && servicesData.containsKey(itemData['service_id'])) {
                itemName = servicesData[itemData['service_id']]!;
              } else if (itemData['product_id'] != null && productsData.containsKey(itemData['product_id'])) {
                itemName = productsData[itemData['product_id']]!;
              }
              
              // Criar o mapa com os dados necessários
              final itemMap = Map<String, dynamic>.from(itemData);
              itemMap['item_name'] = itemName;
              
              saleItems.add(SaleItemDetail.fromJson(itemMap));
            }
            
            final itemsJson = saleItems.map((item) => item.toJson()).toList();
            saleData['sale_items'] = itemsJson;
            print('DEBUG: ${saleItems.length} itens processados para venda ${saleData['id']}');
          } catch (e) {
            print('Erro ao processar itens da venda ${saleData['id']}: $e');
            saleData['sale_items'] = [];
          }
          
          final sale = Sale.fromJson(saleData);
          sales.add(sale);
          print('SalesProvider: Venda $i parseada com sucesso: ID ${sale.id}');
        } catch (e) {
          print('SalesProvider: Erro ao parsear venda $i: $e');
        }
      }
      
      state = sales;
      print('SalesProvider: Total de vendas parseadas: ${state.length}');
      _ref.read(salesLoadedProvider.notifier).state = true;
    } catch (e) {
      print('SalesProvider: Erro ao buscar vendas: $e');
      state = [];
      _ref.read(salesLoadedProvider.notifier).state = true;
    }
  }

  // Método de compatibilidade para manter código existente
  Future<void> fetchSalesForUser() async {
    await fetchSales();
  }

  // Método para buscar vendas com filtros
  Future<void> fetchSalesWithFilters(Map<String, dynamic> filters) async {
    if (_currentUserId == null) return;
    final supabase = Supabase.instance.client;
    
    try {
      // Verificar permissões do usuário atual
      final currentAuthState = _ref.read(authProvider);
      final currentUser = currentAuthState.user;
      
      var query = supabase.from('sale').select('*');
      
      // Filtrar por vendedor se o usuário não tiver permissão para ver todas as vendas
      if (currentUser != null && !currentUser.hasPermission(UserRoles.VIEW_ALL_SALES)) {
        // Vendedor só pode ver suas próprias vendas
        query = query.eq('user_id', _currentUserId!);
      }

      // Aplicar filtros
      if (filters['status'] != null) {
        // Se o filtro for 'pending', buscar em ambos os campos
        if (filters['status'] == 'pending') {
          query = query.or('status.eq.pending,payment_status.eq.Pendente');
        } else {
          query = query.eq('status', filters['status']);
        }
      }
      if (filters['contact_id'] != null && filters['contact_id'] != 0) {
        query = query.eq('customer_id', filters['contact_id']);
      }
      if (filters['start_date'] != null) {
        query = query.gte('created_at', filters['start_date']);
      }
      if (filters['end_date'] != null) {
        query = query.lte('created_at', filters['end_date']);
      }
      if (filters['seller_id'] != null) {
        query = query.eq('user_id', filters['seller_id']);
      }

      final response = await query.order('created_at', ascending: false);

      state = (response as List)
          .map((json) => Sale.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('SalesProvider: Erro ao buscar vendas com filtros: $e');
      state = [];
    }
  }

  // Método para buscar vendas pendentes de pagamento
  Future<void> fetchPendingSales() async {
    if (_currentUserId == null) return;
    final supabase = Supabase.instance.client;
    
    try {
      // Verificar permissões do usuário atual
      final currentAuthState = _ref.read(authProvider);
      final currentUser = currentAuthState.user;
      
      var query = supabase
          .from('sale')
          .select('*')
          .or('status.eq.pending,payment_status.eq.Pendente');
      
      // Filtrar por vendedor se o usuário não tiver permissão para ver todas as vendas
      if (currentUser != null && !currentUser.hasPermission(UserRoles.VIEW_ALL_SALES)) {
        // Vendedor só pode ver suas próprias vendas
        query = query.eq('user_id', _currentUserId!);
      }
      
      final response = await query.order('created_at', ascending: false);

      state = (response as List)
          .map((json) => Sale.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('SalesProvider: Erro ao buscar vendas pendentes: $e');
      state = [];
    }
  }

  // Método para buscar vendas por termo de busca (para global search)
  Future<List<Sale>> searchSales(String searchTerm) async {
    if (_currentUserId == null) return [];
    final supabase = Supabase.instance.client;
    
    try {
      // Verificar permissões do usuário atual
      final currentAuthState = _ref.read(authProvider);
      final currentUser = currentAuthState.user;
      
      var query = supabase
          .from('sale')
          .select('*')
          .or('id.eq.$searchTerm,notes.ilike.%$searchTerm%');
      
      // Filtrar por vendedor se o usuário não tiver permissão para ver todas as vendas
      if (currentUser != null && !currentUser.hasPermission(UserRoles.VIEW_ALL_SALES)) {
        // Vendedor só pode ver suas próprias vendas
        query = query.eq('user_id', _currentUserId!);
      }
      
      final response = await query.order('created_at', ascending: false);

      return (response as List)
          .map((json) => Sale.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Erro ao buscar vendas: $e');
      return [];
    }
  }
}

final salesProvider = StateNotifierProvider<SalesNotifier, List<Sale>>((ref) {
  final salesService = ref.watch(salesServiceProvider);
  final notifier = SalesNotifier(ref);
  
  // Verificar se já existe um usuário autenticado na inicialização
  final currentAuthState = ref.read(authProvider);
  if (currentAuthState.isAuthenticated && currentAuthState.user != null) {
    notifier.setCurrentUserId(currentAuthState.user!.id);
    ref.read(salesLoadedProvider.notifier).state = false;
    notifier.fetchSales();
  }
  
  // Escutar mudanças no estado de autenticação
  ref.listen(authProvider, (previous, next) {
    if (next.isAuthenticated && next.user != null) {
      // Quando o usuário faz login, definir o currentUserId
      notifier.setCurrentUserId(next.user!.id);
      // E buscar as vendas
      ref.read(salesLoadedProvider.notifier).state = false;
      notifier.fetchSales();
    } else {
      // Quando o usuário faz logout, limpar o currentUserId
      notifier.setCurrentUserId('');
      ref.read(salesLoadedProvider.notifier).state = false;
    }
  });
  
  return notifier;
});

// Provider para vendas com filtros
final salesWithFiltersProvider = FutureProvider.family<List<Sale>, Map<String, dynamic>>((ref, filters) async {
  final notifier = ref.read(salesProvider.notifier);
  await notifier.fetchSalesWithFilters(filters);
  return ref.watch(salesProvider);
});

// Provider para vendas pendentes
final pendingSalesProvider = FutureProvider<List<Sale>>((ref) async {
  final notifier = ref.read(salesProvider.notifier);
  await notifier.fetchPendingSales();
  return ref.watch(salesProvider);
});

final saleProvider = FutureProvider.family<Sale?, int>((ref, id) async {
  final service = ref.watch(salesServiceProvider);
  return service.getSaleById(id);
});

// =====================================================
// SALE ITEMS
// =====================================================

final saleItemsProvider = FutureProvider.family<List<SaleItem>, int>((ref, saleId) async {
  final supabase = Supabase.instance.client;
  
  try {
    // Query direta na tabela sales_items sem joins problemáticos
    final response = await supabase
        .from('sale_item')
        .select('*')
        .eq('sales_id', saleId)
        .order('created_at');

    return (response as List)
        .map((json) => SaleItem.fromJson(json as Map<String, dynamic>))
        .toList();
  } catch (e) {
    print('Erro ao buscar itens da venda: $e');
    return [];
  }
});

// =====================================================
// SALE PAYMENTS
// =====================================================

final salePaymentsProvider = FutureProvider.family<List<Map<String, dynamic>>, int>((ref, saleId) async {
  final supabase = Supabase.instance.client;
  
  try {
    // Query simplificada sem joins problemáticos
    final response = await supabase
        .from('sale_payment')
        .select('*')
        .eq('sales_id', saleId)
        .order('payment_date', ascending: false);

    return (response as List).cast<Map<String, dynamic>>();
  } catch (e) {
    print('Erro ao buscar pagamentos da venda: $e');
    return [];
  }
});

// =====================================================
// PROVISIONAL INVOICES
// =====================================================

final provisionalInvoicesProvider = FutureProvider.family<List<ProvisionalInvoice>, Map<String, dynamic>>((ref, filters) async {
  final service = ref.watch(salesServiceProvider);
  return service.getProvisionalInvoices(
    accountId: filters['accountId'],
    status: filters['status'],
    startDate: filters['startDate'],
    endDate: filters['endDate'],
    currencyId: filters['currencyId'],
  );
});

final provisionalInvoiceProvider = FutureProvider.family<ProvisionalInvoice?, int>((ref, id) async {
  final service = ref.watch(salesServiceProvider);
  return service.getProvisionalInvoiceById(id);
});

// =====================================================
// PROVISIONAL INVOICE ITEMS
// =====================================================

final provisionalInvoiceItemsProvider = FutureProvider.family<List<ProvisionalInvoiceItem>, int>((ref, invoiceId) async {
  final service = ref.watch(salesServiceProvider);
  return service.getProvisionalInvoiceItems(invoiceId);
});

// =====================================================
// SERVICES & CUSTOMERS
// =====================================================

final servicesProvider = FutureProvider.family<List<Service>, bool?>((ref, isActive) async {
  final service = ref.watch(salesServiceProvider);
  
  try {
    final services = await service.getServices(isActive: isActive);
    
    // Filtrar apenas serviços válidos
    final validServices = services.where((s) => s.name != null && s.name!.isNotEmpty).toList();
    
    return validServices;
  } catch (e) {
    print('Erro no servicesProvider: $e');
    return [];
  }
});

// =====================================================
// CUSTOMER SERVICES
// =====================================================

final contactServicesProvider = FutureProvider.family<List<ContactService>, Map<String, dynamic>>((ref, filters) async {
  final service = ref.watch(salesServiceProvider);
  return service.getContactServices(
    contactId: filters['contactId'],
    serviceId: filters['serviceId'],
    status: filters['status'],
    paymentStatus: filters['paymentStatus'],
    startDate: filters['startDate'],
    endDate: filters['endDate'],
  );
});

final contactServiceProvider = FutureProvider.family<ContactService?, int>((ref, id) async {
  final service = ref.watch(salesServiceProvider);
  return service.getContactServiceById(id);
});

// =====================================================
// INVOICES (ALIAS FOR PROVISIONAL INVOICES)
// =====================================================

final invoicesProvider = FutureProvider.family<List<ProvisionalInvoice>, Map<String, dynamic>>((ref, filters) async {
  final service = ref.watch(salesServiceProvider);
  return service.getProvisionalInvoices(
    accountId: filters['accountId'],
    status: filters['status'],
    startDate: filters['startDate'],
    endDate: filters['endDate'],
    currencyId: filters['currencyId'],
  );
});

// =====================================================
// ANALYTICS
// =====================================================

final salesAnalyticsProvider = FutureProvider.family<Map<String, dynamic>, Map<String, dynamic>>((ref, filters) async {
  final service = ref.watch(salesServiceProvider);
  return service.getSalesAnalytics(
    startDate: filters['startDate'],
    endDate: filters['endDate'],
    currencyId: filters['currencyId'],
  );
});

// =====================================================
// UTILITY PROVIDERS
// =====================================================

final dollarTourismRateProvider = FutureProvider<double?>((ref) async {
  final service = ref.watch(salesServiceProvider);
  return service.getDollarTourismRate();
});

final invoiceNumberProvider = FutureProvider<String>((ref) async {
  final service = ref.watch(salesServiceProvider);
  return service.generateInvoiceNumber();
});

// =====================================================
// FILTER PROVIDERS
// =====================================================

// Provider para filtros de vendas
final salesFiltersProvider = StateProvider<Map<String, dynamic>>((ref) => {});

// Provider para filtros de faturas
final invoiceFiltersProvider = StateProvider<Map<String, dynamic>>((ref) => {});

// Provider para filtros de analytics
final analyticsFiltersProvider = StateProvider<Map<String, dynamic>>((ref) => {
  'startDate': DateTime.now().subtract(const Duration(days: 30)),
  'endDate': DateTime.now(),
});

// =====================================================
// COMPUTED PROVIDERS
// =====================================================

// Vendas filtradas
final filteredSalesProvider = FutureProvider<List<Sale>>((ref) async {
  final filters = ref.watch(salesFiltersProvider);
  return ref.watch(salesWithFiltersProvider(filters).future);
});

// Faturas filtradas
final filteredInvoicesProvider = FutureProvider<List<ProvisionalInvoice>>((ref) async {
  final filters = ref.watch(invoiceFiltersProvider);
  return ref.watch(provisionalInvoicesProvider(filters).future);
});

// Analytics filtrados
final filteredAnalyticsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final filters = ref.watch(analyticsFiltersProvider);
  return ref.watch(salesAnalyticsProvider(filters).future);
});

// =====================================================
// NOVOS PROVIDERS PARA DASHBOARD
// =====================================================

// Top vendedores
final topSellersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final supabase = Supabase.instance.client;
  
  try {
    final response = await supabase
        .from('sale')
        .select('user_id, total_amount, total_amount_in_brl, total_amount_in_usd')
        .gte('created_at', DateTime.now().subtract(const Duration(days: 30)))
        .order('total_amount', ascending: false)
        .order('id', ascending: false).limit(10);

    return (response as List).cast<Map<String, dynamic>>();
  } catch (e) {
    print('Erro ao buscar top vendedores: $e');
    return [];
  }
});

// Vendas por período
final salesByPeriodProvider = FutureProvider.family<List<Map<String, dynamic>>, Map<String, dynamic>>((ref, filters) async {
  final supabase = Supabase.instance.client;
  
  try {
    final response = await supabase
        .from('sale')
        .select('created_at, total_amount, total_amount_in_brl, total_amount_in_usd, payment_status')
        .gte('created_at', filters['startDate'])
        .lte('created_at', filters['endDate'])
        .order('created_at');

    return (response as List).cast<Map<String, dynamic>>();
  } catch (e) {
    print('Erro ao buscar vendas por período: $e');
    return [];
  }
});

// Vendas com pagamentos em múltiplas moedas
final multiCurrencySalesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final supabase = Supabase.instance.client;
  
  try {
    final response = await supabase
        .from('sale')
        .select('*')
        .not('total_amount', 'eq', 0)
        .order('created_at', ascending: false)
        .order('id', ascending: false).limit(20);

    return (response as List).cast<Map<String, dynamic>>();
  } catch (e) {
    print('Erro ao buscar vendas multi-moeda: $e');
    return [];
  }
});

final globalContactSearchProvider = FutureProvider.family<List<Contact>, String>((ref, term) async {
  final service = ref.watch(salesServiceProvider);
  if (term.trim().isEmpty) return [];
  return service.searchContacts(term);
});

final globalSalesSearchProvider = FutureProvider.family<List<Sale>, String>((ref, term) async {
  final notifier = ref.read(salesProvider.notifier);
  return notifier.searchSales(term);
});
// Flag de carregamento (true quando a primeira busca terminou, mesmo com 0 resultados)
final salesLoadedProvider = StateProvider<bool>((ref) => false);
