-- ============================================================================
-- Migration: Audit Log para Soft Delete de Cotações
-- Data: 2025-12-08
-- Descrição: Trigger para registrar cancelamento de cotações no audit_log
-- ============================================================================

-- Função para registrar cancelamento no audit_log
CREATE OR REPLACE FUNCTION log_quotation_cancellation()
RETURNS TRIGGER AS $$
BEGIN
    -- Apenas registra se status mudou para 'cancelled'
    IF NEW.status = 'cancelled' AND OLD.status != 'cancelled' THEN
        INSERT INTO public.audit_log (
            table_name,
            record_id,
            operation_type,
            old_values,
            new_values,
            user_id,
            user_email,
            ip_address,
            operation_timestamp,
            reason
        ) VALUES (
            'quotation',
            NEW.id::bigint,
            'SOFT_DELETE',
            jsonb_build_object(
                'quotation_number', OLD.quotation_number,
                'client_name', OLD.client_name,
                'status', OLD.status,
                'total', OLD.total,
                'currency', OLD.currency
            ),
            jsonb_build_object(
                'quotation_number', NEW.quotation_number,
                'status', NEW.status,
                'cancelled_at', NEW.updated_at,
                'cancelled_by', NEW.updated_by
            ),
            auth.uid(),
            auth.jwt() ->> 'email',
            -- Pega apenas o primeiro IP da lista (x-forwarded-for pode ter múltiplos IPs)
            NULLIF(split_part(current_setting('request.headers', true)::json ->> 'x-forwarded-for', ',', 1), '')::inet,
            NOW(),
            'Cotação cancelada via CRM'
        );
        
        RAISE NOTICE 'Cotação % cancelada por % e registrada no audit_log', 
            OLD.quotation_number, 
            COALESCE(auth.jwt() ->> 'email', 'system');
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Criar trigger para executar após UPDATE na tabela quotation
DROP TRIGGER IF EXISTS trigger_quotation_cancellation_audit ON public.quotation;

CREATE TRIGGER trigger_quotation_cancellation_audit
    AFTER UPDATE ON public.quotation
    FOR EACH ROW
    WHEN (NEW.status = 'cancelled' AND OLD.status != 'cancelled')
    EXECUTE FUNCTION log_quotation_cancellation();

-- Comentários
COMMENT ON FUNCTION log_quotation_cancellation() IS 
'Registra no audit_log quando uma cotação é cancelada (soft delete)';

COMMENT ON TRIGGER trigger_quotation_cancellation_audit ON public.quotation IS 
'Audita cancelamentos de cotações para compliance e rastreabilidade';

-- ============================================================================
-- Verificação: Ver audit_logs de soft delete de cotações
-- ============================================================================
SELECT 
    al.id,
    al.table_name,
    al.operation_type,
    al.old_values->>'quotation_number' as quotation_number,
    al.old_values->>'client_name' as client_name,
    al.new_values->>'status' as new_status,
    al.user_email,
    al.operation_timestamp,
    al.reason
FROM public.audit_log al
WHERE al.table_name = 'quotation' 
  AND al.operation_type = 'SOFT_DELETE'
ORDER BY al.operation_timestamp DESC
LIMIT 10;

-- ============================================================================
-- Query para gestores: Ver cotações canceladas
-- ============================================================================
-- Esta query pode ser usada em uma tela de auditoria/gestão
SELECT 
    q.id,
    q.quotation_number,
    q.client_name,
    q.total,
    q.currency,
    q.status,
    q.updated_at as cancelled_at,
    q.updated_by as cancelled_by,
    al.user_email as cancelled_by_email
FROM public.quotation q
LEFT JOIN public.audit_log al ON (
    al.table_name = 'quotation' 
    AND al.record_id = q.id 
    AND al.operation_type = 'SOFT_DELETE'
)
WHERE q.status = 'cancelled'
ORDER BY q.updated_at DESC;
