-- Script para popular contatos com source_id para testar as cores
-- Este script atualiza alguns contatos existentes com diferentes origens

-- Primeiro, vamos verificar quais contatos existem
SELECT 'Contatos existentes (primeiros 10):' as info;
SELECT id, name, source_id FROM contact ORDER BY id LIMIT 10;

-- Verificar quais sources existem
SELECT 'Sources disponíveis:' as info;
SELECT id, name FROM source ORDER BY id;

-- Atualizar alguns contatos com diferentes sources para testar as cores
-- Vamos distribuir os primeiros 15 contatos entre as diferentes origens

-- WhatsApp (source_id = 13)
UPDATE contact 
SET source_id = 13 
WHERE id IN (
  SELECT id FROM contact ORDER BY id LIMIT 3
);

-- Instagram (source_id = 9)
UPDATE contact 
SET source_id = 9 
WHERE id IN (
  SELECT id FROM contact 
  WHERE source_id IS NULL OR source_id != 13
  ORDER BY id LIMIT 3
);

-- Facebook (source_id = 6)
UPDATE contact 
SET source_id = 6 
WHERE id IN (
  SELECT id FROM contact 
  WHERE source_id IS NULL OR source_id NOT IN (13, 9)
  ORDER BY id LIMIT 3
);

-- Google (source_id = 7)
UPDATE contact 
SET source_id = 7 
WHERE id IN (
  SELECT id FROM contact 
  WHERE source_id IS NULL OR source_id NOT IN (13, 9, 6)
  ORDER BY id LIMIT 3
);

-- Site (source_id = 12)
UPDATE contact 
SET source_id = 12 
WHERE id IN (
  SELECT id FROM contact 
  WHERE source_id IS NULL OR source_id NOT IN (13, 9, 6, 7)
  ORDER BY id LIMIT 3
);

-- Indicação (source_id = 8)
UPDATE contact 
SET source_id = 8 
WHERE id IN (
  SELECT id FROM contact 
  WHERE source_id IS NULL OR source_id NOT IN (13, 9, 6, 7, 12)
  ORDER BY id LIMIT 3
);

-- Email (source_id = 5)
UPDATE contact 
SET source_id = 5 
WHERE id IN (
  SELECT id FROM contact 
  WHERE source_id IS NULL OR source_id NOT IN (13, 9, 6, 7, 12, 8)
  ORDER BY id LIMIT 3
);

-- Agência (source_id = 1)
UPDATE contact 
SET source_id = 1 
WHERE id IN (
  SELECT id FROM contact 
  WHERE source_id IS NULL OR source_id NOT IN (13, 9, 6, 7, 12, 8, 5)
  ORDER BY id LIMIT 3
);

-- Verificar resultado final
SELECT 'Contatos com origem após atualização:' as info;
SELECT 
  c.id,
  c.name as contact_name,
  c.source_id,
  s.name as source_name
FROM contact c
LEFT JOIN source s ON c.source_id = s.id
WHERE c.source_id IS NOT NULL
ORDER BY c.id
LIMIT 25;

-- Verificar distribuição por origem
SELECT 'Distribuição por origem:' as info;
SELECT 
  s.name as source_name,
  COUNT(c.id) as total_contatos
FROM source s
LEFT JOIN contact c ON s.id = c.source_id
GROUP BY s.id, s.name
ORDER BY total_contatos DESC;