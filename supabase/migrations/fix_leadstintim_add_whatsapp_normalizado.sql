-- ============================================
-- Adicionar extração do campo whatsapp_normalizado
-- Complemento ao script anterior
-- ============================================

-- Atualizar whatsapp_normalizado para registros com estrutura body->lead
UPDATE leadstintim
SET
    whatsapp_normalizado = COALESCE(
        NULLIF(TRIM(whatsapp_normalizado), ''), 
        (body::jsonb)->'lead'->>'phone_normalized',
        (body::jsonb)->'lead'->>'whatsapp_normalized',
        (body::jsonb)->'lead'->>'phone'
    )
WHERE 
    id BETWEEN 83243 AND 83381
    AND body IS NOT NULL
    AND body != ''
    AND (body::jsonb)->'lead' IS NOT NULL
    AND (whatsapp_normalizado IS NULL OR whatsapp_normalizado = '');

-- Atualizar whatsapp_normalizado para registros com estrutura body->campo (sem 'lead')
UPDATE leadstintim
SET
    whatsapp_normalizado = COALESCE(
        NULLIF(TRIM(whatsapp_normalizado), ''), 
        (body::jsonb)->>'phone_normalized',
        (body::jsonb)->>'whatsapp_normalized',
        (body::jsonb)->>'phone'
    )
WHERE 
    id BETWEEN 83280 AND 83381
    AND body IS NOT NULL
    AND body != ''
    AND (body::jsonb)->'lead' IS NULL
    AND (whatsapp_normalizado IS NULL OR whatsapp_normalizado = '');

-- Se ainda estiver vazio, normalizar do campo phone existente
UPDATE leadstintim
SET
    whatsapp_normalizado = CASE
        WHEN phone IS NOT NULL AND phone != '' THEN
            -- Remove espaços, hífens, parênteses, etc
            REGEXP_REPLACE(phone, '[^0-9]', '', 'g')
        ELSE NULL
    END
WHERE 
    id BETWEEN 83243 AND 83381
    AND (whatsapp_normalizado IS NULL OR whatsapp_normalizado = '')
    AND phone IS NOT NULL
    AND phone != '';

-- Verificar resultado
SELECT 
    COUNT(*) as total_registros,
    COUNT(CASE WHEN whatsapp_normalizado IS NOT NULL AND whatsapp_normalizado != '' THEN 1 END) as com_whatsapp_normalizado,
    COUNT(CASE WHEN phone IS NOT NULL AND phone != '' THEN 1 END) as com_phone
FROM leadstintim
WHERE id BETWEEN 83243 AND 83381;

-- Exemplos
SELECT 
    id,
    name,
    phone,
    whatsapp_normalizado,
    LENGTH(whatsapp_normalizado) as tamanho_whatsapp
FROM leadstintim
WHERE id BETWEEN 83243 AND 83381
AND whatsapp_normalizado IS NOT NULL
ORDER BY id DESC
LIMIT 15;
