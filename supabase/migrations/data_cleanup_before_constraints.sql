-- Script de limpeza de dados para preparar aplicação de constraints NOT NULL
-- Este script identifica e corrige dados inconsistentes antes das alterações de schema

-- ==============================================
-- ANÁLISE INICIAL - Verificar problemas existentes
-- ==============================================

-- Relatório de dados problemáticos
SELECT '=== RELATÓRIO DE DADOS PROBLEMÁTICOS ===' AS report_title;

-- Vendas sem cliente
SELECT 
    'Vendas sem cliente' AS problema,
    COUNT(*) AS quantidade,
    string_agg(id::TEXT, ', ') AS ids_afetados
FROM public.sale 
WHERE customer_id IS NULL;

-- Vendas sem usuário
SELECT 
    'Vendas sem usuário' AS problema,
    COUNT(*) AS quantidade,
    string_agg(id::TEXT, ', ') AS ids_afetados
FROM public.sale 
WHERE user_id IS NULL;

-- Vendas sem moeda
SELECT 
    'Vendas sem moeda' AS problema,
    COUNT(*) AS quantidade,
    string_agg(id::TEXT, ', ') AS ids_afetados
FROM public.sale 
WHERE currency_id IS NULL;

-- Itens de venda sem serviço
SELECT 
    'Itens de venda sem serviço' AS problema,
    COUNT(*) AS quantidade,
    string_agg(sales_item_id::TEXT, ', ') AS ids_afetados
FROM public.sale_item 
WHERE service_id IS NULL;

-- Faturas sem venda vinculada
SELECT 
    'Faturas sem venda vinculada' AS problema,
    COUNT(*) AS quantidade,
    string_agg(id::TEXT, ', ') AS ids_afetados
FROM public.invoice 
WHERE sale_id IS NULL;

-- ==============================================
-- CORREÇÃO DE DADOS - Estratégias de limpeza
-- ==============================================

-- Opção 1: Criar registros padrão para referências obrigatórias
DO $$
DECLARE
    default_contact_id INTEGER;
    default_user_id UUID;
    default_currency_id INTEGER;
    default_service_id INTEGER;
    rows_affected INTEGER;
