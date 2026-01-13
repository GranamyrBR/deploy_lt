-- Verificar resultados da marcação de origem dos contatos
-- Executar após aplicar o script de origem

-- 1. Contagem por origem
SELECT 
  origem,
  COUNT(*) as total
FROM contact
GROUP BY origem
ORDER BY total DESC;

-- 2. Ver amostras de contatos LEGADOS (Monday)
SELECT id, name, phone, origem, created_at
FROM contact
WHERE origem = 'monday'
ORDER BY created_at DESC
LIMIT 10;

-- 3. Ver contatos NOVOS (LeadsTintim)
SELECT id, name, phone, origem, created_at
FROM contact
WHERE origem = 'leadstintim'
ORDER BY created_at DESC
LIMIT 10;

-- 4. Ver contatos SEM origem definida (unknown)
SELECT id, name, phone, origem, created_at
FROM contact
WHERE origem = 'unknown' OR origem IS NULL
ORDER BY created_at DESC
LIMIT 10;

-- 5. Identificar clientes RECORRENTES (legados que voltaram)
SELECT 
  c.id,
  c.name,
  c.phone,
  c.origem,
  c.created_at as contato_criado_em,
  l.created_at as lead_criado_em,
  l.status as lead_status
FROM contact c
INNER JOIN leadstintim l ON REGEXP_REPLACE(c.phone, '[^0-9+]', '', 'g') = REGEXP_REPLACE(l.phone, '[^0-9+]', '', 'g')
WHERE c.origem = 'monday'
ORDER BY l.created_at DESC
LIMIT 20;

-- 6. Estatísticas de recorrência
SELECT 
  COUNT(DISTINCT c.id) as total_recorrentes,
  (SELECT COUNT(*) FROM contact WHERE origem = 'monday') as total_legados,
  CASE 
    WHEN (SELECT COUNT(*) FROM contact WHERE origem = 'monday') > 0 THEN
      ROUND(COUNT(DISTINCT c.id)::numeric / (SELECT COUNT(*) FROM contact WHERE origem = 'monday')::numeric * 100, 2)
    ELSE 
      0
  END as taxa_recorrencia_pct
FROM contact c
INNER JOIN leadstintim l ON REGEXP_REPLACE(c.phone, '[^0-9+]', '', 'g') = REGEXP_REPLACE(l.phone, '[^0-9+]', '', 'g')
WHERE c.origem = 'monday';
