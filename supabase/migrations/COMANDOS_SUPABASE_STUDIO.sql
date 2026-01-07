-- =====================================================
-- COMANDOS PARA SUPABASE STUDIO - EXECUÇÃO POR FASES
-- =====================================================
-- 
-- Este arquivo contém todos os comandos organizados por fases
-- para execução direta no Supabase Studio SQL Editor
-- 
-- IMPORTANTE: Executar uma seção por vez, na ordem apresentada
-- =====================================================

-- =====================================================
-- FASE 1: VERIFICAÇÃO INICIAL
-- =====================================================

-- 1.1 Verificar estrutura atual das tabelas
SELECT table_name, column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_name IN ('sale', 'sale_item', 'sale_payment', 'operation')
ORDER BY table_name, ordinal_position;

-- 1.2 Contar registros existentes
SELECT 
    'sale' as tabela, COUNT(*) as registros FROM sale
UNION ALL
SELECT 'sale_item', COUNT(*) FROM sale_item
UNION ALL
SELECT 'sale_payment', COUNT(*) FROM sale_payment
UNION ALL
SELECT 'operation', COUNT(*) FROM operation WHERE sale_id IS NOT NULL;

-- 1.3 Criar backup manual (EXECUTAR UMA POR VEZ)
CREATE TABLE sale_backup_manual AS SELECT * FROM sale;

-- Aguardar conclusão, depois executar:
CREATE TABLE sale_item_backup_manual AS SELECT * FROM sale_item;

-- Aguardar conclusão, depois executar:
CREATE TABLE sale_payment_backup_manual AS SELECT * FROM sale_payment;

-- Aguardar conclusão, depois executar:
CREATE TABLE operation_backup_manual AS SELECT * FROM operation WHERE sale_id IS NOT NULL;

-- 1.4 Verificar backups criados
SELECT 
    'sale_backup_manual' as tabela, COUNT(*) as registros FROM sale_backup_manual
UNION ALL
SELECT 'sale_item_backup_manual', COUNT(*) FROM sale_item_backup_manual
UNION ALL
SELECT 'sale_payment_backup_manual', COUNT(*) FROM sale_payment_backup_manual
UNION ALL
SELECT 'operation_backup_manual', COUNT(*) FROM operation_backup_manual;

-- =====================================================
-- FASE 2: LIMPEZA DOS DADOS
-- =====================================================
-- 
-- COPIAR E EXECUTAR TODO O CONTEÚDO DO ARQUIVO: clean_sales_now.sql
-- 
-- =====================================================

-- =====================================================
-- FASE 3: MIGRAÇÃO - BLOCO 1 (Estrutura Básica)
-- =====================================================

-- 3.1 Adicionar novos campos à tabela sale
ALTER TABLE sale ADD COLUMN IF NOT EXISTS sale_number VARCHAR(20) UNIQUE;
ALTER TABLE sale ADD COLUMN IF NOT EXISTS total_amount_usd DECIMAL(10,2);
ALTER TABLE sale ADD COLUMN IF NOT EXISTS exchange_rate_used DECIMAL(10,6) DEFAULT 1.0;
ALTER TABLE sale ADD COLUMN IF NOT EXISTS exchange_rate_locked_at TIMESTAMP WITH TIME ZONE;
ALTER TABLE sale ADD COLUMN IF NOT EXISTS created_by_user_id UUID;
ALTER TABLE sale ADD COLUMN IF NOT EXISTS updated_by_user_id UUID;
ALTER TABLE sale ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMP WITH TIME ZONE;
ALTER TABLE sale ADD COLUMN IF NOT EXISTS deleted_by_user_id UUID;
ALTER TABLE sale ADD COLUMN IF NOT EXISTS deletion_reason TEXT;
ALTER TABLE sale ADD COLUMN IF NOT EXISTS requires_approval BOOLEAN DEFAULT FALSE;
ALTER TABLE sale ADD COLUMN IF NOT EXISTS approved_at TIMESTAMP WITH TIME ZONE;
ALTER TABLE sale ADD COLUMN IF NOT EXISTS approved_by_user_id UUID;

