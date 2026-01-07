-- 🔍 Verificar estrutura completa das tabelas críticas
-- Execute esta query para entender a estrutura atual do banco

SELECT '=== ESTRUTURA DAS TABELAS CRÍTICAS ===' AS title;

-- Estrutura da tabela sale
SELECT 
    'TABELA: sale' AS table_info,
    column_name,
    data_type || '(' || udt_name || ')' AS type_info,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' AND table_name = 'sale'
ORDER BY ordinal_position;

-- Estrutura da tabela sale_item  
SELECT 
    'TABELA: sale_item' AS table_info,
    column_name,
    data_type || '(' || udt_name || ')' AS type_info,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' AND table_name = 'sale_item'
ORDER BY ordinal_position;

-- Estrutura da tabela contact
SELECT 
    'TABELA: contact' AS table_info,
    column_name,
    data_type || '(' || udt_name || ')' AS type_info,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' AND table_name = 'contact'
ORDER BY ordinal_position;

-- Estrutura da tabela user
SELECT 
    'TABELA: user' AS table_info,
    column_name,
    data_type || '(' || udt_name || ')' AS type_info,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' AND table_name = 'user'
ORDER BY ordinal_position;

-- Verificar constraints existentes
SELECT 
    'CONSTRAINTS EXISTENTES' AS title,
    tc.table_name,
    tc.constraint_name,
    tc.constraint_type,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints tc
LEFT JOIN information_schema.key_column_usage kcu 
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
LEFT JOIN information_schema.constraint_column_usage ccu 
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.table_schema = 'public'
AND tc.table_name IN ('sale', 'sale_item', 'contact', 'user')
ORDER BY tc.table_name, tc.constraint_name;

-- Verificar dados atuais
SELECT '=== DADOS ATUAIS ===' AS title;

SELECT 'sale:' AS table_name, COUNT(*) AS total FROM public.sale
UNION ALL
SELECT 'sale_item:' AS table_name, COUNT(*) AS total FROM public.sale_item  
UNION ALL
SELECT 'contact:' AS table_name, COUNT(*) AS total FROM public.contact
UNION ALL
SELECT 'user:' AS table_name, COUNT(*) AS total FROM public.user;