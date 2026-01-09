import 'package:supabase_flutter/supabase_flutter.dart';

/// Serviço para envio de mensagens WhatsApp via N8N + Evolution API
class WhatsAppService {
  final _supabase = Supabase.instance.client;

  /// Envia mensagem WhatsApp simples
  /// 
  /// Retorna o ID do registro leadstintim criado
  Future<int> sendMessage({
    required String phone,
    required String name,
    required String message,
    String recipientType = 'lead',
    Map<String, dynamic>? context,
  }) async {
    try {
      // Chamar função RPC que enfileira a mensagem
      final result = await _supabase.rpc('queue_whatsapp_message', params: {
        'p_recipient_phone': phone,
        'p_recipient_name': name,
        'p_message_body': message,
        'p_recipient_type': recipientType,
        'p_context': context ?? {},
      });

      return result as int;
    } catch (e) {
      print('❌ Erro ao enviar mensagem WhatsApp: $e');
      rethrow;
    }
  }

  /// Envia mensagem usando template
  Future<int> sendFromTemplate({
    required String phone,
    required String name,
    required String templateName,
    required Map<String, String> variables,
    String recipientType = 'lead',
  }) async {
    try {
      // Buscar template do banco
      final templateData = await _supabase
          .from('whatsapp_message_templates')
          .select('body, variables')
          .eq('name', templateName)
          .eq('is_active', true)
          .single();

      // Substituir variáveis no template
      String message = templateData['body'] as String;
      variables.forEach((key, value) {
        message = message.replaceAll('{{$key}}', value);
      });

      // Incrementar contador de uso
      await _supabase.rpc('increment_template_usage', params: {
        'template_name': templateName,
      });

      // Enviar mensagem
      return await sendMessage(
        phone: phone,
        name: name,
        message: message,
        recipientType: recipientType,
        context: {
          'template': templateName,
          'variables': variables,
        },
      );
    } catch (e) {
      print('❌ Erro ao enviar template WhatsApp: $e');
      rethrow;
    }
  }

  /// Lista templates disponíveis
  Future<List<Map<String, dynamic>>> getTemplates({String? category}) async {
    try {
      var query = _supabase
          .from('whatsapp_message_templates')
          .select('id, name, category, body, variables')
          .eq('is_active', true);

      if (category != null) {
        query = query.eq('category', category);
      }

      return await query.order('category').order('name');
    } catch (e) {
      print('❌ Erro ao buscar templates: $e');
      return [];
    }
  }

  /// Verifica status de envio de uma mensagem
  Future<Map<String, dynamic>?> getMessageStatus(int leadstintimId) async {
    try {
      final result = await _supabase
          .from('leadstintim')
          .select('id, outbound_status, outbound_sent_at, outbound_error, n8n_execution_id')
          .eq('id', leadstintimId)
          .single();

      return result;
    } catch (e) {
      print('❌ Erro ao buscar status: $e');
      return null;
    }
  }

  /// Lista mensagens na fila de envio
  Future<List<Map<String, dynamic>>> getOutboundQueue() async {
    try {
      return await _supabase
          .from('whatsapp_outbound_queue')
          .select('*')
          .limit(50);
    } catch (e) {
      print('❌ Erro ao buscar fila: $e');
      return [];
    }
  }

  /// Envio em massa para múltiplos destinatários
  /// 
  /// Retorna lista de IDs criados
  Future<List<int>> sendBulk({
    required List<Map<String, String>> recipients, // [{phone, name}]
    required String message,
    String recipientType = 'lead',
    Duration? delayBetweenMessages,
  }) async {
    final List<int> ids = [];

    for (var i = 0; i < recipients.length; i++) {
      final recipient = recipients[i];
      
      try {
        final id = await sendMessage(
          phone: recipient['phone']!,
          name: recipient['name']!,
          message: message,
          recipientType: recipientType,
          context: {
            'bulk': true,
            'bulk_index': i,
            'bulk_total': recipients.length,
          },
        );
        
        ids.add(id);

        // Delay entre mensagens (rate limiting)
        if (delayBetweenMessages != null && i < recipients.length - 1) {
          await Future.delayed(delayBetweenMessages);
        }
      } catch (e) {
        print('❌ Erro ao enviar para ${recipient['name']}: $e');
        // Continua enviando para os próximos
      }
    }

    return ids;
  }

  /// Envio para motoristas
  Future<int> notifyDriver({
    required String driverPhone,
    required String driverName,
    required String operationId,
    required String operationDate,
    required String operationDetails,
  }) async {
    return await sendFromTemplate(
      phone: driverPhone,
      name: driverName,
      templateName: 'motorista_atribuido',
      variables: {
        'driver_name': driverName,
        'operation_id': operationId,
        'date': operationDate,
        'details': operationDetails,
      },
      recipientType: 'driver',
    );
  }

  /// Envio para agências
  Future<int> notifyAgency({
    required String agencyPhone,
    required String agencyName,
    required String saleId,
    required String saleValue,
    required String commission,
  }) async {
    return await sendFromTemplate(
      phone: agencyPhone,
      name: agencyName,
      templateName: 'agencia_nova_venda',
      variables: {
        'agency_name': agencyName,
        'sale_id': saleId,
        'value': saleValue,
        'commission': commission,
      },
      recipientType: 'agency',
    );
  }

  /// Confirmação de cotação para cliente
  Future<int> confirmQuotation({
    required String clientPhone,
    required String clientName,
    required String quotationId,
  }) async {
    return await sendFromTemplate(
      phone: clientPhone,
      name: clientName,
      templateName: 'confirmacao_cotacao',
      variables: {
        'name': clientName,
        'quotation_id': quotationId,
      },
      recipientType: 'lead',
    );
  }
}
