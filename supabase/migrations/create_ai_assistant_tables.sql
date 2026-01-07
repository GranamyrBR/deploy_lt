-- 📊 Migration para tabelas de AI Assistant
-- Cria tabelas para armazenar interações, logs de erro e métricas do assistente de IA

-- ==============================================
-- TABELA: AI Interactions
-- Armazena todas as interações entre usuários e o assistente IA
-- ==============================================
CREATE TABLE IF NOT EXISTS ai_interactions (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID REFERENCES "user"(id) ON DELETE CASCADE,
    conversation_id VARCHAR(255) NOT NULL,
    request_message TEXT NOT NULL,
    response_message TEXT NOT NULL,
    tokens_used INTEGER NOT NULL DEFAULT 0,
    model VARCHAR(100) NOT NULL,
    response_time_ms INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices para performance
CREATE INDEX IF NOT EXISTS idx_ai_interactions_user_id ON ai_interactions(user_id);
CREATE INDEX IF NOT EXISTS idx_ai_interactions_conversation_id ON ai_interactions(conversation_id);
CREATE INDEX IF NOT EXISTS idx_ai_interactions_created_at ON ai_interactions(created_at DESC);

-- ==============================================
-- TABELA: AI Errors
-- Armazena logs de erros para debugging e monitoramento
-- ==============================================
CREATE TABLE IF NOT EXISTS ai_errors (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID REFERENCES "user"(id) ON DELETE CASCADE,
    conversation_id VARCHAR(255),
    request_message TEXT,
    error_message TEXT NOT NULL,
    error_type VARCHAR(100),
    stack_trace TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices para debugging
CREATE INDEX IF NOT EXISTS idx_ai_errors_user_id ON ai_errors(user_id);
CREATE INDEX IF NOT EXISTS idx_ai_errors_created_at ON ai_errors(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_ai_errors_error_type ON ai_errors(error_type);

-- ==============================================
-- TABELA: AI Conversation History
-- Armazena histórico de conversas para contexto contínuo
-- ==============================================
CREATE TABLE IF NOT EXISTS ai_conversation_history (
    id BIGSERIAL PRIMARY KEY,
    conversation_id VARCHAR(255) NOT NULL,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    message_role VARCHAR(20) NOT NULL CHECK (message_role IN ('user', 'assistant', 'system')),
    message_content TEXT NOT NULL,
    tokens_used INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices para performance
CREATE INDEX IF NOT EXISTS idx_ai_conv_history_conversation_id ON ai_conversation_history(conversation_id);
CREATE INDEX IF NOT EXISTS idx_ai_conv_history_user_id ON ai_conversation_history(user_id);
CREATE INDEX IF NOT EXISTS idx_ai_conv_history_created_at ON ai_conversation_history(created_at DESC);

-- ==============================================
-- TABELA: AI Usage Metrics
-- Métricas de uso para análise e otimização
-- ==============================================
CREATE TABLE IF NOT EXISTS ai_usage_metrics (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    date DATE NOT NULL DEFAULT CURRENT_DATE,
    total_requests INTEGER DEFAULT 0,
    total_tokens INTEGER DEFAULT 0,
    average_response_time_ms INTEGER DEFAULT 0,
    error_count INTEGER DEFAULT 0,
    success_count INTEGER DEFAULT 0,
    
    -- Índice único para evitar duplicatas por usuário/dia
    UNIQUE(user_id, date)
);

-- Índices para performance
CREATE INDEX IF NOT EXISTS idx_ai_metrics_user_id ON ai_usage_metrics(user_id);
CREATE INDEX IF NOT EXISTS idx_ai_metrics_date ON ai_usage_metrics(date DESC);

-- ==============================================
-- TABELA: AI Rate Limit Tracking
-- Controle de rate limiting por usuário
-- ==============================================
CREATE TABLE IF NOT EXISTS ai_rate_limit_tracking (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    window_start TIMESTAMP WITH TIME ZONE NOT NULL,
    request_count INTEGER DEFAULT 0,
    last_request_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices para limpeza e queries
CREATE INDEX IF NOT EXISTS idx_ai_rate_limit_user_window ON ai_rate_limit_tracking(user_id, window_start);
CREATE INDEX IF NOT EXISTS idx_ai_rate_limit_window_start ON ai_rate_limit_tracking(window_start);

-- ==============================================
-- FUNCTIONS: Stored Procedures para IA
-- ==============================================

-- Função para registrar métricas de uso
CREATE OR REPLACE FUNCTION update_ai_usage_metrics(
    p_user_id UUID,
    p_tokens INTEGER,
    p_response_time_ms INTEGER,
    p_success BOOLEAN
)
RETURNS VOID AS $$
BEGIN
    INSERT INTO ai_usage_metrics (
        user_id, date, total_requests, total_tokens, 
        average_response_time_ms, error_count, success_count
    ) VALUES (
        p_user_id, CURRENT_DATE, 1, p_tokens, 
        p_response_time_ms, 
        CASE WHEN p_success THEN 0 ELSE 1 END,
        CASE WHEN p_success THEN 1 ELSE 0 END
    )
    ON CONFLICT (user_id, date) 
    DO UPDATE SET
        total_requests = ai_usage_metrics.total_requests + 1,
        total_tokens = ai_usage_metrics.total_tokens + p_tokens,
        average_response_time_ms = (
            (ai_usage_metrics.average_response_time_ms * ai_usage_metrics.total_requests + p_response_time_ms) 
            / (ai_usage_metrics.total_requests + 1)
        ),
        error_count = ai_usage_metrics.error_count + CASE WHEN p_success THEN 0 ELSE 1 END,
        success_count = ai_usage_metrics.success_count + CASE WHEN p_success THEN 1 ELSE 0 END;
END;
$$ LANGUAGE plpgsql;

-- Função para limpar rate limit tracking antigo
CREATE OR REPLACE FUNCTION cleanup_old_rate_limit_tracking()
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    DELETE FROM ai_rate_limit_tracking 
    WHERE window_start < NOW() - INTERVAL '1 hour';
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

-- ==============================================
-- TRIGGERS: Automação de logs e métricas
-- ==============================================

-- Trigger para atualizar métricas após cada interação
CREATE OR REPLACE FUNCTION trigger_update_ai_metrics()
RETURNS TRIGGER AS $$
BEGIN
    PERFORM update_ai_usage_metrics(
        NEW.user_id,
        NEW.tokens_used,
        NEW.response_time_ms,
        TRUE  -- success
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ai_interactions_metrics_trigger
    AFTER INSERT ON ai_interactions
    FOR EACH ROW
    EXECUTE FUNCTION trigger_update_ai_metrics();

-- Trigger para registrar erros nas métricas
CREATE OR REPLACE FUNCTION trigger_update_ai_error_metrics()
RETURNS TRIGGER AS $$
BEGIN
    PERFORM update_ai_usage_metrics(
        NEW.user_id,
        0,  -- no tokens used on error
        0,  -- no response time on error
        FALSE  -- error
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ai_errors_metrics_trigger
    AFTER INSERT ON ai_errors
    FOR EACH ROW
    EXECUTE FUNCTION trigger_update_ai_error_metrics();

-- ==============================================
-- ROW LEVEL SECURITY (RLS): Segurança e privacidade
-- ==============================================

-- RLS para ai_interactions
ALTER TABLE ai_interactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own interactions" ON ai_interactions
    FOR SELECT USING (
        auth.uid() = user_id OR 
        EXISTS (
            SELECT 1 FROM "user" 
            WHERE id = auth.uid() AND role IN ('admin', 'manager')
        )
    );

CREATE POLICY "Users can insert own interactions" ON ai_interactions
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- RLS para ai_errors (apenas admins e o próprio usuário)
ALTER TABLE ai_errors ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own errors" ON ai_errors
    FOR SELECT USING (
        auth.uid() = user_id OR 
        EXISTS (
            SELECT 1 FROM "user" 
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

CREATE POLICY "Admins can view all errors" ON ai_errors
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM "user" 
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- RLS para ai_conversation_history
ALTER TABLE ai_conversation_history ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own conversation history" ON ai_conversation_history
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own conversation history" ON ai_conversation_history
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- RLS para ai_usage_metrics (apenas o próprio usuário e admins)
ALTER TABLE ai_usage_metrics ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own metrics" ON ai_usage_metrics
    FOR SELECT USING (
        auth.uid() = user_id OR 
        EXISTS (
            SELECT 1 FROM "user" 
            WHERE id = auth.uid() AND role IN ('admin', 'manager')
        )
    );

-- RLS para ai_rate_limit_tracking (apenas o próprio usuário)
ALTER TABLE ai_rate_limit_tracking ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own rate limit data" ON ai_rate_limit_tracking
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update own rate limit data" ON ai_rate_limit_tracking
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own rate limit data" ON ai_rate_limit_tracking
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- ==============================================
-- PERMISSÕES: Grant access to roles
-- ==============================================

-- Conceder permissões para usuários autenticados
GRANT SELECT, INSERT ON ai_interactions TO authenticated;
GRANT SELECT ON ai_errors TO authenticated;
GRANT SELECT, INSERT ON ai_conversation_history TO authenticated;
GRANT SELECT ON ai_usage_metrics TO authenticated;
GRANT SELECT, INSERT, UPDATE ON ai_rate_limit_tracking TO authenticated;

-- Conceder permissões adicionais para administradores
GRANT SELECT ON ai_errors TO authenticated;  -- Já coberto pela política

-- ==============================================
-- DADOS INICIAIS: Configurações padrão
-- ==============================================

-- Inserir configurações de rate limit padrão (se necessário)
-- Estas serão gerenciadas automaticamente pelo sistema

-- ==============================================
-- RELATÓRIO DE IMPLEMENTAÇÃO
-- ==============================================

SELECT '✅ Tabelas de AI Assistant criadas com sucesso' AS status;
SELECT '✅ Funções de métricas e limpeza implementadas' AS status;
SELECT '✅ Triggers de automação configurados' AS status;
SELECT '✅ RLS (Row Level Security) ativado' AS status;
SELECT '✅ Permissões concedidas para usuários autenticados' AS status;
SELECT '✅ Sistema de auditoria e logs implementado' AS status;

-- Informações sobre as tabelas criadas
SELECT 
    'ai_interactions' AS table_name,
    'Armazena todas as interações IA-usuário' AS description
UNION ALL
SELECT 
    'ai_errors',
    'Logs de erros para debugging e monitoramento'
UNION ALL
SELECT 
    'ai_conversation_history',
    'Histórico de conversas para contexto contínuo'
UNION ALL
SELECT 
    'ai_usage_metrics',
    'Métricas de uso para análise e otimização'
UNION ALL
SELECT 
    'ai_rate_limit_tracking',
    'Controle de rate limiting por usuário';