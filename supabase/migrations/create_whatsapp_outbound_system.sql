-- ============================================
-- Sistema de Envio de WhatsApp via N8N + Evolution API
-- Integrado com tabela leadstintim existente
-- ============================================

-- 1. Adicionar colunas de controle de envio na leadstintim (aproveitando estrutura existente)
ALTER TABLE leadstintim ADD COLUMN IF NOT EXISTS outbound_status TEXT CHECK (outbound_status IN ('none', 'pending', 'queued', 'sent', 'delivered', 'read', 'failed'));
ALTER TABLE leadstintim ADD COLUMN IF NOT EXISTS outbound_sent_at TIMESTAMPTZ;
ALTER TABLE leadstintim ADD COLUMN IF NOT EXISTS outbound_error TEXT;
ALTER TABLE leadstintim ADD COLUMN IF NOT EXISTS n8n_execution_id TEXT;

-- Comentários
COMMENT ON COLUMN leadstintim.outbound_status IS 'Status de mensagem enviada (outbound): none, pending, queued, sent, delivered, read, failed';
COMMENT ON COLUMN leadstintim.outbound_sent_at IS 'Data/hora de envio da mensagem outbound';
COMMENT ON COLUMN leadstintim.outbound_error IS 'Mensagem de erro se envio falhou';
COMMENT ON COLUMN leadstintim.n8n_execution_id IS 'ID da execução N8N que enviou a mensagem';

-- 2. Tabela de templates de mensagens (leve e focada)
CREATE TABLE IF NOT EXISTS whatsapp_message_templates (
    id BIGSERIAL PRIMARY KEY,
    name TEXT UNIQUE NOT NULL,
    category TEXT NOT NULL CHECK (category IN ('boas_vindas', 'lembrete', 'confirmacao', 'follow_up', 'operacional', 'marketing')),
    body TEXT NOT NULL, -- Template com {{variaveis}}
    variables TEXT[], -- Lista de variáveis: ['name', 'date', 'value']
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    usage_count INT DEFAULT 0
);

-- Templates padrão
INSERT INTO whatsapp_message_templates (name, category, body, variables) VALUES
('boas_vindas_lead', 'boas_vindas', 'Olá {{name}}! 👋 Obrigado por entrar em contato com a Lecotour. Como podemos ajudá-lo hoje?', ARRAY['name']),
('confirmacao_cotacao', 'confirmacao', 'Olá {{name}}! Sua cotação #{{quotation_id}} foi criada com sucesso. Em breve nossa equipe entrará em contato.', ARRAY['name', 'quotation_id']),
('lembrete_operacao', 'lembrete', '⏰ Olá {{name}}! Lembrete: sua operação está agendada para {{date}} às {{time}}. Local de embarque: {{location}}.', ARRAY['name', 'date', 'time', 'location']),
('motorista_atribuido', 'operacional', '🚗 Olá {{driver_name}}! Você foi atribuído à operação #{{operation_id}} em {{date}}. Detalhes: {{details}}', ARRAY['driver_name', 'operation_id', 'date', 'details']),
('agencia_nova_venda', 'operacional', '💰 Nova venda registrada! Agência {{agency_name}}, venda #{{sale_id}} no valor de {{value}}. Comissão: {{commission}}.', ARRAY['agency_name', 'sale_id', 'value', 'commission'])
ON CONFLICT (name) DO NOTHING;