-- 3.2 Atualizar campos existentes com valores padrão
UPDATE sale SET 
    sale_number = 'SALE-' || LPAD(id::text, 6, '0'),
    total_amount_usd = total_amount, -- Assumindo que já está em USD
    exchange_rate_used = 1.0,
    exchange_rate_locked_at = created_at
WHERE sale_number IS NULL;

-- 3.3 Verificar atualização
SELECT id, sale_number, total_amount, total_amount_usd, exchange_rate_used
FROM sale 
LIMIT 5;

-- =====================================================
-- FASE 4: MIGRAÇÃO - BLOCO 2 (Tabelas Auxiliares)
-- =====================================================

-- 4.1 Criar tabela exchange_rate_history
CREATE TABLE IF NOT EXISTS exchange_rate_history (
    id SERIAL PRIMARY KEY,
    currency_from VARCHAR(3) NOT NULL,
    currency_to VARCHAR(3) NOT NULL DEFAULT 'USD',
    rate DECIMAL(10,6) NOT NULL,
    rate_date DATE NOT NULL,
    source VARCHAR(50) DEFAULT 'manual',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(currency_from, currency_to, rate_date)
);

-- 4.2 Inserir taxas básicas
INSERT INTO exchange_rate_history (currency_from, currency_to, rate, rate_date, source)
VALUES 
    ('USD', 'USD', 1.0, CURRENT_DATE, 'system'),
    ('BRL', 'USD', 0.20, CURRENT_DATE, 'manual')
ON CONFLICT (currency_from, currency_to, rate_date) DO NOTHING;

