-- =====================================================
-- MIGRAÇÃO INTELIGENTE DA TABELA SALE
-- Atualiza tabela existente mantendo compatibilidade
-- =====================================================

-- =====================================================
-- 1. BACKUP DA ESTRUTURA ATUAL
-- =====================================================

-- Criar backup da tabela atual (opcional, para segurança)
CREATE TABLE sale_backup AS SELECT * FROM sale;

-- =====================================================
-- 2. ADICIONAR NOVOS CAMPOS (SEM QUEBRAR CÓDIGO EXISTENTE)
-- =====================================================

-- Campos de identificação e organização
ALTER TABLE sale ADD COLUMN IF NOT EXISTS sale_number VARCHAR(20) UNIQUE;
ALTER TABLE sale ADD COLUMN IF NOT EXISTS internal_notes TEXT;
ALTER TABLE sale ADD COLUMN IF NOT EXISTS tags TEXT[];

-- Campos de valores em USD (novos campos padronizados)
ALTER TABLE sale ADD COLUMN IF NOT EXISTS total_amount_usd NUMERIC(12,2);
ALTER TABLE sale ADD COLUMN IF NOT EXISTS discount_amount_usd NUMERIC(12,2) DEFAULT 0;
ALTER TABLE sale ADD COLUMN IF NOT EXISTS tax_amount_usd NUMERIC(12,2) DEFAULT 0;
ALTER TABLE sale ADD COLUMN IF NOT EXISTS net_amount_usd NUMERIC(12,2);

-- Campos de auditoria
ALTER TABLE sale ADD COLUMN IF NOT EXISTS created_by_user_id UUID REFERENCES "user"(id);
ALTER TABLE sale ADD COLUMN IF NOT EXISTS updated_by_user_id UUID REFERENCES "user"(id);

-- =====================================================
-- 3. MELHORAR CONSTRAINTS E VALIDAÇÕES
-- =====================================================

-- Melhorar constraint de status
ALTER TABLE sale DROP CONSTRAINT IF EXISTS sale_status_check;
ALTER TABLE sale ADD CONSTRAINT sale_status_check 
    CHECK (status IN ('draft', 'pending', 'confirmed', 'in_progress', 'completed', 'cancelled'));

-- Melhorar constraint de payment_status
ALTER TABLE sale DROP CONSTRAINT IF EXISTS sale_payment_status_check;
ALTER TABLE sale ADD CONSTRAINT sale_payment_status_check 
    CHECK (payment_status IN ('pending', 'partial', 'paid', 'overdue', 'refunded'));

-- =====================================================
-- 4. MIGRAR DADOS EXISTENTES
-- =====================================================

-- Gerar sale_number para vendas existentes
UPDATE sale 
SET sale_number = 'LCT-' || EXTRACT(YEAR FROM COALESCE(sale_date, created_at)) || '-' || LPAD(id::text, 6, '0')
WHERE sale_number IS NULL;

-- Migrar valores para USD (usar campos existentes como base)
UPDATE sale 
SET 
    total_amount_usd = COALESCE(total_amount_usd, price_in_usd, total_amount * COALESCE(exchange_rate_to_usd, 1.0)),
    net_amount_usd = COALESCE(net_amount_usd, total_amount_usd)
WHERE total_amount_usd IS NULL;

-- Definir created_by_user_id para registros existentes (usar user_id atual)
UPDATE sale 
SET created_by_user_id = user_id
WHERE created_by_user_id IS NULL AND user_id IS NOT NULL;

-- =====================================================
-- 5. CRIAR TABELAS AUXILIARES (NOVAS FUNCIONALIDADES)
-- =====================================================

-- Histórico de cotações (se não existir)
CREATE TABLE IF NOT EXISTS exchange_rate_history (
    id BIGSERIAL PRIMARY KEY,
    currency_code VARCHAR(3) NOT NULL,
    rate_to_usd NUMERIC(10,6) NOT NULL,
    rate_date DATE NOT NULL,
    source VARCHAR(50) DEFAULT 'banco_central_brasil',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(currency_code, rate_date)
);

-- Atualizar sale_item para compatibilidade
ALTER TABLE sale_item ADD COLUMN IF NOT EXISTS description TEXT;
ALTER TABLE sale_item ADD COLUMN IF NOT EXISTS requires_flight_data BOOLEAN DEFAULT FALSE;
ALTER TABLE sale_item ADD COLUMN IF NOT EXISTS requires_driver BOOLEAN DEFAULT TRUE;
ALTER TABLE sale_item ADD COLUMN IF NOT EXISTS requires_vehicle BOOLEAN DEFAULT TRUE;
ALTER TABLE sale_item ADD COLUMN IF NOT EXISTS driver_commission_percentage NUMERIC(5,2) DEFAULT 0;
ALTER TABLE sale_item ADD COLUMN IF NOT EXISTS driver_commission_fixed_usd NUMERIC(8,2) DEFAULT 0;

