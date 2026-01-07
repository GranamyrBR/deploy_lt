-- Verificar dados da tabela leadstintim
SELECT 'Verificando estrutura da tabela leadstintim...' as info;

-- Contar total de registros
SELECT COUNT(*) as total_registros FROM leadstintim;

-- Verificar primeiros 5 registros
SELECT 
  id,
  name,
  phone,
  source,
  status,
  datefirst,
  datelast,
  message
FROM leadstintim 
ORDER BY id 
LIMIT 5;

-- Verificar registros com telefone não nulo
SELECT COUNT(*) as registros_com_telefone 
FROM leadstintim 
WHERE phone IS NOT NULL AND TRIM(phone) != '';

-- Verificar exemplos de telefones
SELECT DISTINCT phone 
FROM leadstintim 
WHERE phone IS NOT NULL AND TRIM(phone) != ''
ORDER BY phone
LIMIT 10;

-- Verificar se há registros recentes
SELECT 
  id,
  name,
  phone,
  datelast
FROM leadstintim 
WHERE datelast >= CURRENT_DATE - INTERVAL '30 days'
ORDER BY datelast DESC
LIMIT 5;