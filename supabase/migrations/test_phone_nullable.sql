-- ============================================
-- Testar insert sem phone
-- ============================================

INSERT INTO leadstintim (name, source, message, from_me, created_at)
VALUES ('Teste Webhook', 'WhatsApp', 'Lead sem telefone', false, NOW())
RETURNING *;

-- Depois de verificar que funcionou, delete o teste
-- DELETE FROM leadstintim WHERE name = 'Teste Webhook';