-- Atualizar sale_payment para nova estrutura
ALTER TABLE sale_payment ADD COLUMN IF NOT EXISTS currency_code VARCHAR(3) DEFAULT 'USD';
ALTER TABLE sale_payment ADD COLUMN IF NOT EXISTS exchange_rate_date DATE DEFAULT CURRENT_DATE;
ALTER TABLE sale_payment ADD COLUMN IF NOT EXISTS exchange_rate_source VARCHAR(50) DEFAULT 'banco_central_brasil';
ALTER TABLE sale_payment ADD COLUMN IF NOT EXISTS is_refunded BOOLEAN DEFAULT FALSE;
ALTER TABLE sale_payment ADD COLUMN IF NOT EXISTS refund_date TIMESTAMPTZ;
ALTER TABLE sale_payment ADD COLUMN IF NOT EXISTS refund_transaction_id VARCHAR(100);
ALTER TABLE sale_payment ADD COLUMN IF NOT EXISTS notes TEXT;
ALTER TABLE sale_payment ADD COLUMN IF NOT EXISTS processed_by_user_id UUID REFERENCES "user"(id);

-- =====================================================
-- 6. SISTEMA DE AUDITORIA (OPCIONAL - NÃO QUEBRA CÓDIGO)
-- =====================================================

-- Tabela de auditoria (nova funcionalidade)
CREATE TABLE IF NOT EXISTS audit_log (
    id BIGSERIAL PRIMARY KEY,
    table_name VARCHAR(100) NOT NULL,
    record_id BIGINT NOT NULL,
    operation_type VARCHAR(20) NOT NULL CHECK (operation_type IN ('INSERT', 'UPDATE', 'DELETE', 'SOFT_DELETE')),
    user_id UUID REFERENCES "user"(id),
    user_name VARCHAR(255),
    user_email VARCHAR(255),
    session_id VARCHAR(100),
    ip_address INET,
    user_agent TEXT,
    operation_timestamp TIMESTAMPTZ DEFAULT NOW(),
    old_values JSONB,
    new_values JSONB,
    changed_fields TEXT[],
    reason TEXT,
    notes TEXT,
    application_name VARCHAR(100) DEFAULT 'lecotour_dashboard',
    api_endpoint VARCHAR(255),
    request_id VARCHAR(100)
);

-- Tabela para vendas excluídas (soft delete)
CREATE TABLE IF NOT EXISTS deleted_sales_log (
    id BIGSERIAL PRIMARY KEY,
    original_sale_id BIGINT NOT NULL,
    sale_number VARCHAR(20) NOT NULL,
    customer_id INTEGER NOT NULL,
    customer_name VARCHAR(255),
    total_amount_usd NUMERIC(12,2) NOT NULL,
    total_paid_usd NUMERIC(12,2) DEFAULT 0,
    remaining_balance_usd NUMERIC(12,2) DEFAULT 0,
    status VARCHAR(20),
    payment_status VARCHAR(20),
    deleted_at TIMESTAMPTZ DEFAULT NOW(),
    deleted_by_user_id UUID NOT NULL REFERENCES "user"(id),
    deleted_by_user_name VARCHAR(255),
    deletion_reason TEXT NOT NULL,
    sale_data JSONB NOT NULL,
    sale_items_data JSONB,
    payments_data JSONB,
    affected_operations_count INTEGER DEFAULT 0,
    affected_payments_count INTEGER DEFAULT 0,
    requires_approval BOOLEAN DEFAULT FALSE,
    approved_by_user_id UUID REFERENCES "user"(id),
    approved_at TIMESTAMPTZ,
    approval_notes TEXT
);

-- =====================================================
-- 7. FUNÇÕES AUXILIARES
-- =====================================================

-- Função para buscar cotação mais recente
CREATE OR REPLACE FUNCTION get_latest_exchange_rate(p_currency_code VARCHAR(3), p_date DATE DEFAULT CURRENT_DATE)
RETURNS NUMERIC(10,6) AS $$
DECLARE
    v_rate NUMERIC(10,6);
BEGIN
    SELECT rate_to_usd INTO v_rate
    FROM exchange_rate_history
    WHERE currency_code = p_currency_code
      AND rate_date <= p_date
    ORDER BY rate_date DESC
    LIMIT 1;
    
    IF v_rate IS NULL THEN
        IF p_currency_code = 'USD' THEN
            RETURN 1.0;
        ELSE
            RAISE EXCEPTION 'Cotação não encontrada para % na data %', p_currency_code, p_date;
        END IF;
    END IF;
    
    RETURN v_rate;
END;
$$ LANGUAGE plpgsql;

-- Função para atualizar timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 8. TRIGGERS (OPCIONAIS - NÃO QUEBRAM CÓDIGO EXISTENTE)
-- =====================================================

