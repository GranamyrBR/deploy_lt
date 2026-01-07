-- 🔄 Script de limpeza FINAL - baseado na estrutura real
-- Execute este script para corrigir os dados antes das constraints

-- ==============================================
-- ANÁLISE INICIAL - Verificar problemas existentes
-- ==============================================

SELECT '=== RELATÓRIO DE DADOS PROBLEMÁTICOS ===' AS report_title;

-- Vendas sem cliente (customer_id)
SELECT 
    'Vendas sem cliente' AS problema,
    COUNT(*) AS quantidade,
    string_agg(id::TEXT, ', ') AS ids_afetados
FROM public.sale 
WHERE customer_id IS NULL;

-- Vendas sem usuário (user_id) 
SELECT 
    'Vendas sem usuário' AS problema,
    COUNT(*) AS quantidade,
    string_agg(id::TEXT, ', ') AS ids_afetados
FROM public.sale 
WHERE user_id IS NULL;

-- Vendas sem moeda (currency_id)
SELECT 
    'Vendas sem moeda' AS problema,
    COUNT(*) AS quantidade,
    string_agg(id::TEXT, ', ') AS ids_afetados
FROM public.sale 
WHERE currency_id IS NULL;

-- Itens de venda sem serviço (service_id)
SELECT 
    'Itens de venda sem serviço' AS problema,
    COUNT(*) AS quantidade,
    string_agg(sales_item_id::TEXT, ', ') AS ids_afetados
FROM public.sale_item 
WHERE service_id IS NULL;

-- ==============================================
-- CORREÇÃO DE DADOS - Estratégias de limpeza
-- ==============================================

DO $$
DECLARE
    default_contact_id INTEGER;
    default_user_id UUID;
    default_currency_id INTEGER;
    default_service_id INTEGER;
    rows_affected INTEGER;
BEGIN
    RAISE NOTICE 'Iniciando correção de dados...';
    
    -- Obter contato padrão (primeiro contato existente)
    SELECT id INTO default_contact_id FROM public.contact LIMIT 1;
    
    IF default_contact_id IS NULL THEN
        RAISE WARNING 'Nenhum contato encontrado no sistema. Criando contato padrão...';
        
        -- Criar contato padrão
        INSERT INTO public.contact (name, email, phone, created_at, updated_at)
        VALUES ('Cliente Padrão (Sistema)', 'cliente.padrao@sistema.com', '+5511999999999', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
        RETURNING id INTO default_contact_id;
        
        RAISE NOTICE 'Contato padrão criado com ID: %', default_contact_id;
    ELSE
        RAISE NOTICE 'Usando contato existente ID: %', default_contact_id;
    END IF;
    
    -- Obter usuário padrão (primeiro usuário admin ou qualquer usuário)
    SELECT id INTO default_user_id FROM public.user WHERE role = 'admin' LIMIT 1;
    
    IF default_user_id IS NULL THEN
        -- Se não houver usuário admin, usar o primeiro usuário existente
        SELECT id INTO default_user_id FROM public.user LIMIT 1;
    END IF;
    
    IF default_user_id IS NULL THEN
        RAISE WARNING 'Nenhum usuário encontrado no sistema. Correções de user_id serão ignoradas.';
    ELSE
        RAISE NOTICE 'Usando usuário ID: %', default_user_id;
    END IF;
    
    -- Obter moeda padrão (BRL) ou criar se não existir
    SELECT currency_id INTO default_currency_id FROM public.currency WHERE currency_code = 'BRL' LIMIT 1;
    
    IF default_currency_id IS NULL THEN
        INSERT INTO public.currency (currency_code, currency_name, symbol)
        VALUES ('BRL', 'Brazilian Real', 'R$')
        RETURNING currency_id INTO default_currency_id;
        RAISE NOTICE 'Moeda BRL criada com ID: %', default_currency_id;
    ELSE
        RAISE NOTICE 'Usando moeda BRL ID: %', default_currency_id;
    END IF;
    
    -- Obter serviço padrão ou criar se não existir
    SELECT id INTO default_service_id FROM public.service LIMIT 1;
    
    IF default_service_id IS NULL THEN
        -- Criar serviço padrão
        INSERT INTO public.service (name, description, price, created_at, updated_at)
        VALUES ('Serviço Padrão', 'Serviço padrão do sistema', 0.00, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
        RETURNING id INTO default_service_id;
        
        RAISE NOTICE 'Serviço padrão criado com ID: %', default_service_id;
    ELSE
        RAISE NOTICE 'Usando serviço existente ID: %', default_service_id;
    END IF;
    
    -- Aplicar correções apenas com IDs válidos
    IF default_contact_id IS NOT NULL THEN
        -- Corrigir vendas sem cliente
        UPDATE public.sale 
        SET customer_id = default_contact_id 
        WHERE customer_id IS NULL;
        
        GET DIAGNOSTICS rows_affected = ROW_COUNT;
        RAISE NOTICE 'Corrigidas % vendas sem cliente', rows_affected;
    END IF;
    
    -- Corrigir vendas sem usuário (apenas se tivermos um usuário válido)
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
    
    RAISE NOTICE 'Processo de correção concluído!';
    
END $$;

-- ==============================================
-- VERIFICAÇÃO FINAL - Confirmar que dados estão consistentes
-- ==============================================

SELECT '=== VERIFICAÇÃO FINAL APÓS CORREÇÕES ===' AS verification_title;

-- Verificar se ainda existem dados problemáticos
SELECT 
    CASE 
        WHEN COUNT(*) = 0 THEN '✅ NENHUMA venda sem cliente'
        ELSE '❌ Ainda existem ' || COUNT(*) || ' vendas sem cliente'
    END AS status,
    COUNT(*) AS quantidade
FROM public.sale 
WHERE customer_id IS NULL;

SELECT 
    CASE 
        WHEN COUNT(*) = 0 THEN '✅ NENHUMA venda sem usuário'
        ELSE '❌ Ainda existem ' || COUNT(*) || ' vendas sem usuário'
    END AS status,
    COUNT(*) AS quantidade
FROM public.sale 
WHERE user_id IS NULL;

SELECT 
    CASE 
        WHEN COUNT(*) = 0 THEN '✅ NENHUMA venda sem moeda'
        ELSE '❌ Ainda existem ' || COUNT(*) || ' vendas sem moeda'
    END AS status,
    COUNT(*) AS quantidade
FROM public.sale 
WHERE currency_id IS NULL;

SELECT 
    CASE 
        WHEN COUNT(*) = 0 THEN '✅ NENHUM item de venda sem serviço'
        ELSE '❌ Ainda existem ' || COUNT(*) || ' itens sem serviço'
    END AS status,
    COUNT(*) AS quantidade
FROM public.sale_item 
WHERE service_id IS NULL;

-- Estatísticas finais
SELECT 
    '=== ESTATÍSTICAS FINAIS ===' AS title;

SELECT 
    'Total de vendas: ' || COUNT(*) AS info
FROM public.sale;

SELECT 
    'Total de itens de venda: ' || COUNT(*) AS info
FROM public.sale_item;

SELECT 
    'Total de contatos: ' || COUNT(*) AS info  
FROM public.contact;

SELECT 
    'Total de usuários: ' || COUNT(*) AS info
FROM public.user;

SELECT 
    'Total de moedas: ' || COUNT(*) AS info
FROM public.currency;

SELECT 
    'Total de serviços: ' || COUNT(*) AS info
FROM public.service;

SELECT '=== PROCESSO DE LIMPEZA CONCLUÍDO ===' AS final_message;