-- 4.3 Criar tabela audit_log
CREATE TABLE IF NOT EXISTS audit_log (
    id SERIAL PRIMARY KEY,
    table_name VARCHAR(50) NOT NULL,
    record_id INTEGER,
    operation VARCHAR(10) NOT NULL, -- INSERT, UPDATE, DELETE
    old_values JSONB,
    new_values JSONB,
    user_id UUID,
    session_id VARCHAR(100),
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 4.4 Criar tabela deleted_sales_log
CREATE TABLE IF NOT EXISTS deleted_sales_log (
    id SERIAL PRIMARY KEY,
    sale_id INTEGER NOT NULL,
    sale_data JSONB NOT NULL,
    deletion_reason TEXT,
    requires_approval BOOLEAN DEFAULT FALSE,
    approved BOOLEAN DEFAULT FALSE,
    approved_at TIMESTAMP WITH TIME ZONE,
    approved_by_user_id UUID,
    deleted_by_user_id UUID,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 4.5 Verificar tabelas criadas
SELECT table_name 
FROM information_schema.tables 
WHERE table_name IN ('exchange_rate_history', 'audit_log', 'deleted_sales_log')
ORDER BY table_name;

-- =====================================================
-- FASE 5: MIGRAÇÃO - BLOCO 3 (Funções Básicas)
-- =====================================================

-- 5.1 Função para obter taxa de câmbio
CREATE OR REPLACE FUNCTION get_latest_exchange_rate(currency_code VARCHAR(3))
RETURNS DECIMAL(10,6) AS $$
BEGIN
    IF currency_code = 'USD' THEN
        RETURN 1.0;
    END IF;
    
    RETURN COALESCE(
        (SELECT rate 
         FROM exchange_rate_history 
         WHERE currency_from = currency_code 
           AND currency_to = 'USD' 
           AND rate_date <= CURRENT_DATE 
         ORDER BY rate_date DESC 
         LIMIT 1),
        1.0
    );
END;
$$ LANGUAGE plpgsql;

-- 5.2 Função para atualizar updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 5.3 Testar funções
SELECT get_latest_exchange_rate('USD') as usd_rate;
SELECT get_latest_exchange_rate('BRL') as brl_rate;

-- =====================================================
-- FASE 6: MIGRAÇÃO - BLOCO 4 (Triggers)
-- =====================================================

-- 6.1 Trigger para updated_at na tabela sale
DROP TRIGGER IF EXISTS update_sale_updated_at ON sale;
CREATE TRIGGER update_sale_updated_at
    BEFORE UPDATE ON sale
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- 6.2 Trigger para auditoria na tabela sale
CREATE OR REPLACE FUNCTION audit_sale_changes()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO audit_log (table_name, record_id, operation, new_values)
        VALUES ('sale', NEW.id, 'INSERT', to_jsonb(NEW));
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO audit_log (table_name, record_id, operation, old_values, new_values)
        VALUES ('sale', NEW.id, 'UPDATE', to_jsonb(OLD), to_jsonb(NEW));
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO audit_log (table_name, record_id, operation, old_values)
        VALUES ('sale', OLD.id, 'DELETE', to_jsonb(OLD));
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS audit_sale_trigger ON sale;
CREATE TRIGGER audit_sale_trigger
    AFTER INSERT OR UPDATE OR DELETE ON sale
    FOR EACH ROW
    EXECUTE FUNCTION audit_sale_changes();

-- =====================================================
-- FASE 7: MIGRAÇÃO - BLOCO 5 (Índices e Views)
-- =====================================================

-- 7.1 Criar índices importantes
CREATE INDEX IF NOT EXISTS idx_sale_sale_number ON sale(sale_number);
CREATE INDEX IF NOT EXISTS idx_sale_created_by ON sale(created_by_user_id);
CREATE INDEX IF NOT EXISTS idx_sale_deleted_at ON sale(deleted_at);
CREATE INDEX IF NOT EXISTS idx_audit_log_table_record ON audit_log(table_name, record_id);
CREATE INDEX IF NOT EXISTS idx_audit_log_created_at ON audit_log(created_at);
CREATE INDEX IF NOT EXISTS idx_exchange_rate_currency_date ON exchange_rate_history(currency_from, rate_date);

-- 7.2 Criar view para vendas ativas
CREATE OR REPLACE VIEW active_sales AS
SELECT *
FROM sale
WHERE deleted_at IS NULL;

-- 7.3 Criar view para relatório de vendas
CREATE OR REPLACE VIEW sales_report AS
SELECT 
    s.id,
    s.sale_number,
    s.total_amount,
    s.total_amount_usd,
    s.exchange_rate_used,
    s.status,
    s.payment_status,
    s.sale_date,
    s.created_at,
    COUNT(si.id) as total_items,
    SUM(si.quantity) as total_quantity
FROM sale s
LEFT JOIN sale_item si ON s.id = si.sale_id
WHERE s.deleted_at IS NULL
GROUP BY s.id, s.sale_number, s.total_amount, s.total_amount_usd, 
         s.exchange_rate_used, s.status, s.payment_status, 
         s.sale_date, s.created_at;

-- =====================================================
-- FASE 8: INSTALAÇÃO DAS FUNÇÕES FLUTTER - BLOCO 1
-- =====================================================

-- 8.1 Função para definir contexto do usuário
CREATE OR REPLACE FUNCTION set_current_user_context(
    p_user_id UUID,
    p_session_id VARCHAR(100) DEFAULT NULL,
    p_ip_address INET DEFAULT NULL
)
RETURNS BOOLEAN AS $$
BEGIN
    -- Define variáveis de sessão para auditoria
    PERFORM set_config('app.current_user_id', p_user_id::text, true);
    PERFORM set_config('app.current_session_id', COALESCE(p_session_id, ''), true);
    PERFORM set_config('app.current_ip_address', COALESCE(p_ip_address::text, ''), true);
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- 8.2 Função para verificar se pode deletar venda
CREATE OR REPLACE FUNCTION can_delete_sale(p_sale_id INTEGER)
RETURNS TABLE(
    can_delete BOOLEAN,
    requires_approval BOOLEAN,
    reason TEXT
) AS $$
DECLARE
    v_sale RECORD;
    v_payment_count INTEGER;
    v_total_usd DECIMAL(10,2);
BEGIN
    -- Buscar informações da venda
    SELECT * INTO v_sale FROM sale WHERE id = p_sale_id AND deleted_at IS NULL;
    
    IF NOT FOUND THEN
        RETURN QUERY SELECT FALSE, FALSE, 'Venda não encontrada ou já deletada';
        RETURN;
    END IF;
    
    -- Verificar se tem pagamentos
    SELECT COUNT(*) INTO v_payment_count 
    FROM sale_payment 
    WHERE sale_id = p_sale_id;
    
    -- Verificar se venda está completa
    IF v_sale.status = 'completed' THEN
        RETURN QUERY SELECT FALSE, FALSE, 'Não é possível deletar venda completa';
        RETURN;
    END IF;
    
    -- Verificar se tem pagamentos
    IF v_payment_count > 0 THEN
        RETURN QUERY SELECT FALSE, FALSE, 'Não é possível deletar venda com pagamentos';
        RETURN;
    END IF;
    
    -- Verificar se precisa de aprovação (vendas > $1000)
    v_total_usd := COALESCE(v_sale.total_amount_usd, 0);
    
    IF v_total_usd > 1000 THEN
        RETURN QUERY SELECT TRUE, TRUE, 'Venda de alto valor requer aprovação para exclusão';
    ELSE
        RETURN QUERY SELECT TRUE, FALSE, 'Venda pode ser deletada diretamente';
    END IF;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- FASE 9: INSTALAÇÃO DAS FUNÇÕES FLUTTER - BLOCO 2
-- =====================================================

-- 9.1 Função para deletar venda com validação
CREATE OR REPLACE FUNCTION delete_sale_with_validation(
    p_sale_id INTEGER,
    p_reason TEXT DEFAULT NULL,
    p_user_id UUID DEFAULT NULL
)
RETURNS TABLE(
    success BOOLEAN,
    message TEXT,
    requires_approval BOOLEAN
) AS $$
DECLARE
    v_can_delete BOOLEAN;
    v_requires_approval BOOLEAN;
    v_reason TEXT;
    v_sale_data JSONB;
BEGIN
    -- Verificar se pode deletar
    SELECT cd.can_delete, cd.requires_approval, cd.reason 
    INTO v_can_delete, v_requires_approval, v_reason
    FROM can_delete_sale(p_sale_id) cd;
    
    IF NOT v_can_delete THEN
        RETURN QUERY SELECT FALSE, v_reason, FALSE;
        RETURN;
    END IF;
    
    -- Obter dados da venda para log
    SELECT to_jsonb(s.*) INTO v_sale_data FROM sale s WHERE id = p_sale_id;
    
    -- Se requer aprovação, apenas registrar no log
    IF v_requires_approval THEN
        INSERT INTO deleted_sales_log (
            sale_id, sale_data, deletion_reason, requires_approval, 
            deleted_by_user_id
        ) VALUES (
            p_sale_id, v_sale_data, p_reason, TRUE, p_user_id
        );
        
        RETURN QUERY SELECT TRUE, 'Solicitação de exclusão registrada. Aguardando aprovação.', TRUE;
        RETURN;
    END IF;
    
    -- Deletar diretamente
    -- 1. Registrar no log
    INSERT INTO deleted_sales_log (
        sale_id, sale_data, deletion_reason, requires_approval, 
        approved, approved_at, deleted_by_user_id
    ) VALUES (
        p_sale_id, v_sale_data, p_reason, FALSE, 
        TRUE, CURRENT_TIMESTAMP, p_user_id
    );
    
    -- 2. Soft delete da venda
    UPDATE sale SET 
        deleted_at = CURRENT_TIMESTAMP,
        deleted_by_user_id = p_user_id,
        deletion_reason = p_reason
    WHERE id = p_sale_id;
    
    RETURN QUERY SELECT TRUE, 'Venda deletada com sucesso.', FALSE;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- FASE 10: INSTALAÇÃO DAS FUNÇÕES FLUTTER - BLOCO 3
-- =====================================================

-- 10.1 Função para aprovar exclusão de venda
CREATE OR REPLACE FUNCTION approve_sale_deletion(
    p_deletion_log_id INTEGER,
    p_approver_user_id UUID
)
RETURNS TABLE(
    success BOOLEAN,
    message TEXT
) AS $$
DECLARE
    v_log RECORD;
BEGIN
    -- Buscar log de exclusão
    SELECT * INTO v_log 
    FROM deleted_sales_log 
    WHERE id = p_deletion_log_id 
      AND requires_approval = TRUE 
      AND approved = FALSE;
    
    IF NOT FOUND THEN
        RETURN QUERY SELECT FALSE, 'Solicitação de exclusão não encontrada ou já processada';
        RETURN;
    END IF;
    
    -- Aprovar exclusão
    UPDATE deleted_sales_log SET
        approved = TRUE,
        approved_at = CURRENT_TIMESTAMP,
        approved_by_user_id = p_approver_user_id
    WHERE id = p_deletion_log_id;
    
    -- Soft delete da venda
    UPDATE sale SET 
        deleted_at = CURRENT_TIMESTAMP,
        deleted_by_user_id = v_log.deleted_by_user_id,
        deletion_reason = v_log.deletion_reason,
        approved_at = CURRENT_TIMESTAMP,
        approved_by_user_id = p_approver_user_id
    WHERE id = v_log.sale_id;
    
    RETURN QUERY SELECT TRUE, 'Exclusão aprovada e venda deletada com sucesso.';
END;
$$ LANGUAGE plpgsql;

-- 10.2 Função para obter log de auditoria
CREATE OR REPLACE FUNCTION get_audit_log(
    p_table_name VARCHAR(50) DEFAULT NULL,
    p_record_id INTEGER DEFAULT NULL,
    p_user_id UUID DEFAULT NULL,
    p_limit INTEGER DEFAULT 100
)
RETURNS TABLE(
    id INTEGER,
    table_name VARCHAR(50),
    record_id INTEGER,
    operation VARCHAR(10),
    old_values JSONB,
    new_values JSONB,
    user_id UUID,
    created_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        al.id, al.table_name, al.record_id, al.operation,
        al.old_values, al.new_values, al.user_id, al.created_at
    FROM audit_log al
    WHERE 
        (p_table_name IS NULL OR al.table_name = p_table_name)
        AND (p_record_id IS NULL OR al.record_id = p_record_id)
        AND (p_user_id IS NULL OR al.user_id = p_user_id)
    ORDER BY al.created_at DESC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- FASE 11: INSTALAÇÃO DAS FUNÇÕES FLUTTER - BLOCO 4
-- =====================================================

-- 11.1 Função para obter vendas deletadas
CREATE OR REPLACE FUNCTION get_deleted_sales(
    p_requires_approval BOOLEAN DEFAULT NULL,
    p_approved BOOLEAN DEFAULT NULL,
    p_limit INTEGER DEFAULT 50
)
RETURNS TABLE(
    id INTEGER,
    sale_id INTEGER,
    sale_number VARCHAR(20),
    total_amount_usd DECIMAL(10,2),
    deletion_reason TEXT,
    requires_approval BOOLEAN,
    approved BOOLEAN,
    deleted_by_user_id UUID,
    approved_by_user_id UUID,
    created_at TIMESTAMP WITH TIME ZONE,
    approved_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        dsl.id, dsl.sale_id, 
        (dsl.sale_data->>'sale_number')::VARCHAR(20) as sale_number,
        (dsl.sale_data->>'total_amount_usd')::DECIMAL(10,2) as total_amount_usd,
        dsl.deletion_reason, dsl.requires_approval, dsl.approved,
        dsl.deleted_by_user_id, dsl.approved_by_user_id,
        dsl.created_at, dsl.approved_at
    FROM deleted_sales_log dsl
    WHERE 
        (p_requires_approval IS NULL OR dsl.requires_approval = p_requires_approval)
        AND (p_approved IS NULL OR dsl.approved = p_approved)
    ORDER BY dsl.created_at DESC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

-- 11.2 Função para estatísticas de auditoria
CREATE OR REPLACE FUNCTION get_audit_statistics()
RETURNS TABLE(
    total_operations BIGINT,
    sales_created BIGINT,
    sales_updated BIGINT,
    sales_deleted BIGINT,
    pending_approvals BIGINT,
    approved_deletions BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        (SELECT COUNT(*) FROM audit_log) as total_operations,
        (SELECT COUNT(*) FROM audit_log WHERE table_name = 'sale' AND operation = 'INSERT') as sales_created,
        (SELECT COUNT(*) FROM audit_log WHERE table_name = 'sale' AND operation = 'UPDATE') as sales_updated,
        (SELECT COUNT(*) FROM audit_log WHERE table_name = 'sale' AND operation = 'DELETE') as sales_deleted,
        (SELECT COUNT(*) FROM deleted_sales_log WHERE requires_approval = TRUE AND approved = FALSE) as pending_approvals,
        (SELECT COUNT(*) FROM deleted_sales_log WHERE approved = TRUE) as approved_deletions;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- FASE 12: VALIDAÇÃO FINAL
-- =====================================================

-- 12.1 Verificar estrutura da tabela sale
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'sale' 
ORDER BY ordinal_position;

-- 12.2 Verificar novas tabelas
SELECT table_name, 
       (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = t.table_name) as column_count
FROM information_schema.tables t
WHERE t.table_name IN ('exchange_rate_history', 'audit_log', 'deleted_sales_log')
ORDER BY table_name;

-- 12.3 Verificar funções criadas
SELECT routine_name, routine_type
FROM information_schema.routines 
WHERE routine_name IN (
    'get_latest_exchange_rate',
    'set_current_user_context',
    'can_delete_sale',
    'delete_sale_with_validation',
    'approve_sale_deletion',
    'get_audit_log',
    'get_deleted_sales',
    'get_audit_statistics'
)
ORDER BY routine_name;

-- 12.4 Verificar índices criados
SELECT indexname, tablename
FROM pg_indexes 
WHERE indexname LIKE 'idx_%'
ORDER BY tablename, indexname;

-- 12.5 Verificar views criadas
SELECT table_name as view_name
FROM information_schema.views 
WHERE table_name IN ('active_sales', 'sales_report')
ORDER BY table_name;

-- 12.6 Teste funcional básico
SELECT 
    'Função get_latest_exchange_rate' as teste,
    get_latest_exchange_rate('USD') as resultado;

SELECT 
    'Função get_audit_statistics' as teste,
    (SELECT total_operations FROM get_audit_statistics()) as total_operations;

-- 12.7 Verificar dados de teste
SELECT COUNT(*) as exchange_rates_count FROM exchange_rate_history;
SELECT COUNT(*) as sales_count FROM sale;
SELECT COUNT(*) as audit_logs_count FROM audit_log;

-- =====================================================
-- MENSAGEM FINAL
-- =====================================================

SELECT '✅ MIGRAÇÃO CONCLUÍDA COM SUCESSO!' as status,
       'Sistema pronto para uso com todas as funcionalidades' as message;

-- =====================================================
-- COMANDOS DE TESTE PÓS-IMPLEMENTAÇÃO
-- =====================================================

-- Teste 1: Criar uma venda de teste
/*
INSERT INTO sale (customer_id, total_amount, total_amount_usd, status, payment_status, sale_date)
VALUES (1, 500.00, 100.00, 'pending', 'pending', CURRENT_DATE);
*/

-- Teste 2: Verificar se pode deletar
/*
SELECT * FROM can_delete_sale(1);
*/

-- Teste 3: Definir contexto de usuário
/*
SELECT set_current_user_context(
    (SELECT id FROM auth.users LIMIT 1),
    'test-session',
    '127.0.0.1'::inet
);
*/

-- Teste 4: Ver estatísticas
/*
SELECT * FROM get_audit_statistics();
*/