BEGIN
    -- Obter ou criar contato padrão
    SELECT id INTO default_contact_id FROM public.contact WHERE phone = '+5511999999999' LIMIT 1;
    
    IF default_contact_id IS NULL THEN
        -- Tentar criar contato padrão
        BEGIN
            INSERT INTO public.contact (name, email, phone, created_at, updated_at)
            VALUES ('Cliente Padrão (Sistema)', 'cliente.padrao@sistema.com', '+5511999999999', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
            RETURNING id INTO default_contact_id;
        EXCEPTION
            WHEN OTHERS THEN
                -- Se houver algum erro, usar o primeiro contato existente
                SELECT id INTO default_contact_id FROM public.contact LIMIT 1;
                IF default_contact_id IS NULL THEN
                    RAISE WARNING 'Nenhum contato encontrado no sistema.';
                    default_contact_id := NULL; -- Será tratado posteriormente
                END IF;
        END;
    END IF;
    
    -- Obter usuário padrão (primeiro usuário admin encontrado ou criar um usuário básico)
    SELECT id INTO default_user_id FROM public.user WHERE role = 'admin' LIMIT 1;
    
    IF default_user_id IS NULL THEN
        -- Se não houver usuário admin, usar o primeiro usuário existente
        SELECT id INTO default_user_id FROM public.user LIMIT 1;
    END IF;
    
    IF default_user_id IS NULL THEN
        RAISE WARNING 'Nenhum usuário encontrado no sistema. Será necessário criar um usuário manualmente.';
        -- Usar um UUID padrão temporário (será necessário ajustar manualmente depois)
        default_user_id := '00000000-0000-0000-0000-000000000000'::uuid;
    END IF;
    
    -- Obter moeda padrão (BRL)
    SELECT currency_id INTO default_currency_id FROM public.currency WHERE currency_code = 'BRL' LIMIT 1;
    IF default_currency_id IS NULL THEN
        INSERT INTO public.currency (currency_code, currency_name, symbol)
        VALUES ('BRL', 'Brazilian Real', 'R$')
        RETURNING currency_id INTO default_currency_id;
    END IF;
    
    -- Obter ou criar serviço padrão
    SELECT id INTO default_service_id FROM public.service WHERE name = 'Serviço Padrão' LIMIT 1;
    
    IF default_service_id IS NULL THEN
        -- Tentar criar serviço padrão
        BEGIN
            INSERT INTO public.service (name, description, price, created_at, updated_at)
            VALUES ('Serviço Padrão', 'Serviço padrão do sistema', 0.00, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
            RETURNING id INTO default_service_id;
        EXCEPTION
            WHEN OTHERS THEN
                -- Se houver algum erro, usar o primeiro serviço existente
                SELECT id INTO default_service_id FROM public.service LIMIT 1;
                IF default_service_id IS NULL THEN
                    RAISE WARNING 'Nenhum serviço encontrado no sistema.';
                    default_service_id := 1; -- Valor padrão seguro
                END IF;
        END;
    END IF;
    
    -- Verificar se temos IDs válidos antes de aplicar correções
    IF default_contact_id IS NULL THEN
        RAISE WARNING 'Nenhum contato válido encontrado. Pulando correção de vendas sem cliente.';
    ELSE
        RAISE NOTICE 'Contato padrão: %', default_contact_id;
    END IF;
    
    IF default_user_id IS NULL THEN
        RAISE WARNING 'Nenhum usuário válido encontrado. Pulando correção de vendas sem usuário.';
    ELSE
        RAISE NOTICE 'Usuário padrão: %', default_user_id;
    END IF;
    
    RAISE NOTICE 'Moeda padrão: %', default_currency_id;
    RAISE NOTICE 'Serviço padrão: %', default_service_id;
    
    -- Aplicar correções apenas com IDs válidos
    IF default_contact_id IS NOT NULL THEN
        -- Corrigir vendas sem cliente
        UPDATE public.sale 
        SET customer_id = default_contact_id 
        WHERE customer_id IS NULL;
        
        GET DIAGNOSTICS rows_affected = ROW_COUNT;
        RAISE NOTICE 'Corrigidas % vendas sem cliente', rows_affected;
    END IF;
    
    -- Corrigir vendas sem usuário
    IF default_user_id IS NOT NULL THEN
        UPDATE public.sale 
        SET user_id = default_user_id 
        WHERE user_id IS NULL;
        
        GET DIAGNOSTICS rows_affected = ROW_COUNT;
        RAISE NOTICE 'Corrigidas % vendas sem usuário', rows_affected;
    END IF;
    
    -- Corrigir vendas sem moeda
    UPDATE public.sale 
    SET currency_id = default_currency_id 
    WHERE currency_id IS NULL;
    
    GET DIAGNOSTICS rows_affected = ROW_COUNT;
    RAISE NOTICE 'Corrigidas % vendas sem moeda', rows_affected;
    
    -- Corrigir itens de venda sem serviço
    IF default_service_id IS NOT NULL THEN
        UPDATE public.sale_item 
        SET service_id = default_service_id 
        WHERE service_id IS NULL;
        
        GET DIAGNOSTICS rows_affected = ROW_COUNT;
        RAISE NOTICE 'Corrigidos % itens de venda sem serviço', rows_affected;
    END IF;
    
END $$;

-- ==============================================
-- OPÇÃO 2: Excluir registros inválidos (se preferível)
-- DESCOMENTE ESTA SEÇÃO SE PREFERIR EXCLUIR AO INVÉS DE CRIAR PADRÕES
-- ==============================================

-- DELETE FROM public.sale WHERE customer_id IS NULL OR user_id IS NULL OR currency_id IS NULL;
-- DELETE FROM public.sale_item WHERE service_id IS NULL;
-- DELETE FROM public.invoice WHERE sale_id IS NULL;

-- ==============================================
-- VERIFICAÇÃO FINAL - Confirmar que dados estão consistentes
-- ==============================================

SELECT '=== VERIFICAÇÃO FINAL APÓS CORREÇÕES ===' AS verification_title;

-- Verificar se ainda existem dados problemáticos
SELECT 
    'Vendas sem cliente (pós-correção)' AS problema,
    COUNT(*) AS quantidade
FROM public.sale 
WHERE customer_id IS NULL;

SELECT 
    'Vendas sem usuário (pós-correção)' AS problema,
    COUNT(*) AS quantidade
FROM public.sale 
WHERE user_id IS NULL;

SELECT 
    'Vendas sem moeda (pós-correção)' AS problema,
    COUNT(*) AS quantidade
FROM public.sale 
WHERE currency_id IS NULL;

SELECT 
    'Itens de venda sem serviço (pós-correção)' AS problema,
    COUNT(*) AS quantidade
FROM public.sale_item 
WHERE service_id IS NULL;

-- ==============================================
-- ESTATÍSTICAS FINAIS
-- ==============================================

SELECT 
    'Total de vendas' AS estatistica,
    COUNT(*) AS valor
FROM public.sale;

SELECT 
    'Total de itens de venda' AS estatistica,
    COUNT(*) AS valor
FROM public.sale_item;

SELECT 
    'Total de faturas' AS estatistica,
    COUNT(*) AS valor
FROM public.invoice;

-- Mensagem final
SELECT '=== PROCESSO DE LIMPEZA CONCLUÍDO ===' AS final_message;