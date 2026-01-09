# 🚀 Integração WhatsApp: N8N + Evolution API + Lecotour

## 📋 Visão Geral

Sistema integrado para **enviar** mensagens WhatsApp usando a estrutura existente da tabela `leadstintim`.

### Arquitetura:
```
Flutter App → Supabase (leadstintim) → Trigger → N8N → Evolution API → WhatsApp
     ↓                                                        ↓
     └─────────────────── Webhook Callback ──────────────────┘
```

---

## ✅ Vantagens desta Abordagem

1. **Zero Duplicação** - Usa a tabela `leadstintim` existente
2. **Histórico Unificado** - Mensagens enviadas e recebidas no mesmo lugar
3. **Modal Existente** - `WhatsAppMessagesModal` mostra tudo
4. **Simples** - Apenas 4 colunas adicionais na tabela existente
5. **Compatível** - Mantém 100% da funcionalidade atual

---

## 🗄️ Estrutura do Banco de Dados

### Colunas Adicionadas em `leadstintim`:

| Coluna | Tipo | Descrição |
|--------|------|-----------|
| `outbound_status` | TEXT | Status: pending, queued, sent, delivered, read, failed |
| `outbound_sent_at` | TIMESTAMPTZ | Quando foi enviada |
| `outbound_error` | TEXT | Mensagem de erro (se falhou) |
| `n8n_execution_id` | TEXT | ID da execução N8N |

### Como Diferenciar Mensagens:

**Mensagens RECEBIDAS** (já existente):
```sql
from_me = 'false' ou NULL
```

**Mensagens ENVIADAS** (novo):
```sql
from_me = 'true' AND outbound_status IS NOT NULL
```

---

## 🔧 Setup no Supabase

### 1. Executar Migration

```bash
# Execute no Supabase SQL Editor
supabase/migrations/create_whatsapp_outbound_system.sql
```

Isso cria:
- ✅ Colunas de controle outbound em `leadstintim`
- ✅ Tabela `whatsapp_message_templates` (templates reutilizáveis)
- ✅ Tabela `n8n_webhook_config` (configuração N8N)
- ✅ Função `queue_whatsapp_message()` (enfileirar envio)
- ✅ Trigger automático que notifica N8N
- ✅ View `whatsapp_outbound_queue` (fila de envio)

### 2. Configurar Webhook N8N

```sql
-- Atualizar com sua URL real do N8N
UPDATE n8n_webhook_config 
SET webhook_url = 'https://seu-n8n.exemplo.com/webhook/send-whatsapp'
WHERE name = 'send_whatsapp';
```

---

## 📱 Como Enviar Mensagens (Flutter App)

### Opção 1: Via Função SQL Direta

```dart
// services/whatsapp_service.dart
class WhatsAppService {
  final _supabase = Supabase.instance.client;
  
  Future<int> sendMessage({
    required String phone,
    required String name,
    required String message,
    String recipientType = 'lead',
    Map<String, dynamic>? context,
  }) async {
    final result = await _supabase.rpc('queue_whatsapp_message', params: {
      'p_recipient_phone': phone,
      'p_recipient_name': name,
      'p_message_body': message,
      'p_recipient_type': recipientType,
      'p_context': context ?? {},
    });
    
    return result as int; // Retorna leadstintim_id
  }
  
  // Enviar usando template
  Future<int> sendFromTemplate({
    required String phone,
    required String name,
    required String templateName,
    required Map<String, String> variables,
  }) async {
    // Buscar template
    final template = await _supabase
        .from('whatsapp_message_templates')
        .select()
        .eq('name', templateName)
        .eq('is_active', true)
        .single();
    
    // Substituir variáveis
    String message = template['body'];
    variables.forEach((key, value) {
      message = message.replaceAll('{{$key}}', value);
    });
    
    return sendMessage(
      phone: phone,
      name: name,
      message: message,
      context: {'template': templateName, 'variables': variables},
    );
  }
}

// Exemplo de uso:
final whatsappService = WhatsAppService();

// 1. Mensagem simples
await whatsappService.sendMessage(
  phone: '+5511984239118',
  name: 'Paty',
  message: 'Olá! Sua cotação está pronta.',
  recipientType: 'lead',
);

// 2. Usando template
await whatsappService.sendFromTemplate(
  phone: '+5511984239118',
  name: 'Paty',
  templateName: 'confirmacao_cotacao',
  variables: {
    'name': 'Paty',
    'quotation_id': '12345',
  },
);
```

