-- ============================================
-- Verificar quais IDs precisam ser corrigidos
-- ============================================

SELECT 
    id,
    name,
    phone,
    source,
    CASE 
        WHEN (name IS NULL OR name = '') AND body->'lead'->>'name' IS NOT NULL 
        THEN 'PRECISA CORRIGIR' 
        ELSE 'OK' 
    END as status_correcao,
    body->'lead'->>'name' as nome_no_body,
    body->'lead'->>'phone' as telefone_no_body
FROM leadstintim
WHERE id BETWEEN 83243 AND 83381
ORDER BY id DESC
LIMIT 30;
