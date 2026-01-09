-- ============================================
-- Debug: Por que N8N não recebe notificação?
-- ============================================

-- 1. Verificar se trigger existe e está ativo
SELECT 
    tgname as trigger_name,
    tgenabled as enabled,
    tgtype as type,
    proname as function_name
FROM pg_trigger t
JOIN pg_proc p ON t.tgfoid = p.oid
WHERE tgrelid = 'leadstintim'::regclass
AND tgname LIKE '%notify%';

-- 2. Ver função do trigger
SELECT 
    routine_name,
    routine_definition
FROM information_schema.routines
WHERE routine_name = 'notify_n8n_new_message';

-- 3. Verificar mensagens criadas mas não enviadas
SELECT 
    id,
    name,
    phone,
    from_me,
    outbound_status,
    created_at,
    LEFT(message, 50) as message_preview
FROM leadstintim
WHERE from_me = 'true'
AND outbound_status = 'pending'
ORDER BY created_at DESC
LIMIT 10;

-- 4. Ver se há mensagens com status 'queued' (trigger funcionou)
SELECT 
    COUNT(*) as total_queued
FROM leadstintim
WHERE from_me = 'true'
AND outbound_status = 'queued';

-- 5. Testar pg_notify manualmente (debug)
-- Execute e veja se N8N recebe:
SELECT pg_notify('whatsapp_outbound', 
    json_build_object(
        'test', true,
        'leadstintim_id', 99999,
        'phone', '+5511999999999',
        'message', 'Teste manual pg_notify'
    )::text
);

-- ============================================
-- ANÁLISE
-- ============================================
-- Se trigger está ativo mas N8N não recebe:
-- Problema: pg_notify não chega no N8N
-- 
-- Solução: Usar HTTP request direto ao invés de pg_notify
-- Precisamos modificar o trigger para chamar webhook via HTTP
-- ============================================
