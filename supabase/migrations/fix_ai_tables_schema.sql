-- 📊 Correção completa das tabelas de AI Assistant
-- Fix para foreign keys e consistência de schema

-- ==============================================
-- CORREÇÕES DE FOREIGN KEYS
-- ==============================================

-- 1. Corrigir foreign keys na tabela ai_interactions (já está correto)
-- ALTER TABLE ai_interactions DROP CONSTRAINT IF EXISTS ai_interactions_user_id_fkey;
-- ALTER TABLE ai_interactions ADD CONSTRAINT ai_interactions_user_id_fkey 
--     FOREIGN KEY (user_id) REFERENCES "user"(id) ON DELETE CASCADE;

-- 2. Corrigir foreign keys na tabela ai_errors (já está correto)
-- ALTER TABLE ai_errors DROP CONSTRAINT IF EXISTS ai_errors_user_id_fkey;
-- ALTER TABLE ai_errors ADD CONSTRAINT ai_errors_user_id_fkey 
--     FOREIGN KEY (user_id) REFERENCES "user"(id) ON DELETE CASCADE;

-- 3. Corrigir foreign keys na tabela ai_conversation_history
ALTER TABLE ai_conversation_history DROP CONSTRAINT IF EXISTS ai_conversation_history_user_id_fkey;
ALTER TABLE ai_conversation_history ADD CONSTRAINT ai_conversation_history_user_id_fkey 
    FOREIGN KEY (user_id) REFERENCES "user"(id) ON DELETE CASCADE;

-- 4. Corrigir foreign keys na tabela ai_usage_metrics
ALTER TABLE ai_usage_metrics DROP CONSTRAINT IF EXISTS ai_usage_metrics_user_id_fkey;
ALTER TABLE ai_usage_metrics ADD CONSTRAINT ai_usage_metrics_user_id_fkey 
    FOREIGN KEY (user_id) REFERENCES "user"(id) ON DELETE CASCADE;

-- 5. Corrigir foreign keys na tabela ai_rate_limit_tracking
ALTER TABLE ai_rate_limit_tracking DROP CONSTRAINT IF EXISTS ai_rate_limit_tracking_user_id_fkey;
ALTER TABLE ai_rate_limit_tracking ADD CONSTRAINT ai_rate_limit_tracking_user_id_fkey 
    FOREIGN KEY (user_id) REFERENCES "user"(id) ON DELETE CASCADE;

-- ==============================================
-- CORREÇÕES DE PERMISSÕES RLS
-- ==============================================

-- Remover políticas antigas incorretas
DROP POLICY IF EXISTS "Users can view own interactions" ON ai_interactions;
DROP POLICY IF EXISTS "Users can insert own interactions" ON ai_interactions;
DROP POLICY IF EXISTS "Users can view own errors" ON ai_errors;
DROP POLICY IF EXISTS "Admins can view all errors" ON ai_errors;
DROP POLICY IF EXISTS "Users can view own conversation history" ON ai_conversation_history;
DROP POLICY IF EXISTS "Users can insert own conversation history" ON ai_conversation_history;
DROP POLICY IF EXISTS "Users can view own metrics" ON ai_usage_metrics;
DROP POLICY IF EXISTS "Users can view own rate limit data" ON ai_rate_limit_tracking;
DROP POLICY IF EXISTS "Users can update own rate limit data" ON ai_rate_limit_tracking;
DROP POLICY IF EXISTS "Users can insert own rate limit data" ON ai_rate_limit_tracking;

-- Criar políticas corretas baseadas na tabela "user"
-- Políticas para ai_interactions
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

-- Políticas para ai_errors
CREATE POLICY "Users can view own errors" ON ai_errors
    FOR SELECT USING (
        auth.uid() = user_id OR 
        EXISTS (
            SELECT 1 FROM "user" 
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- Políticas para ai_conversation_history
CREATE POLICY "Users can view own conversation history" ON ai_conversation_history
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own conversation history" ON ai_conversation_history
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Políticas para ai_usage_metrics
CREATE POLICY "Users can view own metrics" ON ai_usage_metrics
    FOR SELECT USING (
        auth.uid() = user_id OR 
        EXISTS (
            SELECT 1 FROM "user" 
            WHERE id = auth.uid() AND role IN ('admin', 'manager')
        )
    );

-- Políticas para ai_rate_limit_tracking
CREATE POLICY "Users can view own rate limit data" ON ai_rate_limit_tracking
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update own rate limit data" ON ai_rate_limit_tracking
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own rate limit data" ON ai_rate_limit_tracking
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- ==============================================
-- CORREÇÕES DE PERMISSÕES GRANT
-- ==============================================

-- Revogar permissões antigas
REVOKE ALL ON ai_interactions FROM authenticated;
REVOKE ALL ON ai_errors FROM authenticated;
REVOKE ALL ON ai_conversation_history FROM authenticated;
REVOKE ALL ON ai_usage_metrics FROM authenticated;
REVOKE ALL ON ai_rate_limit_tracking FROM authenticated;

-- Conceder permissões corretas
GRANT SELECT, INSERT ON ai_interactions TO authenticated;
GRANT SELECT ON ai_errors TO authenticated;
GRANT SELECT, INSERT ON ai_conversation_history TO authenticated;
GRANT SELECT ON ai_usage_metrics TO authenticated;
GRANT SELECT, INSERT, UPDATE ON ai_rate_limit_tracking TO authenticated;

-- ==============================================
-- CORREÇÃO DA FUNÇÃO update_ai_usage_metrics
-- ==============================================
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

-- ==============================================
-- RELATÓRIO DE CORREÇÕES
-- ==============================================
SELECT '✅ Foreign keys corrigidas para referenciar tabela "user"' AS status;
SELECT '✅ Políticas RLS atualizadas com estrutura correta' AS status;
SELECT '✅ Permissões GRANT revogadas e reconcedidas corretamente' AS status;
SELECT '✅ Função update_ai_usage_metrics atualizada' AS status;

-- Verificar estrutura atual
SELECT 
    table_name,
    constraint_name,
    constraint_type
FROM information_schema.table_constraints 
WHERE table_name LIKE 'ai_%'
ORDER BY table_name, constraint_type;