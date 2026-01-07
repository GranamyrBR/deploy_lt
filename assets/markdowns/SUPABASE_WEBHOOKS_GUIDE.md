# Guia de Implementação de Webhooks do Supabase

## Visão Geral

O Supabase oferece webhooks nativos que eliminam a necessidade de criar tabelas customizadas para gerenciar configurações e logs de webhooks. Os webhooks do Supabase são triggers de banco de dados que enviam dados em tempo real para sistemas externos quando eventos de tabela ocorrem.

## Funcionalidades dos Webhooks do Supabase

### Eventos Suportados
- **INSERT**: Quando uma nova linha é inserida
- **UPDATE**: Quando uma linha existente é atualizada
- **DELETE**: Quando uma linha é deletada

### Vantagens
- ✅ **Tempo Real**: Envio automático de dados quando mudanças ocorrem
- ✅ **Flexibilidade**: Configuração para tabelas e eventos específicos
- ✅ **Processamento Assíncrono**: Baseado na extensão pg_net
- ✅ **Configuração Fácil**: Via Dashboard do Supabase ou SQL
- ✅ **Payload Customizado**: Dados relevantes sobre o evento incluindo estados antigo e novo
- ✅ **Logs Automáticos**: Histórico disponível no schema `net` do banco

## Implementação para o LeCotour Dashboard

### 1. Webhooks para Operações

#### Configuração no Dashboard do Supabase:
```
Nome: Operation Events
Tabela: operation
Eventos: INSERT, UPDATE
URL: https://n8n.lecotour.com/webhook/operations
```

#### Payload Automático:
```json
{
  "type": "INSERT", // ou "UPDATE"
  "table": "operation",
  "record": {
    "id": 123,
    "status": "confirmed",
    "customer_name": "João Silva",
    // ... todos os campos da operação
  },
  "old_record": null, // para INSERT
  "schema": "public"
}
```

### 2. Webhooks para Pagamentos

#### Configuração:
```
Nome: Payment Events
Tabela: sale_payment
Eventos: INSERT, UPDATE
URL: https://n8n.lecotour.com/webhook/payments
```

### 3. Webhooks para Dados de Voo

#### Configuração:
```
Nome: Flight Status Events
Tabela: flight_data
Eventos: UPDATE
URL: https://n8n.lecotour.com/webhook/flights
```

## Configuração via SQL

Alternativamente, você pode criar webhooks diretamente via SQL:

```sql
-- Webhook para operações
SELECT
  net.http_post(
    url:='https://n8n.lecotour.com/webhook/operations',
    body:=jsonb_build_object(
      'type', TG_OP,
      'table', TG_TABLE_NAME,
      'record', row_to_json(NEW),
      'old_record', row_to_json(OLD)
    ),
    headers:=jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer YOUR_SECRET_KEY'
    )
  ) AS request_id;
```

## Monitoramento e Logs

### Verificar Histórico de Webhooks
```sql
-- Ver logs de webhooks
SELECT * FROM net.http_request_queue 
ORDER BY created_at DESC;

-- Ver status das requisições
SELECT 
  id,
  url,
  method,
  status_code,
  response,
  created_at
FROM net.http_request_queue 
WHERE url LIKE '%webhook%'
ORDER BY created_at DESC;
```

## Integração com N8N

### Endpoint N8N para Operações
```javascript
// Webhook receiver no N8N
const payload = $input.all()[0].json;

switch(payload.type) {
  case 'INSERT':
    // Nova operação criada
    return {
      action: 'operation_created',
      operation: payload.record,
      timestamp: new Date().toISOString()
    };
    
  case 'UPDATE':
    // Operação atualizada
    const statusChanged = payload.old_record.status !== payload.record.status;
    
    return {
      action: statusChanged ? 'status_changed' : 'operation_updated',
      operation: payload.record,
      previous_status: payload.old_record.status,
      new_status: payload.record.status,
      timestamp: new Date().toISOString()
    };
}
```

## Segurança

### Validação de Assinatura
```javascript
// Verificar se o webhook veio do Supabase
const crypto = require('crypto');

function verifyWebhookSignature(payload, signature, secret) {
  const expectedSignature = crypto
    .createHmac('sha256', secret)
    .update(JSON.stringify(payload))
    .digest('hex');
    
  return signature === expectedSignature;
}
```

### Variáveis de Ambiente
```env
SUPABASE_WEBHOOK_SECRET=your_webhook_secret_key
N8N_WEBHOOK_URL=https://n8n.lecotour.com/webhook
```

## Migração do Sistema Atual

### Passos para Migração:

1. **Configurar Webhooks no Supabase Dashboard**
   - Acessar Database > Webhooks
   - Criar webhooks para tabelas relevantes

2. **Atualizar WebhookService**
   - Remover lógica de tabelas customizadas
   - Manter apenas métodos de envio direto para casos especiais

3. **Configurar Endpoints N8N**
   - Criar workflows para receber webhooks
   - Implementar lógica de processamento

4. **Testar Integração**
   - Verificar se eventos são disparados corretamente
   - Validar payloads recebidos

### Benefícios da Migração:
- ❌ **Remove** necessidade de tabelas `webhook_configurations` e `webhook_logs`
- ❌ **Remove** complexidade de gerenciamento manual
- ✅ **Adiciona** confiabilidade nativa do Supabase
- ✅ **Adiciona** performance otimizada
- ✅ **Adiciona** logs automáticos

## Casos de Uso Específicos

### 1. Notificação de WhatsApp
```sql
-- Trigger quando operação precisa de WhatsApp
CREATE OR REPLACE FUNCTION notify_whatsapp_required()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.whatsapp_required = true AND OLD.whatsapp_required = false THEN
    PERFORM net.http_post(
      url := 'https://n8n.lecotour.com/webhook/whatsapp',
      body := jsonb_build_object(
        'operation_id', NEW.id,
        'customer_phone', NEW.customer_phone,
        'message_type', 'confirmation'
      )
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

### 2. Sincronização com Google Calendar
```sql
-- Trigger para eventos de calendário
CREATE OR REPLACE FUNCTION sync_calendar_event()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.calendar_event_required = true THEN
    PERFORM net.http_post(
      url := 'https://n8n.lecotour.com/webhook/calendar',
      body := jsonb_build_object(
        'operation_id', NEW.id,
        'event_date', NEW.operation_date,
        'customer_name', NEW.customer_name,
        'service_type', NEW.service_type
      )
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

## Conclusão

Os webhooks nativos do Supabase oferecem uma solução mais robusta, confiável e eficiente para integração em tempo real. Eles eliminam a necessidade de gerenciar tabelas customizadas e fornecem funcionalidades avançadas como retry automático, logs e monitoramento.

A migração para webhooks nativos simplificará significativamente a arquitetura do sistema e melhorará a confiabilidade das integrações.
# Guia de Implementação de Webhooks do Supabase
