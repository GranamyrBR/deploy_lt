-- =====================================================
-- FUNÇÕES PARA INTEGRAÇÃO FLUTTER - COMPATÍVEL
-- Funciona com tabela 'sale' atualizada (não sale_v2)
-- =====================================================

-- =====================================================
-- 1. FUNÇÃO PARA DEFINIR CONTEXTO DO USUÁRIO
-- =====================================================

CREATE OR REPLACE FUNCTION set_current_user_context(
    p_user_id UUID,
    p_session_id VARCHAR(100) DEFAULT NULL,
    p_ip_address INET DEFAULT NULL,
    p_user_agent TEXT DEFAULT NULL
)
RETURNS VOID AS $$
BEGIN
    -- Definir variáveis de sessão para auditoria
    PERFORM set_config('app.current_user_id', p_user_id::text, true);
    PERFORM set_config('app.current_session_id', COALESCE(p_session_id, ''), true);
    PERFORM set_config('app.current_ip_address', COALESCE(p_ip_address::text, ''), true);
    PERFORM set_config('app.current_user_agent', COALESCE(p_user_agent, ''), true);
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 2. FUNÇÃO PARA VERIFICAR SE PODE EXCLUIR VENDA
-- =====================================================

CREATE OR REPLACE FUNCTION can_delete_sale(p_sale_id BIGINT)
RETURNS TABLE(
    can_delete BOOLEAN,
    reason TEXT,
    requires_approval BOOLEAN,
    total_amount_usd NUMERIC(12,2),
    payment_count INTEGER,
    operation_count INTEGER
) AS $$
DECLARE
    v_sale RECORD;
    v_payment_count INTEGER;
    v_operation_count INTEGER;
    v_total_paid NUMERIC(12,2);
BEGIN
    -- Buscar dados da venda
    SELECT s.*, COALESCE(s.total_amount_usd, s.total_amount) as amount_usd
    INTO v_sale
    FROM sale s
    WHERE s.id = p_sale_id;
    
    IF NOT FOUND THEN
        RETURN QUERY SELECT false, 'Venda não encontrada', false, 0::NUMERIC(12,2), 0, 0;
        RETURN;
    END IF;
    
    -- Contar pagamentos
    SELECT COUNT(*), COALESCE(SUM(COALESCE(amount_in_usd, amount)), 0)
    INTO v_payment_count, v_total_paid
    FROM sale_payment
    WHERE sale_id = p_sale_id;
    
    -- Contar operações
    SELECT COUNT(*)
    INTO v_operation_count
    FROM operation
    WHERE sale_id = p_sale_id;
    
    -- Regras de validação
    IF v_sale.status = 'completed' THEN
        RETURN QUERY SELECT false, 'Não é possível excluir venda concluída', false, v_sale.amount_usd, v_payment_count, v_operation_count;
        RETURN;
    END IF;
    
    IF v_total_paid > 0 THEN
        RETURN QUERY SELECT false, 'Não é possível excluir venda com pagamentos realizados', false, v_sale.amount_usd, v_payment_count, v_operation_count;
        RETURN;
    END IF;
    
    -- Verificar se requer aprovação (vendas acima de $1000)
    IF v_sale.amount_usd > 1000 THEN
        RETURN QUERY SELECT true, 'Venda de alto valor - requer aprovação', true, v_sale.amount_usd, v_payment_count, v_operation_count;
        RETURN;
    END IF;
    
    -- Pode excluir normalmente
    RETURN QUERY SELECT true, 'Venda pode ser excluída', false, v_sale.amount_usd, v_payment_count, v_operation_count;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 3. FUNÇÃO PARA EXCLUIR VENDA COM VALIDAÇÃO
-- =====================================================

CREATE OR REPLACE FUNCTION delete_sale_with_validation(
    p_sale_id BIGINT,
    p_reason TEXT,
    p_user_id UUID DEFAULT NULL
)
RETURNS TABLE(
    success BOOLEAN,
    message TEXT,
    requires_approval BOOLEAN,
    deletion_log_id BIGINT
) AS $$
DECLARE
    v_can_delete RECORD;
    v_sale RECORD;
    v_user_id UUID;
    v_log_id BIGINT;
