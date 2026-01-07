# 🚀 Guia de Migração Inteligente - Sistema de Vendas LeCotour

## 📋 Visão Geral

Esta migração atualiza o sistema de vendas **SEM QUEBRAR** o código Flutter existente. A tabela `sale` é expandida com novos campos e funcionalidades, mantendo total compatibilidade.

## ✅ Benefícios da Migração

- **Zero mudanças no Flutter**: Código existente continua funcionando
- **Compatibilidade total**: Campos antigos permanecem funcionais
- **Novas funcionalidades**: Sistema de auditoria e controles avançados
- **Implementação gradual**: Novos recursos podem ser adotados aos poucos
- **Rollback seguro**: Backup automático da estrutura atual

## 🔧 Arquivos da Migração

### 1. `migration_sale_upgrade.sql`
- **Propósito**: Atualiza tabela `sale` existente
- **Ação**: Adiciona novos campos sem remover antigos
- **Resultado**: Compatibilidade total + novas funcionalidades

### 2. `flutter_functions_compatible.sql`
- **Propósito**: Funções SQL para integração Flutter
- **Ação**: Fornece APIs SQL para novas funcionalidades
- **Resultado**: Interface limpa para o Flutter usar

## 📊 Comparação: Antes vs Depois

### Tabela `sale` - ANTES
```sql
CREATE TABLE sale (
    id BIGSERIAL PRIMARY KEY,
    customer_id INTEGER,
    total_amount NUMERIC(10,2),
    status VARCHAR(20),
    payment_status VARCHAR(20),
    sale_date DATE,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ
    -- ... outros campos existentes
);
```

### Tabela `sale` - DEPOIS
```sql
CREATE TABLE sale (
    -- CAMPOS EXISTENTES (mantidos)
    id BIGSERIAL PRIMARY KEY,
    customer_id INTEGER,
    total_amount NUMERIC(10,2),
    status VARCHAR(20),
    payment_status VARCHAR(20),
    sale_date DATE,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ,
    
    -- NOVOS CAMPOS (adicionados)
    sale_number VARCHAR(20) UNIQUE,           -- Número único da venda
    total_amount_usd NUMERIC(12,2),           -- Valor sempre em USD
    discount_amount_usd NUMERIC(12,2),        -- Desconto em USD
    tax_amount_usd NUMERIC(12,2),             -- Impostos em USD
    net_amount_usd NUMERIC(12,2),             -- Valor líquido em USD
    internal_notes TEXT,                      -- Notas internas
    tags TEXT[],                              -- Tags para categorização
    created_by_user_id UUID,                  -- Usuário criador
    updated_by_user_id UUID                   -- Último usuário que alterou
);
```

## 🎯 Novas Funcionalidades

### 1. **Sistema de Auditoria Completo**
- Rastreamento de todas as operações
- Log de exclusões com backup completo
- Aprovação para operações críticas

### 2. **Controle de Exclusões**
- Validação antes de excluir
- Aprovação obrigatória para vendas de alto valor
- Backup completo dos dados excluídos

### 3. **Padronização Monetária**
- Todos os valores em USD
- Histórico de cotações
- Conversão automática

### 4. **Melhor Organização**
- Números únicos de venda
- Tags para categorização
- Notas internas

## 🚀 Passo a Passo da Implementação

### Fase 1: Preparação (5 minutos)

1. **Backup do banco atual**
```bash
pg_dump lecotour_db > backup_antes_migracao.sql
```

2. **Verificar conexões ativas**
```sql
SELECT * FROM pg_stat_activity WHERE datname = 'lecotour_db';
```

### Fase 2: Execução da Migração (10 minutos)

1. **Executar migração principal**
```bash
psql -d lecotour_db -f migration_sale_upgrade.sql
```

2. **Executar funções Flutter**
```bash
psql -d lecotour_db -f flutter_functions_compatible.sql
```

3. **Verificar sucesso**
```sql
-- Verificar novos campos
\d sale

-- Verificar dados migrados
SELECT id, sale_number, total_amount, total_amount_usd 
FROM sale 
LIMIT 5;

-- Verificar funções criadas
\df can_delete_sale
```

### Fase 3: Teste da Aplicação (15 minutos)

1. **Testar Flutter sem mudanças**
   - Abrir aplicação Flutter
   - Navegar pelas telas de vendas
   - Criar/editar/visualizar vendas
   - **Resultado esperado**: Tudo funciona normalmente

2. **Testar novas funcionalidades**
```sql
-- Teste 1: Verificar se pode excluir venda
SELECT * FROM can_delete_sale(1);

-- Teste 2: Definir contexto de usuário
SELECT set_current_user_context(
    (SELECT id FROM "user" LIMIT 1),
    'test-session',
    '127.0.0.1'::inet
);

-- Teste 3: Buscar auditoria
SELECT * FROM get_audit_log('sale', NULL, NULL, NOW() - INTERVAL '1 day', NOW(), 10);
```

## 📱 Integração com Flutter

### Uso Imediato (sem mudanças no código)

O Flutter continua funcionando exatamente como antes:

```dart
// Este código continua funcionando sem alterações
final sales = await database.query('sale', 
  columns: ['id', 'customer_id', 'total_amount', 'status'],
  where: 'customer_id = ?',
  whereArgs: [customerId]
);
```

### Uso das Novas Funcionalidades (opcional)

