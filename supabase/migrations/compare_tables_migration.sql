-- =====================================================
-- COMPARAÇÃO ENTRE TABELAS LEADSTINTIM E CONTACT
-- =====================================================
-- Este script compara os dados entre as tabelas para identificar
-- problemas na migração, considerando que a tabela contact já tinha dados de teste

-- 1. ESTATÍSTICAS GERAIS DAS TABELAS
SELECT 'ESTATÍSTICAS GERAIS:' as info;

SELECT 
  'leadstintim' as tabela,
  COUNT(*) as total_registros,
  COUNT(DISTINCT phone) as telefones_unicos,
  COUNT(CASE WHEN name IS NOT NULL AND TRIM(name) != '' THEN 1 END) as com_nome,
  COUNT(CASE WHEN name IS NULL OR TRIM(name) = '' THEN 1 END) as sem_nome
FROM leadstintim
WHERE phone IS NOT NULL AND TRIM(phone) != ''

UNION ALL

SELECT 
  'contact (todos)' as tabela,
  COUNT(*) as total_registros,
  COUNT(DISTINCT phone) as telefones_unicos,
  COUNT(CASE WHEN name IS NOT NULL AND TRIM(name) != '' THEN 1 END) as com_nome,
  COUNT(CASE WHEN name IS NULL OR TRIM(name) = '' THEN 1 END) as sem_nome
FROM contact
WHERE phone IS NOT NULL AND TRIM(phone) != ''

UNION ALL

SELECT 
  'contact (WhatsApp)' as tabela,
  COUNT(*) as total_registros,
  COUNT(DISTINCT phone) as telefones_unicos,
  COUNT(CASE WHEN name IS NOT NULL AND TRIM(name) != '' THEN 1 END) as com_nome,
  COUNT(CASE WHEN name IS NULL OR TRIM(name) = '' THEN 1 END) as sem_nome
FROM contact
WHERE source_id = 13 -- WhatsApp
  AND phone IS NOT NULL AND TRIM(phone) != '';

-- 2. ANÁLISE DE SOBREPOSIÇÃO DE TELEFONES
SELECT '\nSOBREPOSIÇÃO DE TELEFONES:' as info;

WITH phone_analysis AS (
  SELECT 
    l.phone,
    l.name as nome_leadstintim,
    c.name as nome_contact,
    c.source_id,
    c.id as contact_id,
    l.datefirst,
    l.datelast,
    c.created_at as contact_created_at,
    CASE 
      WHEN c.source_id = 13 THEN 'MIGRADO_WHATSAPP'
      WHEN c.source_id != 13 THEN 'DADOS_TESTE_ORIGINAIS'
      ELSE 'OUTROS'
    END as tipo_contact
  FROM leadstintim l
  LEFT JOIN contact c ON l.phone = c.phone
  WHERE l.phone IS NOT NULL AND TRIM(l.phone) != ''
)
SELECT 
  tipo_contact,
  COUNT(*) as quantidade,
  COUNT(CASE WHEN nome_contact = 'Contato WhatsApp' THEN 1 END) as nomes_genericos,
  COUNT(CASE WHEN nome_contact != 'Contato WhatsApp' AND nome_contact IS NOT NULL THEN 1 END) as nomes_especificos
FROM phone_analysis
GROUP BY tipo_contact
ORDER BY quantidade DESC;

-- 3. TELEFONES QUE EXISTEM EM AMBAS AS TABELAS
SELECT '\nTELEFONES EM AMBAS AS TABELAS (primeiros 20):' as info;

SELECT 
  l.phone,
  l.name as nome_original_leadstintim,
  c.name as nome_atual_contact,
  c.source_id,
  CASE 
    WHEN c.source_id = 13 THEN 'Migrado do WhatsApp'
    ELSE 'Dados de teste originais'
  END as origem_contact,
  CASE 
    WHEN l.name = c.name THEN 'NOMES_IGUAIS'
    WHEN c.name = 'Contato WhatsApp' THEN 'NOME_GENÉRICO_USADO'
    WHEN l.name IS NULL OR TRIM(l.name) = '' THEN 'SEM_NOME_ORIGINAL'
    ELSE 'NOMES_DIFERENTES'
  END as status_comparacao,
  l.datelast,
  c.created_at
FROM leadstintim l
INNER JOIN contact c ON l.phone = c.phone
WHERE l.phone IS NOT NULL AND TRIM(l.phone) != ''
ORDER BY l.datelast DESC
LIMIT 20;

-- 4. TELEFONES ÚNICOS EM CADA TABELA
SELECT '\nTELEFONES ÚNICOS EM LEADSTINTIM (não migrados):' as info;

SELECT COUNT(*) as telefones_nao_migrados
FROM leadstintim l
WHERE l.phone IS NOT NULL 
  AND TRIM(l.phone) != ''
  AND NOT EXISTS (
    SELECT 1 FROM contact c 
    WHERE c.phone = l.phone
  );

