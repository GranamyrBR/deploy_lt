-- ============================================
-- Fix: Tornar coluna phone opcional em leadstintim
-- Motivo: Webhook pode receber leads sem telefone
-- ============================================

-- 1. Remover constraint NOT NULL
ALTER TABLE leadstintim 
ALTER COLUMN phone DROP NOT NULL;

-- 2. Remover CHECK constraint que impede valores vazios
ALTER TABLE leadstintim 
DROP CONSTRAINT IF EXISTS leadstintim_phone_check;

-- 3. Adicionar CHECK mais flexível (permite NULL ou valor válido)
ALTER TABLE leadstintim 
ADD CONSTRAINT leadstintim_phone_check 
CHECK (phone IS NULL OR phone <> ''::text);

-- 4. Criar índice para buscas por telefone (ignorando nulls)
CREATE INDEX IF NOT EXISTS idx_leadstintim_phone 
ON leadstintim(phone) 
WHERE phone IS NOT NULL;

-- Comentário na coluna
COMMENT ON COLUMN leadstintim.phone IS 
'Telefone do lead (opcional). Pode ser NULL se não fornecido no webhook.';
