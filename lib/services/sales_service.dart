import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/provisional_invoice_item.dart';
import '../models/contact.dart';
import '../models/contact_service.dart';
import '../models/provisional_invoice.dart';
import '../models/sale_item.dart';
import '../models/sale.dart';
import '../models/currency.dart';
import '../models/service.dart';

class SalesService {
  SupabaseClient get _client => Supabase.instance.client;

  // =====================================================
  // CURRENCIES
  // =====================================================

  Future<List<Currency>> getCurrencies() async {
    try {
      final response = await _client
          .from('currency')
          .select()
          .order('currency_code');
      
      return response.map<Currency>((json) => Currency.fromJson(json)).toList();
    } catch (e) {
      print('Erro ao buscar moedas: $e');
      rethrow;
    }
  }

  Future<Currency?> getCurrencyById(int currencyId) async {
    try {
      final response = await _client
          .from('currency')
          .select()
          .eq('id', currencyId)
          .single();
      
      return Currency.fromJson(response);
    } catch (e) {
      print('Erro ao buscar moeda: $e');
      return null;
    }
  }

  // =====================================================
  // SALES
  // =====================================================

  Future<List<Sale>> getSales() async {
    try {
      final response = await _client
          .from('sale')
          .select('*, contacts(*), currencies(*)')
          .order('created_at', ascending: false);
      return response.map<Sale>((json) => Sale.fromJson(json)).toList();
    } catch (e) {
      print('Erro ao buscar vendas: $e');
      rethrow;
    }
  }

  Future<Sale?> getSaleById(int id) async {
    try {
      final response = await _client
          .from('sale')
          .select('*')
          .eq('id', id)
          .single();
      return Sale.fromJson(response);
    } catch (e) {
      print('Erro ao buscar venda: $e');
      return null;
    }
  }

  Future<Sale> createSale(Map<String, dynamic> data) async {
    try {
      final response = await _client
          .from('sale')
          .insert(data)
          .select()
          .single();
      return Sale.fromJson(response);
    } catch (e) {
      print('Erro ao criar venda: $e');
      rethrow;
    }
  }

  Future<Sale> updateSale(int id, Map<String, dynamic> data) async {
    try {
      final response = await _client
          .from('sale')
          .update(data)
          .eq('id', id)
          .select()
          .single();
      return Sale.fromJson(response);
    } catch (e) {
      print('Erro ao atualizar venda: $e');
      rethrow;
    }
  }

  // =====================================================
  // SALE ITEMS
  // =====================================================

  Future<List<SaleItem>> getSaleItems(int saleId) async {
    try {
      final response = await _client
          .from('sale_item')
          .select('*')
          .eq('sales_id', saleId)
          .order('created_at');
      return response.map<SaleItem>((json) => SaleItem.fromJson(json)).toList();
    } catch (e) {
      print('Erro ao buscar itens da venda: $e');
      return [];
    }
  }

  Future<SaleItem> createSaleItem(Map<String, dynamic> data) async {
    try {
      final response = await _client
          .from('sale_item')
          .insert(data)
          .select()
          .single();
      
      return SaleItem.fromJson(response);
    } catch (e) {
      print('Erro ao criar item da venda: $e');
      rethrow;
    }
  }

  // =====================================================
  // PROVISIONAL INVOICES
  // =====================================================

