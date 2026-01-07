# Plano de Migração para Webhooks Nativos do Supabase

## Situação Atual

O sistema atual utiliza:
- `WebhookService` para envio manual de webhooks
- Tabelas customizadas `webhook_configurations` e `webhook_logs`
- Lógica complexa de retry e gerenciamento de estado
- Múltiplos métodos específicos (WhatsApp, Calendar, Trello, etc.)

## Situação Futura com Webhooks Nativos

### Vantagens da Migração

1. **Automação Completa**: Webhooks disparados automaticamente pelo Supabase
2. **Redução de Código**: Eliminação de 70% do código atual
3. **Confiabilidade**: Sistema nativo com retry automático
4. **Performance**: Processamento assíncrono otimizado
5. **Logs Automáticos**: Histórico no schema `net` do Supabase

### Arquitetura Simplificada

```
ANTES:
App Flutter → WebhookService → HTTP Request → N8N
                ↓
        webhook_configurations
        webhook_logs

DEPOIS:
Supabase DB → Native Webhook → N8N
     ↓
  net.http_request_queue (logs automáticos)
```

## Plano de Migração

### Fase 1: Configuração dos Webhooks Nativos

#### 1.1 Webhooks para Operações
```sql
-- Criar função para webhook de operações
CREATE OR REPLACE FUNCTION notify_operation_change()
RETURNS TRIGGER AS $$
DECLARE
  webhook_url TEXT := 'https://n8n.lecotour.com/webhook/operations';
  payload JSONB;
BEGIN
  -- Construir payload
  payload := jsonb_build_object(
    'event_type', TG_OP,
    'table', 'operation',
    'timestamp', NOW(),
    'data', row_to_json(NEW),
    'old_data', CASE WHEN TG_OP = 'UPDATE' THEN row_to_json(OLD) ELSE NULL END,
    'metadata', jsonb_build_object(
      'source', 'supabase_webhook',
      'trigger', 'operation_change'
    )
  );

  -- Enviar webhook
  PERFORM net.http_post(
    url := webhook_url,
    body := payload,
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || current_setting('app.webhook_secret', true)
    )
  );

  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- Criar trigger
CREATE TRIGGER operation_webhook_trigger
  AFTER INSERT OR UPDATE OR DELETE ON operation
  FOR EACH ROW
  EXECUTE FUNCTION notify_operation_change();
```

#### 1.2 Webhooks para Pagamentos
```sql
-- Função para webhook de pagamentos
CREATE OR REPLACE FUNCTION notify_payment_change()
RETURNS TRIGGER AS $$
DECLARE
  webhook_url TEXT := 'https://n8n.lecotour.com/webhook/payments';
  payload JSONB;
BEGIN
  payload := jsonb_build_object(
    'event_type', TG_OP,
    'table', 'sale_payment',
    'timestamp', NOW(),
    'data', row_to_json(NEW),
    'old_data', CASE WHEN TG_OP = 'UPDATE' THEN row_to_json(OLD) ELSE NULL END,
    'metadata', jsonb_build_object(
      'source', 'supabase_webhook',
      'trigger', 'payment_change'
    )
  );

  PERFORM net.http_post(
    url := webhook_url,
    body := payload,
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || current_setting('app.webhook_secret', true)
    )
  );

  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER payment_webhook_trigger
  AFTER INSERT OR UPDATE ON sale_payment
  FOR EACH ROW
  EXECUTE FUNCTION notify_payment_change();
```

### Fase 2: Simplificação do WebhookService

#### 2.1 Novo WebhookService Simplificado
```dart
// lib/services/webhook_service_v2.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class WebhookServiceV2 {
  static const Duration _defaultTimeout = Duration(seconds: 30);
  final http.Client _httpClient;
  
  WebhookServiceV2({http.Client? httpClient}) 
      : _httpClient = httpClient ?? http.Client();

  /// Envia webhook manual (apenas para casos especiais)
  /// A maioria dos webhooks agora são automáticos via Supabase
  Future<WebhookResponse> sendManualWebhook({
    required String url,
    required Map<String, dynamic> payload,
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    final defaultHeaders = {
      'Content-Type': 'application/json',
      'User-Agent': 'LecotourDashboard/2.0',
    };

    final finalHeaders = {...defaultHeaders, ...?headers};
    
    try {
      final response = await _httpClient.post(
        Uri.parse(url),
        headers: finalHeaders,
        body: jsonEncode(payload),
      ).timeout(timeout ?? _defaultTimeout);

      return WebhookResponse(
        success: response.statusCode >= 200 && response.statusCode < 300,
        statusCode: response.statusCode,
        message: response.reasonPhrase ?? 'OK',
        responseBody: response.body,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      return WebhookResponse(
        success: false,
        statusCode: 0,
        message: e.toString(),
        timestamp: DateTime.now(),
      );
    }
  }

  /// Testa conectividade (mantido para debugging)
  Future<WebhookResponse> testConnection(String url) async {
    return await sendManualWebhook(
      url: url,
      payload: {
        'event_type': 'test',
        'timestamp': DateTime.now().toIso8601String(),
        'message': 'Teste de conectividade',
        'source': 'lecotour_dashboard_v2',
      },
    );
  }

  void dispose() {
    _httpClient.close();
  }
}
```

### Fase 3: Atualização dos Providers

