-- =====================================================
-- CORREÇÃO DA FOREIGN KEY SALE_ITEM_ID NA TABELA OPERATION
-- =====================================================
-- 
-- PROBLEMA IDENTIFICADO:
-- Possível inconsistência na foreign key entre operation.sale_item_id 
-- e sale_item.sales_item_id

-- =====================================================
-- 1. VERIFICAR SE A CONSTRAINT EXISTE E ESTÁ CORRETA
-- =====================================================

SELECT 
    tc.constraint_name,
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
    AND tc.table_name = 'operation'
    AND kcu.column_name = 'sale_item_id';

-- =====================================================
-- 2. VERIFICAR SE EXISTEM DADOS ÓRFÃOS
-- =====================================================

-- Verificar se há operações com sale_item_id que não existem na tabela sale_item
SELECT 
    o.id as operation_id,
    o.sale_item_id,
    'ÓRFÃO - sale_item não existe' as problema
FROM operation o
LEFT JOIN sale_item si ON o.sale_item_id = si.sales_item_id
WHERE o.sale_item_id IS NOT NULL 
    AND si.sales_item_id IS NULL;

-- =====================================================
-- 3. CORRIGIR DADOS ÓRFÃOS (SE EXISTIREM)
-- =====================================================

-- Opção 1: Definir sale_item_id como NULL para operações órfãs
-- (descomente se necessário)
-- UPDATE operation 
-- SET sale_item_id = NULL
-- WHERE sale_item_id NOT IN (
--     SELECT sales_item_id FROM sale_item WHERE sales_item_id IS NOT NULL
-- );

-- Opção 2: Deletar operações órfãs (CUIDADO - só use se tiver certeza)
-- DELETE FROM operation 
-- WHERE sale_item_id NOT IN (
--     SELECT sales_item_id FROM sale_item WHERE sales_item_id IS NOT NULL
-- );

-- =====================================================
-- 4. RECRIAR A FOREIGN KEY CORRETAMENTE
-- =====================================================

-- Remover a constraint existente
ALTER TABLE public.operation 
DROP CONSTRAINT IF EXISTS operation_sale_item_id_fkey;

-- Adicionar a constraint corretamente
ALTER TABLE public.operation 
ADD CONSTRAINT operation_sale_item_id_fkey 
FOREIGN KEY (sale_item_id) 
REFERENCES public.sale_item(sales_item_id);

-- =====================================================
-- 5. VERIFICAR SE A CONSTRAINT FOI CRIADA CORRETAMENTE
-- =====================================================

SELECT 
    tc.constraint_name,
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
    AND tc.table_name = 'operation'
    AND kcu.column_name = 'sale_item_id';

-- =====================================================
-- 6. TESTAR O RELACIONAMENTO
-- =====================================================

-- Testar se o relacionamento funciona
SELECT 
    o.id as operation_id,
    o.sale_item_id,
    si.sales_id,
    si.unit_price_at_sale,
    si.item_total
FROM operation o
JOIN sale_item si ON o.sale_item_id = si.sales_item_id
LIMIT 5;

SELECT '✅ Foreign key sale_item_id corrigida com sucesso!' as status;