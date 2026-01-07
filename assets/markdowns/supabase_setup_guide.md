# Guia de Execução dos Scripts no Supabase

## Pré-requisitos

1. Acesso ao Dashboard do Supabase
2. Permissões de administrador no projeto
3. Backup dos dados (recomendado)

## Ordem de Execução

### 1. Fazer Backup (OBRIGATÓRIO)

#### Via Dashboard Supabase:
1. Acesse seu projeto no Supabase Dashboard
2. Vá em **Settings** → **Database**
3. Na seção **Database Backups**, clique em **Create Backup**
4. Aguarde a conclusão do backup

#### Via CLI (alternativo):
```bash
# Instalar Supabase CLI se não tiver
npm install -g supabase

# Login no Supabase
supabase login

# Fazer backup
supabase db dump --file backup_antes_correcoes.sql
```

### 2. Executar Limpeza dos Dados

1. No Dashboard do Supabase, vá em **SQL Editor**
2. Crie uma nova query
3. Copie e cole o conteúdo do arquivo `clean_sales_now.sql`
4. **IMPORTANTE**: Verifique se está no ambiente correto (desenvolvimento/teste)
5. Execute o script
6. Verifique os resultados da query de verificação no final

### 3. Executar Migração Principal

1. No SQL Editor, crie uma nova query
2. Copie e cole o conteúdo do arquivo `migration_sale_upgrade.sql` (em blocos)
3. Execute cada bloco sequencialmente
4. Verifique se todas as tabelas e campos foram criados com sucesso

### 4. Instalar Funções Flutter

1. No SQL Editor, crie uma nova query
2. Copie e cole o conteúdo do arquivo `flutter_functions_compatible.sql`
3. Execute o script
4. Verifique se todas as funções foram criadas

### 5. Verificação Final

Execute o script de validação completo:

1. No SQL Editor, copie e cole o conteúdo do arquivo `validation_tests.sql`
2. Execute o script completo
3. Verifique se todas as validações passaram

Ou execute esta query rápida para verificar a estrutura:

```sql
-- Verificar novos campos na tabela sale
SELECT column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_name = 'sale' 
  AND column_name IN ('sale_number', 'total_amount_usd', 'created_by_user_id')
ORDER BY column_name;

-- Verificar novas tabelas criadas
SELECT table_name 
FROM information_schema.tables 
WHERE table_name IN ('exchange_rate_history', 'audit_log', 'deleted_sales_log');

-- Verificar funções criadas
SELECT routine_name 
FROM information_schema.routines 
WHERE routine_name LIKE '%sale%' OR routine_name LIKE '%audit%';
```

## Características Específicas do Supabase

### Diferenças do PostgreSQL Padrão:

1. **Transações**: Supabase suporta transações normalmente
2. **RAISE NOTICE**: Funciona no SQL Editor
3. **session_replication_role**: Suportado para desabilitar triggers
4. **ANALYZE**: Funciona normalmente
5. **Sequences**: Auto-gerenciadas, mas podem ser resetadas

### Limitações:

1. **Timeouts**: Queries muito longas podem ter timeout
2. **Permissões**: Algumas operações podem requerer permissões especiais
3. **RLS (Row Level Security)**: Pode interferir nas operações

## Troubleshooting

### Se der erro de permissão:
```sql
-- Verificar se RLS está ativo
SELECT schemaname, tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename IN ('sale', 'sale_item', 'sale_payment');

-- Se necessário, desabilitar RLS temporariamente
ALTER TABLE public.sale DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.sale_item DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.sale_payment DISABLE ROW LEVEL SECURITY;
```

### Se der erro de FK:
```sql
-- Verificar dados órfãos antes de criar FK
SELECT si.id, si.sale_id
FROM sale_item si
LEFT JOIN sale s ON si.sale_id = s.id 
WHERE s.id IS NULL;

-- Se houver dados órfãos, limpe-os primeiro
DELETE FROM sale_item WHERE sale_id NOT IN (SELECT id FROM sale);
```

### Se der timeout:
1. Execute os scripts em partes menores
2. Use o CLI do Supabase para scripts grandes
3. Considere executar fora do horário de pico

## Rollback em Caso de Problema

### Via Dashboard:
1. Vá em **Settings** → **Database**
2. Na seção **Database Backups**, encontre o backup criado
3. Clique em **Restore** no backup desejado

### Via CLI:
```bash
# Restaurar backup
supabase db reset --file backup_antes_correcoes.sql
```

## Monitoramento Pós-Execução

1. **Verificar logs**: Dashboard → **Logs** → **Database**
2. **Testar aplicação**: Executar testes funcionais
3. **Monitorar performance**: Verificar se queries estão mais lentas
4. **Verificar integridade**: Executar queries de validação

## Comandos Úteis para Supabase

```sql
-- Ver todas as constraints de uma tabela
SELECT * FROM information_schema.table_constraints 
WHERE table_name = 'sale_item';

-- Ver índices de uma tabela
SELECT * FROM pg_indexes WHERE tablename = 'sale';

-- Ver estatísticas de uma tabela
SELECT * FROM pg_stat_user_tables WHERE relname = 'sale';

-- Ver tamanho das tabelas
SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size
FROM pg_tables 
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
```

## Contato e Suporte

Em caso de problemas:
1. Verifique os logs do Supabase
2. Consulte a documentação oficial: https://supabase.com/docs
3. Use o backup para restaurar se necessário
4. Teste em ambiente de desenvolvimento primeiro
# Guia de Execução dos Scripts no Supabase
