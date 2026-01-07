-- =====================================================
-- SCRIPT: Adicionar Índices de Performance em leadstintim
-- DATA: 2025-01-06
-- OBJETIVO: Otimizar queries que filtram por from_me
-- =====================================================

-- 1. Verificar se a coluna from_me existe
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'leadstintim' 
        AND column_name = 'from_me'
    ) THEN
        RAISE EXCEPTION 'Coluna from_me não existe na tabela leadstintim';
    END IF;
END $$;

-- 2. Criar índice simples para from_me
-- Útil para filtrar mensagens do cliente vs empresa
CREATE INDEX IF NOT EXISTS idx_leadstintim_from_me 
ON leadstintim(from_me);

-- 3. Criar índice composto: from_me + created_at
-- Útil para queries que buscam mensagens por origem ordenadas por data
CREATE INDEX IF NOT EXISTS idx_leadstintim_from_me_created_at 
ON leadstintim(from_me, created_at DESC);

-- 4. Criar índice composto: phone + from_me + created_at
-- Útil para buscar conversas completas de um contato
CREATE INDEX IF NOT EXISTS idx_leadstintim_phone_from_me_created 
ON leadstintim(phone, from_me, created_at DESC);

-- 5. Criar índice parcial: apenas mensagens do cliente (from_me = 'false')
-- Otimiza queries que buscam apenas mensagens recebidas
CREATE INDEX IF NOT EXISTS idx_leadstintim_client_messages 
ON leadstintim(phone, created_at DESC) 
WHERE from_me = 'false';

-- 6. Criar índice parcial: apenas mensagens enviadas (from_me = 'true')
-- Otimiza queries que buscam apenas mensagens enviadas pela empresa
CREATE INDEX IF NOT EXISTS idx_leadstintim_sent_messages 
ON leadstintim(phone, created_at DESC) 
WHERE from_me = 'true';

-- =====================================================
-- VERIFICAÇÃO DOS ÍNDICES CRIADOS
-- =====================================================

SELECT 
    indexname AS "Nome do Índice",
    indexdef AS "Definição"
FROM pg_indexes 
WHERE tablename = 'leadstintim' 
AND indexname LIKE '%from_me%'
ORDER BY indexname;

-- =====================================================
-- ESTATÍSTICAS APÓS CRIAÇÃO DOS ÍNDICES
-- =====================================================

SELECT 
    'Total de registros' AS metrica,
    COUNT(*) AS valor
FROM leadstintim
UNION ALL
SELECT 
    'Mensagens do cliente (from_me = ''false'')',
    COUNT(*)
FROM leadstintim
WHERE from_me = 'false'
UNION ALL
SELECT 
    'Mensagens da empresa (from_me = ''true'')',
    COUNT(*)
FROM leadstintim
WHERE from_me = 'true'
UNION ALL
SELECT 
    'Mensagens sem from_me (NULL)',
    COUNT(*)
FROM leadstintim
WHERE from_me IS NULL;

-- =====================================================
-- EXEMPLO DE USO DOS ÍNDICES
-- =====================================================

-- Query 1: Buscar todas as mensagens recebidas de um cliente
-- USA: idx_leadstintim_client_messages
EXPLAIN ANALYZE
SELECT * FROM leadstintim 
WHERE phone = '+5511999999999' 
AND from_me = 'false' 
ORDER BY created_at DESC 
LIMIT 50;

-- Query 2: Buscar últimas mensagens enviadas pela empresa
-- USA: idx_leadstintim_sent_messages
EXPLAIN ANALYZE
SELECT * FROM leadstintim 
WHERE from_me = 'true' 
ORDER BY created_at DESC 
LIMIT 100;

-- Query 3: Buscar conversa completa de um contato
-- USA: idx_leadstintim_phone_from_me_created
EXPLAIN ANALYZE
SELECT * FROM leadstintim 
WHERE phone = '+5511999999999'
ORDER BY from_me, created_at DESC;

-- =====================================================
-- ✅ SCRIPT CONCLUÍDO COM SUCESSO
-- =====================================================
-- Índices criados:
-- 1. idx_leadstintim_from_me (simples)
-- 2. idx_leadstintim_from_me_created_at (composto)
-- 3. idx_leadstintim_phone_from_me_created (composto triplo)
-- 4. idx_leadstintim_client_messages (parcial - clientes)
-- 5. idx_leadstintim_sent_messages (parcial - empresa)
-- =====================================================
