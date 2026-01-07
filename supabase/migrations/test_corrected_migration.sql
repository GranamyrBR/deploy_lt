-- =====================================================
-- TESTE E VALIDAÇÃO DA MIGRAÇÃO CORRIGIDA
-- =====================================================
-- Este script testa e valida os resultados da nova migração
-- que preserva os nomes reais da tabela leadstintim

-- 1. TESTE PRELIMINAR - VERIFICAR DADOS ANTES DA MIGRAÇÃO
SELECT 'TESTE PRELIMINAR - DADOS ANTES DA MIGRAÇÃO:' as info;

-- Verificar quantos leads têm nomes válidos na tabela leadstintim
SELECT 
  'leadstintim - análise de nomes' as tabela,
  COUNT(*) as total_registros,
  COUNT(DISTINCT phone) as telefones_unicos,
  COUNT(CASE WHEN name IS NOT NULL AND TRIM(name) != '' AND LENGTH(TRIM(name)) >= 2 THEN 1 END) as nomes_validos,
  COUNT(CASE WHEN name IS NULL OR TRIM(name) = '' OR LENGTH(TRIM(name)) < 2 THEN 1 END) as nomes_invalidos,
  ROUND(
    COUNT(CASE WHEN name IS NOT NULL AND TRIM(name) != '' AND LENGTH(TRIM(name)) >= 2 THEN 1 END) * 100.0 / 
    COUNT(*), 2
  ) as percentual_nomes_validos
FROM leadstintim
WHERE phone IS NOT NULL 
  AND phone != '' 
  AND TRIM(phone) != ''
  AND LENGTH(TRIM(phone)) >= 10;

-- Mostrar exemplos de nomes da leadstintim
SELECT 'EXEMPLOS DE NOMES NA LEADSTINTIM:' as info;
SELECT 
  phone,
  name,
  CASE 
    WHEN name IS NOT NULL AND TRIM(name) != '' AND LENGTH(TRIM(name)) >= 2 THEN 'NOME_VÁLIDO'
    ELSE 'NOME_INVÁLIDO'
  END as status_nome,
  datelast
FROM leadstintim
WHERE phone IS NOT NULL 
  AND phone != '' 
  AND TRIM(phone) != ''
  AND LENGTH(TRIM(phone)) >= 10
ORDER BY datelast DESC
LIMIT 15;

-- 2. SIMULAÇÃO DA MIGRAÇÃO (SEM EXECUTAR)
SELECT 'SIMULAÇÃO DA MIGRAÇÃO:' as info;

-- Simular o que seria migrado
WITH migration_preview AS (
  SELECT DISTINCT ON (l.phone)
    l.phone,
    l.name as nome_original,
    CASE 
      WHEN l.name IS NOT NULL AND TRIM(l.name) != '' AND LENGTH(TRIM(l.name)) >= 2 THEN TRIM(l.name)
      ELSE 'Contato WhatsApp'
    END as nome_que_seria_migrado,
    CASE 
      WHEN l.name IS NOT NULL AND TRIM(l.name) != '' AND LENGTH(TRIM(l.name)) >= 2 THEN 'NOME_REAL_PRESERVADO'
      ELSE 'NOME_GENÉRICO_USADO'
    END as resultado_migracao,
    l.datelast
  FROM leadstintim l
  WHERE l.phone IS NOT NULL 
    AND l.phone != '' 
    AND TRIM(l.phone) != ''
    AND LENGTH(TRIM(l.phone)) >= 10
    AND NOT EXISTS (
      SELECT 1 FROM contact c 
      WHERE c.phone = l.phone
    )
  ORDER BY l.phone, l.datelast DESC NULLS LAST
)
SELECT 
  resultado_migracao,
  COUNT(*) as quantidade,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) as percentual
FROM migration_preview
GROUP BY resultado_migracao
ORDER BY quantidade DESC;

-- Mostrar exemplos do que seria migrado
SELECT 'EXEMPLOS DO QUE SERIA MIGRADO:' as info;
WITH migration_preview AS (
  SELECT DISTINCT ON (l.phone)
    l.phone,
    l.name as nome_original,
    CASE 
      WHEN l.name IS NOT NULL AND TRIM(l.name) != '' AND LENGTH(TRIM(l.name)) >= 2 THEN TRIM(l.name)
      ELSE 'Contato WhatsApp'
    END as nome_que_seria_migrado,
    CASE 
      WHEN l.name IS NOT NULL AND TRIM(l.name) != '' AND LENGTH(TRIM(l.name)) >= 2 THEN 'NOME_REAL_PRESERVADO'
      ELSE 'NOME_GENÉRICO_USADO'
    END as resultado_migracao,
    l.datelast
  FROM leadstintim l
  WHERE l.phone IS NOT NULL 
    AND l.phone != '' 
    AND TRIM(l.phone) != ''
    AND LENGTH(TRIM(l.phone)) >= 10
    AND NOT EXISTS (
      SELECT 1 FROM contact c 
      WHERE c.phone = l.phone
    )
  ORDER BY l.phone, l.datelast DESC NULLS LAST
)
SELECT 
  phone,
  nome_original,
  nome_que_seria_migrado,
  resultado_migracao,
  datelast
FROM migration_preview
ORDER BY 
  CASE WHEN resultado_migracao = 'NOME_REAL_PRESERVADO' THEN 0 ELSE 1 END,
  datelast DESC
LIMIT 20;

-- 3. VERIFICAR CONFLITOS POTENCIAIS
SELECT 'VERIFICAÇÃO DE CONFLITOS:' as info;

-- Telefones que já existem na tabela contact
SELECT 
  'Telefones que já existem em contact' as tipo,
  COUNT(*) as quantidade
