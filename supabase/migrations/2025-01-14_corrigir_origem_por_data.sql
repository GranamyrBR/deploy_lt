-- Corrigir identificação de origem baseado em DATAS
-- Lógica: Contatos criados ANTES do primeiro leadstintim = LEGADO (monday)
--         Contatos criados DEPOIS do primeiro leadstintim = NOVO (leadstintim)

-- 1. Encontrar a data do primeiro registro no leadstintim
SELECT MIN(created_at) as primeira_data_leadstintim FROM leadstintim;

-- 2. Encontrar a última data da tabela monday
SELECT MAX(created_at) as ultima_data_monday FROM monday;

-- 3. Marcar contatos como LEGADO (criados antes do primeiro leadstintim)
UPDATE contact
SET origem = 'monday'
WHERE created_at < (SELECT MIN(created_at) FROM leadstintim WHERE created_at IS NOT NULL)
  AND (origem IS NULL OR origem = 'unknown');

-- 4. Marcar contatos como NOVO (criados depois E existe no leadstintim)
UPDATE contact c
SET origem = 'leadstintim'
FROM leadstintim l
WHERE REGEXP_REPLACE(c.phone, '[^0-9+]', '', 'g') = REGEXP_REPLACE(l.phone, '[^0-9+]', '', 'g')
  AND c.created_at >= (SELECT MIN(created_at) FROM leadstintim WHERE created_at IS NOT NULL)
  AND (c.origem IS NULL OR c.origem = 'unknown');

-- 5. Verificar resultados
SELECT 
  origem,
  COUNT(*) as total,
  MIN(created_at) as primeiro_contato,
  MAX(created_at) as ultimo_contato
FROM contact
GROUP BY origem
ORDER BY origem;

-- 6. Ver linha divisória
SELECT 
  'LEGADO (Monday)' as tipo,
  COUNT(*) as total,
  MAX(created_at) as ultima_data
FROM contact
WHERE origem = 'monday'
UNION ALL
SELECT 
  'NOVO (LeadsTintim)' as tipo,
  COUNT(*) as total,
  MIN(created_at) as primeira_data
FROM contact
WHERE origem = 'leadstintim'
UNION ALL
SELECT 
  'Primeira data LeadsTintim' as tipo,
  1 as total,
  MIN(created_at) as data
FROM leadstintim;

-- 7. Identificar RECORRENTES (legados que aparecem no leadstintim)
SELECT 
  c.id,
  c.name,
  c.phone,
  c.origem,
  c.created_at as contato_criado_em,
  l.created_at as lead_criado_em,
  l.status
FROM contact c
INNER JOIN leadstintim l ON REGEXP_REPLACE(c.phone, '[^0-9+]', '', 'g') = REGEXP_REPLACE(l.phone, '[^0-9+]', '', 'g')
WHERE c.origem = 'monday'
ORDER BY l.created_at DESC
LIMIT 20;

-- 8. Estatísticas finais
SELECT 
  (SELECT COUNT(*) FROM contact WHERE origem = 'monday') as total_legados,
  (SELECT COUNT(*) FROM contact WHERE origem = 'leadstintim') as total_novos,
  (SELECT COUNT(*) FROM contact WHERE origem = 'unknown' OR origem IS NULL) as total_sem_origem,
  (SELECT COUNT(DISTINCT c.id) 
   FROM contact c 
   INNER JOIN leadstintim l ON REGEXP_REPLACE(c.phone, '[^0-9+]', '', 'g') = REGEXP_REPLACE(l.phone, '[^0-9+]', '', 'g')
   WHERE c.origem = 'monday') as total_recorrentes;
