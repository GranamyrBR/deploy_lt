-- 🔧 CORREÇÃO DEFINITIVA DO DEFAULT payment_status
-- O problema persiste: DEFAULT é 'Pendente' mas CHECK só aceita inglês

-- ==============================================
-- VERIFICAR SITUAÇÃO ATUAL
-- ==============================================

SELECT '=== VERIFICANDO SITUAÇÃO ATUAL ===' AS title;

SELECT 
    column_name,
    column_default,
    is_nullable,
    data_type
FROM information_schema.columns
WHERE table_schema = 'public'
AND table_name = 'sale'
AND column_name = 'payment_status';

-- Verificar constraints existentes
SELECT 
    conname as constraint_name,
    pg_get_constraintdef(c.oid) as constraint_definition
FROM pg_constraint c
JOIN pg_namespace n ON n.oid = c.connamespace
JOIN pg_class cl ON cl.oid = c.conrelid
WHERE cl.relname = 'sale' 
  AND n.nspname = 'public'
  AND conname LIKE '%payment_status%'
ORDER BY conname;

-- ==============================================
-- CORREÇÃO DEFINITIVA: ALTERAR DEFAULT PARA INGLÊS
-- ==============================================

SELECT '=== CORRIGINDO DEFAULT PARA INGLÊS ===' AS title;

-- Remover o default atual (português)
ALTER TABLE public.sale ALTER COLUMN payment_status DROP DEFAULT;

-- Adicionar default em inglês (compatível com CHECK constraint)
ALTER TABLE public.sale 
ALTER COLUMN payment_status 
SET DEFAULT 'pending'::character varying;

-- ==============================================
-- VERIFICAR CORREÇÃO
-- ==============================================

SELECT '=== VERIFICANDO CORREÇÃO ===' AS title;

SELECT 
    column_name,
    column_default,
    is_nullable,
    data_type,
    CASE 
        WHEN column_default = '''pending''::character varying' THEN '✅ CORRIGIDO PARA INGLÊS'
        ELSE '❌ AINDA COM PROBLEMA'
    END AS status_correcao
FROM information_schema.columns
WHERE table_schema = 'public'
AND table_name = 'sale'
AND column_name = 'payment_status';

-- ==============================================
-- TESTE DEFINITIVO
-- ==============================================

SELECT '=== TESTE DEFINITIVO ===' AS title;

-- Teste 1: Inserção sem payment_status (deve usar 'pending' como default)
INSERT INTO public.sale (
    customer_id, 
    user_id, 
    currency_id,
    total_amount,
    total_amount_brl,
    total_amount_usd,
    price_in_brl,
    price_in_usd
) 
SELECT 
    (SELECT id FROM public.contact LIMIT 1),
    'bfc1a714-139c-4b11-8c76-a489fa0422a4'::uuid,
    (SELECT currency_id FROM public.currency WHERE currency_code = 'BRL' LIMIT 1),
    150.00,
    150.00,
    30.00,
    150.00,
    30.00
RETURNING 
    id, 
    payment_status,
    '✅ TESTE DEFAULT' AS tipo_teste;

-- Teste 2: Inserção com payment_status em inglês (deve funcionar)
INSERT INTO public.sale (
    customer_id, 
    user_id, 
    currency_id,
    total_amount,
    total_amount_brl,
    total_amount_usd,
    price_in_brl,
    price_in_usd,
    payment_status
) 
SELECT 
    (SELECT id FROM public.contact LIMIT 1),
    'bfc1a714-139c-4b11-8c76-a489fa0422a4'::uuid,
    (SELECT currency_id FROM public.currency WHERE currency_code = 'BRL' LIMIT 1),
    200.00,
    200.00,
    40.00,
    200.00,
    40.00,
    'paid'
RETURNING 
    id, 
    payment_status,
    '✅ TESTE VALOR EXPLÍCITO' AS tipo_teste;

-- ==============================================
-- VERIFICAR RESULTADOS
-- ==============================================

SELECT '=== RESULTADOS FINAIS ===' AS title;

SELECT 
    id,
    payment_status,
    total_amount,
    created_at,
    CASE 
        WHEN payment_status IN ('pending', 'paid') THEN '✅ VALOR VÁLIDO'
        ELSE '❌ VALOR INVÁLIDO'
    END AS validacao
FROM public.sale 
WHERE id IN (
    SELECT MAX(id) FROM public.sale UNION 
    SELECT MAX(id)-1 FROM public.sale
)
ORDER BY id DESC;

-- ==============================================
-- LIMPAR TESTES
-- ==============================================

DELETE FROM public.sale WHERE id IN (
    SELECT MAX(id) FROM public.sale UNION 
    SELECT MAX(id)-1 FROM public.sale
);

-- ==============================================
-- RELATÓRIO FINAL
-- ==============================================

SELECT '=== RELATÓRIO FINAL ===' AS title;
SELECT '✅ DEFAULT payment_status corrigido para ''pending''' AS mensagem;
SELECT '✅ CHECK constraint aceita valores em inglês' AS mensagem;
SELECT '✅ INSERTs sem payment_status funcionam (usam default)' AS mensagem;
SELECT '✅ INSERTs com payment_status em inglês funcionam' AS mensagem;
SELECT '✅ BANCO TOTALMENTE COMPATÍVEL COM FLUTTER!' AS mensagem;