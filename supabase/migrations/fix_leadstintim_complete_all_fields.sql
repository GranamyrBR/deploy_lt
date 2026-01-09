-- ============================================
-- Corrigir TODOS os campos dos registros leadstintim
-- Extrai TODOS os dados disponíveis do body JSON
-- Para ambas estruturas: com 'lead' e sem 'lead'
-- ============================================

-- Atualizar registros com estrutura body->lead->campo
UPDATE leadstintim
SET
    name = COALESCE(NULLIF(TRIM(name), ''), (body::jsonb)->'lead'->>'name'),
    phone = COALESCE(NULLIF(TRIM(phone), ''), (body::jsonb)->'lead'->>'phone'),
    source = COALESCE(NULLIF(TRIM(source), ''), (body::jsonb)->'lead'->>'source', 'Meta Ads'),
    country = COALESCE(NULLIF(TRIM(country), ''), (body::jsonb)->'lead'->'location'->>'country'),
    state = COALESCE(NULLIF(TRIM(state), ''), (body::jsonb)->'lead'->'location'->>'state'),
    status = COALESCE(NULLIF(TRIM(status), ''), (body::jsonb)->'lead'->'status'->>'name'),
    messageid = COALESCE(NULLIF(TRIM(messageid), ''), (body::jsonb)->'lead'->>'messageid'),
    from_me = COALESCE(NULLIF(TRIM(from_me), ''), (body::jsonb)->'lead'->>'from_me', 'false'),
    datefirst = COALESCE(datefirst, ((body::jsonb)->'lead'->>'created')::timestamptz),
    datelast = COALESCE(datelast, ((body::jsonb)->'lead'->>'updated')::timestamptz)
WHERE 
    id BETWEEN 83243 AND 83381
    AND body IS NOT NULL
    AND body != ''
    AND (body::jsonb)->'lead' IS NOT NULL;

-- Atualizar registros com estrutura body->campo (sem 'lead')
UPDATE leadstintim
SET
    name = COALESCE(NULLIF(TRIM(name), ''), (body::jsonb)->>'name'),
    phone = COALESCE(NULLIF(TRIM(phone), ''), (body::jsonb)->>'phone'),
    source = COALESCE(NULLIF(TRIM(source), ''), (body::jsonb)->>'source', 'Meta Ads'),
    country = COALESCE(NULLIF(TRIM(country), ''), (body::jsonb)->'location'->>'country'),
    state = COALESCE(NULLIF(TRIM(state), ''), (body::jsonb)->'location'->>'state'),
    status = COALESCE(NULLIF(TRIM(status), ''), (body::jsonb)->'status'->>'name'),
    messageid = COALESCE(NULLIF(TRIM(messageid), ''), (body::jsonb)->>'messageid'),
    from_me = COALESCE(NULLIF(TRIM(from_me), ''), (body::jsonb)->>'from_me', 'false'),
    datefirst = COALESCE(datefirst, ((body::jsonb)->>'created')::timestamptz),
    datelast = COALESCE(datelast, ((body::jsonb)->>'updated')::timestamptz)
WHERE 
    id BETWEEN 83280 AND 83381
    AND body IS NOT NULL
    AND body != ''
    AND (body::jsonb)->'lead' IS NULL;

-- Estatísticas finais
SELECT 
    COUNT(*) as total_registros,
    COUNT(CASE WHEN name IS NOT NULL AND name != '' THEN 1 END) as com_nome,
    COUNT(CASE WHEN phone IS NOT NULL AND phone != '' THEN 1 END) as com_telefone,
    COUNT(CASE WHEN source IS NOT NULL AND source != '' THEN 1 END) as com_source,
    COUNT(CASE WHEN country IS NOT NULL AND country != '' THEN 1 END) as com_country,
    COUNT(CASE WHEN state IS NOT NULL AND state != '' THEN 1 END) as com_state,
    COUNT(CASE WHEN messageid IS NOT NULL AND messageid != '' THEN 1 END) as com_messageid,
    COUNT(CASE WHEN datefirst IS NOT NULL THEN 1 END) as com_datefirst,
    COUNT(CASE WHEN datelast IS NOT NULL THEN 1 END) as com_datelast
FROM leadstintim
WHERE id BETWEEN 83243 AND 83381;

-- Mostrar exemplos dos registros corrigidos
SELECT 
    id,
    name,
    LEFT(phone, 13) as phone,
    source,
    country,
    state,
    messageid,
    datefirst,
    datelast
FROM leadstintim
WHERE id BETWEEN 83243 AND 83381
ORDER BY id DESC
LIMIT 20;
