-- ============================================
-- Sistema de Mensagens WhatsApp via N8N + Evolution API
-- Integração completa para envio de mensagens
-- ============================================

-- 1. Tabela de mensagens WhatsApp (outbound)
CREATE TABLE IF NOT EXISTS whatsapp_messages (
    id BIGSERIAL PRIMARY KEY,
    
    -- Identificação
    message_id TEXT UNIQUE, -- ID retornado pela Evolution API
    
    -- Destinatário (relacionamento flexível)
    recipient_type TEXT NOT NULL CHECK (recipient_type IN ('lead', 'customer', 'employee', 'driver', 'agency', 'supplier', 'other')),
    recipient_id BIGINT, -- ID do registro relacionado (leadstintim_id, contact_id, etc)
    recipient_phone TEXT NOT NULL, -- Telefone normalizado com +55
    recipient_name TEXT,
    
    -- Conteúdo
    message_type TEXT NOT NULL DEFAULT 'text' CHECK (message_type IN ('text', 'image', 'document', 'audio', 'video', 'location', 'contact', 'template')),
    message_body TEXT, -- Texto da mensagem
    media_url TEXT, -- URL da mídia (se image/document/video)
    caption TEXT, -- Legenda da mídia
    template_name TEXT, -- Nome do template (se type = template)
    template_params JSONB, -- Parâmetros do template
    
    -- Metadata
    context JSONB, -- Contexto adicional (operation_id, sale_id, quotation_id, etc)
    tags TEXT[], -- Tags para organização ['cotacao', 'urgente', 'follow-up']
    
    -- Status e rastreamento
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'queued', 'sent', 'delivered', 'read', 'failed', 'cancelled')),
    error_message TEXT,
    
    -- Webhook N8N
    n8n_webhook_url TEXT, -- URL do webhook específico
    n8n_execution_id TEXT, -- ID da execução no N8N
    
    -- Evolution API response
    evolution_response JSONB,
    
    -- Datas
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    queued_at TIMESTAMPTZ,
    sent_at TIMESTAMPTZ,
    delivered_at TIMESTAMPTZ,
    read_at TIMESTAMPTZ,
    failed_at TIMESTAMPTZ,
    
    -- Auditoria
    created_by UUID REFERENCES auth.users(id),
    scheduled_for TIMESTAMPTZ, -- Agendar envio futuro
    
    -- Índices para busca rápida
    CONSTRAINT valid_recipient_phone CHECK (recipient_phone ~ '^\+[0-9]{10,15}$')
);

-- 2. Tabela de templates de mensagens
CREATE TABLE IF NOT EXISTS whatsapp_templates (
    id BIGSERIAL PRIMARY KEY,
    
    -- Identificação
    name TEXT UNIQUE NOT NULL, -- Nome único do template
    category TEXT NOT NULL CHECK (category IN ('welcome', 'notification', 'reminder', 'confirmation', 'marketing', 'support', 'follow_up', 'custom')),
    
    -- Conteúdo
    body TEXT NOT NULL, -- Template com variáveis: {{name}}, {{date}}, etc
    media_type TEXT CHECK (media_type IN ('none', 'image', 'document', 'video')),
    media_url TEXT, -- URL padrão da mídia
    
    -- Configuração
    variables TEXT[], -- ['name', 'date', 'value'] - lista de variáveis usadas
    example_params JSONB, -- Exemplo de parâmetros para teste
    
    -- Metadata
    description TEXT,
    tags TEXT[],
    recipient_types TEXT[], -- ['lead', 'customer', 'employee']
    
    -- Status
    is_active BOOLEAN DEFAULT true,
    
    -- Auditoria
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES auth.users(id),
    
    -- Estatísticas de uso
    usage_count INT DEFAULT 0,
    last_used_at TIMESTAMPTZ
);

-- 3. Tabela de configurações N8N
CREATE TABLE IF NOT EXISTS n8n_webhooks (
    id BIGSERIAL PRIMARY KEY,
    
    -- Identificação
    name TEXT UNIQUE NOT NULL, -- Nome do webhook
    webhook_url TEXT NOT NULL, -- URL completa do webhook N8N
    
    -- Tipo e propósito
    purpose TEXT NOT NULL CHECK (purpose IN ('send_message', 'send_bulk', 'notification', 'integration', 'custom')),
    recipient_types TEXT[], -- Tipos de destinatários suportados
    
    -- Configuração
    headers JSONB, -- Headers customizados
    auth_type TEXT CHECK (auth_type IN ('none', 'bearer', 'basic', 'api_key')),
    auth_credentials JSONB, -- Credenciais (criptografadas)
    
    -- Status
    is_active BOOLEAN DEFAULT true,
    
    -- Metadata
    description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 4. Índices para performance
CREATE INDEX IF NOT EXISTS idx_whatsapp_messages_status ON whatsapp_messages(status);
CREATE INDEX IF NOT EXISTS idx_whatsapp_messages_recipient ON whatsapp_messages(recipient_type, recipient_id);
CREATE INDEX IF NOT EXISTS idx_whatsapp_messages_phone ON whatsapp_messages(recipient_phone);
CREATE INDEX IF NOT EXISTS idx_whatsapp_messages_created_at ON whatsapp_messages(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_whatsapp_messages_scheduled ON whatsapp_messages(scheduled_for) WHERE status = 'pending';
CREATE INDEX IF NOT EXISTS idx_whatsapp_templates_category ON whatsapp_templates(category) WHERE is_active = true;

-- 5. Comentários
COMMENT ON TABLE whatsapp_messages IS 'Mensagens WhatsApp enviadas via N8N + Evolution API';
COMMENT ON TABLE whatsapp_templates IS 'Templates reutilizáveis para mensagens WhatsApp';
COMMENT ON TABLE n8n_webhooks IS 'Configuração de webhooks N8N para integração';

COMMENT ON COLUMN whatsapp_messages.recipient_type IS 'Tipo do destinatário: lead, customer, employee, driver, agency, supplier';
COMMENT ON COLUMN whatsapp_messages.context IS 'Contexto adicional em JSON: {operation_id: 123, quotation_id: 456}';
COMMENT ON COLUMN whatsapp_messages.scheduled_for IS 'Agendar envio futuro (NULL = enviar imediatamente)';
