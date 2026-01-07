-- =====================================================
-- SCRIPT RÁPIDO DE VERIFICAÇÃO DE STATUS DE MIGRAÇÃO
-- =====================================================
-- Este script executa verificações rápidas e específicas
-- para identificar o status da migração entre leadstintim e contact

-- VERIFICAÇÃO 1: Contagem básica de registros
SELECT 'CONTAGEM BÁSICA:' as verificacao;

SELECT 
  'leadstintim' as tabela,
  COUNT(*) as total
FROM leadstintim;

SELECT 
  'contact' as tabela,
  COUNT(*) as total
FROM contact;

-- VERIFICAÇÃO 2: Amostra de telefones únicos não migrados (LIMITE PEQUENO)
SELECT 'AMOSTRA DE NÃO MIGRADOS (LIMITE 50):' as verificacao;

SELECT 
  l.phone,
  l.name,
  l.datelast
FROM leadstintim l
WHERE l.phone IS NOT NULL 
  AND LENGTH(l.phone) >= 10
  AND l.phone NOT IN (
    SELECT DISTINCT c.phone 
    FROM contact c 
    WHERE c.phone IS NOT NULL
    LIMIT 1000  -- Limita a subconsulta
  )
LIMIT 50;

-- VERIFICAÇÃO 3: Contatos recentes em leadstintim
SELECT 'CONTATOS RECENTES LEADSTINTIM:' as verificacao;

SELECT 
  COUNT(*) as contatos_ultimos_7_dias
FROM leadstintim
WHERE datelast >= CURRENT_DATE - INTERVAL '7 days';

-- VERIFICAÇÃO 4: Exemplos de telefones com formatos diferentes
SELECT 'FORMATOS DE TELEFONE:' as verificacao;

SELECT 
  SUBSTRING(phone, 1, 3) as prefixo,
  COUNT(*) as quantidade
FROM leadstintim
WHERE phone IS NOT NULL
GROUP BY SUBSTRING(phone, 1, 3)
ORDER BY quantidade DESC
LIMIT 10;

-- VERIFICAÇÃO 5: Status de nomes em leadstintim
SELECT 'STATUS DOS NOMES:' as verificacao;

SELECT 
  CASE 
    WHEN name IS NULL THEN 'SEM_NOME'
    WHEN LENGTH(name) < 2 THEN 'NOME_CURTO'
    ELSE 'NOME_OK'
  END as status_nome,
  COUNT(*) as quantidade
FROM leadstintim
WHERE phone IS NOT NULL
GROUP BY 
  CASE 
    WHEN name IS NULL THEN 'SEM_NOME'
    WHEN LENGTH(name) < 2 THEN 'NOME_CURTO'
    ELSE 'NOME_OK'
  END;

-- VERIFICAÇÃO 6: Verificação direta de alguns telefones específicos
SELECT 'VERIFICAÇÃO DIRETA DE MIGRAÇÃO:' as verificacao;

SELECT 
  l.phone as telefone_leadstintim,
  l.name as nome_leadstintim,
  CASE 
    WHEN EXISTS (SELECT 1 FROM contact c WHERE c.phone = l.phone) 
    THEN 'MIGRADO' 
    ELSE 'NÃO_MIGRADO' 
  END as status_migracao
FROM leadstintim l
WHERE l.phone IS NOT NULL 
  AND LENGTH(l.phone) >= 10
ORDER BY l.id DESC
LIMIT 20;

SELECT '✅ VERIFICAÇÃO RÁPIDA CONCLUÍDA!' as resultado;
SELECT 'Este script executa verificações rápidas para evitar timeouts.' as info;