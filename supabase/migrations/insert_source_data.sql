-- Script para inserir dados de origem (source) na base de dados
-- Baseado nas cores definidas em source_colors.dart

-- Inserir origens principais
INSERT INTO source (name, is_active) VALUES 
('WhatsApp', true),
('Instagram', true),
('Facebook', true),
('Google', true),
('Site', true),
('Indicação', true),
('Telefone', true),
('Email', true),
('LinkedIn', true),
('Twitter', true),
('YouTube', true),
('TikTok', true),
('Pinterest', true),
('Snapchat', true),
('Telegram', true),
('Discord', true),
('Reddit', true),
('Twitch', true),
('Tumblr', true)
ON CONFLICT (name) DO NOTHING;

-- Verificar se os dados foram inseridos
SELECT 'Origens inseridas:' as info;
SELECT id, name, is_active FROM source ORDER BY id;

-- Atualizar alguns contatos para terem source_id (para teste)
-- Primeiro, vamos ver quais IDs de source temos
SELECT 'IDs de origem disponíveis:' as info;
SELECT id, name FROM source WHERE name IN ('WhatsApp', 'Instagram', 'Facebook', 'Site', 'Indicação') ORDER BY id;

-- Atualizar alguns contatos aleatoriamente com source_id
-- (Substitua os IDs pelos IDs reais das origens após executar o SELECT acima)
UPDATE contact 
SET source_id = (
  SELECT id FROM source WHERE name = 'WhatsApp' LIMIT 1
)
WHERE id IN (
  SELECT id FROM contact WHERE source_id IS NULL LIMIT 5
);

UPDATE contact 
SET source_id = (
  SELECT id FROM source WHERE name = 'Instagram' LIMIT 1
)
WHERE id IN (
  SELECT id FROM contact WHERE source_id IS NULL LIMIT 3
);

UPDATE contact 
SET source_id = (
  SELECT id FROM source WHERE name = 'Facebook' LIMIT 1
)
WHERE id IN (
  SELECT id FROM contact WHERE source_id IS NULL LIMIT 3
);

UPDATE contact 
SET source_id = (
  SELECT id FROM source WHERE name = 'Site' LIMIT 1
)
WHERE id IN (
  SELECT id FROM contact WHERE source_id IS NULL LIMIT 2
);

UPDATE contact 
SET source_id = (
  SELECT id FROM source WHERE name = 'Indicação' LIMIT 1
)
WHERE id IN (
  SELECT id FROM contact WHERE source_id IS NULL LIMIT 2
);

-- Verificar resultado final
SELECT 'Contatos com origem após atualização:' as info;
SELECT 
  c.id,
  c.name as contact_name,
  s.name as source_name
FROM contact c
INNER JOIN source s ON c.source_id = s.id
LIMIT 15;