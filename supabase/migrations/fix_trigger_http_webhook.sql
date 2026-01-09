-- ============================================
-- Trigger HTTP: Chamar N8N via HTTP ao invés de pg_notify
-- Requer extensão: pg_net (já vem no Supabase)
-- ============================================

-- Ativar extensão pg_net (se ainda não estiver)
CREATE EXTENSION IF NOT EXISTS pg_net;

-- Recriar função para usar HTTP request
CREATE OR REPLACE FUNCTION notify_n8n_new_message()
RETURNS TRIGGER AS $$
DECLARE
    v_webhook_url TEXT;
    v_payload JSONB;
    v_request_id BIGINT;
BEGIN
    -- Apenas dispara se for mensagem outbound pendente
    IF NEW.from_me = 'true' AND NEW.outbound_status = 'pending' THEN
        
        -- Buscar URL do webhook
        SELECT webhook_url INTO v_webhook_url 
        FROM n8n_webhook_config 
        WHERE name = 'send_whatsapp' AND is_active = true
        LIMIT 1;
        
        IF v_webhook_url IS NOT NULL THEN
            -- Construir payload
            v_payload := jsonb_build_object(
                'leadstintim_id', NEW.id,
                'phone', NEW.whatsapp_normalizado,
                'name', NEW.name,
                'message', NEW.message,
                'context', COALESCE((NEW.body::jsonb), '{}'::jsonb)
            );
            
            -- Fazer HTTP POST para N8N (assíncrono)
            SELECT net.http_post(
                url := v_webhook_url,
                headers := '{"Content-Type": "application/json"}'::jsonb,
                body := v_payload
            ) INTO v_request_id;
            
            -- Atualizar status para 'queued'
            UPDATE leadstintim 
            SET outbound_status = 'queued' 
            WHERE id = NEW.id;
            
            -- Log (opcional)
            RAISE NOTICE 'WhatsApp queued: ID=%, Request=%', NEW.id, v_request_id;
        ELSE
            RAISE WARNING 'Webhook N8N não configurado ou inativo';
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Recriar trigger (já existe, mas garante que usa nova função)
DROP TRIGGER IF EXISTS trigger_notify_n8n_new_message ON leadstintim;
CREATE TRIGGER trigger_notify_n8n_new_message
    AFTER INSERT ON leadstintim
    FOR EACH ROW
    EXECUTE FUNCTION notify_n8n_new_message();

-- Verificar
SELECT 
    tgname,
    tgenabled,
    'Trigger ativo e usando HTTP' as status
FROM pg_trigger
WHERE tgname = 'trigger_notify_n8n_new_message';

-- ============================================
-- TESTE RÁPIDO
-- ============================================
-- Agora execute novamente:
-- SELECT queue_whatsapp_message(
--   '+5511999999999',
--   'Teste HTTP',
--   'Teste com HTTP trigger',
--   'lead',
--   '{}'::jsonb
-- );
-- 
-- E verifique no N8N: https://critical.axioscode.com
-- ============================================
