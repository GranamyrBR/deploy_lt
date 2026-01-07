-- =====================================================
-- SCRIPT OTIMIZADO DE VERIFICAÇÃO DE CONTATOS NÃO MIGRADOS
-- =====================================================
-- Este script verifica se há contatos na tabela leadstintim
-- que não foram migrados para a tabela contact
-- 
-- VERSÃO OTIMIZADA: Consultas simplificadas para evitar timeout
-- Execute as seções separadamente se necessário

-- ETAPA 1: ESTATÍSTICAS BÁSICAS (OTIMIZADA)
SELECT 'CONTAGEM BÁSICA DE REGISTROS:' as info;

-- Contagem simples sem DISTINCT para evitar timeout
SELECT 
  'leadstintim' as tabela,
  COUNT(*) as total_registros
FROM leadstintim;

SELECT 
  'contact' as tabela,
  COUNT(*) as total_registros
FROM contact;

SELECT 
  'contact_whatsapp' as tabela,
  COUNT(*) as total_registros
FROM contact
WHERE source_id = 13;

-- ETAPA 2: VERIFICAÇÃO RÁPIDA DE MIGRAÇÃO
SELECT 'VERIFICAÇÃO DE MIGRAÇÃO (AMOSTRA):' as info;

-- Verificação otimizada com LIMIT para evitar timeout
SELECT 
  COUNT(*) as amostra_nao_migrados
FROM (
  SELECT l.phone
  FROM leadstintim l
  WHERE l.phone IS NOT NULL 
    AND LENGTH(l.phone) >= 10
    AND NOT EXISTS (
      SELECT 1 FROM contact c 
      WHERE c.phone = l.phone
    )
  LIMIT 1000
) subquery;

-- ETAPA 3: EXEMPLOS DE CONTATOS NÃO MIGRADOS (OTIMIZADA)
SELECT 'EXEMPLOS DE CONTATOS NÃO MIGRADOS:' as info;

-- Busca otimizada com índices
SELECT 
  l.id,
  l.phone,
  l.name,
  l.datelast,
  CASE 
    WHEN l.name IS NOT NULL AND LENGTH(l.name) >= 2 
    THEN 'NOME_VÁLIDO'
    ELSE 'NOME_INVÁLIDO'
  END as status_nome
FROM leadstintim l
WHERE l.phone IS NOT NULL 
  AND LENGTH(l.phone) >= 10
  AND l.id NOT IN (
    SELECT DISTINCT l2.id 
    FROM leadstintim l2 
    INNER JOIN contact c ON c.phone = l2.phone
    WHERE l2.id = l.id
  )
ORDER BY l.id DESC
LIMIT 10;

-- ETAPA 4: ANÁLISE SIMPLIFICADA POR PERÍODO
SELECT 'CONTATOS RECENTES (ÚLTIMOS 30 DIAS):' as info;

-- Contagem simples de contatos recentes
SELECT 
  COUNT(*) as contatos_recentes_leadstintim
FROM leadstintim l
WHERE l.datelast >= CURRENT_DATE - INTERVAL '30 days'
  AND l.phone IS NOT NULL;

-- Exemplos de contatos recentes (sem verificação de migração para evitar timeout)
SELECT 
  l.phone,
  l.name,
  l.datelast
FROM leadstintim l
WHERE l.phone IS NOT NULL 
  AND LENGTH(l.phone) >= 10
  AND l.datelast >= CURRENT_DATE - INTERVAL '30 days'
ORDER BY l.datelast DESC
LIMIT 5;

-- ETAPA 5: ANÁLISE SIMPLIFICADA DE QUALIDADE
SELECT 'QUALIDADE DOS DADOS LEADSTINTIM:' as info;

-- Análise simples da qualidade dos nomes (sem verificação de migração)
SELECT 
  CASE 
    WHEN l.name IS NULL THEN 'NOME_NULL'
    WHEN LENGTH(l.name) < 2 THEN 'NOME_CURTO'
    ELSE 'NOME_VÁLIDO'
  END as categoria_nome,
  COUNT(*) as quantidade
FROM leadstintim l
WHERE l.phone IS NOT NULL 
  AND LENGTH(l.phone) >= 10
GROUP BY 
  CASE 
    WHEN l.name IS NULL THEN 'NOME_NULL'
    WHEN LENGTH(l.name) < 2 THEN 'NOME_CURTO'
    ELSE 'NOME_VÁLIDO'
  END
ORDER BY quantidade DESC;

-- ETAPA 6: VERIFICAÇÃO SIMPLES DE FORMATAÇÃO
SELECT 'EXEMPLOS DE FORMATAÇÃO DE TELEFONE:' as info;

-- Exemplos de diferentes formatos de telefone em leadstintim
SELECT 
  l.phone,
  LENGTH(l.phone) as tamanho,
  CASE 
    WHEN l.phone LIKE '+%' THEN 'COM_CODIGO_PAIS'
    WHEN LENGTH(l.phone) > 11 THEN 'LONGO'
    ELSE 'FORMATO_SIMPLES'
  END as tipo_formato
FROM leadstintim l
WHERE l.phone IS NOT NULL
GROUP BY l.phone, LENGTH(l.phone)
ORDER BY LENGTH(l.phone) DESC
LIMIT 10;

-- ETAPA 7: CONTATOS COM NOMES VÁLIDOS
SELECT 'CONTATOS COM NOMES VÁLIDOS EM LEADSTINTIM:' as info;

-- Contagem simples de contatos com nomes válidos
SELECT 
  COUNT(*) as contatos_com_nome_valido
FROM leadstintim l
WHERE l.phone IS NOT NULL 
  AND LENGTH(l.phone) >= 10
  AND l.name IS NOT NULL 
  AND LENGTH(l.name) >= 2;

-- Exemplos de contatos com nomes válidos
SELECT 
  l.phone,
  l.name,
  l.datelast
FROM leadstintim l
WHERE l.phone IS NOT NULL 
  AND LENGTH(l.phone) >= 10
  AND l.name IS NOT NULL 
  AND LENGTH(l.name) >= 2
ORDER BY l.datelast DESC
LIMIT 10;

-- ETAPA 8: RESUMO SIMPLIFICADO
SELECT 'RESUMO FINAL:' as info;

-- Estatísticas básicas sem subconsultas complexas
SELECT 
  'leadstintim_total' as metrica,
  COUNT(*) as valor
FROM leadstintim
WHERE phone IS NOT NULL AND LENGTH(phone) >= 10

UNION ALL

SELECT 
  'contact_total' as metrica,
  COUNT(*) as valor
FROM contact
WHERE phone IS NOT NULL

UNION ALL

SELECT 
  'leadstintim_com_nome' as metrica,
  COUNT(*) as valor
FROM leadstintim
WHERE phone IS NOT NULL 
  AND LENGTH(phone) >= 10
  AND name IS NOT NULL 
  AND LENGTH(name) >= 2;

SELECT '✅ VERIFICAÇÃO OTIMIZADA CONCLUÍDA!' as resultado;
SELECT 'Script otimizado para evitar timeouts. Execute seções individuais se necessário.' as instrucao;
SELECT 'Para verificação completa de migração, execute consultas menores com LIMIT.' as dica;