-- 🔧 CORREÇÃO DA INCOERÊNCIA NO PAYMENT_STATUS
-- O arquivo DB_schema_public.sql foi atualizado com uma incoerência:
-- DEFAULT: 'Pendente' (português) 
-- CHECK: ['pending', 'partial', 'paid', 'overdue', 'refunded'] (inglês)

-- ==============================================
-- OPÇÃO 1: MUDAR O DEFAULT PARA INGLÊS (Recomendado - compatível com Flutter)
-- ==============================================

-- Verificar situação atual
SELECT 
    '=== SITUAÇÃO ATUAL DE PAYMENT_STATUS ===' AS title;

SELECT 
    column_name,
    column_default,
    is_nullable,
    data_type
FROM information_schema.columns
WHERE table_schema = 'public'
AND table_name = 'sale'
AND column_name = 'payment_status';

-- Verificar valores atuais na tabela
SELECT 
    payment_status,
    COUNT(*) as quantidade,
    CASE 
        WHEN payment_status IN ('pending', 'partial', 'paid', 'overdue', 'refunded') THEN '✅ INGLÊS (válido)'
        WHEN payment_status IN ('Pendente', 'Parcial', 'Pago', 'Vencido', 'Reembolsado') THEN '❌ PORTUGUÊS (inválido)'
        ELSE '🤔 OUTRO'
    END AS status
FROM public.sale
WHERE payment_status IS NOT NULL
GROUP BY payment_status
ORDER BY quantidade DESC;

-- ==============================================
-- CORREÇÃO: ALTERAR DEFAULT PARA INGLÊS
-- ==============================================

-- Remover a constraint atual com problema
ALTER TABLE public.sale ALTER COLUMN payment_status DROP DEFAULT;

-- Adicionar default em inglês (compatível com Flutter)
ALTER TABLE public.sale 
ALTER COLUMN payment_status 
SET DEFAULT 'pending'::character varying;

-- ==============================================
-- VERIFICAÇÃO APÓS CORREÇÃO
-- ==============================================

SELECT 
    '=== APÓS CORREÇÃO ===' AS title;

SELECT 
    column_name,
    column_default,
    is_nullable,
    data_type
FROM information_schema.columns
WHERE table_schema = 'public'
AND table_name = 'sale'
AND column_name = 'payment_status';

-- Testar inserção com valor padrão
SELECT '=== TESTANDO INSERÇÃO COM VALOR PADRÃO ===' AS title;

-- Teste 1: Inserção sem especificar payment_status (deve usar 'pending')
INSERT INTO public.sale (customer_id, user_id, currency_id, total_amount_brl) 
VALUES (1, '00000000-0000-0000-0000-000000000000', 1, 100.00) 
RETURNING id, payment_status;

-- Teste 2: Inserção com valor em inglês (deve funcionar)
INSERT INTO public.sale (customer_id, user_id, currency_id, total_amount_brl, payment_status) 
VALUES (1, '00000000-0000-0000-0000-000000000000', 1, 200.00, 'paid') 
RETURNING id, payment_status;

-- Verificar se as inserções funcionaram
SELECT 
    id,
    payment_status,
    '✅ INSERÇÃO FUNCIONOU' AS status
FROM public.sale 
WHERE id IN (SELECT MAX(id) FROM public.sale UNION SELECT MAX(id)-1 FROM public.sale)
ORDER BY id DESC;

-- Limpar testes
DELETE FROM public.sale 
WHERE id IN (SELECT MAX(id) FROM public.sale UNION SELECT MAX(id)-1 FROM public.sale)
AND customer_id = 1;

SELECT '=== CORREÇÃO CONCLUÍDA ===' AS title;
SELECT '✅ DEFAULT agora é ''pending'' (inglês)' AS mensagem;
SELECT '✅ CHECK valida inglês: [pending, partial, paid, overdue, refunded]' AS mensagem;
SELECT '✅ COMPATÍVEL com código Flutter' AS mensagem;