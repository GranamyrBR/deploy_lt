-- 🔍 Verificar estrutura atual das tabelas críticas

-- Verificar tipos de dados das colunas
SELECT 
    table_name,
    column_name,
    data_type,
    udt_name,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name IN ('sale', 'sale_item', 'user', 'contact')
ORDER BY table_name, ordinal_position;

-- Verificar se user.id é UUID
SELECT 
    table_name,
    column_name,
    data_type,
    udt_name
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'user' 
AND column_name = 'id';

-- Verificar se sale.user_id é UUID
SELECT 
    table_name,
    column_name,
    data_type,
    udt_name
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'sale' 
AND column_name = 'user_id';