BEGIN
    -- Obter user_id do contexto se não fornecido
    v_user_id := COALESCE(p_user_id, current_setting('app.current_user_id', true)::UUID);
    
    IF v_user_id IS NULL THEN
        RETURN QUERY SELECT false, 'Usuário não identificado', false, NULL::BIGINT;
        RETURN;
    END IF;
    
    -- Verificar se pode excluir
    SELECT * INTO v_can_delete FROM can_delete_sale(p_sale_id);
    
    IF NOT v_can_delete.can_delete THEN
        RETURN QUERY SELECT false, v_can_delete.reason, false, NULL::BIGINT;
        RETURN;
    END IF;
    
    -- Buscar dados completos da venda
    SELECT * INTO v_sale FROM sale WHERE id = p_sale_id;
    
    -- Registrar na tabela de exclusões
    INSERT INTO deleted_sales_log (
        original_sale_id,
        sale_number,
        customer_id,
        customer_name,
        total_amount_usd,
        status,
        payment_status,
        deleted_by_user_id,
        deleted_by_user_name,
        deletion_reason,
        sale_data,
        requires_approval
    )
    SELECT 
        v_sale.id,
        COALESCE(v_sale.sale_number, 'LCT-' || v_sale.id),
        v_sale.customer_id,
        c.name,
        COALESCE(v_sale.total_amount_usd, v_sale.total_amount),
        v_sale.status,
        v_sale.payment_status,
        v_user_id,
        u.name,
        p_reason,
        to_jsonb(v_sale),
        v_can_delete.requires_approval
    FROM sale s
    LEFT JOIN contact c ON s.customer_id = c.id
    LEFT JOIN "user" u ON u.id = v_user_id
    WHERE s.id = p_sale_id
    RETURNING id INTO v_log_id;
    
    -- Se requer aprovação, não excluir ainda
    IF v_can_delete.requires_approval THEN
        RETURN QUERY SELECT true, 'Solicitação de exclusão registrada - aguardando aprovação', true, v_log_id;
        RETURN;
    END IF;
    
    -- Excluir registros relacionados
    DELETE FROM sale_item WHERE sale_id = p_sale_id;
    DELETE FROM operation WHERE sale_id = p_sale_id;
    DELETE FROM sale_payment WHERE sale_id = p_sale_id;
    
    -- Excluir a venda
    DELETE FROM sale WHERE id = p_sale_id;
    
    -- Registrar auditoria
    INSERT INTO audit_log (
        table_name,
        record_id,
        operation_type,
        user_id,
        reason,
        old_values
    ) VALUES (
        'sale',
        p_sale_id,
        'DELETE',
        v_user_id,
        p_reason,
        to_jsonb(v_sale)
    );
    
    RETURN QUERY SELECT true, 'Venda excluída com sucesso', false, v_log_id;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 4. FUNÇÃO PARA APROVAR EXCLUSÃO DE VENDA
-- =====================================================

CREATE OR REPLACE FUNCTION approve_sale_deletion(
    p_deletion_log_id BIGINT,
    p_approver_user_id UUID,
    p_approval_notes TEXT DEFAULT NULL
)
RETURNS TABLE(
    success BOOLEAN,
    message TEXT
) AS $$
DECLARE
    v_deletion_log RECORD;
    v_sale_id BIGINT;
BEGIN
    -- Buscar log de exclusão
    SELECT * INTO v_deletion_log
    FROM deleted_sales_log
    WHERE id = p_deletion_log_id
      AND requires_approval = true
      AND approved_at IS NULL;
    
    IF NOT FOUND THEN
        RETURN QUERY SELECT false, 'Solicitação de exclusão não encontrada ou já processada';
        RETURN;
    END IF;
    
    v_sale_id := v_deletion_log.original_sale_id;
    
    -- Verificar se a venda ainda existe
    IF NOT EXISTS (SELECT 1 FROM sale WHERE id = v_sale_id) THEN
        RETURN QUERY SELECT false, 'Venda já foi excluída';
        RETURN;
    END IF;
    
    -- Atualizar log com aprovação
    UPDATE deleted_sales_log
    SET 
        approved_by_user_id = p_approver_user_id,
        approved_at = NOW(),
        approval_notes = p_approval_notes
    WHERE id = p_deletion_log_id;
    
    -- Excluir registros relacionados
    DELETE FROM sale_item WHERE sale_id = v_sale_id;
        DELETE FROM operation WHERE sale_id = v_sale_id;
        DELETE FROM sale_payment WHERE sale_id = v_sale_id;
    
    -- Excluir a venda
    DELETE FROM sale WHERE id = v_sale_id;
    
    -- Registrar auditoria da aprovação
    INSERT INTO audit_log (
        table_name,
        record_id,
        operation_type,
        user_id,
        reason,
        notes
    ) VALUES (
        'sale',
        v_sale_id,
        'DELETE',
        p_approver_user_id,
        'Exclusão aprovada: ' || v_deletion_log.deletion_reason,
        'Aprovado por supervisor. ' || COALESCE(p_approval_notes, '')
    );
    
    RETURN QUERY SELECT true, 'Exclusão aprovada e executada com sucesso';
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 5. FUNÇÃO PARA BUSCAR LOG DE AUDITORIA
-- =====================================================

