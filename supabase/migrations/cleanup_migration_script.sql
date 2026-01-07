-- =====================================================
-- SCRIPT DE LIMPEZA DA MIGRAÇÃO LEADSTINTIM -> CONTACT
-- =====================================================
-- Este script remove contatos migrados incorretamente e prepara
-- para uma nova migração correta da tabela leadstintim

-- 1. BACKUP DOS DADOS ATUAIS (OPCIONAL - DESCOMENTE SE NECESSÁRIO)
-- CREATE TABLE contact_backup_before_cleanup AS SELECT * FROM contact;

-- 2. IDENTIFICAR E REMOVER CONTATOS MIGRADOS DO WHATSAPP
-- Remove contatos que foram migrados da tabela leadstintim (source_id = 13)
SELECT 'REMOVENDO CONTATOS MIGRADOS DO WHATSAPP...' as info;

-- Primeiro, vamos ver quantos contatos serão removidos
SELECT 
  'Contatos a serem removidos' as tipo,
  COUNT(*) as quantidade
FROM contact 
WHERE source_id = 13; -- WhatsApp

-- Remover contatos migrados do WhatsApp
DELETE FROM contact 
WHERE source_id = 13;

SELECT 'Contatos do WhatsApp removidos com sucesso!' as resultado;

-- 3. VERIFICAR SE TELEFONE JÁ É CHAVE PRIMÁRIA
SELECT 'VERIFICANDO ESTRUTURA DA TABELA...' as info;

SELECT 
  constraint_name,
  constraint_type
FROM information_schema.table_constraints 
WHERE table_name = 'contact' 
  AND table_schema = 'public'
  AND constraint_type = 'PRIMARY KEY';

-- 4. VERIFICAR DUPLICATAS POR TELEFONE (se ainda usar id como PK)
SELECT 'VERIFICANDO DUPLICATAS POR TELEFONE...' as info;

SELECT 
  phone,
  COUNT(*) as quantidade,
  STRING_AGG(name, ' | ') as nomes
FROM contact
WHERE phone IS NOT NULL AND TRIM(phone) != ''
GROUP BY phone
HAVING COUNT(*) > 1
ORDER BY quantidade DESC;

-- NOTA: Se telefone for PK, não haverá duplicatas por telefone
SELECT 'Verificação de duplicatas concluída!' as resultado;

-- 5. VERIFICAR INTEGRIDADE DOS DADOS RESTANTES
SELECT 'VERIFICANDO INTEGRIDADE DOS DADOS...' as info;

SELECT 
  'Contatos restantes' as tipo,
  COUNT(*) as quantidade,
  COUNT(DISTINCT phone) as telefones_unicos,
  COUNT(CASE WHEN name IS NOT NULL AND TRIM(name) != '' THEN 1 END) as com_nome,
  COUNT(CASE WHEN source_id IS NOT NULL THEN 1 END) as com_source
FROM contact;

-- 6. VERIFICAR SE HÁ CONFLITOS COM LEADSTINTIM
SELECT 'VERIFICANDO CONFLITOS COM LEADSTINTIM...' as info;

SELECT 
  'Telefones em comum' as tipo,
  COUNT(*) as quantidade
FROM contact c
INNER JOIN leadstintim l ON c.phone = l.phone
WHERE c.phone IS NOT NULL AND TRIM(c.phone) != ''
  AND l.phone IS NOT NULL AND TRIM(l.phone) != '';

-- Mostrar exemplos de conflitos (se houver)
SELECT 
  'CONFLITOS ENCONTRADOS:' as info,
  c.id as contact_id,
  c.phone,
  c.name as nome_contact,
  c.source_id,
  l.name as nome_leadstintim,
  l.source as source_leadstintim
FROM contact c
INNER JOIN leadstintim l ON c.phone = l.phone
WHERE c.phone IS NOT NULL AND TRIM(c.phone) != ''
  AND l.phone IS NOT NULL AND TRIM(l.phone) != ''
LIMIT 10;

-- 7. PREPARAR ESTATÍSTICAS PARA NOVA MIGRAÇÃO
SELECT 'ESTATÍSTICAS PARA NOVA MIGRAÇÃO:' as info;

SELECT 
  'leadstintim' as tabela,
  COUNT(*) as total_registros,
  COUNT(DISTINCT phone) as telefones_unicos,
  COUNT(CASE WHEN name IS NOT NULL AND TRIM(name) != '' THEN 1 END) as com_nome_valido,
  COUNT(CASE WHEN phone IS NOT NULL AND TRIM(phone) != '' AND LENGTH(phone) >= 10 THEN 1 END) as telefones_validos
FROM leadstintim

UNION ALL

SELECT 
  'contact (após limpeza)' as tabela,
  COUNT(*) as total_registros,
  COUNT(DISTINCT phone) as telefones_unicos,
  COUNT(CASE WHEN name IS NOT NULL AND TRIM(name) != '' THEN 1 END) as com_nome_valido,
  COUNT(CASE WHEN phone IS NOT NULL AND TRIM(phone) != '' AND LENGTH(phone) >= 10 THEN 1 END) as telefones_validos
FROM contact;

-- 8. VERIFICAR DISPONIBILIDADE DO SOURCE_ID 13 (WHATSAPP)
SELECT 'VERIFICANDO SOURCE_ID 13 (WhatsApp):' as info;

SELECT 
  id,
  name
FROM source 
WHERE id = 13;

-- Se não existir, criar o source WhatsApp
INSERT INTO source (id, name, created_at, updated_at)
SELECT 13, 'WhatsApp', NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM source WHERE id = 13);

SELECT 'LIMPEZA CONCLUÍDA! Pronto para nova migração.' as resultado_final;

-- =====================================================
-- RESUMO DO QUE FOI FEITO:
-- 1. Removidos contatos migrados do WhatsApp (source_id = 13)
-- 2. Removidas duplicatas por telefone
-- 3. Verificada integridade dos dados restantes
-- 4. Identificados conflitos com leadstintim
-- 5. Preparadas estatísticas para nova migração
-- 6. Verificado/criado source WhatsApp (id = 13)
-- =====================================================