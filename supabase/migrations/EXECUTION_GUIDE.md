# Instruções de Execução - Correção de Integridade Referencial do Banco de Dados

## 📋 Resumo
Este documento fornece instruções detalhadas para aplicar as correções de integridade referencial identificadas na análise de regras de negócio.

## 🚨 IMPORTANTE - Leia antes de executar

### ⚠️ Riscos e Precauções
- **BACKUP OBRIGATÓRIO**: Faça backup completo do banco antes de executar qualquer script
- **TESTE EM AMBIENTE DE DESENVOLVIMENTO**: Teste todos os scripts em ambiente de staging/dev primeiro
- **MONITORAMENTO**: Monitore a aplicação após a execução
- **ROLLBACK**: Tenha um plano de rollback preparado

### 📊 Impacto Estimado
- **Tempo de execução**: 5-15 minutos (dependendo do tamanho do banco)
- **Indisponibilidade**: Banco ficará indisponível durante a execução
- **Dados existentes**: Scripts criarão registros padrão para dados faltantes

## 📝 Scripts Criados

### 1. `fix_all_missing_foreign_keys.sql` (Existente)
- **Descrição**: Adiciona FKs básicas já identificadas
- **Impacto**: Resolve problemas críticos de integridade

### 2. `data_cleanup_before_constraints.sql` (Novo)
- **Descrição**: Limpa e prepara dados para constraints NOT NULL
- **Impacto**: Cria registros padrão para referências faltantes

### 3. `apply_not_null_constraints.sql` (Novo)
- **Descrição**: Aplica constraints NOT NULL após limpeza
- **Impacto**: Torna campos obrigatórios no banco

### 4. `fix_remaining_issues.sql` (Novo)
- **Descrição**: Adiciona FKs adicionais, auditoria e views padronizadas
- **Impacto**: Completa a integridade referencial

### 5. `complete_database_migration.sql` (Novo)
- **Descrição**: Script unificado que executa tudo em sequência
- **Impacto**: Aplica todas as correções automaticamente

## 🚀 Opções de Execução

### Opção A: Execução Automática (Recomendado)
Execute o script unificado que aplica todas as correções:

```bash
# Conectar ao PostgreSQL
psql -h seu_host -d seu_banco -U seu_usuario

# Executar script unificado
\i complete_database_migration.sql
```

### Opção B: Execução Manual (Para controle total)
Execute cada script individualmente na ordem correta:

```bash
# 1. FKs básicas
psql -h seu_host -d seu_banco -U seu_usuario -f fix_all_missing_foreign_keys.sql

# 2. Limpeza de dados
psql -h seu_host -d seu_banco -U seu_usuario -f data_cleanup_before_constraints.sql

# 3. Constraints NOT NULL
psql -h seu_host -d seu_banco -U seu_usuario -f apply_not_null_constraints.sql

# 4. FKs adicionais e auditoria
psql -h seu_host -d seu_banco -U seu_usuario -f fix_remaining_issues.sql
```

## 🔍 Verificação Após Execução

### Queries de Validação
Execute estas queries para verificar se as correções foram aplicadas corretamente:

```sql
-- Verificar todas as FKs existentes
SELECT 
    tc.table_name, 
    tc.constraint_name, 
    kcu.column_name, 
    ccu.table_name AS foreign_table_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage ccu ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY' 
AND tc.table_schema = 'public'
ORDER BY tc.table_name;

-- Verificar campos NOT NULL
SELECT 
    table_name,
    column_name,
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
AND (table_name, column_name) IN 
    (('sale', 'customer_id'), ('sale', 'user_id'), ('sale', 'currency_id'), ('sale_item', 'service_id'))
ORDER BY table_name, column_name;

-- Verificar campos de auditoria
SELECT table_name, column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'public'
AND column_name IN ('created_at', 'updated_at', 'created_by', 'updated_by')
ORDER BY table_name, column_name;
```

## 🔧 Problemas Comuns e Soluções

### Problema: "Constraint violation" durante execução
**Causa**: Dados existentes violam as novas constraints
**Solução**: Execute o script de limpeza (`data_cleanup_before_constraints.sql`) novamente

### Problema: "Permission denied"
**Causa**: Usuário não tem permissões suficientes
**Solução**: Use usuário com privilégios de superusuário ou DBA

### Problema: "Table does not exist"
**Causa**: Schema ou tabela não encontrada
**Solução**: Verifique o schema correto e a existência das tabelas

## 📊 Mudanças no Código Dart

Após aplicar as correções no banco, você precisará atualizar o código Dart:

### 1. Atualizar Models
- Remover validações de nullable para campos que agora são NOT NULL
- Adicionar validações para novos campos de auditoria

### 2. Atualizar Queries
- Atualizar queries que usam `sales_id` para usar views padronizadas
- Adicionar tratamento para campos de auditoria

### 3. Atualizar Providers
- Adicionar providers para campos de auditoria
- Atualizar validações de integridade

## 📈 Benefícios Após Aplicação

### ✅ Integridade de Dados
- Prevenção de dados órfãos
- Garantia de relacionamentos válidos
- Consistência entre tabelas

### ✅ Performance
- Melhor performance em joins
- Índices mais eficientes
- Queries mais rápidas

### ✅ Manutenibilidade
- Código mais confiável
- Menos validações na aplicação
- Debugging mais fácil

## 🔄 Rollback (Se Necessário)

Se precisar desfazer as alterações:

```sql
-- Remover constraints NOT NULL (se necessário)
ALTER TABLE public.sale ALTER COLUMN customer_id DROP NOT NULL;
ALTER TABLE public.sale ALTER COLUMN user_id DROP NOT NULL;
ALTER TABLE public.sale ALTER COLUMN currency_id DROP NOT NULL;
ALTER TABLE public.sale_item ALTER COLUMN service_id DROP NOT NULL;

-- Remover FKs (se necessário)
ALTER TABLE public.sale DROP CONSTRAINT IF EXISTS sale_customer_id_fkey;
ALTER TABLE public.invoice DROP CONSTRAINT IF EXISTS invoice_sale_id_fkey;
ALTER TABLE public.invoice DROP CONSTRAINT IF EXISTS invoice_customer_id_fkey;
```

## 📞 Suporte

Se encontrar problemas durante a execução:

1. **Verifique os logs**: Todos os scripts incluem mensagens detalhadas
2. **Execute validações**: Use as queries de verificação fornecidas
3. **Documente o erro**: Capture mensagens de erro completas
4. **Teste incremental**: Execute scripts individuais para isolar problemas

---

**✅ Status**: Scripts prontos para execução
**📅 Data**: 2024-12-03
**👨‍💻 Responsável**: Equipe de Desenvolvimento