#### 3.1 Simplificação do WebhookProvider
```dart
// lib/providers/webhook_provider_v2.dart
import 'package:flutter/foundation.dart';
import '../services/supabase_service.dart';

class WebhookProviderV2 extends ChangeNotifier {
  final SupabaseService _supabaseService;
  
  List<Map<String, dynamic>> _webhookLogs = [];
  bool _isLoading = false;
  
  WebhookProviderV2(this._supabaseService);

  List<Map<String, dynamic>> get webhookLogs => _webhookLogs;
  bool get isLoading => _isLoading;

  /// Busca logs de webhooks do schema net do Supabase
  Future<void> fetchWebhookLogs({
    int limit = 50,
    String? filterUrl,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      var query = _supabaseService.client
          .from('net.http_request_queue')
          .select('*')
          .order('created_at', ascending: false)
          .limit(limit);

      if (filterUrl != null) {
        query = query.ilike('url', '%$filterUrl%');
      }

      if (startDate != null) {
        query = query.gte('created_at', startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.lte('created_at', endDate.toIso8601String());
      }

      final response = await query;
      _webhookLogs = List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Erro ao buscar logs de webhook: $e');
      _webhookLogs = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Reenviar webhook (apenas para casos especiais)
  Future<bool> retryWebhook(Map<String, dynamic> logEntry) async {
    try {
      final webhookService = WebhookServiceV2();
      final response = await webhookService.sendManualWebhook(
        url: logEntry['url'],
        payload: logEntry['body'],
        headers: Map<String, String>.from(logEntry['headers'] ?? {}),
      );
      
      return response.success;
    } catch (e) {
      debugPrint('Erro ao reenviar webhook: $e');
      return false;
    }
  }
}
```

### Fase 4: Configuração do N8N

#### 4.1 Workflow N8N para Operações
```javascript
// Webhook receiver para operações
const payload = $input.all()[0].json;

// Processar diferentes tipos de eventos
switch(payload.event_type) {
  case 'INSERT':
    return {
      action: 'operation_created',
      operation_id: payload.data.id,
      customer_name: payload.data.customer_name,
      status: payload.data.status,
      timestamp: payload.timestamp,
      // Dados para próximos nós do workflow
      whatsapp_required: payload.data.whatsapp_notification,
      calendar_required: payload.data.calendar_sync,
      trello_required: payload.data.trello_card
    };
    
  case 'UPDATE':
    const statusChanged = payload.old_data?.status !== payload.data.status;
    
    return {
      action: statusChanged ? 'status_changed' : 'operation_updated',
      operation_id: payload.data.id,
      old_status: payload.old_data?.status,
      new_status: payload.data.status,
      timestamp: payload.timestamp,
      // Triggers condicionais
      notify_customer: statusChanged && ['confirmed', 'cancelled'].includes(payload.data.status),
      update_calendar: statusChanged && payload.data.calendar_sync,
      update_trello: statusChanged && payload.data.trello_card
    };
    
  default:
    return { action: 'unknown', payload };
}
```

### Fase 5: Remoção de Código Legacy

#### 5.1 Arquivos a Remover
- `lib/models/webhook_configuration.dart`
- `lib/widgets/webhook_config_dialog.dart`
- `lib/widgets/webhook_config_card.dart`
- `lib/screens/webhook_configuration_screen.dart`
- Métodos específicos do `WebhookService` atual

#### 5.2 Tabelas a Remover
```sql
-- Remover tabelas customizadas (após migração completa)
DROP TABLE IF EXISTS webhook_logs;
DROP TABLE IF EXISTS webhook_configurations;
```

## Cronograma de Migração

### Semana 1: Preparação
- [ ] Configurar webhooks nativos no Supabase
- [ ] Testar triggers em ambiente de desenvolvimento
- [ ] Configurar workflows N8N

### Semana 2: Implementação
- [ ] Criar WebhookServiceV2
- [ ] Atualizar WebhookProvider
- [ ] Testar integração completa

### Semana 3: Migração
- [ ] Ativar webhooks nativos em produção
- [ ] Monitorar logs e performance
- [ ] Ajustar configurações conforme necessário

### Semana 4: Limpeza
- [ ] Remover código legacy
- [ ] Remover tabelas antigas
- [ ] Documentar nova arquitetura

## Benefícios Esperados

### Redução de Código
- **Antes**: ~345 linhas no WebhookService
- **Depois**: ~80 linhas no WebhookServiceV2
- **Redução**: ~77% menos código

### Melhoria de Performance
- Webhooks em tempo real (< 100ms)
- Eliminação de polling
- Processamento assíncrono nativo

### Maior Confiabilidade
- Retry automático do Supabase
- Logs detalhados no schema `net`
- Monitoramento nativo

### Facilidade de Manutenção
- Configuração via SQL ou Dashboard
- Menos código para manter
- Debugging simplificado

## Rollback Plan

Em caso de problemas:
1. Desativar triggers nativos
2. Reativar WebhookService original
3. Restaurar tabelas de configuração
4. Investigar e corrigir problemas
5. Tentar migração novamente

## Conclusão

A migração para webhooks nativos do Supabase representa uma evolução significativa na arquitetura do sistema, oferecendo maior confiabilidade, performance e simplicidade de manutenção. O investimento inicial na migração será compensado pela redução drástica na complexidade do código e melhoria na experiência do usuário.
# Plano de Migração para Webhooks Nativos do Supabase
