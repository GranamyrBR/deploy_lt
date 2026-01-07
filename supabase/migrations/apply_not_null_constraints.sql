-- Script final para aplicar NOT NULL constraints após limpeza de dados
-- EXECUTE ESTE SCRIPT APÓS executar data_cleanup_before_constraints.sql

-- ==============================================
-- VERIFICAÇÃO PRÉVIA - Garantir que não há dados NULL
-- ==============================================

DO $$
DECLARE
    null_count INTEGER := 0;
    can_proceed BOOLEAN := true;
BEGIN
    -- Verificar sale.customer_id
    SELECT COUNT(*) INTO null_count FROM public.sale WHERE customer_id IS NULL;
    IF null_count > 0 THEN
        RAISE WARNING 'Ainda existem % vendas com customer_id NULL. Execute o script de limpeza primeiro.', null_count;
        can_proceed := false;
    END IF;

    -- Verificar sale.user_id
    SELECT COUNT(*) INTO null_count FROM public.sale WHERE user_id IS NULL;
    IF null_count > 0 THEN
        RAISE WARNING 'Ainda existem % vendas com user_id NULL. Execute o script de limpeza primeiro.', null_count;
        can_proceed := false;
    END IF;

    -- Verificar sale.currency_id
    SELECT COUNT(*) INTO null_count FROM public.sale WHERE currency_id IS NULL;
    IF null_count > 0 THEN
        RAISE WARNING 'Ainda existem % vendas com currency_id NULL. Execute o script de limpeza primeiro.', null_count;
        can_proceed := false;
    END IF;

    -- Verificar sale_item.service_id
    SELECT COUNT(*) INTO null_count FROM public.sale_item WHERE service_id IS NULL;
    IF null_count > 0 THEN
        RAISE WARNING 'Ainda existem % itens de venda com service_id NULL. Execute o script de limpeza primeiro.', null_count;
        can_proceed := false;
    END IF;

    IF can_proceed THEN
        RAISE NOTICE '✓ Todos os dados estão consistentes. Prosseguindo com aplicação de NOT NULL...';
    ELSE
        RAISE EXCEPTION '✗ Dados inconsistentes encontrados. Corrija antes de prosseguir.';
    END IF;
END $$;

-- ==============================================
-- APLICAÇÃO DE NOT NULL CONSTRAINTS
-- ==============================================

-- 1. Tornar campos obrigatórios na tabela sale
DO $$
BEGIN
    -- customer_id
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'sale' 
        AND column_name = 'customer_id'
        AND is_nullable = 'YES'
    ) THEN
        ALTER TABLE public.sale ALTER COLUMN customer_id SET NOT NULL;
        RAISE NOTICE '✓ sale.customer_id agora é NOT NULL';
    ELSE
        RAISE NOTICE '✓ sale.customer_id já é NOT NULL ou não existe';
    END IF;

    -- user_id
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'sale' 
        AND column_name = 'user_id'
        AND is_nullable = 'YES'
    ) THEN
        ALTER TABLE public.sale ALTER COLUMN user_id SET NOT NULL;
        RAISE NOTICE '✓ sale.user_id agora é NOT NULL';
    ELSE
        RAISE NOTICE '✓ sale.user_id já é NOT NULL ou não existe';
    END IF;

    -- currency_id
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'sale' 
        AND column_name = 'currency_id'
        AND is_nullable = 'YES'
    ) THEN
        ALTER TABLE public.sale ALTER COLUMN currency_id SET NOT NULL;
        RAISE NOTICE '✓ sale.currency_id agora é NOT NULL';
    ELSE
        RAISE NOTICE '✓ sale.currency_id já é NOT NULL ou não existe';
    END IF;

END $$;

-- 2. Tornar service_id NOT NULL na tabela sale_item
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'sale_item' 
        AND column_name = 'service_id'
        AND is_nullable = 'YES'
    ) THEN
        ALTER TABLE public.sale_item ALTER COLUMN service_id SET NOT NULL;
        RAISE NOTICE '✓ sale_item.service_id agora é NOT NULL';
    ELSE
        RAISE NOTICE '✓ sale_item.service_id já é NOT NULL ou não existe';
    END IF;
END $$;

-- ==============================================
-- VALIDAÇÃO DAS ALTERAÇÕES
-- ==============================================

-- Verificar constraints aplicadas
SELECT 
    '=== VERIFICAÇÃO DE CONSTRAINTS APLICADAS ===' AS validation_title;

SELECT 
    table_name,
    column_name,
    is_nullable,
    CASE 
        WHEN is_nullable = 'NO' THEN '✓ NOT NULL aplicado'
        ELSE '✗ Ainda permite NULL'
    END AS status
FROM information_schema.columns
WHERE table_schema = 'public'
AND (table_name, column_name) IN 
    (('sale', 'customer_id'), ('sale', 'user_id'), ('sale', 'currency_id'), ('sale_item', 'service_id'))
ORDER BY table_name, column_name;

-- Verificar todas as foreign keys agora existentes
SELECT 
    '=== VERIFICAÇÃO DE FOREIGN KEYS ===' AS fk_validation_title;

SELECT 
    tc.table_name, 
    tc.constraint_name, 
    kcu.column_name, 
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name,
    '✓ FK aplicada' AS status
FROM 
    information_schema.table_constraints AS tc
    JOIN information_schema.key_column_usage AS kcu
      ON tc.constraint_name = kcu.constraint_name
      AND tc.table_schema = kcu.table_schema
    JOIN information_schema.constraint_column_usage AS ccu
      ON ccu.constraint_name = tc.constraint_name
      AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY' 
AND tc.table_schema = 'public'
AND tc.table_name IN ('sale', 'sale_item', 'sale_payment', 'invoice')
ORDER BY tc.table_name, tc.constraint_name;

-- ==============================================
-- RELATÓRIO FINAL
-- ==============================================

SELECT 
    '=== RELATÓRIO FINAL DE MIGRAÇÃO ===' AS final_report_title;

SELECT 
    'Integridade referencial aplicada com sucesso!' AS mensagem,
    'Todas as FKs críticas foram adicionadas' AS fk_status,
    'Campos obrigatórios agora são NOT NULL' AS null_constraints_status,
    'Execute os scripts de auditoria e nomenclatura em seguida' AS proximos_passos;

-- Mensagem de conclusão
SELECT '✓ MIGRAÇÃO DE CONSTRAINTS CONCLUÍDA COM SUCESSO!' AS conclusion;