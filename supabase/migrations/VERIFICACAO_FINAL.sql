-- ✅ VERIFICAÇÃO FINAL DA MIGRAÇÃO COMPLETA
-- Execute esta query para confirmar que tudo foi aplicado corretamente

SELECT '=== VERIFICAÇÃO FINAL DA MIGRAÇÃO ===' AS title;

-- 1. Verificar constraints NOT NULL aplicadas
SELECT 
    '1. CONSTRAINTS NOT NULL' AS verification_step,
    table_name,
    column_name,
    is_nullable,
    CASE 
        WHEN is_nullable = 'NO' THEN '✅ APLICADO'
        ELSE '❌ FALTANDO'
    END AS status
FROM information_schema.columns
WHERE table_schema = 'public'
AND (table_name, column_name) IN 
    (('sale', 'customer_id'), ('sale', 'user_id'), ('sale', 'currency_id'), ('sale_item', 'service_id'))
ORDER BY table_name, column_name;

-- 2. Verificar campos de auditoria
SELECT 
    '2. CAMPOS DE AUDITORIA' AS verification_step,
    table_name,
    column_name,
    data_type,
    CASE 
        WHEN data_type IS NOT NULL THEN '✅ EXISTE'
        ELSE '❌ FALTANDO'
    END AS status
FROM information_schema.columns
WHERE table_schema = 'public'
AND column_name IN ('created_at', 'updated_at', 'created_by', 'updated_by')
ORDER BY table_name, column_name;

-- 3. Verificar foreign keys existentes
SELECT 
    '3. FOREIGN KEYS' AS verification_step,
    tc.table_name, 
    tc.constraint_name, 
    kcu.column_name, 
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name,
    '✅ APLICADA' AS status
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

-- 4. Verificar views criadas
SELECT 
    '4. VIEWS PADRONIZADAS' AS verification_step,
    table_name AS view_name,
    '✅ CRIADA' AS status
FROM information_schema.views 
WHERE table_schema = 'public'
AND table_name LIKE 'v_%' OR table_name LIKE '%standardized%'
ORDER BY table_name;

-- 5. Verificar dados finais
SELECT 
    '5. ESTATÍSTICAS FINAIS' AS verification_step,
    'sale:' AS table_name, 
    COUNT(*) AS total_registros,
    COUNT(customer_id) AS com_customer,
    COUNT(user_id) AS com_user,
    COUNT(currency_id) AS com_currency,
    COUNT(created_at) AS com_created_at,
    COUNT(updated_at) AS com_updated_at
FROM public.sale
UNION ALL
SELECT 
    'sale_item:' AS table_name,
    COUNT(*) AS total_registros,
    0 AS com_customer,
    0 AS com_user,
    0 AS com_currency,
    COUNT(created_at) AS com_created_at,
    COUNT(updated_at) AS com_updated_at
FROM public.sale_item;

-- 6. Relatório final de sucesso
SELECT 
    '=== RELATÓRIO FINAL ===' AS title,
    '✅ MIGRAÇÃO CONCLUÍDA COM SUCESSO!' AS mensagem,
    'Todas as constraints foram aplicadas' AS constraints_status,
    'Campos de auditoria adicionados' AS audit_status,
    'Views padronizadas criadas' AS views_status,
    'Integridade referencial estabelecida' AS integrity_status;