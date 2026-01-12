-- ============================================
-- Verificar se sistema WhatsApp foi instalado corretamente
-- ============================================

-- 1. Verificar colunas adicionadas em leadstintim
SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_name = 'leadstintim'
AND column_name IN ('outbound_status', 'outbound_sent_at', 'outbound_error', 'n8n_execution_id')
ORDER BY column_name;

-- 2. Ver templates instalados
SELECT 
    id,
    name,
    category,
    LEFT(body, 50) as body_preview,
    is_active
FROM whatsapp_message_templates
ORDER BY category, name;

-- 3. Ver configuração N8N
SELECT * FROM n8n_webhook_config;

-- 4. Verificar funções criadas
SELECT 
    routine_name,
    routine_type
FROM information_schema.routines
WHERE routine_schema = 'public'
AND routine_name LIKE '%whatsapp%'
ORDER BY routine_name;

-- 5. Verificar view
SELECT 
    table_name,
    table_type
FROM information_schema.tables
WHERE table_name = 'whatsapp_outbound_queue';
