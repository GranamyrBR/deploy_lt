-- ============================================
-- Normalizar whatsapp_normalizado a partir do phone já preenchido
-- Remove todos caracteres não-numéricos
-- ============================================

-- Atualizar whatsapp_normalizado normalizando do campo phone
UPDATE leadstintim
SET
    whatsapp_normalizado = REGEXP_REPLACE(phone, '[^0-9]', '', 'g')
WHERE 
    id BETWEEN 83243 AND 83381
    AND phone IS NOT NULL
    AND phone != '';

-- Verificar resultado
SELECT 
    COUNT(*) as total_registros,
    COUNT(CASE WHEN whatsapp_normalizado IS NOT NULL AND LENGTH(whatsapp_normalizado) > 10 THEN 1 END) as whatsapp_validos,
    COUNT(CASE WHEN phone IS NOT NULL AND phone != '' THEN 1 END) as com_phone,
    AVG(LENGTH(whatsapp_normalizado)) as tamanho_medio_whatsapp
FROM leadstintim
WHERE id BETWEEN 83243 AND 83381;

-- Exemplos dos registros corrigidos
SELECT 
    id,
    name,
    phone,
    whatsapp_normalizado,
    LENGTH(whatsapp_normalizado) as tamanho
FROM leadstintim
WHERE id BETWEEN 83243 AND 83381
AND phone IS NOT NULL
ORDER BY id DESC
LIMIT 20;