```dart
// 1. Definir contexto do usuário (no login)
await database.rawQuery(
  'SELECT set_current_user_context(?, ?, ?)',
  [userId, sessionId, ipAddress]
);

// 2. Verificar se pode excluir venda
final canDelete = await database.rawQuery(
  'SELECT * FROM can_delete_sale(?)',
  [saleId]
);

// 3. Excluir venda com validação
final result = await database.rawQuery(
  'SELECT * FROM delete_sale_with_validation(?, ?, ?)',
  [saleId, reason, userId]
);

// 4. Buscar histórico de auditoria
final auditLog = await database.rawQuery(
  'SELECT * FROM get_audit_log(?, ?, ?, ?, ?, ?)',
  ['sale', saleId, null, startDate, endDate, 50]
);
```

## 🔍 Monitoramento e Relatórios

### Dashboard de Auditoria

```sql
-- Estatísticas dos últimos 30 dias
SELECT * FROM get_audit_statistics(
    NOW() - INTERVAL '30 days',
    NOW()
);

-- Vendas excluídas recentes
SELECT * FROM get_deleted_sales(
    NOW() - INTERVAL '7 days',
    NOW(),
    NULL,
    NULL,
    20
);

-- Operações por usuário
SELECT 
    user_name,
    COUNT(*) as total_operations,
    COUNT(*) FILTER (WHERE operation_type = 'DELETE') as deletions
FROM audit_log 
WHERE operation_timestamp >= NOW() - INTERVAL '30 days'
GROUP BY user_name
ORDER BY total_operations DESC;
```

## ⚠️ Pontos de Atenção

### 1. **Campos Duplicados Temporários**
- `total_amount` (original) e `total_amount_usd` (novo)
- Durante transição, ambos existem
- Gradualmente migrar para `total_amount_usd`

### 2. **Aprovações Pendentes**
- Vendas de alto valor requerem aprovação para exclusão
- Implementar interface para supervisores aprovarem

### 3. **Performance**
- Novos índices criados automaticamente
- Monitorar performance das consultas

## 🔄 Rollback (se necessário)

```sql
-- 1. Restaurar estrutura original (remove novos campos)
ALTER TABLE sale DROP COLUMN IF EXISTS sale_number;
ALTER TABLE sale DROP COLUMN IF EXISTS total_amount_usd;
ALTER TABLE sale DROP COLUMN IF EXISTS discount_amount_usd;
ALTER TABLE sale DROP COLUMN IF EXISTS tax_amount_usd;
ALTER TABLE sale DROP COLUMN IF EXISTS net_amount_usd;
ALTER TABLE sale DROP COLUMN IF EXISTS internal_notes;
ALTER TABLE sale DROP COLUMN IF EXISTS tags;
ALTER TABLE sale DROP COLUMN IF EXISTS created_by_user_id;
ALTER TABLE sale DROP COLUMN IF EXISTS updated_by_user_id;

-- 2. Remover tabelas de auditoria
DROP TABLE IF EXISTS audit_log;
DROP TABLE IF EXISTS deleted_sales_log;
DROP TABLE IF EXISTS exchange_rate_history;

-- 3. Restaurar backup completo (alternativa)
-- psql -d lecotour_db < backup_antes_migracao.sql
```

## 📈 Próximos Passos

### Curto Prazo (1-2 semanas)
1. ✅ Executar migração em desenvolvimento
2. ✅ Testar aplicação Flutter
3. ✅ Validar novas funcionalidades
4. 🔄 Treinar equipe nas novas funcionalidades
5. 🔄 Implementar interface de aprovações

### Médio Prazo (1 mês)
1. 🔄 Migrar código Flutter para usar novos campos
2. 🔄 Implementar dashboard de auditoria
3. 🔄 Configurar alertas automáticos
4. 🔄 Executar em produção

### Longo Prazo (2-3 meses)
1. 🔄 Remover campos antigos (após validação)
2. 🔄 Otimizar performance
3. 🔄 Expandir auditoria para outras tabelas
4. 🔄 Implementar relatórios avançados

## 🆘 Suporte e Troubleshooting

### Problemas Comuns

**1. Erro: "column does not exist"**
```sql
-- Verificar se migração foi executada
SELECT column_name FROM information_schema.columns 
WHERE table_name = 'sale' AND column_name = 'sale_number';
```

**2. Performance lenta**
```sql
-- Verificar índices criados
SELECT indexname, indexdef FROM pg_indexes WHERE tablename = 'sale';

-- Analisar tabela
ANALYZE sale;
```

**3. Dados não migrados**
```sql
-- Verificar migração de dados
SELECT 
    COUNT(*) as total_sales,
    COUNT(sale_number) as with_sale_number,
    COUNT(total_amount_usd) as with_usd_amount
FROM sale;
```

### Contatos de Suporte
- **Desenvolvedor**: [Seu contato]
- **DBA**: [Contato do DBA]
- **Documentação**: Este arquivo

---

## 📝 Resumo Executivo

✅ **Compatibilidade**: 100% - código Flutter continua funcionando  
✅ **Segurança**: Backup automático + rollback disponível  
✅ **Funcionalidades**: Sistema de auditoria completo  
✅ **Performance**: Índices otimizados incluídos  
✅ **Manutenção**: Implementação gradual possível  

**Tempo estimado de implementação**: 30 minutos  
**Risco**: Baixo (compatibilidade total)  
**Benefício**: Alto (auditoria + controles + padronização)  

---

*Última atualização: $(date)*
# 🚀 Guia de Migração Inteligente - Sistema de Vendas LeCotour