SELECT '\nExemplos de telefones não migrados:' as info;

SELECT 
  l.phone,
  l.name,
  l.source,
  l.status,
  l.datelast
FROM leadstintim l
WHERE l.phone IS NOT NULL 
  AND TRIM(l.phone) != ''
  AND NOT EXISTS (
    SELECT 1 FROM contact c 
    WHERE c.phone = l.phone
  )
ORDER BY l.datelast DESC
LIMIT 10;

-- 5. PROBLEMAS IDENTIFICADOS NA MIGRAÇÃO
SELECT '\nPROBLEMAS NA MIGRAÇÃO:' as info;

WITH migration_problems AS (
  SELECT 
    l.phone,
    l.name as nome_correto,
    c.name as nome_migrado,
    c.id as contact_id,
    l.datelast,
    CASE 
      WHEN c.name = 'Contato WhatsApp' AND l.name IS NOT NULL AND TRIM(l.name) != '' THEN 'NOME_PERDIDO'
      WHEN c.name != l.name AND l.name IS NOT NULL AND TRIM(l.name) != '' THEN 'NOME_ALTERADO'
      WHEN l.name IS NULL OR TRIM(l.name) = '' THEN 'SEM_NOME_ORIGINAL'
      ELSE 'OK'
    END as tipo_problema
  FROM contact c
  INNER JOIN leadstintim l ON c.phone = l.phone
  WHERE c.source_id = 13 -- WhatsApp
)
SELECT 
  tipo_problema,
  COUNT(*) as quantidade,
  CASE 
    WHEN SUM(COUNT(*)) OVER () > 0 THEN ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2)
    ELSE 0
  END as percentual
FROM migration_problems
GROUP BY tipo_problema
ORDER BY quantidade DESC;

-- 6. CASOS ESPECÍFICOS QUE PRECISAM SER CORRIGIDOS
SELECT '\nCASOS QUE PRECISAM CORREÇÃO (primeiros 15):' as info;

SELECT 
  c.id as contact_id,
  c.phone,
  c.name as nome_atual_incorreto,
  l.name as nome_correto_leadstintim,
  l.datelast as ultima_interacao,
  'UPDATE contact SET name = ''' || l.name || ''' WHERE id = ' || c.id || ';' as sql_correcao
FROM contact c
INNER JOIN leadstintim l ON c.phone = l.phone
WHERE c.source_id = 13 -- WhatsApp
  AND c.name = 'Contato WhatsApp'
  AND l.name IS NOT NULL 
  AND TRIM(l.name) != ''
  AND LENGTH(l.name) >= 3
ORDER BY l.datelast DESC
LIMIT 15;

-- 7. VERIFICAR CONFLITOS COM DADOS DE TESTE
SELECT '\nCONFLITOS COM DADOS DE TESTE:' as info;

SELECT 
  'Telefones que existiam antes da migração' as tipo,
  COUNT(*) as quantidade
FROM contact c
WHERE c.source_id != 13 -- Não WhatsApp
  AND EXISTS (
    SELECT 1 FROM leadstintim l 
    WHERE l.phone = c.phone
  )

UNION ALL

SELECT 
  'Telefones duplicados após migração' as tipo,
  COUNT(*) as quantidade
FROM (
  SELECT phone, COUNT(*) as cnt
  FROM contact
  WHERE phone IS NOT NULL AND TRIM(phone) != ''
  GROUP BY phone
  HAVING COUNT(*) > 1
) duplicates;

-- 8. RESUMO EXECUTIVO
SELECT '\nRESUMO EXECUTIVO:' as info;

WITH summary_stats AS (
  SELECT 
    COUNT(DISTINCT l.phone) as total_phones_leadstintim,
    COUNT(DISTINCT CASE WHEN c.source_id = 13 THEN c.phone END) as phones_migrados,
    COUNT(CASE WHEN c.source_id = 13 AND c.name = 'Contato WhatsApp' THEN 1 END) as nomes_genericos,
    COUNT(CASE WHEN c.source_id = 13 AND c.name = 'Contato WhatsApp' AND l.name IS NOT NULL AND TRIM(l.name) != '' THEN 1 END) as nomes_perdidos
  FROM leadstintim l
  LEFT JOIN contact c ON l.phone = c.phone
  WHERE l.phone IS NOT NULL AND TRIM(l.phone) != ''
)
SELECT 
  total_phones_leadstintim as telefones_total_leadstintim,
  phones_migrados as telefones_migrados_contact,
  CASE 
    WHEN total_phones_leadstintim > 0 THEN ROUND(phones_migrados * 100.0 / total_phones_leadstintim, 2)
    ELSE 0
  END as percentual_migrado,
  nomes_genericos as contatos_com_nome_generico,
  nomes_perdidos as nomes_reais_perdidos,
  CASE 
    WHEN phones_migrados > 0 THEN ROUND(nomes_perdidos * 100.0 / phones_migrados, 2)
    ELSE 0
  END as percentual_nomes_perdidos
FROM summary_stats;