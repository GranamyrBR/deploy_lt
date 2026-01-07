import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/provisional_invoice_item.dart';
import '../models/provisional_invoice.dart';

class InvoicesService {
  SupabaseClient get _client => Supabase.instance.client;

  // =====================================================
  // PROVISIONAL INVOICES
  // =====================================================

  Future<List<ProvisionalInvoice>> getProvisionalInvoices() async {
    try {
      final response = await _client
          .from('provisional_invoice')
          .select('*')
          .order('issue_date', ascending: false);
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

  Future<void> deleteProvisionalInvoice(int id) async {
    try {
      await _client
          .from('provisional_invoice')
          .delete()
          .eq('id', id);
    } catch (e) {
      print('Erro ao deletar fatura provisória: $e');
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
          .select('*, services(*)')
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

  Future<ProvisionalInvoiceItem> updateProvisionalInvoiceItem(int id, Map<String, dynamic> data) async {
    try {
      final response = await _client
          .from('provisional_invoice_item')
          .update(data)
          .eq('id', id)
          .select()
          .single();
      
      return ProvisionalInvoiceItem.fromJson(response);
    } catch (e) {
      print('Erro ao atualizar item da fatura: $e');
      rethrow;
    }
  }

  Future<void> deleteProvisionalInvoiceItem(int id) async {
    try {
      await _client
          .from('provisional_invoice_item')
          .delete()
          .eq('id', id);
    } catch (e) {
      print('Erro ao deletar item da fatura: $e');
      rethrow;
    }
  }

  // =====================================================
  // UTILITY METHODS
  // =====================================================

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

  Future<List<Map<String, dynamic>>> getAccountsSimple() async {
    try {
      final rows = await _client
          .from('account')
          .select('id, name')
          .order('name');
      return List<Map<String, dynamic>>.from(rows);
    } catch (e) {
      print('Erro ao buscar contas: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getCurrenciesSimple() async {
    try {
      final rows = await _client
          .from('currency')
          .select('currency_id, currency_code, currency_name')
          .order('currency_name');
      return List<Map<String, dynamic>>.from(rows);
    } catch (e) {
      print('Erro ao buscar moedas: $e');
      return [];
    }
  }

  // =====================================================
  // FINAL INVOICES
  // =====================================================

  Future<Map<String, dynamic>> createFinalInvoiceFromProvisional(ProvisionalInvoice pi) async {
    try {
      final data = {
        'customer_id': pi.accountId, // opcional; usar conta como cliente
        'invoice_number': pi.invoiceNumber,
        'total_amount': pi.totalAmount,
        'due_date': pi.dueDate,
        'status': 'pending',
        'issued_date': pi.issueDate,
      };

      final response = await _client
          .from('invoice')
          .insert(data)
          .select('*')
          .single();

      // Atualiza status na fatura provisória
      await _client
          .from('provisional_invoice')
          .update({'status': 'Converted'})
          .eq('id', pi.id);

      return response;
    } catch (e) {
      print('Erro ao gerar fatura final: $e');
      rethrow;
    }
  }

  // Enviar lembrete/Invoice por email (registrar em provisional_invoice_reminder)
  Future<void> sendProvisionalInvoiceReminder({
    required int provisionalInvoiceId,
    required String toEmail,
    String? toName,
    String subject = 'Fatura Provisória',
    required String message,
  }) async {
    try {
      await _client
          .from('provisional_invoice_reminder')
          .insert({
            'provisional_invoice_id': provisionalInvoiceId,
            'reminder_type': 'email',
            'sent_to_email': toEmail,
            'sent_to_name': toName,
            'subject': subject,
            'message_content': message,
          });
    } catch (e) {
      print('Erro ao registrar reminder de fatura: $e');
      rethrow;
    }
  }

  // Buscar estatísticas de faturas
  Future<Map<String, dynamic>> getInvoiceStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = _client.from('provisional_invoice').select('total_amount, status, issue_date');
      
      if (startDate != null) {
        query = query.gte('issue_date', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('issue_date', endDate.toIso8601String());
      }
      
      final response = await query;
      
      double totalAmount = 0;
      double pendingAmount = 0;
      double paidAmount = 0;
      int totalInvoices = response.length;
      int pendingInvoices = 0;
      int paidInvoices = 0;
      
      for (final invoice in response) {
        final amount = invoice['total_amount'] ?? 0.0;
        final status = invoice['status'] ?? 'Pending';
        
        totalAmount += amount;
        
        if (status == 'Paid') {
          paidAmount += amount;
          paidInvoices++;
        } else {
          pendingAmount += amount;
          pendingInvoices++;
        }
      }
      
      return {
        'totalAmount': totalAmount,
        'pendingAmount': pendingAmount,
        'paidAmount': paidAmount,
        'totalInvoices': totalInvoices,
        'pendingInvoices': pendingInvoices,
        'paidInvoices': paidInvoices,
        'paidPercentage': totalAmount > 0 ? (paidAmount / totalAmount) * 100 : 0.0,
      };
    } catch (e) {
      print('Erro ao buscar estatísticas de faturas: $e');
      rethrow;
    }
  }
} 
