-- Script para verificar origem dos contatos e diferenciar legado (monday) de novos (leadstintim)
-- Criado em: 2025-01-14
-- Objetivo: Identificar quais contatos vieram do leadstintim vs monday para aplicar regras corretas

-- 1. Verificar estrutura da tabela contact
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'contact'
ORDER BY ordinal_position;

-- 2. Verificar se existe campo que identifica origem (leadstintim_id, monday_id, source, etc)
SELECT column_name
FROM information_schema.columns
WHERE table_name = 'contact'
  AND (column_name ILIKE '%lead%' OR 
       column_name ILIKE '%monday%' OR 
       column_name ILIKE '%source%' OR
       column_name ILIKE '%origin%');

-- 3. Ver amostra de contatos
SELECT id, name, phone, email, created_at, updated_at
FROM contact
ORDER BY created_at DESC
LIMIT 10;

-- 4. Verificar relação entre contact e leadstintim (pelo telefone)
SELECT 
  c.id as contact_id,
  c.name as contact_name,
  c.phone as contact_phone,
  c.created_at as contact_created_at,
  l.id as lead_id,
  l.status as lead_status,
  l.created_at as lead_created_at,
  CASE 
    WHEN l.id IS NOT NULL THEN 'LEADSTINTIM'
    ELSE 'MONDAY (LEGADO)'
  END as origem
FROM contact c
LEFT JOIN leadstintim l ON REGEXP_REPLACE(c.phone, '[^0-9+]', '', 'g') = REGEXP_REPLACE(l.phone, '[^0-9+]', '', 'g')
ORDER BY c.created_at DESC
LIMIT 20;

-- 5. Contar contatos por origem
SELECT 
  CASE 
    WHEN l.id IS NOT NULL THEN 'Novos (LeadsTintim)'
    ELSE 'Legado (Monday)'
  END as origem,
  COUNT(*) as total
FROM contact c
LEFT JOIN leadstintim l ON REGEXP_REPLACE(c.phone, '[^0-9+]', '', 'g') = REGEXP_REPLACE(l.phone, '[^0-9+]', '', 'g')
GROUP BY origem;

-- 6. Verificar contatos com status "comprou" no leadstintim
SELECT 
  c.id,
  c.name,
  c.phone,
  c.contact_category_id,
  cc.name as categoria_atual,
  l.status as lead_status,
  l.created_at as lead_created_at
FROM contact c
INNER JOIN leadstintim l ON REGEXP_REPLACE(c.phone, '[^0-9+]', '', 'g') = REGEXP_REPLACE(l.phone, '[^0-9+]', '', 'g')
LEFT JOIN contact_category cc ON c.contact_category_id = cc.id
WHERE LOWER(l.status) = 'comprou'
ORDER BY l.created_at DESC;
