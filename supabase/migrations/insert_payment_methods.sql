-- =====================================================
-- INSERIR MÉTODOS DE PAGAMENTO PADRÃO
-- =====================================================
-- 
-- NOTA: A tabela payment_method é uma tabela de referência/categoria
-- que não precisa de colunas created_at/updated_at nem triggers.
-- Ela apenas armazena os tipos de métodos de pagamento disponíveis.

-- Inserir métodos de pagamento básicos
INSERT INTO public.payment_method (payment_method_id, method_name) VALUES 
(1, 'PIX'),
(2, 'Cartão de Crédito'),
(3, 'Transferência Bancária'),
(4, 'Dinheiro'),
(5, 'Zelle')
ON CONFLICT (payment_method_id) DO UPDATE SET 
    method_name = EXCLUDED.method_name;

-- Verificar se os dados foram inseridos corretamente
SELECT payment_method_id, method_name FROM public.payment_method ORDER BY payment_method_id;

SELECT '✅ Métodos de pagamento inseridos com sucesso!' as status;