-- 3. Tabela de configuração N8N
CREATE TABLE IF NOT EXISTS n8n_webhook_config (
    id SERIAL PRIMARY KEY,
    name TEXT UNIQUE NOT NULL,
    webhook_url TEXT NOT NULL,
    is_active BOOLEAN DEFAULT true,
    description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Webhook padrão (você vai atualizar com a URL real)
INSERT INTO n8n_webhook_config (name, webhook_url, description) VALUES
('send_whatsapp', 'https://seu-n8n.com/webhook/send-whatsapp', 'Webhook principal para envio de mensagens WhatsApp via Evolution API')
ON CONFLICT (name) DO UPDATE SET webhook_url = EXCLUDED.webhook_url;

-- 4. Função para enfileirar mensagem para envio
CREATE OR REPLACE FUNCTION queue_whatsapp_message(
    p_recipient_phone TEXT,
    p_recipient_name TEXT,
    p_message_body TEXT,
    p_recipient_type TEXT DEFAULT 'lead',
    p_context JSONB DEFAULT '{}'::jsonb
) RETURNS BIGINT AS $$
DECLARE
    v_lead_id BIGINT;
BEGIN
    -- Inserir ou atualizar na leadstintim
    INSERT INTO leadstintim (
        phone,
        whatsapp_normalizado,
        name,
        message,
        from_me,
        outbound_status,
        source,
        status,
        created_at,
        body
    ) VALUES (
        p_recipient_phone,
        CASE 
            WHEN p_recipient_phone LIKE '+%' THEN p_recipient_phone
            ELSE '+' || REGEXP_REPLACE(p_recipient_phone, '[^0-9]', '', 'g')
        END,
        p_recipient_name,
        p_message_body,
        'true', -- from_me = true (mensagem enviada por nós)
        'pending', -- Status inicial
        'Sistema', -- Source
        'Novo Lead', -- Status
        NOW(),
        jsonb_build_object(
            'type', 'outbound',
            'recipient_type', p_recipient_type,
            'context', p_context,
            'queued_at', NOW()
        )::text
    )
    RETURNING id INTO v_lead_id;
    
    RETURN v_lead_id;
END;
$$ LANGUAGE plpgsql;

-- 5. Trigger para disparar webhook N8N quando mensagem é enfileirada
CREATE OR REPLACE FUNCTION notify_n8n_new_message()
RETURNS TRIGGER AS $$
DECLARE
    v_webhook_url TEXT;
    v_payload JSONB;
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
                'context', NEW.body::jsonb
            );
            
            -- Notificar via pg_notify (N8N pode escutar ou usar HTTP request)
            PERFORM pg_notify('whatsapp_outbound', v_payload::text);
            
            -- Atualizar status para 'queued'
            UPDATE leadstintim 
            SET outbound_status = 'queued' 
            WHERE id = NEW.id;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Criar trigger
DROP TRIGGER IF EXISTS trigger_notify_n8n_new_message ON leadstintim;
CREATE TRIGGER trigger_notify_n8n_new_message
    AFTER INSERT ON leadstintim
    FOR EACH ROW
    EXECUTE FUNCTION notify_n8n_new_message();

-- 6. Função para N8N atualizar status após envio
CREATE OR REPLACE FUNCTION update_outbound_status(
    p_leadstintim_id BIGINT,
    p_status TEXT,
    p_n8n_execution_id TEXT DEFAULT NULL,
    p_error TEXT DEFAULT NULL
) RETURNS VOID AS $$
BEGIN
    UPDATE leadstintim
    SET 
        outbound_status = p_status,
        outbound_sent_at = CASE WHEN p_status = 'sent' THEN NOW() ELSE outbound_sent_at END,
        n8n_execution_id = COALESCE(p_n8n_execution_id, n8n_execution_id),
        outbound_error = p_error
    WHERE id = p_leadstintim_id;
END;
$$ LANGUAGE plpgsql;

-- 7. View para mensagens pendentes de envio
CREATE OR REPLACE VIEW whatsapp_outbound_queue AS
SELECT 
    id,
    phone,
    whatsapp_normalizado,
    name,
    message,
    outbound_status,
    created_at,
    body::jsonb->'context' as context
FROM leadstintim
WHERE from_me = 'true' 
  AND outbound_status IN ('pending', 'queued')
ORDER BY created_at ASC;

-- 8. Índices para performance
CREATE INDEX IF NOT EXISTS idx_leadstintim_outbound_status ON leadstintim(outbound_status) WHERE from_me = 'true';
CREATE INDEX IF NOT EXISTS idx_leadstintim_from_me ON leadstintim(from_me);

-- Comentários finais
COMMENT ON FUNCTION queue_whatsapp_message IS 'Enfileira mensagem WhatsApp para envio via N8N';
COMMENT ON FUNCTION update_outbound_status IS 'Atualiza status da mensagem após processamento pelo N8N';
COMMENT ON VIEW whatsapp_outbound_queue IS 'Mensagens pendentes de envio (fila)';
