-- Identificar origem usando campo GENDER + DATA
-- Lógica: Tabela monday tem gender preenchido
--         Tabela leadstintim geralmente não tem gender

-- 1. Verificar distribuição de gender
SELECT 
  CASE 
    WHEN gender IS NOT NULL AND gender != '' THEN 'COM gender'
    ELSE 'SEM gender'
  END as tem_gender,
  COUNT(*) as total,
  MIN(created_at) as primeiro_registro,
  MAX(created_at) as ultimo_registro
FROM contact
GROUP BY tem_gender
ORDER BY tem_gender;

-- 2. Ver amostras COM gender (provavelmente monday)
SELECT id, name, phone, gender, created_at, origem
FROM contact
WHERE gender IS NOT NULL AND gender != ''
ORDER BY created_at
LIMIT 10;

-- 3. Ver amostras SEM gender (provavelmente leadstintim)
SELECT id, name, phone, gender, created_at, origem
FROM contact
WHERE gender IS NULL OR gender = ''
ORDER BY created_at DESC
LIMIT 10;

-- 4. Encontrar primeira data do leadstintim
SELECT 
  MIN(created_at) as primeira_data_leadstintim,
  MAX(created_at) as ultima_data_leadstintim,
  COUNT(*) as total_leadstintim
FROM leadstintim;

-- 5. ESTRATÉGIA HÍBRIDA: Usar gender como critério principal
-- Marcar como LEGADO: Contatos COM gender preenchido
UPDATE contact
SET origem = 'monday'
WHERE (gender IS NOT NULL AND gender != '')
  AND (origem IS NULL OR origem = 'unknown');

-- 6. Marcar como NOVO: Contatos SEM gender E existe no leadstintim
UPDATE contact c
SET origem = 'leadstintim'
FROM leadstintim l
WHERE REGEXP_REPLACE(c.phone, '[^0-9+]', '', 'g') = REGEXP_REPLACE(l.phone, '[^0-9+]', '', 'g')
  AND (c.gender IS NULL OR c.gender = '')
  AND (c.origem IS NULL OR c.origem = 'unknown');

-- 7. Contatos com gender MAS que aparecem no leadstintim = RECORRENTES
-- (não mudar origem, eles continuam como 'monday' mas identificados como recorrentes)

-- 8. Verificar resultados
SELECT 
  origem,
  COUNT(*) as total,
  COUNT(CASE WHEN gender IS NOT NULL AND gender != '' THEN 1 END) as com_gender,
  COUNT(CASE WHEN gender IS NULL OR gender = '' THEN 1 END) as sem_gender,
  MIN(created_at) as primeiro_contato,
  MAX(created_at) as ultimo_contato
FROM contact
GROUP BY origem
ORDER BY origem;

-- 9. Identificar RECORRENTES (legados que aparecem no leadstintim)
SELECT 
  c.id,
  c.name,
  c.phone,
  c.gender,
  c.origem,
  c.created_at as contato_criado_em,
  l.created_at as lead_criado_em,
  l.status,
  'RECORRENTE' as tipo
FROM contact c
INNER JOIN leadstintim l ON REGEXP_REPLACE(c.phone, '[^0-9+]', '', 'g') = REGEXP_REPLACE(l.phone, '[^0-9+]', '', 'g')
WHERE c.origem = 'monday'
ORDER BY l.created_at DESC
LIMIT 20;

-- 10. Estatísticas finais
SELECT 
  (SELECT COUNT(*) FROM contact WHERE origem = 'monday') as total_legados,
  (SELECT COUNT(*) FROM contact WHERE origem = 'leadstintim') as total_novos,
  (SELECT COUNT(*) FROM contact WHERE origem = 'unknown' OR origem IS NULL) as total_sem_origem,
  (SELECT COUNT(DISTINCT c.id) 
   FROM contact c 
   INNER JOIN leadstintim l ON REGEXP_REPLACE(c.phone, '[^0-9+]', '', 'g') = REGEXP_REPLACE(l.phone, '[^0-9+]', '', 'g')
   WHERE c.origem = 'monday') as total_recorrentes,
  CASE 
    WHEN (SELECT COUNT(*) FROM contact WHERE origem = 'monday') > 0 THEN
      ROUND(
        (SELECT COUNT(DISTINCT c.id) 
         FROM contact c 
         INNER JOIN leadstintim l ON REGEXP_REPLACE(c.phone, '[^0-9+]', '', 'g') = REGEXP_REPLACE(l.phone, '[^0-9+]', '', 'g')
         WHERE c.origem = 'monday')::numeric 
        / (SELECT COUNT(*) FROM contact WHERE origem = 'monday')::numeric * 100, 2
      )
    ELSE 0
  END as taxa_recorrencia_pct;

-- 11. Resumo visual
SELECT 
  '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━' as divisor
UNION ALL
SELECT CONCAT('📊 LEGADOS (Monday): ', COUNT(*), ' contatos COM gender') 
FROM contact WHERE origem = 'monday'
UNION ALL
SELECT CONCAT('📊 NOVOS (LeadsTintim): ', COUNT(*), ' contatos SEM gender')
FROM contact WHERE origem = 'leadstintim'
UNION ALL
SELECT CONCAT('🔄 RECORRENTES: ', COUNT(DISTINCT c.id), ' legados que voltaram!')
FROM contact c 
INNER JOIN leadstintim l ON REGEXP_REPLACE(c.phone, '[^0-9+]', '', 'g') = REGEXP_REPLACE(l.phone, '[^0-9+]', '', 'g')
WHERE c.origem = 'monday'
UNION ALL
SELECT '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
