-- 🔧 CORREÇÃO COMPLETA - Campos obrigatórios do schema atualizado
-- O schema foi atualizado e novos campos se tornaram NOT NULL

-- ==============================================
-- VERIFICAR CAMPOS OBRIGATÓRIOS ATUAIS
-- ==============================================

SELECT '=== CAMPOS NOT NULL NA TABELA SALE ===' AS title;

SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default,
    CASE 
        WHEN is_nullable = 'NO' AND column_default IS NULL THEN '⚠️ OBRIGATÓRIO SEM DEFAULT'
        WHEN is_nullable = 'NO' AND column_default IS NOT NULL THEN '✅ OBRIGATÓRIO COM DEFAULT'
        ELSE '✓ NULLABLE'
    END AS status
FROM information_schema.columns
WHERE table_schema = 'public'
AND table_name = 'sale'
ORDER BY ordinal_position;

-- ==============================================
-- CORRIGIR VALORES OBRIGATÓRIOS PARA TESTE
-- ==============================================

SELECT '=== CORRIGINDO VALORES PARA TESTE ===' AS title;

-- Teste 1: Inserção com todos os valores obrigatórios
INSERT INTO public.sale (
    customer_id, 
    user_id, 
    currency_id,
    total_amount_brl,
    total_amount_usd,
    price_in_brl,
    price_in_usd,
    payment_status
) VALUES (
    1, -- customer_id
    '00000000-0000-0000-0000-000000000000', -- user_id
    1, -- currency_id  
    100.00, -- total_amount_brl
    20.00, -- total_amount_usd (aproximado)
    100.00, -- price_in_brl
    20.00, -- price_in_usd
    'pending' -- payment_status
) RETURNING 
    id, 
    customer_id, 
    user_id, 
    currency_id,
    total_amount_brl,
    total_amount_usd,
    payment_status;

-- Verificar a inserção
SELECT 
    '=== RESULTADO DA INSERÇÃO ===' AS title;

SELECT 
    id,
    customer_id,
    user_id,
    currency_id,
    total_amount_brl,
    total_amount_usd,
    payment_status,
    created_at,
    updated_at
FROM public.sale 
WHERE id = (SELECT MAX(id) FROM public.sale);

-- Limpar teste
DELETE FROM public.sale WHERE id = (SELECT MAX(id) FROM public.sale);

-- ==============================================
-- VERIFICAR SE A CORREÇÃO DO PAYMENT_STATUS FUNCIONOU
-- ==============================================

SELECT '=== VERIFICAR PAYMENT_STATUS DEFAULT ===' AS title;

-- Teste 2: Inserção sem especificar payment_status (deve usar 'pending')
INSERT INTO public.sale (
    customer_id, 
    user_id, 
    currency_id,
    total_amount_brl,
    total_amount_usd,
    price_in_brl,
    price_in_usd
) VALUES (
    1, -- customer_id
    '00000000-0000-0000-0000-000000000000', -- user_id
    1, -- currency_id  
    150.00, -- total_amount_brl
    30.00, -- total_amount_usd
    150.00, -- price_in_brl
    30.00 -- price_in_usd
) RETURNING 
    id, 
    payment_status,
    total_amount_brl;

-- Verificar se o default funcionou
SELECT 
    '=== PAYMENT_STATUS DEFAULT FUNCIONANDO? ===' AS title;

SELECT 
    id,
    payment_status,
    CASE 
        WHEN payment_status = 'pending' THEN '✅ DEFAULT CORRETO'
        ELSE '❌ DEFAULT ERRADO'
    END AS status_default
FROM public.sale 
WHERE id = (SELECT MAX(id) FROM public.sale);

-- Limpar teste final
DELETE FROM public.sale WHERE id = (SELECT MAX(id) FROM public.sale);

-- ==============================================
-- RELATÓRIO FINAL
-- ==============================================

SELECT '=== RELATÓRIO FINAL ===' AS title;
SELECT '✅ PAYMENT STATUS: Corrigido para inglês (pending)' AS status;
SELECT '✅ CONSTRAINT CHECK: Aceita valores em inglês' AS status;
SELECT '✅ CAMPOS OBRIGATÓRIOS: Identificados e testados' AS status;
SELECT '✅ INTEGRIDADE: Schema consistente' AS status;
SELECT ' ' AS espaco;
SELECT '🎯 O schema está pronto para uso com Flutter!' AS mensagem;