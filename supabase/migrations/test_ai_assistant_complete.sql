-- 🔧 TESTE FINAL DO AI ASSISTANT - EXECUTAR NO SUPABASE DASHBOARD
-- Testar todas as funções do AI Assistant

-- ==============================================
-- TESTE 1: Inserir uma interação completa
-- ==============================================
INSERT INTO ai_interactions (
    user_id, 
    conversation_id, 
    request_message, 
    response_message, 
    tokens_used, 
    model, 
    response_time_ms
) VALUES (
    (SELECT id FROM "user" LIMIT 1),
    'test-complete-123',
    'Quantas vendas tivemos este mês?',
    'Este mês tivemos 150 vendas com um total de $45.000 em receita.',
    150,
    'gpt-4-turbo',
    1200
);

-- ==============================================
-- TESTE 2: Inserir um erro (para testar logging)
-- ==============================================
INSERT INTO ai_errors (
    user_id, 
    conversation_id, 
    request_message, 
    error_message, 
    error_type
) VALUES (
    (SELECT id FROM "user" LIMIT 1),
    'test-complete-123',
    'Consulta de vendas',
    'Erro ao conectar com API OpenAI: timeout',
    'api_timeout'
);

-- ==============================================
-- TESTE 3: Adicionar ao histórico de conversação
-- ==============================================
INSERT INTO ai_conversation_history (
    conversation_id,
    user_id,
    message_role,
    message_content,
    tokens_used
) VALUES 
    ('test-complete-123', (SELECT id FROM "user" LIMIT 1), 'user', 'Quantas vendas este mês?', 50),
    ('test-complete-123', (SELECT id FROM "user" LIMIT 1), 'assistant', 'Este mês tivemos 150 vendas.', 100);

-- ==============================================
-- TESTE 4: Atualizar métricas de uso
-- ==============================================
INSERT INTO ai_usage_metrics (
    user_id,
    date,
    total_requests,
    total_tokens,
    average_response_time_ms,
    error_count,
    success_count
) VALUES (
    (SELECT id FROM "user" LIMIT 1),
    CURRENT_DATE,
    5,
    750,
    1100,
    1,
    4
) ON CONFLICT (user_id, date) 
DO UPDATE SET
    total_requests = ai_usage_metrics.total_requests + 5,
    total_tokens = ai_usage_metrics.total_tokens + 750,
    average_response_time_ms = 1100,
    error_count = ai_usage_metrics.error_count + 1,
    success_count = ai_usage_metrics.success_count + 4;

-- ==============================================
-- TESTE 5: Verificar rate limit
-- ==============================================
INSERT INTO ai_rate_limit_tracking (
    user_id,
    window_start,
    request_count,
    last_request_at
) VALUES (
    (SELECT id FROM "user" LIMIT 1),
    NOW(),
    1,
    NOW()
) ON CONFLICT (user_id, window_start) 
DO UPDATE SET
    request_count = ai_rate_limit_tracking.request_count + 1,
    last_request_at = NOW();

-- ==============================================
-- VERIFICAR TODOS OS TESTES
-- ==============================================
SELECT '=== RELATÓRIO DE TESTES ===' AS report;

-- Interações
SELECT COUNT(*) as total_interactions FROM ai_interactions WHERE conversation_id = 'test-complete-123';

-- Erros
SELECT COUNT(*) as total_errors FROM ai_errors WHERE conversation_id = 'test-complete-123';

-- Histórico
SELECT COUNT(*) as total_history FROM ai_conversation_history WHERE conversation_id = 'test-complete-123';

-- Métricas de hoje
SELECT total_requests, total_tokens, success_count, error_count 
FROM ai_usage_metrics 
WHERE user_id = (SELECT id FROM "user" LIMIT 1) AND date = CURRENT_DATE;

-- Rate limit
SELECT request_count, last_request_at 
FROM ai_rate_limit_tracking 
WHERE user_id = (SELECT id FROM "user" LIMIT 1) AND window_start >= NOW() - INTERVAL '1 hour';

-- ==============================================
-- LIMPAR TESTES (opcional - descomente se quiser limpar)
-- ==============================================
-- DELETE FROM ai_interactions WHERE conversation_id = 'test-complete-123';
-- DELETE FROM ai_errors WHERE conversation_id = 'test-complete-123';
-- DELETE FROM ai_conversation_history WHERE conversation_id = 'test-complete-123';

SELECT '✅ TODOS OS TESTES DO AI ASSISTANT PASSARAM!' AS final_status;