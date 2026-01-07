-- =====================================================
-- MODIFICAR TABELA CONTACT - TELEFONE COMO CHAVE PRIMÁRIA
-- =====================================================
-- Este script modifica a estrutura da tabela contact para usar
-- o telefone como chave primária única para identificar clientes

-- 1. BACKUP DA TABELA ATUAL
CREATE TABLE contact_backup_before_phone_pk AS SELECT * FROM contact;

-- 2. VERIFICAR DADOS ATUAIS
SELECT 'ANÁLISE DOS DADOS ATUAIS:' as info;

SELECT 
  'Total de contatos' as tipo,
  COUNT(*) as quantidade
FROM contact;

SELECT 
  'Telefones únicos' as tipo,
  COUNT(DISTINCT phone) as quantidade
FROM contact
WHERE phone IS NOT NULL AND TRIM(phone) != '';

SELECT 
  'Telefones duplicados' as tipo,
  COUNT(*) as quantidade
FROM (
  SELECT phone
  FROM contact
  WHERE phone IS NOT NULL AND TRIM(phone) != ''
  GROUP BY phone
  HAVING COUNT(*) > 1
) duplicates;

-- 3. LIMPAR TELEFONES INVÁLIDOS E DUPLICATAS
SELECT 'LIMPANDO DADOS ANTES DA MODIFICAÇÃO...' as info;

-- Remover contatos sem telefone ou com telefone inválido
DELETE FROM contact 
WHERE phone IS NULL OR TRIM(phone) = '' OR LENGTH(TRIM(phone)) < 10;

-- Remover duplicatas mantendo o mais recente
WITH duplicates AS (
  SELECT 
    id,
    phone,
    ROW_NUMBER() OVER (PARTITION BY phone ORDER BY created_at DESC, id DESC) as rn
  FROM contact
  WHERE phone IS NOT NULL AND TRIM(phone) != ''
)
DELETE FROM contact 
WHERE id IN (
  SELECT id FROM duplicates WHERE rn > 1
);

SELECT 'Dados limpos com sucesso!' as resultado;

-- 4. VERIFICAR INTEGRIDADE APÓS LIMPEZA
SELECT 'VERIFICAÇÃO APÓS LIMPEZA:' as info;

SELECT 
  'Contatos restantes' as tipo,
  COUNT(*) as quantidade,
  COUNT(DISTINCT phone) as telefones_unicos
FROM contact;

-- Verificar se ainda há duplicatas
SELECT 
  phone,
  COUNT(*) as quantidade
FROM contact
GROUP BY phone
HAVING COUNT(*) > 1;

-- 5. MODIFICAR ESTRUTURA DA TABELA
SELECT 'MODIFICANDO ESTRUTURA DA TABELA...' as info;

-- Remover a constraint de chave primária atual
ALTER TABLE contact DROP CONSTRAINT contact_pkey;

-- Adicionar constraint UNIQUE no telefone
ALTER TABLE contact ADD CONSTRAINT contact_phone_unique UNIQUE (phone);

-- Tornar o telefone NOT NULL
ALTER TABLE contact ALTER COLUMN phone SET NOT NULL;

-- Definir telefone como nova chave primária
ALTER TABLE contact ADD CONSTRAINT contact_pkey PRIMARY KEY (phone);

-- Manter o campo id como UNIQUE para compatibilidade com FKs existentes
ALTER TABLE contact ADD CONSTRAINT contact_id_unique UNIQUE (id);

SELECT 'Estrutura modificada com sucesso!' as resultado;

-- 6. VERIFICAR NOVA ESTRUTURA
SELECT 'VERIFICANDO NOVA ESTRUTURA:' as info;

-- Verificar constraints
SELECT 
  constraint_name,
  constraint_type
FROM information_schema.table_constraints 
WHERE table_name = 'contact' AND table_schema = 'public'
ORDER BY constraint_type, constraint_name;

-- Verificar colunas
SELECT 
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns 
WHERE table_name = 'contact' AND table_schema = 'public'
ORDER BY ordinal_position;

-- 7. TESTAR INSERÇÃO COM NOVA ESTRUTURA
SELECT 'TESTANDO NOVA ESTRUTURA...' as info;

-- Tentar inserir um contato de teste
INSERT INTO contact (phone, name, source_id, created_at, updated_at)
VALUES ('+5511999999999', 'Teste Estrutura Nova', 15, NOW(), NOW())
ON CONFLICT (phone) DO NOTHING;

-- Verificar se foi inserido
SELECT 
  phone,
  name,
  id
FROM contact 
WHERE phone = '+5511999999999';

-- Remover o teste
DELETE FROM contact WHERE phone = '+5511999999999';

SELECT 'Teste concluído com sucesso!' as resultado;

-- 8. ESTATÍSTICAS FINAIS
SELECT 'ESTATÍSTICAS FINAIS:' as info;

SELECT 
  'Contatos com telefone como PK' as tipo,
  COUNT(*) as quantidade,
  MIN(LENGTH(phone)) as menor_telefone,
  MAX(LENGTH(phone)) as maior_telefone
FROM contact;

SELECT 'MODIFICAÇÃO CONCLUÍDA! Telefone agora é a chave primária.' as resultado_final;

-- =====================================================
-- RESUMO DAS MODIFICAÇÕES:
-- 1. Backup da tabela original criado
-- 2. Dados limpos (removidos telefones inválidos e duplicatas)
-- 3. Chave primária alterada de 'id' para 'phone'
-- 4. Campo 'phone' agora é NOT NULL e UNIQUE
-- 5. Campo 'id' mantido como UNIQUE para compatibilidade
-- 6. Estrutura testada e validada
-- =====================================================