### Opção 2: Adicionar Botão no Modal Existente

```dart
// Em lib/widgets/whatsapp_messages_modal.dart
// Adicionar botão de envio no header

ElevatedButton.icon(
  onPressed: () => _showSendMessageDialog(),
  icon: Icon(Icons.send),
  label: Text('Enviar Mensagem'),
  style: ElevatedButton.styleFrom(
    backgroundColor: Color(0xFF25D366), // Verde WhatsApp
  ),
),

// Função para mostrar dialog de envio
Future<void> _showSendMessageDialog() async {
  final messageController = TextEditingController();
  
  await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Enviar Mensagem WhatsApp'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: messageController,
            decoration: InputDecoration(
              labelText: 'Mensagem',
              hintText: 'Digite sua mensagem...',
            ),
            maxLines: 5,
          ),
          SizedBox(height: 16),
          // Dropdown com templates
          DropdownButton<String>(
            hint: Text('Ou escolha um template'),
            onChanged: (template) {
              // Carregar template e preencher
            },
            items: [], // Templates da tabela
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () async {
            // Enviar mensagem
            await WhatsAppService().sendMessage(
              phone: widget.contact.phone!,
              name: widget.contact.name!,
              message: messageController.text,
            );
            Navigator.pop(context);
            _loadMessages(); // Recarregar para mostrar mensagem enviada
          },
          child: Text('Enviar'),
        ),
      ],
    ),
  );
}
```

---

## 🔄 Workflow N8N

### Estrutura do Workflow:

```
1. Webhook Trigger (recebe notificação do Supabase)
   ↓
2. Get Message Data (busca dados completos)
   ↓
3. Evolution API - Send Message
   ↓
4. Update Status (callback para Supabase)
```

### Exemplo de Workflow N8N (JSON):

```json
{
  "name": "Send WhatsApp via Evolution API",
  "nodes": [
    {
      "name": "Webhook",
      "type": "n8n-nodes-base.webhook",
      "parameters": {
        "path": "send-whatsapp",
        "responseMode": "responseNode",
        "options": {}
      }
    },
    {
      "name": "Get Message Details",
      "type": "n8n-nodes-base.supabase",
      "parameters": {
        "operation": "get",
        "tableId": "leadstintim",
        "id": "={{ $json.leadstintim_id }}"
      }
    },
    {
      "name": "Send WhatsApp",
      "type": "n8n-nodes-base.httpRequest",
      "parameters": {
        "url": "https://sua-evolution-api.com/message/sendText/INSTANCE_NAME",
        "method": "POST",
        "authentication": "genericCredentialType",
        "genericAuthType": "httpHeaderAuth",
        "sendBody": true,
        "bodyParameters": {
          "parameters": [
            {
              "name": "number",
              "value": "={{ $json.whatsapp_normalizado }}"
            },
            {
              "name": "text",
              "value": "={{ $json.message }}"
            }
          ]
        }
      }
    },
    {
      "name": "Update Status - Success",
      "type": "n8n-nodes-base.supabase",
      "parameters": {
        "operation": "executeFunction",
        "function": "update_outbound_status",
        "parameters": {
          "p_leadstintim_id": "={{ $('Get Message Details').item.json.id }}",
          "p_status": "sent",
          "p_n8n_execution_id": "={{ $execution.id }}"
        }
      }
    },
    {
      "name": "Update Status - Failed",
      "type": "n8n-nodes-base.supabase",
      "parameters": {
        "operation": "executeFunction",
        "function": "update_outbound_status",
        "parameters": {
          "p_leadstintim_id": "={{ $('Get Message Details').item.json.id }}",
          "p_status": "failed",
          "p_error": "={{ $json.error }}"
        }
      }
    }
  ]
}
```

