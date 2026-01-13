-- Adicionar campo para identificar origem do contato
-- Criado em: 2025-01-14
-- Objetivo: Diferenciar contatos legados (Monday) de novos (LeadsTintim)

-- 1. Adicionar coluna 'origem' na tabela contact
ALTER TABLE contact 
ADD COLUMN IF NOT EXISTS origem VARCHAR(20) DEFAULT 'unknown';

-- Adicionar comentário explicativo
COMMENT ON COLUMN contact.origem IS 'Origem do contato: monday (legado), leadstintim (novo), recorrente (legado que voltou)';

-- 2. Criar índice para melhorar performance
CREATE INDEX IF NOT EXISTS idx_contact_origem ON contact(origem);

-- 3. Marcar contatos LEGADOS (que existem na tabela monday)
-- Estes são clientes antigos do sistema
UPDATE contact c
SET origem = 'monday'
FROM monday m
WHERE c.id = m.contact_id
  AND (c.origem IS NULL OR c.origem = 'unknown');

-- 4. Marcar contatos NOVOS (que existem APENAS no leadstintim)
-- Estes são clientes que vieram do WhatsApp e NÃO estavam no Monday
UPDATE contact c
SET origem = 'leadstintim'
FROM leadstintim l
WHERE REGEXP_REPLACE(c.phone, '[^0-9+]', '', 'g') = REGEXP_REPLACE(l.phone, '[^0-9+]', '', 'g')
  AND NOT EXISTS (
    SELECT 1 FROM monday m WHERE m.contact_id = c.id
  )
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

-- 6. Ver amostras de cada origem
SELECT id, name, phone, origem, created_at
FROM contact
WHERE origem = 'monday'
ORDER BY created_at
LIMIT 5;

SELECT id, name, phone, origem, created_at
FROM contact
WHERE origem = 'leadstintim'
ORDER BY created_at DESC
LIMIT 5;

-- 7. Identificar clientes RECORRENTES (legados que aparecem no leadstintim)
SELECT 
  c.id,
  c.name,
  c.phone,
  c.origem,
  c.created_at as contato_criado_em,
  l.created_at as lead_criado_em,
  l.status as lead_status,
  'RECORRENTE' as tipo
FROM contact c
INNER JOIN leadstintim l ON REGEXP_REPLACE(c.phone, '[^0-9+]', '', 'g') = REGEXP_REPLACE(l.phone, '[^0-9+]', '', 'g')
WHERE c.origem = 'monday'
ORDER BY l.created_at DESC;
