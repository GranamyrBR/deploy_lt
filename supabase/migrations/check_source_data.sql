-- Script para verificar dados de origem (source) na base de dados

-- 1. Verificar se há dados na tabela source
SELECT 'Dados na tabela source:' as info;
SELECT id, name, is_active FROM source ORDER BY id;

-- 2. Verificar quantos contatos têm source_id preenchido
SELECT 'Contatos com source_id:' as info;
SELECT 
  COUNT(*) as total_contatos,
  COUNT(source_id) as contatos_com_source,
  COUNT(*) - COUNT(source_id) as contatos_sem_source
FROM contact;

-- 3. Verificar alguns contatos com seus dados de origem
SELECT 'Amostra de contatos com origem:' as info;
SELECT 
  c.id,
  c.name as contact_name,
  c.source_id,
  s.name as source_name
FROM contact c
LEFT JOIN source s ON c.source_id = s.id
WHERE c.source_id IS NOT NULL
LIMIT 10;

-- 4. Verificar se há contatos sem source_id
SELECT 'Contatos sem origem definida:' as info;
SELECT 
  c.id,
  c.name as contact_name,
  c.source_id
FROM contact c
WHERE c.source_id IS NULL
LIMIT 5;

-- 5. Verificar distribuição por origem
SELECT 'Distribuição por origem:' as info;
SELECT 
  s.name as source_name,
  COUNT(c.id) as total_contatos
FROM source s
LEFT JOIN contact c ON s.id = c.source_id
GROUP BY s.id, s.name
ORDER BY total_contatos DESC;