FROM leadstintim l
WHERE l.phone IS NOT NULL 
  AND l.phone != '' 
  AND TRIM(l.phone) != ''
  AND LENGTH(TRIM(l.phone)) >= 10
  AND EXISTS (
    SELECT 1 FROM contact c 
    WHERE c.phone = l.phone
  )

UNION ALL

SELECT 
  'Telefones únicos para migração' as tipo,
  COUNT(*) as quantidade
FROM (
  SELECT DISTINCT l.phone
  FROM leadstintim l
  WHERE l.phone IS NOT NULL 
    AND l.phone != '' 
    AND TRIM(l.phone) != ''
    AND LENGTH(TRIM(l.phone)) >= 10
    AND NOT EXISTS (
      SELECT 1 FROM contact c 
      WHERE c.phone = l.phone
    )
) unique_phones;

-- 4. TESTE PÓS-MIGRAÇÃO (EXECUTAR APÓS A MIGRAÇÃO)
SELECT 'INSTRUÇÕES PARA TESTE PÓS-MIGRAÇÃO:' as info;
SELECT 'Execute as consultas abaixo APÓS executar a migração corrigida' as instrucao;

-- Consultas para executar após a migração:
/*
-- TESTE PÓS-MIGRAÇÃO - VERIFICAR RESULTADOS
SELECT 'RESULTADOS DA MIGRAÇÃO EXECUTADA:' as info;

-- Estatísticas gerais
SELECT 
  'Contatos migrados do WhatsApp' as metrica,
  COUNT(*) as valor
FROM contact 
WHERE source_id = 13

UNION ALL

SELECT 
  'Contatos com nomes reais preservados' as metrica,
  COUNT(*) as valor
FROM contact 
WHERE source_id = 13 
  AND name != 'Contato WhatsApp'

UNION ALL

SELECT 
  'Contatos com nomes genéricos' as metrica,
  COUNT(*) as valor
FROM contact 
WHERE source_id = 13 
  AND name = 'Contato WhatsApp';

-- Verificar qualidade dos nomes migrados
SELECT 'QUALIDADE DOS NOMES MIGRADOS:' as info;
SELECT 
  CASE 
    WHEN name = 'Contato WhatsApp' THEN 'Nomes genéricos'
    ELSE 'Nomes reais preservados'
  END as tipo_nome,
  COUNT(*) as quantidade,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) as percentual
FROM contact 
WHERE source_id = 13
GROUP BY 
  CASE 
    WHEN name = 'Contato WhatsApp' THEN 'Nomes genéricos'
    ELSE 'Nomes reais preservados'
  END
ORDER BY quantidade DESC;

-- Comparar com dados originais
SELECT 'COMPARAÇÃO COM DADOS ORIGINAIS:' as info;
SELECT 
  c.phone,
  l.name as nome_original_leadstintim,
  c.name as nome_migrado_contact,
  CASE 
    WHEN l.name = c.name THEN 'NOME_PRESERVADO_CORRETAMENTE'
    WHEN c.name = 'Contato WhatsApp' AND (l.name IS NULL OR TRIM(l.name) = '' OR LENGTH(TRIM(l.name)) < 2) THEN 'NOME_GENÉRICO_CORRETO'
    ELSE 'POSSÍVEL_PROBLEMA'
  END as status_migracao,
  l.datelast,
  c.created_at
FROM contact c
INNER JOIN leadstintim l ON c.phone = l.phone
WHERE c.source_id = 13
ORDER BY 
  CASE WHEN status_migracao = 'POSSÍVEL_PROBLEMA' THEN 0 ELSE 1 END,
  l.datelast DESC
LIMIT 25;

-- Verificar se há problemas na migração
SELECT 'PROBLEMAS IDENTIFICADOS:' as info;
WITH migration_check AS (
  SELECT 
    c.phone,
    l.name as nome_original,
    c.name as nome_migrado,
    CASE 
      WHEN l.name = c.name THEN 'OK'
      WHEN c.name = 'Contato WhatsApp' AND (l.name IS NULL OR TRIM(l.name) = '' OR LENGTH(TRIM(l.name)) < 2) THEN 'OK'
      WHEN c.name != 'Contato WhatsApp' AND l.name IS NOT NULL AND TRIM(l.name) != '' AND LENGTH(TRIM(l.name)) >= 2 AND l.name != c.name THEN 'NOME_ALTERADO'
      WHEN c.name = 'Contato WhatsApp' AND l.name IS NOT NULL AND TRIM(l.name) != '' AND LENGTH(TRIM(l.name)) >= 2 THEN 'NOME_PERDIDO'
      ELSE 'OUTROS'
    END as tipo_problema
  FROM contact c
  INNER JOIN leadstintim l ON c.phone = l.phone
  WHERE c.source_id = 13
)
SELECT 
  tipo_problema,
  COUNT(*) as quantidade,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) as percentual
FROM migration_check
GROUP BY tipo_problema
ORDER BY quantidade DESC;
*/

-- 5. RESUMO DO TESTE
SELECT 'RESUMO DO TESTE DE VALIDAÇÃO:' as info;
SELECT 
  'Este script validou a lógica da migração corrigida' as resultado,
  'Execute a migração e depois as consultas comentadas acima' as proximos_passos;

-- =====================================================
-- CRITÉRIOS DE SUCESSO:
-- 1. Nomes reais da leadstintim devem ser preservados
-- 2. Apenas nomes inválidos devem usar 'Contato WhatsApp'
-- 3. Não deve haver perda de nomes válidos
-- 4. Telefones únicos devem ser migrados sem duplicatas
-- 5. Países e estados devem ser identificados corretamente
-- =====================================================