  Future<List<ProvisionalInvoice>> getProvisionalInvoices({
    int? accountId,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    int? currencyId,
  }) async {
    try {
      var query = _client
          .from('provisional_invoice')
          .select('*');
      
      if (accountId != null) {
        query = query.eq('account_id', accountId);
      }
      if (status != null) {
        query = query.eq('status', status);
      }
      if (startDate != null) {
        query = query.gte('issue_date', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('issue_date', endDate.toIso8601String());
      }
      if (currencyId != null) {
        query = query.eq('currency_id', currencyId);
      }
      
      final response = await query.order('issue_date', ascending: false);
      
      return response.map<ProvisionalInvoice>((json) => ProvisionalInvoice.fromJson(json)).toList();
    } catch (e) {
      print('Erro ao buscar faturas provisórias: $e');
      rethrow;
    }
  }

  Future<ProvisionalInvoice?> getProvisionalInvoiceById(int id) async {
    try {
      final response = await _client
          .from('provisional_invoice')
          .select('*')
          .eq('id', id)
          .single();
      
      return ProvisionalInvoice.fromJson(response);
    } catch (e) {
      print('Erro ao buscar fatura provisória: $e');
      return null;
    }
  }

  Future<ProvisionalInvoice> createProvisionalInvoice(Map<String, dynamic> data) async {
    try {
      // Calcular valores convertidos se necessário
      if (data['currency_code'] == 'BRL' && data['exchange_rate_to_usd'] != null) {
        final exchangeRate = data['exchange_rate_to_usd'] as double;
        data['total_amount_in_usd'] = data['total_amount'] / exchangeRate;
        data['total_amount_in_brl'] = data['total_amount'];
      } else if (data['currency_code'] == 'USD' && data['exchange_rate_to_usd'] != null) {
        final exchangeRate = data['exchange_rate_to_usd'] as double;
        data['total_amount_in_brl'] = data['total_amount'] * exchangeRate;
        data['total_amount_in_usd'] = data['total_amount'];
      }

      final response = await _client
          .from('provisional_invoice')
          .insert(data)
          .select()
          .single();
      
      return ProvisionalInvoice.fromJson(response);
    } catch (e) {
      print('Erro ao criar fatura provisória: $e');
      rethrow;
    }
  }

  Future<ProvisionalInvoice> updateProvisionalInvoice(int id, Map<String, dynamic> data) async {
    try {
      // Calcular valores convertidos se necessário
      if (data['currency_code'] == 'BRL' && data['exchange_rate_to_usd'] != null) {
        final exchangeRate = data['exchange_rate_to_usd'] as double;
        data['total_amount_in_usd'] = data['total_amount'] / exchangeRate;
        data['total_amount_in_brl'] = data['total_amount'];
      } else if (data['currency_code'] == 'USD' && data['exchange_rate_to_usd'] != null) {
        final exchangeRate = data['exchange_rate_to_usd'] as double;
        data['total_amount_in_brl'] = data['total_amount'] * exchangeRate;
        data['total_amount_in_usd'] = data['total_amount'];
      }

      final response = await _client
          .from('provisional_invoice')
          .update(data)
          .eq('id', id)
          .select()
          .single();
      
      return ProvisionalInvoice.fromJson(response);
    } catch (e) {
      print('Erro ao atualizar fatura provisória: $e');
      rethrow;
    }
  }

  // =====================================================
  // PROVISIONAL INVOICE ITEMS
  // =====================================================

  Future<List<ProvisionalInvoiceItem>> getProvisionalInvoiceItems(int invoiceId) async {
    try {
      final response = await _client
          .from('provisional_invoice_item')
          .select('*')
          .eq('provisional_invoice_id', invoiceId)
          .order('created_at');
      
      return response.map<ProvisionalInvoiceItem>((json) => ProvisionalInvoiceItem.fromJson(json)).toList();
    } catch (e) {
      print('Erro ao buscar itens da fatura: $e');
      return [];
    }
  }

  Future<ProvisionalInvoiceItem> createProvisionalInvoiceItem(Map<String, dynamic> data) async {
    try {
      final response = await _client
          .from('provisional_invoice_item')
          .insert(data)
          .select()
          .single();
      
      return ProvisionalInvoiceItem.fromJson(response);
    } catch (e) {
      print('Erro ao criar item da fatura: $e');
      rethrow;
    }
  }

  // =====================================================
  // SERVICES & CUSTOMERS (mantidos para compatibilidade)
  // =====================================================

  Future<List<Service>> getServices({bool? isActive}) async {
    try {
      final response = await _client
          .from('service')
          .select('*, service_category(name)')
          .order('name');

      final services = <Service>[];
      
      for (final json in response) {
        try {
          // Verificar se o serviço tem os campos mínimos necessários
          if (json['id'] != null && json['name'] != null) {
            // Extrair o nome da categoria do JOIN
            final serviceTypeData = json['service_category'] as Map<String, dynamic>?;
            final categoryName = serviceTypeData?['name'] as String?;
            
            // Criar um JSON modificado com a categoria
            final modifiedJson = Map<String, dynamic>.from(json);
            modifiedJson['category'] = categoryName;
            
            final service = Service.fromJson(modifiedJson);
            services.add(service);
          }
        } catch (e) {
          print('Erro ao converter serviço ${json['id']}: $e');
          // Continuar com o próximo serviço
        }
      }
      
      return services;
    } catch (e) {
      print('Erro ao buscar serviços: $e');
      return [];
    }
  }

  Future<List<Contact>> getContacts({bool? isActive}) async {
    try {
      // Por enquanto, retorna todos os dados sem filtros
      // TODO: Implementar filtros quando a sintaxe do Supabase for corrigida
      final response = await _client
          .from('contact')
          .select()
          .order('name');

      return response.map((json) => Contact.fromJson(json)).toList();
    } catch (e) {
      print('Erro ao buscar clientes: $e');
      rethrow;
    }
  }

  // =====================================================
  // ANALYTICS
  // =====================================================

  Future<Map<String, dynamic>> getSalesAnalytics({
    DateTime? startDate,
    DateTime? endDate,
    int? currencyId,
  }) async {
    try {
      var query = _client.from('sale').select('total_amount, total_amount_in_brl, total_amount_in_usd, payment_status');
      
      if (startDate != null) {
        query = query.gte('created_at', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('created_at', endDate.toIso8601String());
      }
      if (currencyId != null) {
        query = query.eq('currency_id', currencyId);
      }
      
      final response = await query;
      
      double totalRevenueBrl = 0;
      double totalRevenueUsd = 0;
      double paidRevenueBrl = 0;
      double paidRevenueUsd = 0;
      int totalSales = response.length;
      int paidSales = 0;
      
      for (final sale in response) {
        final totalBrl = sale['total_amount_in_brl'] ?? 0.0;
        final totalUsd = sale['total_amount_in_usd'] ?? 0.0;
        final paymentStatus = sale['payment_status'] ?? 'pending';
        
        totalRevenueBrl += totalBrl;
        totalRevenueUsd += totalUsd;
        
        if (paymentStatus == 'paid') {
          paidRevenueBrl += totalBrl;
          paidRevenueUsd += totalUsd;
          paidSales++;
        }
      }
      
      final paymentRate = totalSales > 0 ? (paidSales / totalSales) * 100 : 0.0;
      
      return {
        'totalRevenueBrl': totalRevenueBrl,
        'totalRevenueUsd': totalRevenueUsd,
        'paidRevenueBrl': paidRevenueBrl,
        'paidRevenueUsd': paidRevenueUsd,
        'totalSales': totalSales,
        'paidSales': paidSales,
        'paymentRate': paymentRate,
      };
    } catch (e) {
      print('Erro ao buscar analytics de vendas: $e');
      rethrow;
    }
  }

  // =====================================================
  // UTILITY METHODS
  // =====================================================

  // Método para obter a cotação do dólar turismo (pode ser integrado com API externa)
  Future<double?> getDollarTourismRate() async {
    try {
      // Por enquanto, retorna um valor fixo ou busca de uma tabela de cotações
      // TODO: Integrar com API de cotação do dólar turismo
      return 5.20; // Valor exemplo
    } catch (e) {
      print('Erro ao buscar cotação do dólar: $e');
      return null;
    }
  }

  // Método para gerar número de fatura único
  Future<String> generateInvoiceNumber() async {
    try {
      final year = DateTime.now().year;
      final response = await _client
          .from('provisional_invoice')
          .select('invoice_number')
          .like('invoice_number', 'INV-$year-%')
          .order('invoice_number', ascending: false)
          .order('id', ascending: false).limit(1);
      
      int nextNumber = 1;
      if (response.isNotEmpty) {
        final lastNumber = response.first['invoice_number'].toString().split('-').last;
        nextNumber = int.parse(lastNumber) + 1;
      }
      
      return 'INV-$year-${nextNumber.toString().padLeft(4, '0')}';
    } catch (e) {
      print('Erro ao gerar número de fatura: $e');
      return 'INV-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  // =====================================================
  // CUSTOMER SERVICES
  // =====================================================

  Future<List<ContactService>> getContactServices({
    int? contactId,
    int? serviceId,
    String? status,
    String? paymentStatus,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = _client
          .from('contact_services')
          .select('*');
      
      if (contactId != null) {
        query = query.eq('contact_id', contactId);
      }
      if (serviceId != null) {
        query = query.eq('service_id', serviceId);
      }
      if (status != null) {
        query = query.eq('status', status);
      }
      if (paymentStatus != null) {
        query = query.eq('payment_status', paymentStatus);
      }
      if (startDate != null) {
        query = query.gte('scheduled_date', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('scheduled_date', endDate.toIso8601String());
      }
      
      final response = await query.order('scheduled_date', ascending: false);
      
      return response.map<ContactService>((json) => ContactService.fromJson(json)).toList();
    } catch (e) {
      print('Erro ao buscar serviços de clientes: $e');
      rethrow;
    }
  }

  Future<ContactService?> getContactServiceById(int id) async {
    try {
      final response = await _client
          .from('contact_services')
          .select('*')
          .eq('id', id)
          .single();
      
      return ContactService.fromJson(response);
    } catch (e) {
      print('Erro ao buscar serviço de cliente: $e');
      return null;
    }
  }

  // =====================================================
  // CUSTOMER SERVICES
  // =====================================================

  Future<List<Contact>> searchContacts(String term) async {
    if (term.trim().isEmpty) return [];
    final lowerTerm = term.toLowerCase();
    
    try {
      final response = await _client
          .from('contact')
          .select('*')
          .or('name.ilike.%$lowerTerm%,email.ilike.%$lowerTerm%,phone.ilike.%$lowerTerm%')
          .order('name');
      return response.map<Contact>((json) => Contact.fromJson(json)).toList();
    } catch (e) {
      print('Erro ao buscar contatos: $e');
      return [];
    }
  }

  // =====================================================
  // B2B METRICS
  // =====================================================

  Future<Map<String, dynamic>> getB2BMetrics() async {
    try {
      // Buscar faturas provisórias para análise B2B
      final invoices = await _client
          .from('provisional_invoice')
          .select('*, account(*)')
          .order('issue_date', ascending: false);
      
      int totalProposals = invoices.length;
      int pendingProposals = 0;
      int approvedProposals = 0;
      int convertedProposals = 0;
      double totalConvertedValue = 0.0;
      double totalDaysToFirstView = 0.0;
      double totalDaysToApproval = 0.0;
      double totalDaysToConversion = 0.0;
      int proposalsWithFirstView = 0;
      int proposalsWithApproval = 0;
      int proposalsWithConversion = 0;
      
      for (final invoice in invoices) {
        final status = invoice['status'] ?? 'pending';
        final totalAmount = (invoice['total_amount'] ?? 0.0).toDouble();
        final issueDate = DateTime.parse(invoice['issue_date']);
        final firstViewDate = invoice['first_view_date'] != null 
            ? DateTime.parse(invoice['first_view_date']) 
            : null;
        final approvalDate = invoice['approval_date'] != null 
            ? DateTime.parse(invoice['approval_date']) 
            : null;
        final conversionDate = invoice['conversion_date'] != null 
            ? DateTime.parse(invoice['conversion_date']) 
            : null;
        
        // Contar por status
        switch (status.toLowerCase()) {
          case 'pending':
            pendingProposals++;
            break;
          case 'approved':
            approvedProposals++;
            break;
          case 'converted':
            convertedProposals++;
            totalConvertedValue += totalAmount;
            break;
        }
        
        // Calcular tempos médios
        if (firstViewDate != null) {
          totalDaysToFirstView += firstViewDate.difference(issueDate).inDays.toDouble();
          proposalsWithFirstView++;
        }
        
        if (approvalDate != null) {
          totalDaysToApproval += approvalDate.difference(issueDate).inDays.toDouble();
          proposalsWithApproval++;
        }
        
        if (conversionDate != null) {
          totalDaysToConversion += conversionDate.difference(issueDate).inDays.toDouble();
          proposalsWithConversion++;
        }
      }
      
      // Calcular médias
      final avgDaysToFirstView = proposalsWithFirstView > 0 
          ? totalDaysToFirstView / proposalsWithFirstView 
          : 0.0;
      final avgDaysToApproval = proposalsWithApproval > 0 
          ? totalDaysToApproval / proposalsWithApproval 
          : 0.0;
      final avgDaysToConversion = proposalsWithConversion > 0 
          ? totalDaysToConversion / proposalsWithConversion 
          : 0.0;
      
      // Calcular taxa de conversão
      final conversionRatePercent = totalProposals > 0 
          ? (convertedProposals / totalProposals) * 100 
          : 0.0;
      
      return {
        'total_proposals': totalProposals,
        'pending_proposals': pendingProposals,
        'approved_proposals': approvedProposals,
        'converted_proposals': convertedProposals,
        'conversion_rate_percent': conversionRatePercent,
        'total_converted_value': totalConvertedValue,
        'avg_days_to_first_view': avgDaysToFirstView,
        'avg_days_to_approval': avgDaysToApproval,
        'avg_days_to_conversion': avgDaysToConversion,
      };
    } catch (e) {
      print('Erro ao buscar métricas B2B: $e');
      // Retornar dados padrão em caso de erro
      return {
        'total_proposals': 0,
        'pending_proposals': 0,
        'approved_proposals': 0,
        'converted_proposals': 0,
        'conversion_rate_percent': 0.0,
        'total_converted_value': 0.0,
        'avg_days_to_first_view': 0.0,
        'avg_days_to_approval': 0.0,
        'avg_days_to_conversion': 0.0,
      };
    }
  }

  Future<List<Map<String, dynamic>>> getProvisionalInvoicePerformance() async {
    try {
      // Buscar faturas provisórias com informações de performance
      final invoices = await _client
          .from('provisional_invoice')
          .select('*, account(*)')
          .order('issue_date', ascending: false)
          .order('id', ascending: false).limit(20); // Limitar a 20 propostas mais recentes
      
      return invoices.map<Map<String, dynamic>>((invoice) {
        final issueDate = DateTime.parse(invoice['issue_date']);
        final approvalDate = invoice['approval_date'] != null 
            ? DateTime.parse(invoice['approval_date']) 
            : null;
        final conversionDate = invoice['conversion_date'] != null 
            ? DateTime.parse(invoice['conversion_date']) 
            : null;
        
        // Calcular dias para aprovação
        double daysToApproval = 0.0;
        if (approvalDate != null) {
          daysToApproval = approvalDate.difference(issueDate).inDays.toDouble();
        }
        
        // Determinar nível de prioridade baseado no valor
        final totalAmount = (invoice['total_amount'] ?? 0.0).toDouble();
        String priorityLevel = 'normal';
        if (totalAmount > 10000) {
          priorityLevel = 'urgent';
        } else if (totalAmount > 5000) {
          priorityLevel = 'high';
        } else if (totalAmount < 1000) {
          priorityLevel = 'low';
        }
        
        return {
          'invoice_number': invoice['invoice_number'] ?? 'N/A',
          'account_name': invoice['account']?['name'] ?? 'N/A',
          'status': invoice['status'] ?? 'pending',
          'total_amount': totalAmount,
          'priority_level': priorityLevel,
          'days_to_approval': daysToApproval,
          'issue_date': invoice['issue_date'],
          'approval_date': invoice['approval_date'],
          'conversion_date': invoice['conversion_date'],
        };
      }).toList();
    } catch (e) {
      print('Erro ao buscar performance de faturas provisórias: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getB2BMetricsByAccount(int accountId) async {
    try {
      // Buscar métricas B2B específicas para uma conta
      final invoices = await _client
          .from('provisional_invoice')
          .select('*')
          .eq('account_id', accountId)
          .order('issue_date', ascending: false);
      
      // Implementar lógica similar ao getB2BMetrics mas filtrado por conta
      // Por enquanto, retornar dados básicos
      return {
        'account_id': accountId,
        'total_proposals': invoices.length,
        'pending_proposals': invoices.where((i) => i['status'] == 'pending').length,
        'approved_proposals': invoices.where((i) => i['status'] == 'approved').length,
        'converted_proposals': invoices.where((i) => i['status'] == 'converted').length,
      };
    } catch (e) {
      print('Erro ao buscar métricas B2B por conta: $e');
      return {
        'account_id': accountId,
        'total_proposals': 0,
        'pending_proposals': 0,
        'approved_proposals': 0,
        'converted_proposals': 0,
      };
    }
  }

  Future<Map<String, dynamic>> getB2BMetricsByPeriod({required DateTime startDate, required DateTime endDate}) async {
    try {
      // Buscar métricas B2B para um período específico
      final invoices = await _client
          .from('provisional_invoice')
          .select('*')
          .gte('issue_date', startDate.toIso8601String())
          .lte('issue_date', endDate.toIso8601String())
          .order('issue_date', ascending: false);
      
      // Implementar lógica similar ao getB2BMetrics mas filtrado por período
      return {
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
        'total_proposals': invoices.length,
        'pending_proposals': invoices.where((i) => i['status'] == 'pending').length,
        'approved_proposals': invoices.where((i) => i['status'] == 'approved').length,
        'converted_proposals': invoices.where((i) => i['status'] == 'converted').length,
      };
    } catch (e) {
      print('Erro ao buscar métricas B2B por período: $e');
      return {
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
        'total_proposals': 0,
        'pending_proposals': 0,
        'approved_proposals': 0,
        'converted_proposals': 0,
      };
    }
  }
  Future<List<Map<String, dynamic>>> getProvisionalInvoiceApprovals(int invoiceId) async => throw UnimplementedError();
  Future<List<Map<String, dynamic>>> getProvisionalInvoiceReminders(int invoiceId) async => throw UnimplementedError();
  Future<List<Map<String, dynamic>>> getExpiredProposals() async => throw UnimplementedError();
  Future<List<Map<String, dynamic>>> getUrgentProposals() async => throw UnimplementedError();
  Future<List<Map<String, dynamic>>> getOverdueProposals() async => throw UnimplementedError();
  Future<List<Map<String, dynamic>>> getB2BPerformanceByAccount() async => throw UnimplementedError();
  Future<List<Map<String, dynamic>>> getB2BPerformanceByPeriod({required DateTime startDate, required DateTime endDate}) async => throw UnimplementedError();
  Future<List<Map<String, dynamic>>> getB2BTopPerformers() async => throw UnimplementedError();
  Future<Map<String, int>> getB2BWorkflowStages() async => throw UnimplementedError();
  Future<List<Map<String, dynamic>>> getB2BBottleneckAnalysis() async => throw UnimplementedError();
  Future<Map<String, dynamic>> getB2BForecast(int months) async => throw UnimplementedError();
  Future<double> getB2BPipelineValue() async => throw UnimplementedError();
  Future<Map<String, dynamic>> getB2BComparison({required dynamic period1, required dynamic period2, required String metric}) async => throw UnimplementedError();
  Future<String> exportB2BData({String format = 'csv', Map<String, dynamic>? filters, dynamic period}) async => throw UnimplementedError();
}
