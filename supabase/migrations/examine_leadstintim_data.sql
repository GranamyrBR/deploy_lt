-- =====================================================
-- ANÁLISE DA TABELA LEADSTINTIM - INVESTIGAÇÃO DE NOMES
-- =====================================================
-- Este script examina os dados reais da tabela leadstintim
-- para identificar problemas na migração de nomes

-- 1. Verificar estrutura da tabela leadstintim
SELECT 'Estrutura da tabela leadstintim:' as info;
\d leadstintim;

-- 2. Verificar campos disponíveis
SELECT column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_name = 'leadstintim' 
  AND table_schema = 'public'
ORDER BY ordinal_position;

-- 3. Examinar dados reais - primeiros 10 registros
SELECT 'Primeiros 10 registros da tabela leadstintim:' as info;
SELECT 
  id,
  name,
  phone,
  source,
  status,
  datefirst,
  datelast,
  created_at
FROM leadstintim 
ORDER BY id 
LIMIT 10;

-- 4. Verificar distribuição de nomes
SELECT 'Análise de nomes na tabela leadstintim:' as info;
SELECT 
  CASE 
    WHEN name IS NULL THEN 'NULL'
    WHEN TRIM(name) = '' THEN 'VAZIO'
    WHEN LENGTH(name) < 3 THEN 'MUITO_CURTO'
    ELSE 'VÁLIDO'
  END as tipo_nome,
  COUNT(*) as quantidade
FROM leadstintim 
GROUP BY 
  CASE 
    WHEN name IS NULL THEN 'NULL'
    WHEN TRIM(name) = '' THEN 'VAZIO'
    WHEN LENGTH(name) < 3 THEN 'MUITO_CURTO'
    ELSE 'VÁLIDO'
  END
ORDER BY quantidade DESC;

-- 5. Exemplos de nomes válidos
SELECT 'Exemplos de nomes válidos:' as info;
SELECT DISTINCT name, COUNT(*) as ocorrencias
FROM leadstintim 
WHERE name IS NOT NULL 
  AND TRIM(name) != ''
  AND LENGTH(name) >= 3
GROUP BY name
ORDER BY ocorrencias DESC
LIMIT 20;

-- 6. Verificar nomes problemáticos
SELECT 'Nomes problemáticos ou inválidos:' as info;
SELECT 
  id,
  name,
  phone,
  LENGTH(name) as tamanho_nome
FROM leadstintim 
WHERE name IS NULL 
   OR TRIM(name) = ''
   OR LENGTH(name) < 3
LIMIT 10;

-- 7. Verificar telefones únicos com nomes
SELECT 'Telefones únicos com seus respectivos nomes:' as info;
SELECT DISTINCT ON (phone)
  phone,
  name,
  datefirst,
  datelast
FROM leadstintim 
WHERE phone IS NOT NULL 
  AND phone != ''
  AND TRIM(phone) != ''
ORDER BY phone, datelast DESC NULLS LAST
LIMIT 20;

-- 8. Comparar com dados migrados na tabela contact
SELECT 'Comparação com dados migrados na tabela contact:' as info;
SELECT 
  c.name as nome_contact,
  c.phone as telefone_contact,
  l.name as nome_leadstintim,
  l.phone as telefone_leadstintim,
  CASE 
    WHEN c.name = l.name THEN 'IGUAL'
    WHEN c.name = 'Contato WhatsApp' THEN 'NOME_GENÉRICO'
    ELSE 'DIFERENTE'
  END as comparacao_nome
FROM contact c
INNER JOIN leadstintim l ON c.phone = l.phone
WHERE c.source_id = 13 -- WhatsApp
LIMIT 20;

-- 9. Contar problemas na migração
SELECT 'Estatísticas de problemas na migração:' as info;
SELECT 
  COUNT(*) as total_contatos_whatsapp,
  SUM(CASE WHEN c.name = 'Contato WhatsApp' THEN 1 ELSE 0 END) as nomes_genericos,
  SUM(CASE WHEN c.name != 'Contato WhatsApp' AND l.name IS NOT NULL AND TRIM(l.name) != '' THEN 1 ELSE 0 END) as nomes_preservados,
  SUM(CASE WHEN l.name IS NULL OR TRIM(l.name) = '' THEN 1 ELSE 0 END) as sem_nome_original
FROM contact c
INNER JOIN leadstintim l ON c.phone = l.phone
WHERE c.source_id = 13;

-- 10. Identificar registros que deveriam ter nomes preservados
SELECT 'Registros que deveriam ter nomes preservados:' as info;
SELECT 
  c.id as contact_id,
  c.name as nome_atual_contact,
  c.phone,
  l.name as nome_correto_leadstintim,
  l.datefirst,
  l.datelast
FROM contact c
INNER JOIN leadstintim l ON c.phone = l.phone
WHERE c.source_id = 13 -- WhatsApp
  AND c.name = 'Contato WhatsApp'
  AND l.name IS NOT NULL 
  AND TRIM(l.name) != ''
  AND LENGTH(l.name) >= 3
ORDER BY l.datelast DESC
LIMIT 20;