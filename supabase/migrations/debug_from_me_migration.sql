-- =====================================================
-- DIAGNÓSTICO: Verificar migração from_me
-- =====================================================

-- 1. Ver exemplos reais do body
SELECT 
    '1. EXEMPLOS DE BODY COM from_me' AS secao,
    id,
    from_me AS coluna_atual,
    body::jsonb->>'from_me' AS body_from_me_string,
    body::jsonb->'from_me' AS body_from_me_raw,
    jsonb_typeof(body::jsonb->'from_me') AS tipo_no_json,
    LEFT(body, 200) AS body_preview
FROM leadstintim
WHERE body::text LIKE '%"from_me"%'
LIMIT 5;

-- 2. Contar tipos diferentes no JSON
SELECT 
    '2. TIPOS DE from_me NO BODY' AS secao,
    jsonb_typeof(body::jsonb->'from_me') AS tipo,
    COUNT(*) AS quantidade
FROM leadstintim
WHERE body::text LIKE '%"from_me"%'
GROUP BY jsonb_typeof(body::jsonb->'from_me');

-- 3. Ver valores distintos extraídos
SELECT 
    '3. VALORES EXTRAÍDOS DO BODY' AS secao,
    body::jsonb->>'from_me' AS valor_extraido,
    COUNT(*) AS quantidade
FROM leadstintim
WHERE body::text LIKE '%"from_me"%'
GROUP BY body::jsonb->>'from_me';

-- 4. Verificar coluna from_me atual
SELECT 
    '4. STATUS DA COLUNA from_me' AS secao,
    from_me,
    COUNT(*) AS quantidade
FROM leadstintim
GROUP BY from_me
ORDER BY from_me NULLS LAST;

-- 5. Comparar body vs coluna
SELECT 
    '5. COMPARAÇÃO: BODY vs COLUNA' AS secao,
    body::jsonb->>'from_me' AS no_body,
    from_me AS na_coluna,
    COUNT(*) AS quantidade
FROM leadstintim
WHERE body::text LIKE '%"from_me"%'
GROUP BY body::jsonb->>'from_me', from_me;

-- 6. Ver registros que DEVIAM ter sido migrados mas não foram
SELECT 
    '6. REGISTROS NÃO MIGRADOS (from_me NULL mas existe no body)' AS secao,
    COUNT(*) AS quantidade
FROM leadstintim
WHERE body::text LIKE '%"from_me"%'
AND from_me IS NULL;

-- Se houver registros não migrados, mostrar exemplos:
SELECT 
    id,
    body::jsonb->>'from_me' AS body_value,
    from_me AS column_value,
    created_at
FROM leadstintim
WHERE body::text LIKE '%"from_me"%'
AND from_me IS NULL
LIMIT 10;