---

## 📊 Evolution API - Endpoints Principais

### 1. Enviar Mensagem de Texto
```http
POST /message/sendText/{instance}
Content-Type: application/json
apikey: YOUR_API_KEY

{
  "number": "+5511984239118",
  "text": "Sua mensagem aqui"
}
```

### 2. Enviar Mídia
```http
POST /message/sendMedia/{instance}

{
  "number": "+5511984239118",
  "mediatype": "image",
  "mimetype": "image/jpeg",
  "caption": "Legenda da imagem",
  "media": "https://url-da-imagem.com/image.jpg"
}
```

### 3. Verificar Status da Mensagem
```http
GET /message/status/{messageId}
```

---

## 🎯 Casos de Uso Práticos

### 1. Notificar Cliente sobre Cotação
```dart
await whatsappService.sendFromTemplate(
  phone: contact.phone,
  name: contact.name,
  templateName: 'confirmacao_cotacao',
  variables: {
    'name': contact.name,
    'quotation_id': quotation.id.toString(),
  },
);
```

### 2. Avisar Motorista de Nova Operação
```dart
await whatsappService.sendFromTemplate(
  phone: driver.phone,
  name: driver.name,
  templateName: 'motorista_atribuido',
  variables: {
    'driver_name': driver.name,
    'operation_id': operation.id.toString(),
    'date': DateFormat('dd/MM/yyyy').format(operation.date),
    'details': operation.description,
  },
);
```

### 3. Envio em Massa (Agências)
```dart
for (var agency in agencies) {
  await whatsappService.sendMessage(
    phone: agency.phone,
    name: agency.name,
    message: 'Promoção especial: 20% off em todos os pacotes!',
    recipientType: 'agency',
  );
  await Future.delayed(Duration(seconds: 2)); // Rate limit
}
```

---

## 🔍 Monitoramento e Logs

### Ver Fila de Envio
```sql
SELECT * FROM whatsapp_outbound_queue;
```

### Estatísticas de Envio
```sql
SELECT 
    outbound_status,
    COUNT(*) as total,
    COUNT(*) FILTER (WHERE outbound_sent_at > NOW() - INTERVAL '1 day') as ultimas_24h
FROM leadstintim
WHERE from_me = 'true'
GROUP BY outbound_status;
```

### Mensagens Falhadas
```sql
SELECT id, name, phone, message, outbound_error, created_at
FROM leadstintim
WHERE outbound_status = 'failed'
ORDER BY created_at DESC
LIMIT 50;
```

---

## 🚨 Troubleshooting

### Mensagem não enviou?
1. Verificar se trigger está ativo: `SELECT * FROM pg_trigger WHERE tgname = 'trigger_notify_n8n_new_message';`
2. Verificar webhook URL: `SELECT * FROM n8n_webhook_config;`
3. Ver logs N8N: execution history
4. Testar Evolution API diretamente

### Como reenviar mensagem falhada?
```sql
UPDATE leadstintim 
SET outbound_status = 'pending'
WHERE id = 12345;
-- Trigger vai processar novamente
```

---

## 📚 Próximos Passos

1. ✅ **Executar migration** no Supabase
2. ✅ **Configurar webhook** N8N com URL real
3. ✅ **Criar workflow** no N8N (importar JSON)
4. ✅ **Configurar Evolution API** com sua instância
5. ✅ **Testar envio** com função SQL
6. ✅ **Adicionar botão** no `WhatsAppMessagesModal`
7. ✅ **Criar templates** customizados

---

## 🎉 Pronto!

Agora você tem um sistema completo de envio de WhatsApp integrado perfeitamente com a estrutura existente!

**Perguntas? Issues? Me chame!** 🚀
