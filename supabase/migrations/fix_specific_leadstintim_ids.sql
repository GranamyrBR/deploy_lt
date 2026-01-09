-- ============================================
-- Corrigir registros específicos do CSV com campos vazios
-- IDs: 83381 até 83243 (138 registros)
-- ============================================

-- Atualizar registros específicos onde campos estão vazios
UPDATE leadstintim
SET
    name = COALESCE(NULLIF(TRIM(name), ''), body->'lead'->>'name'),
    phone = COALESCE(NULLIF(TRIM(phone), ''), body->'lead'->>'phone'),
    source = COALESCE(NULLIF(TRIM(source), ''), body->'lead'->>'source', 'Meta Ads'),
    country = COALESCE(NULLIF(TRIM(country), ''), body->'lead'->'location'->>'country'),
    state = COALESCE(NULLIF(TRIM(state), ''), body->'lead'->'location'->>'state'),
    status = COALESCE(NULLIF(TRIM(status), ''), body->'lead'->'status'->>'name'),
    from_me = COALESCE(from_me, (body->'lead'->>'from_me')::boolean, false)
WHERE 
    id BETWEEN 83243 AND 83381
    AND body IS NOT NULL;

-- Mostrar resultado
SELECT 
    id,
    name,
    phone,
    source,
    CASE 
        WHEN name IS NOT NULL THEN '✅' 
        ELSE '❌' 
    END as tem_nome,
    CASE 
        WHEN phone IS NOT NULL THEN '✅' 
        ELSE '❌' 
    END as tem_telefone
FROM leadstintim
WHERE id BETWEEN 83243 AND 83381
ORDER BY id DESC
LIMIT 20;
