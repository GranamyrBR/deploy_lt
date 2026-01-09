-- ============================================
-- Corrigir registros com estrutura JSON alternativa
-- Body sem 'lead' como chave raiz (dados diretos no root)
-- IDs: 83280 até 83355 (75 registros)
-- ============================================

-- Atualizar registros onde body tem estrutura alternativa
UPDATE leadstintim
SET
    name = COALESCE(
        NULLIF(TRIM(name), ''), 
        (body::jsonb)->>'name'
    ),
    phone = COALESCE(
        NULLIF(TRIM(phone), ''), 
        (body::jsonb)->>'phone'
    ),
    source = COALESCE(
        NULLIF(TRIM(source), ''), 
        (body::jsonb)->>'source',
        'Meta Ads'
    ),
    country = COALESCE(
        NULLIF(TRIM(country), ''), 
        (body::jsonb)->'location'->>'country'
    ),
    state = COALESCE(
        NULLIF(TRIM(state), ''), 
        (body::jsonb)->'location'->>'state'
    ),
    status = COALESCE(
        NULLIF(TRIM(status), ''), 
        (body::jsonb)->'status'->>'name'
    ),
    from_me = COALESCE(
        NULLIF(TRIM(from_me), ''), 
        (body::jsonb)->>'from_me',
        'false'
    )
WHERE 
    id BETWEEN 83280 AND 83355
    AND body IS NOT NULL
    AND body != ''
    AND (name IS NULL OR name = '' OR phone IS NULL OR phone = '');

-- Mostrar resultado
SELECT 
    COUNT(*) as total_atualizados,
    COUNT(CASE WHEN name IS NOT NULL AND name != '' THEN 1 END) as com_nome,
    COUNT(CASE WHEN phone IS NOT NULL AND phone != '' THEN 1 END) as com_telefone
FROM leadstintim
WHERE id BETWEEN 83280 AND 83355;

-- Mostrar exemplos
SELECT 
    id,
    name,
    LEFT(phone, 15) as phone,
    source,
    country,
    state
FROM leadstintim
WHERE id BETWEEN 83280 AND 83355
AND (name IS NOT NULL OR phone IS NOT NULL)
ORDER BY id DESC
LIMIT 15;
