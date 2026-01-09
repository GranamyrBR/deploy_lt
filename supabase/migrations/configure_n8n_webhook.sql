-- ============================================
-- Configurar webhook N8N para envio WhatsApp
-- ============================================

-- Atualizar URL do webhook N8N
UPDATE n8n_webhook_config 
SET 
    webhook_url = 'https://critical.axioscode.com/webhook/Leco_Flutter',
    description = 'Webhook N8N (Leco_Flutter) para envio de mensagens WhatsApp via Evolution API',
    is_active = true,
    updated_at = NOW()
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
