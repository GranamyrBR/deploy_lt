-- ============================================
-- Extrair dados do campo body (JSON) e popular campos vazios
-- Para registros que vieram do webhook com campos vazios
-- ============================================

-- Atualizar registros onde os campos estão vazios mas body tem dados
UPDATE leadstintim
SET
    name = COALESCE(name, body->'lead'->>'name'),
    phone = COALESCE(phone, body->'lead'->>'phone'),
    source = COALESCE(source, body->'lead'->>'source'),
    country = COALESCE(country, body->'lead'->'location'->>'country'),
    state = COALESCE(state, body->'lead'->'location'->>'state'),
    status = COALESCE(status, body->'lead'->'status'->>'name'),
    from_me = COALESCE(from_me, (body->'lead'->>'from_me')::boolean, false)
WHERE 
    body IS NOT NULL
    AND (
        name IS NULL OR name = '' OR
        phone IS NULL OR phone = '' OR
        source IS NULL OR source = ''
    );

-- Verificar quantos registros foram atualizados
SELECT 
    COUNT(*) as total_atualizados,
    COUNT(CASE WHEN name IS NOT NULL THEN 1 END) as com_nome,
    COUNT(CASE WHEN phone IS NOT NULL THEN 1 END) as com_telefone,
    COUNT(CASE WHEN source IS NOT NULL THEN 1 END) as com_source
FROM leadstintim
WHERE body IS NOT NULL;
