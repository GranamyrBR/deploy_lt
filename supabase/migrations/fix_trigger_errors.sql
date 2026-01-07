-- =====================================================
-- CORREÇÃO DE TRIGGERS PROBLEMÁTICOS
-- =====================================================
-- 
-- PROBLEMA: Triggers tentando atualizar updated_at em tabelas que não têm essa coluna
-- SOLUÇÃO: Remover triggers de tabelas sem updated_at e verificar quais tabelas precisam da coluna

-- =====================================================
-- 1. VERIFICAR QUAIS TABELAS TÊM UPDATED_AT
-- =====================================================

SELECT 
    table_name,
    column_name,
    data_type
FROM information_schema.columns 
WHERE table_schema = 'public' 
    AND column_name = 'updated_at'
ORDER BY table_name;

-- =====================================================
-- 2. LISTAR TODOS OS TRIGGERS QUE USAM update_updated_at_column
-- =====================================================

SELECT 
    trigger_name,
    event_object_table as table_name,
    action_statement
FROM information_schema.triggers 
WHERE trigger_schema = 'public' 
    AND action_statement LIKE '%update_updated_at_column%'
ORDER BY event_object_table;

-- =====================================================
-- 3. REMOVER TRIGGERS PROBLEMÁTICOS
-- =====================================================

-- Remover trigger da tabela payment_method (que não tem updated_at)
DROP TRIGGER IF EXISTS update_payment_method_updated_at ON payment_method;

-- Verificar se existem outros triggers problemáticos e removê-los
-- (Este comando será executado apenas se o trigger existir)
DROP TRIGGER IF EXISTS update_contact_updated_at ON contact;
DROP TRIGGER IF EXISTS update_service_updated_at ON service;
DROP TRIGGER IF EXISTS update_currency_updated_at ON currency;

-- =====================================================
-- 4. MANTER APENAS TRIGGERS EM TABELAS COM UPDATED_AT
-- =====================================================

-- Verificar se os triggers necessários existem e recriar se necessário
-- (Apenas para tabelas que realmente têm updated_at)

-- Trigger para sale (tem updated_at)
DROP TRIGGER IF EXISTS update_sale_updated_at ON sale;
CREATE TRIGGER update_sale_updated_at 
    BEFORE UPDATE ON sale
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Trigger para sale_item (tem updated_at)
DROP TRIGGER IF EXISTS update_sale_item_updated_at ON sale_item;
CREATE TRIGGER update_sale_item_updated_at 
    BEFORE UPDATE ON sale_item
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Trigger para sale_payment (tem updated_at)
DROP TRIGGER IF EXISTS update_sale_payment_updated_at ON sale_payment;
CREATE TRIGGER update_sale_payment_updated_at 
    BEFORE UPDATE ON sale_payment
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- 5. VERIFICAÇÃO FINAL
-- =====================================================

-- Listar triggers restantes
SELECT 
    trigger_name,
    event_object_table as table_name,
    action_statement
FROM information_schema.triggers 
WHERE trigger_schema = 'public' 
    AND action_statement LIKE '%update_updated_at_column%'
ORDER BY event_object_table;

SELECT '✅ Triggers problemáticos corrigidos!' as status;