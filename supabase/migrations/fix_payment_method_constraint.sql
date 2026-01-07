-- =====================================================
-- CORREÇÃO DA FOREIGN KEY PAYMENT_METHOD
-- =====================================================
-- 
-- PROBLEMA IDENTIFICADO:
-- A tabela sale_payment não possui foreign key para payment_method,
-- causando erro: "Could not find a relationship between 'sale_payment' 
-- and 'payment_method' in the schema cache"

-- =====================================================
-- 1. VERIFICAR SE A CONSTRAINT JÁ EXISTE
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
    AND tc.table_name = 'sale_payment'
    AND kcu.column_name = 'payment_method_id';

-- =====================================================
-- 2. VERIFICAR SE EXISTEM DADOS ÓRFÃOS
-- =====================================================

-- Verificar se há pagamentos com payment_method_id que não existem na tabela payment_method
SELECT 
    sp.payment_id,
    sp.payment_method_id,
    'ÓRFÃO - payment_method não existe' as problema
FROM sale_payment sp
LEFT JOIN payment_method pm ON sp.payment_method_id = pm.payment_method_id
WHERE pm.payment_method_id IS NULL;

-- =====================================================
-- 3. CORRIGIR DADOS ÓRFÃOS (SE EXISTIREM)
-- =====================================================

-- Atualizar pagamentos órfãos para usar método padrão (ID 1 = PIX)
UPDATE sale_payment 
SET payment_method_id = 1
WHERE payment_method_id NOT IN (
    SELECT payment_method_id FROM payment_method
);

-- =====================================================
-- 4. ADICIONAR A FOREIGN KEY
-- =====================================================

-- Remover a constraint se ela existir (para recriar corretamente)
ALTER TABLE public.sale_payment 
DROP CONSTRAINT IF EXISTS sale_payment_payment_method_id_fkey;

-- Adicionar a constraint corretamente
ALTER TABLE public.sale_payment 
ADD CONSTRAINT sale_payment_payment_method_id_fkey 
FOREIGN KEY (payment_method_id) 
REFERENCES public.payment_method(payment_method_id);

-- =====================================================
-- 5. VERIFICAR SE A CONSTRAINT FOI CRIADA
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
    AND tc.table_name = 'sale_payment'
    AND kcu.column_name = 'payment_method_id';

-- =====================================================
-- 6. TESTAR O RELACIONAMENTO
-- =====================================================

-- Testar se o relacionamento funciona
SELECT 
    sp.payment_id,
    sp.sales_id,
    sp.amount,
    pm.method_name as payment_method_name
FROM sale_payment sp
JOIN payment_method pm ON sp.payment_method_id = pm.payment_method_id
LIMIT 5;

SELECT '✅ Foreign key payment_method adicionada com sucesso!' as status;