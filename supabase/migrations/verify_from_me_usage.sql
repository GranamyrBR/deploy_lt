-- ============================================
-- Verificar como o campo from_me é usado atualmente
-- ============================================

-- 1. Ver distribuição de valores em from_me
SELECT 
    from_me,
    COUNT(*) as total,
    MIN(created_at) as primeira_ocorrencia,
    MAX(created_at) as ultima_ocorrencia
FROM leadstintim
GROUP BY from_me
ORDER BY total DESC;

-- 2. Ver exemplos de mensagens com from_me = 'true'
SELECT 
    id,
    name,
    LEFT(phone, 15) as phone,
    from_me,
    LEFT(message, 100) as message_preview,
    created_at
FROM leadstintim
WHERE from_me = 'true'
ORDER BY created_at DESC
LIMIT 10;

-- 3. Ver exemplos de mensagens com from_me = 'false' ou NULL
SELECT 
    id,
    name,
    LEFT(phone, 15) as phone,
    from_me,
    LEFT(message, 100) as message_preview,
    created_at
FROM leadstintim
WHERE from_me IS NULL OR from_me = 'false' OR from_me = ''
ORDER BY created_at DESC
LIMIT 10;

-- 4. Total geral
SELECT 
    COUNT(*) as total_registros,
    COUNT(CASE WHEN from_me = 'true' THEN 1 END) as from_me_true,
    COUNT(CASE WHEN from_me = 'false' OR from_me = '' OR from_me IS NULL THEN 1 END) as from_me_false_or_null
FROM leadstintim;
