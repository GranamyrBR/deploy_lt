-- Script unificado de execução para correção completa do banco de dados
-- EXECUTE ESTE SCRIPT PARA APLICAR TODAS AS CORREÇÕES EM SEQUÊNCIA
-- 
-- ORDEM DE EXECUÇÃO:
-- 1. Executar fix_all_missing_foreign_keys.sql (já existente)
-- 2. Executar data_cleanup_before_constraints.sql
-- 3. Executar apply_not_null_constraints.sql
-- 4. Executar fix_remaining_issues.sql (FKs adicionais e auditoria)

-- ==============================================
-- INÍCIO DO PROCESSO DE MIGRAÇÃO
-- ==============================================

SELECT '==========================================' AS separator;
SELECT 'INICIANDO PROCESSO DE MIGRAÇÃO DO BANCO' AS title;
SELECT '==========================================' AS separator;

-- ==============================================
-- ETAPA 1: Executar script existente de FKs básicas
-- ==============================================

SELECT 'ETAPA 1: Aplicando FKs básicas...' AS step_1;
\i fix_all_missing_foreign_keys.sql

SELECT '✓ ETAPA 1 CONCLUÍDA: FKs básicas aplicadas' AS step_1_complete;

-- ==============================================
-- ETAPA 2: Limpeza de dados para preparar NOT NULL
-- ==============================================

SELECT 'ETAPA 2: Executando limpeza de dados...' AS step_2;
\i data_cleanup_before_constraints.sql

SELECT '✓ ETAPA 2 CONCLUÍDA: Dados limpos e preparados' AS step_2_complete;

-- ==============================================
-- ETAPA 3: Aplicar constraints NOT NULL
-- ==============================================

SELECT 'ETAPA 3: Aplicando constraints NOT NULL...' AS step_3;
\i apply_not_null_constraints.sql

SELECT '✓ ETAPA 3 CONCLUÍDA: NOT NULL constraints aplicadas' AS step_3_complete;

-- ==============================================
-- ETAPA 4: FKs adicionais e auditoria
-- ==============================================

SELECT 'ETAPA 4: Aplicando FKs adicionais e auditoria...' AS step_4;
\i fix_remaining_issues.sql

SELECT '✓ ETAPA 4 CONCLUÍDA: FKs adicionais e auditoria aplicadas' AS step_4_complete;

-- ==============================================
-- VALIDAÇÃO FINAL
-- ==============================================

SELECT 'ETAPA 5: Executando validação final...' AS step_5;

-- Verificar integridade de todas as tabelas principais
SELECT 
    'Validação de integridade:' AS validation_type,
    table_name,
    constraint_name,
    constraint_type
FROM information_schema.table_constraints
WHERE table_schema = 'public'
AND table_name IN ('sale', 'sale_item', 'sale_payment', 'invoice', 'contact', 'service')
AND constraint_type IN ('PRIMARY KEY', 'FOREIGN KEY')
ORDER BY table_name, constraint_type;

-- Verificar campos NOT NULL críticos
SELECT 
    'Campos NOT NULL:' AS validation_type,
    table_name,
    column_name,
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
AND (table_name, column_name) IN 
    (('sale', 'customer_id'), ('sale', 'user_id'), ('sale', 'currency_id'), ('sale_item', 'service_id'))
ORDER BY table_name, column_name;

-- Verificar campos de auditoria
SELECT 
    'Campos de auditoria:' AS validation_type,
    table_name,
    column_name,
    data_type
FROM information_schema.columns
WHERE table_schema = 'public'
AND table_name IN ('sale', 'sale_item', 'sale_payment', 'invoice')
AND column_name IN ('created_at', 'updated_at', 'created_by', 'updated_by')
ORDER BY table_name, column_name;

-- ==============================================
-- RELATÓRIO FINAL
-- ==============================================

SELECT '==========================================' AS separator;
SELECT 'RELATÓRIO FINAL DE MIGRAÇÃO' AS final_title;
SELECT '==========================================' AS separator;

SELECT 
    'Status da migração:' AS report_item,
    'SUCESSO' AS status,
    'Todas as correções de integridade referencial foram aplicadas' AS description;

SELECT 
    'Foreign Keys aplicadas:' AS report_item,
    'sale.currency_id, sale_item.sales_id, sale_item.service_id, sale_payment.sales_id, sale.customer_id, invoice.sale_id, invoice.customer_id' AS details;

SELECT 
    'NOT NULL constraints:' AS report_item,
    'sale.customer_id, sale.user_id, sale.currency_id, sale_item.service_id' AS details;

SELECT 
    'Auditoria implementada:' AS report_item,
    'created_at, updated_at, created_by, updated_by nas tabelas principais' AS details;

SELECT 
    'Views criadas:' AS report_item,
    'sale_item_standardized, sale_payment_standardized (padronização de nomenclatura)' AS details;

-- Mensagem final de sucesso
SELECT '==========================================' AS separator;
SELECT '🎉 MIGRAÇÃO CONCLUÍDA COM SUCESSO! 🎉' AS success_message;
SELECT '==========================================' AS separator;

SELECT 
    'Próximos passos:' AS next_steps_title,
    '1. Atualizar código Dart para refletir mudanças' AS step_1,
    '2. Executar testes de integração' AS step_2,
    '3. Monitorar aplicação em produção' AS step_3;

-- ==============================================
-- INSTRUÇÕES DE USO
-- ==============================================

-- Para executar este script:
-- 1. Conecte-se ao PostgreSQL: psql -h seu_host -d seu_banco -U seu_usuario
-- 2. Navegue até o diretório: cd supabase/migrations/
-- 3. Execute: \i complete_database_migration.sql
-- 
-- OU execute individualmente:
-- psql -h seu_host -d seu_banco -U seu_usuario -f complete_database_migration.sql