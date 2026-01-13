-- Diagnóstico: Verificar situação da tabela monday e relação com contact

-- 1. Verificar se tabela monday tem dados
SELECT COUNT(*) as total_registros_monday FROM monday;

-- 2. Ver estrutura da tabela monday
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'monday'
ORDER BY ordinal_position;

-- 3. Ver amostra de dados da tabela monday
SELECT * FROM monday LIMIT 5;

-- 4. Verificar se contact_id da monday existe em contact
SELECT 
  COUNT(*) as total_monday,
  COUNT(DISTINCT m.contact_id) as contact_ids_unicos,
  COUNT(DISTINCT c.id) as contact_ids_existem_em_contact
FROM monday m
LEFT JOIN contact c ON m.contact_id = c.id;

-- 5. Ver contatos que estão em monday MAS não em contact (órfãos)
SELECT m.*
FROM monday m
LEFT JOIN contact c ON m.contact_id = c.id
WHERE c.id IS NULL
LIMIT 10;

-- 6. Contagem atual de origens
SELECT 
  origem,
  COUNT(*) as total
FROM contact
GROUP BY origem
ORDER BY total DESC;

-- 7. Se monday estiver vazia, verificar se há tabela monday_backup
SELECT COUNT(*) as total_registros_monday_backup FROM monday_backup;
