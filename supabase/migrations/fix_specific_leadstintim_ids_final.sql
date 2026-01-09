-- ============================================
-- Corrigir registros específicos do CSV com campos vazios
-- IDs: 83381 até 83243 (138 registros)
-- Corrigido: tipos de dados
-- ============================================

-- Atualizar registros específicos onde campos estão vazios
UPDATE leadstintim
SET
    name = COALESCE(
        NULLIF(TRIM(name), ''), 
        (body::jsonb)->'lead'->>'name'
    ),
    phone = COALESCE(
        NULLIF(TRIM(phone), ''), 
        (body::jsonb)->'lead'->>'phone'
    ),
    source = COALESCE(
        NULLIF(TRIM(source), ''), 
        (body::jsonb)->'lead'->>'source',
        'Meta Ads'
    ),
    country = COALESCE(
        NULLIF(TRIM(country), ''), 
        (body::jsonb)->'lead'->'location'->>'country'
    ),
    state = COALESCE(
        NULLIF(TRIM(state), ''), 
        (body::jsonb)->'lead'->'location'->>'state'
    ),
    status = COALESCE(
        NULLIF(TRIM(status), ''), 
        (body::jsonb)->'lead'->'status'->>'name'
    ),
    from_me = CASE 
        WHEN from_me IS NOT NULL THEN from_me
        WHEN (body::jsonb)->'lead'->>'from_me' IS NOT NULL THEN ((body::jsonb)->'lead'->>'from_me')::boolean
        ELSE false
    END
WHERE 
    id BETWEEN 83243 AND 83381
    AND body IS NOT NULL
    AND body != '';

-- Mostrar resultado
SELECT 
    COUNT(*) as total_atualizados,
    COUNT(CASE WHEN name IS NOT NULL AND name != '' THEN 1 END) as com_nome,
    COUNT(CASE WHEN phone IS NOT NULL AND phone != '' THEN 1 END) as com_telefone,
    COUNT(CASE WHEN source IS NOT NULL AND source != '' THEN 1 END) as com_source
FROM leadstintim
WHERE id BETWEEN 83243 AND 83381;

-- Mostrar exemplos
SELECT 
    id,
    name,
    LEFT(phone, 15) as phone,
    source,
    country,
    state
FROM leadstintim
WHERE id BETWEEN 83243 AND 83381
ORDER BY id DESC
LIMIT 10;
