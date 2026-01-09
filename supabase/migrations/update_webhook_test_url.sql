-- ============================================
-- Atualizar webhook N8N para URL de teste
-- ============================================

-- Atualizar URL do webhook N8N para teste
UPDATE n8n_webhook_config 
SET 
    webhook_url = 'https://critical.axioscode.com/webhook-test/leco_flutter',
    description = 'Webhook N8N (leco_flutter) - URL DE TESTE para envio de mensagens WhatsApp via Evolution API',
    is_active = true
WHERE name = 'send_whatsapp';

-- Verificar configuração
SELECT 
    id,
    name,
    webhook_url,
    is_active,
    description
FROM n8n_webhook_config
WHERE name = 'send_whatsapp';
