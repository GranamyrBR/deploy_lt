-- ============================================
-- Script de Teste Manual - Envio WhatsApp
-- Execute este script para testar o sistema sem usar o app
-- ============================================

-- IMPORTANTE: Substitua o telefone abaixo pelo SEU número de teste
-- Formato: +55 (código país) + DDD + número
-- Exemplo: +5511987654321

-- Teste 1: Envio simples
SELECT queue_whatsapp_message(
  '+5561981328287',  -- ⚠️ SUBSTITUA PELO SEU TELEFONE DE TESTE
  'Teste Sistema',
  '🎉 Olá! Esta é uma mensagem de teste do sistema WhatsApp integrado. Se você recebeu isso, o sistema está funcionando!',
  'lead',
  '{"test": true, "source": "sql_test"}'::jsonb
) as leadstintim_id_criado;

-- Aguarde 5 segundos e verifique o status
-- Depois execute:

-- Teste 2: Verificar mensagem criada
SELECT 
    id,
    name,
    phone,
    message,
    from_me,
    outbound_status,
    outbound_sent_at,
    outbound_error,
    n8n_execution_id,
    created_at
FROM leadstintim
WHERE from_me = 'true'
AND outbound_status IS NOT NULL
ORDER BY created_at DESC
LIMIT 5;

-- Teste 3: Ver fila de envio
SELECT * FROM whatsapp_outbound_queue;

-- Teste 4: Ver templates disponíveis
SELECT 
    id,
    name,
    category,
    body,
    variables
FROM whatsapp_message_templates
WHERE is_active = true;

-- Teste 5: Estatísticas de envio
SELECT 
    outbound_status,
    COUNT(*) as total,
    MAX(outbound_sent_at) as ultimo_envio
FROM leadstintim
WHERE from_me = 'true'
AND outbound_status IS NOT NULL
GROUP BY outbound_status;

-- ============================================
-- TROUBLESHOOTING
-- ============================================

-- Se status ficou em 'pending' (não foi para 'queued'):
-- 1. Verificar se trigger está ativo:
SELECT 
    tgname,
    tgenabled
FROM pg_trigger 
WHERE tgname = 'trigger_notify_n8n_new_message';

-- 2. Verificar webhook configurado:
SELECT * FROM n8n_webhook_config WHERE is_active = true;

-- 3. Verificar logs do N8N:
-- Acesse: https://critical.axioscode.com
-- Menu: Executions
-- Procure por execuções recentes do workflow
