-- 🔍 VERIFICAR CONSTRAINTS DE PAYMENT_STATUS
-- Verificar se ainda existe o conflito descrito no guia

SELECT '=== VERIFICANDO CONSTRAINTS DE PAYMENT_STATUS ===' AS title;

-- Verificar todas as constraints da tabela sale
SELECT 
    conname as constraint_name,
    contype as constraint_type,
    pg_get_constraintdef(c.oid) as constraint_definition,
    CASE 
        WHEN conname LIKE '%payment_status%' THEN '🎯 CONSTRAINT DE PAYMENT'
        ELSE '🔧 OUTRA CONSTRAINT'
    END AS tipo
FROM pg_constraint c
JOIN pg_namespace n ON n.oid = c.connamespace
JOIN pg_class cl ON cl.oid = c.conrelid
WHERE cl.relname = 'sale' 
  AND n.nspname = 'public'
ORDER BY conname;

-- Verificar especificamente constraints de payment_status
SELECT 
    '=== CONSTRAINTS DE PAYMENT_STATUS ENCONTRADAS ===' AS section;

SELECT 
    conname as constraint_name,
    pg_get_constraintdef(c.oid) as constraint_definition,
    CASE 
        WHEN pg_get_constraintdef(c.oid) LIKE '%pending%' THEN '✅ ACEITA INGLÊS (pending, paid, etc)'
        WHEN pg_get_constraintdef(c.oid) LIKE '%Pendente%' THEN '❌ ACEITA PORTUGUÊS (Pendente, Pago, etc)'
        ELSE '🤔 OUTRO TIPO'
    END AS idioma_aceito
FROM pg_constraint c
JOIN pg_namespace n ON n.oid = c.connamespace
JOIN pg_class cl ON cl.oid = c.conrelid
WHERE cl.relname = 'sale' 
  AND n.nspname = 'public'
  AND conname LIKE '%payment_status%'
ORDER BY conname;

-- Verificar valores atuais na tabela
SELECT 
    '=== VALORES ATUAIS DE PAYMENT_STATUS ===' AS section;

SELECT 
    payment_status,
    COUNT(*) as quantidade,
    CASE 
        WHEN payment_status IN ('pending', 'partial', 'paid', 'overdue', 'refunded') THEN '✅ INGLÊS'
        WHEN payment_status IN ('Pendente', 'Pago', 'Parcial', 'Cancelado', 'Reembolsado') THEN '❌ PORTUGUÊS'
        ELSE '🤔 DESCONHECIDO'
    END AS idioma
FROM public.sale
WHERE payment_status IS NOT NULL
GROUP BY payment_status
ORDER BY quantidade DESC;