CREATE OR REPLACE FUNCTION get_audit_log(
    p_table_name VARCHAR(100) DEFAULT NULL,
    p_record_id BIGINT DEFAULT NULL,
    p_user_id UUID DEFAULT NULL,
    p_start_date TIMESTAMPTZ DEFAULT NULL,
    p_end_date TIMESTAMPTZ DEFAULT NULL,
    p_limit INTEGER DEFAULT 100
)
RETURNS TABLE(
    id BIGINT,
    table_name VARCHAR(100),
    record_id BIGINT,
    operation_type VARCHAR(20),
    user_name VARCHAR(255),
    user_email VARCHAR(255),
    operation_timestamp TIMESTAMPTZ,
    reason TEXT,
    changed_fields TEXT[],
    notes TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        al.id,
        al.table_name,
        al.record_id,
        al.operation_type,
        al.user_name,
        al.user_email,
        al.operation_timestamp,
        al.reason,
        al.changed_fields,
        al.notes
    FROM audit_log al
    WHERE 
        (p_table_name IS NULL OR al.table_name = p_table_name)
        AND (p_record_id IS NULL OR al.record_id = p_record_id)
        AND (p_user_id IS NULL OR al.user_id = p_user_id)
        AND (p_start_date IS NULL OR al.operation_timestamp >= p_start_date)
        AND (p_end_date IS NULL OR al.operation_timestamp <= p_end_date)
    ORDER BY al.operation_timestamp DESC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 6. FUNÇÃO PARA BUSCAR VENDAS EXCLUÍDAS
-- =====================================================

CREATE OR REPLACE FUNCTION get_deleted_sales(
    p_start_date TIMESTAMPTZ DEFAULT NULL,
    p_end_date TIMESTAMPTZ DEFAULT NULL,
    p_deleted_by_user_id UUID DEFAULT NULL,
    p_requires_approval BOOLEAN DEFAULT NULL,
    p_limit INTEGER DEFAULT 50
)
RETURNS TABLE(
    id BIGINT,
    sale_number VARCHAR(20),
    customer_name VARCHAR(255),
    total_amount_usd NUMERIC(12,2),
    status VARCHAR(20),
    deleted_at TIMESTAMPTZ,
    deleted_by_user_name VARCHAR(255),
    deletion_reason TEXT,
    requires_approval BOOLEAN,
    approved_at TIMESTAMPTZ,
    approved_by_user_name VARCHAR(255)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        dsl.id,
        dsl.sale_number,
        dsl.customer_name,
        dsl.total_amount_usd,
        dsl.status,
        dsl.deleted_at,
        dsl.deleted_by_user_name,
        dsl.deletion_reason,
        dsl.requires_approval,
        dsl.approved_at,
        u.name as approved_by_user_name
    FROM deleted_sales_log dsl
    LEFT JOIN "user" u ON dsl.approved_by_user_id = u.id
    WHERE 
        (p_start_date IS NULL OR dsl.deleted_at >= p_start_date)
        AND (p_end_date IS NULL OR dsl.deleted_at <= p_end_date)
        AND (p_deleted_by_user_id IS NULL OR dsl.deleted_by_user_id = p_deleted_by_user_id)
        AND (p_requires_approval IS NULL OR dsl.requires_approval = p_requires_approval)
    ORDER BY dsl.deleted_at DESC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 7. FUNÇÃO PARA ESTATÍSTICAS DE AUDITORIA
-- =====================================================

CREATE OR REPLACE FUNCTION get_audit_statistics(
    p_start_date TIMESTAMPTZ DEFAULT CURRENT_DATE - INTERVAL '30 days',
    p_end_date TIMESTAMPTZ DEFAULT NOW()
)
RETURNS TABLE(
    total_operations BIGINT,
    total_sales_created BIGINT,
    total_sales_updated BIGINT,
    total_sales_deleted BIGINT,
    total_deletions_pending_approval BIGINT,
    total_deletions_approved BIGINT,
    most_active_user VARCHAR(255),
    most_active_user_operations BIGINT
) AS $$
BEGIN
    RETURN QUERY
    WITH stats AS (
        SELECT 
            COUNT(*) as total_ops,
            COUNT(*) FILTER (WHERE table_name = 'sale' AND operation_type = 'INSERT') as sales_created,
            COUNT(*) FILTER (WHERE table_name = 'sale' AND operation_type = 'UPDATE') as sales_updated,
            COUNT(*) FILTER (WHERE table_name = 'sale' AND operation_type = 'DELETE') as sales_deleted
        FROM audit_log
        WHERE operation_timestamp BETWEEN p_start_date AND p_end_date
    ),
    deletion_stats AS (
        SELECT 
            COUNT(*) FILTER (WHERE requires_approval = true AND approved_at IS NULL) as pending_approval,
            COUNT(*) FILTER (WHERE requires_approval = true AND approved_at IS NOT NULL) as approved
        FROM deleted_sales_log
        WHERE deleted_at BETWEEN p_start_date AND p_end_date
    ),
    user_stats AS (
        SELECT 
            user_name,
            COUNT(*) as operations
        FROM audit_log
        WHERE operation_timestamp BETWEEN p_start_date AND p_end_date
          AND user_name IS NOT NULL
        GROUP BY user_name
        ORDER BY COUNT(*) DESC
        LIMIT 1
    )
    SELECT 
        s.total_ops,
        s.sales_created,
        s.sales_updated,
        s.sales_deleted,
        ds.pending_approval,
        ds.approved,
        us.user_name,
        us.operations
    FROM stats s
    CROSS JOIN deletion_stats ds
    LEFT JOIN user_stats us ON true;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 8. FUNÇÃO PARA VERIFICAR PERMISSÕES DO USUÁRIO
-- =====================================================

CREATE OR REPLACE FUNCTION check_user_permissions(
    p_user_id UUID,
    p_operation VARCHAR(50)
)
RETURNS TABLE(
    has_permission BOOLEAN,
    user_role VARCHAR(100),
    department VARCHAR(100)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        CASE 
            WHEN p.name IN ('admin', 'supervisor') THEN true
            WHEN p.name = 'sales_manager' AND p_operation IN ('delete_sale', 'approve_deletion') THEN true
            WHEN p.name = 'sales_agent' AND p_operation = 'delete_sale' THEN true
            ELSE false
        END as has_permission,
        p.name as user_role,
        d.name as department
    FROM "user" u
    LEFT JOIN position p ON u.position_id = p.id
    LEFT JOIN department d ON u.department_id = d.id
    WHERE u.id = p_user_id;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 9. FUNÇÃO PARA DETALHES DE AUDITORIA
-- =====================================================

CREATE OR REPLACE FUNCTION get_audit_details(
    p_audit_log_id BIGINT
)
RETURNS TABLE(
    id BIGINT,
    table_name VARCHAR(100),
    record_id BIGINT,
    operation_type VARCHAR(20),
    user_name VARCHAR(255),
    operation_timestamp TIMESTAMPTZ,
    old_values JSONB,
    new_values JSONB,
    changed_fields TEXT[],
    reason TEXT,
    notes TEXT,
    session_id VARCHAR(100),
    ip_address INET
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        al.id,
        al.table_name,
        al.record_id,
        al.operation_type,
        al.user_name,
        al.operation_timestamp,
        al.old_values,
        al.new_values,
        al.changed_fields,
        al.reason,
        al.notes,
        al.session_id,
        al.ip_address
    FROM audit_log al
    WHERE al.id = p_audit_log_id;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 10. COMENTÁRIOS E DOCUMENTAÇÃO
-- =====================================================

COMMENT ON FUNCTION set_current_user_context IS 'Define contexto do usuário para auditoria';
COMMENT ON FUNCTION can_delete_sale IS 'Verifica se uma venda pode ser excluída';
COMMENT ON FUNCTION delete_sale_with_validation IS 'Exclui venda com validação e auditoria';
COMMENT ON FUNCTION approve_sale_deletion IS 'Aprova exclusão de venda de alto valor';
COMMENT ON FUNCTION get_audit_log IS 'Busca registros de auditoria com filtros';
COMMENT ON FUNCTION get_deleted_sales IS 'Lista vendas excluídas';
COMMENT ON FUNCTION get_audit_statistics IS 'Estatísticas de auditoria do período';
COMMENT ON FUNCTION check_user_permissions IS 'Verifica permissões do usuário';
COMMENT ON FUNCTION get_audit_details IS 'Detalhes completos de um registro de auditoria';

-- =====================================================
-- EXEMPLOS DE USO NO FLUTTER
-- =====================================================

/*
-- 1. Definir contexto do usuário (chamar no login)
SELECT set_current_user_context(
    'user-uuid-here',
    'session-123',
    '192.168.1.100'::inet,
    'Flutter App v1.0'
);

-- 2. Verificar se pode excluir venda
SELECT * FROM can_delete_sale(123);

-- 3. Excluir venda com validação
SELECT * FROM delete_sale_with_validation(
    123,
    'Cliente cancelou o pedido',
    'user-uuid-here'
);

-- 4. Buscar log de auditoria
SELECT * FROM get_audit_log(
    'sale',
    123,
    NULL,
    NOW() - INTERVAL '7 days',
    NOW(),
    50
);

-- 5. Listar vendas excluídas
SELECT * FROM get_deleted_sales(
    NOW() - INTERVAL '30 days',
    NOW(),
    NULL,
    NULL,
    20
);

-- 6. Estatísticas de auditoria
SELECT * FROM get_audit_statistics(
    NOW() - INTERVAL '30 days',
    NOW()
);
*/