-- Trigger para atualizar updated_at automaticamente
DROP TRIGGER IF EXISTS update_sale_updated_at ON sale;
CREATE TRIGGER update_sale_updated_at 
    BEFORE UPDATE ON sale
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_sale_item_updated_at ON sale_item;
CREATE TRIGGER update_sale_item_updated_at 
    BEFORE UPDATE ON sale_item
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_sale_payment_updated_at ON sale_payment;
CREATE TRIGGER update_sale_payment_updated_at 
    BEFORE UPDATE ON sale_payment
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- 9. VIEWS MELHORADAS (COMPATÍVEIS COM CÓDIGO EXISTENTE)
-- =====================================================

-- View consolidada de vendas
CREATE OR REPLACE VIEW sales_summary AS
SELECT 
    s.id,
    s.sale_number,
    s.customer_id,
    c.name as customer_name,
    COALESCE(s.total_amount_usd, s.total_amount) as total_amount_usd,
    s.total_amount as total_amount_original,
    s.status,
    s.payment_status,
    s.sale_date,
    
    -- Total pago
    COALESCE(SUM(sp.amount_in_usd), SUM(sp.amount), 0) as total_paid_usd,
    
    -- Saldo restante
    COALESCE(s.total_amount_usd, s.total_amount) - COALESCE(SUM(sp.amount_in_usd), SUM(sp.amount), 0) as remaining_balance_usd,
    
    -- Contadores
    COUNT(DISTINCT si.sales_item_id) as total_items,
    COUNT(DISTINCT sp.payment_id) as total_payments
    
FROM sale s
LEFT JOIN contact c ON s.customer_id = c.id
LEFT JOIN sale_item si ON s.id = si.sales_id
LEFT JOIN sale_payment sp ON s.id = sp.sales_id
GROUP BY s.id, s.sale_number, s.customer_id, c.name, s.total_amount_usd, s.total_amount, s.status, s.payment_status, s.sale_date;

-- =====================================================
-- 10. ÍNDICES PARA PERFORMANCE
-- =====================================================

CREATE INDEX IF NOT EXISTS idx_sale_customer_date ON sale(customer_id, sale_date DESC);
CREATE INDEX IF NOT EXISTS idx_sale_status ON sale(status, payment_status);
CREATE INDEX IF NOT EXISTS idx_sale_number ON sale(sale_number);
CREATE INDEX IF NOT EXISTS idx_sale_created_by ON sale(created_by_user_id);
CREATE INDEX IF NOT EXISTS idx_sale_tags ON sale USING GIN(tags);

CREATE INDEX IF NOT EXISTS idx_exchange_rate_currency_date ON exchange_rate_history(currency_code, rate_date DESC);
CREATE INDEX IF NOT EXISTS idx_audit_log_table_record ON audit_log(table_name, record_id);
CREATE INDEX IF NOT EXISTS idx_audit_log_user_timestamp ON audit_log(user_id, operation_timestamp DESC);

-- =====================================================
-- 11. COMENTÁRIOS EXPLICATIVOS
-- =====================================================

COMMENT ON COLUMN sale.sale_number IS 'Número único da venda (ex: LCT-2024-001)';
COMMENT ON COLUMN sale.total_amount_usd IS 'Valor total sempre em USD (novo padrão)';
COMMENT ON COLUMN sale.discount_amount_usd IS 'Desconto aplicado em USD';
COMMENT ON COLUMN sale.tax_amount_usd IS 'Impostos em USD';
COMMENT ON COLUMN sale.net_amount_usd IS 'Valor líquido em USD';
COMMENT ON COLUMN sale.internal_notes IS 'Notas internas (não visíveis ao cliente)';
COMMENT ON COLUMN sale.tags IS 'Tags para categorização e busca';
COMMENT ON COLUMN sale.created_by_user_id IS 'Usuário que criou a venda';
COMMENT ON COLUMN sale.updated_by_user_id IS 'Último usuário que alterou a venda';

COMMENT ON TABLE audit_log IS 'Log completo de auditoria do sistema';
COMMENT ON TABLE deleted_sales_log IS 'Registro de vendas excluídas com backup completo';
COMMENT ON TABLE exchange_rate_history IS 'Histórico de cotações para conversão de moedas';

-- =====================================================
-- 12. VALIDAÇÃO FINAL
-- =====================================================

-- Verificar se a migração foi bem-sucedida
DO $$
BEGIN
    -- Verificar se novos campos existem
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'sale' AND column_name = 'sale_number') THEN
        RAISE EXCEPTION 'Migração falhou: campo sale_number não foi criado';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'sale' AND column_name = 'total_amount_usd') THEN
        RAISE EXCEPTION 'Migração falhou: campo total_amount_usd não foi criado';
    END IF;
    
    RAISE NOTICE 'Migração concluída com sucesso! Tabela sale atualizada mantendo compatibilidade.';
END $$;

-- =====================================================
-- FIM DA MIGRAÇÃO INTELIGENTE
-- =====================================================

-- PRÓXIMOS PASSOS:
-- 1. Executar este script em ambiente de desenvolvimento
-- 2. Testar aplicação Flutter (deve funcionar normalmente)
-- 3. Implementar novas funcionalidades gradualmente
-- 4. Migrar para produção quando validado
-- 5. Documentar mudanças para a equipe