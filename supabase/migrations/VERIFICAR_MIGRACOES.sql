-- 🔍 VERIFICAÇÃO DO STATUS DAS MIGRAÇÕES
-- Execute estas queries para confirmar o estado do banco

-- 1. Verificar se as tabelas têm os campos audit
SELECT table_name, column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND column_name IN ('created_at', 'updated_at', 'created_by', 'updated_by')
ORDER BY table_name, column_name;

-- 2. Verificar constraints NOT NULL aplicadas
SELECT table_name, column_name, is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND is_nullable = 'NO'
AND table_name IN ('sale', 'sale_item', 'payment', 'contact', 'service')
ORDER BY table_name, column_name;

-- 3. Verificar foreign keys existentes
SELECT
    tc.table_name, 
    kcu.column_name, 
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name 
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
ORDER BY tc.table_name, kcu.column_name;

-- 4. Verificar se as views foram criadas
SELECT table_name 
FROM information_schema.views 
WHERE table_schema = 'public'
AND table_name LIKE 'v_%';

-- 5. Verificar dados críticos (exemplo)
SELECT 
    'sale' as tabela,
    COUNT(*) as total_registros,
    COUNT(created_at) as com_created_at,
    COUNT(updated_at) as com_updated_at,
    COUNT(created_by) as com_created_by,
    COUNT(user_id) as com_user_id,
    COUNT(customer_id) as com_customer_id,
    COUNT(currency_id) as com_currency_id
FROM sale
UNION ALL
SELECT 
    'sale_item' as tabela,
    COUNT(*) as total_registros,
    COUNT(created_at) as com_created_at,
    COUNT(updated_at) as com_updated_at,
    COUNT(created_by) as com_created_by,
    0 as com_user_id,
    COUNT(service_id) as com_service_id,
    0 as com_currency_id
FROM sale_item;

-- 6. Verificar usuários e permissões
SELECT 
    grantee,
    table_name,
    privilege_type 
FROM information_schema.role_table_grants 
WHERE table_schema = 'public' 
AND grantee IN ('anon', 'authenticated')
ORDER BY table_name, grantee;