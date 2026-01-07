# ✅ Checklist de Implementação - Supabase Studio

## 📋 Visão Geral

Este checklist guia a implementação completa do sistema de vendas atualizado através do **Supabase Studio** (interface web), sem necessidade de acesso ao terminal do banco de dados.

---

## 🚀 Fase 1: Preparação (15 minutos)

### ✅ 1.1 Backup e Verificação Inicial

**Local**: Supabase Studio → SQL Editor

- [ ] **Acessar Supabase Studio**
  - Fazer login no dashboard do Supabase
  - Selecionar o projeto LeCotour
  - Ir para "SQL Editor"

- [ ] **Verificar estrutura atual**
  ```sql
  -- Copiar e executar no SQL Editor
  SELECT table_name, column_name, data_type 
  FROM information_schema.columns 
  WHERE table_name IN ('sale', 'sale_item', 'sale_payment', 'operation')
  ORDER BY table_name, ordinal_position;
  ```

- [ ] **Contar registros existentes**
  ```sql
  -- Verificar quantidade de dados
  SELECT 
      'sale' as tabela, COUNT(*) as registros FROM sale
  UNION ALL
  SELECT 'sale_item', COUNT(*) FROM sale_item
  UNION ALL
  SELECT 'sale_payment', COUNT(*) FROM sale_payment
  UNION ALL
  SELECT 'operation', COUNT(*) FROM operation WHERE sale_id IS NOT NULL;
  ```

- [ ] **Criar backup manual** (IMPORTANTE)
  ```sql
  -- Executar uma por vez no SQL Editor
  CREATE TABLE sale_backup_manual AS SELECT * FROM sale;
  CREATE TABLE sale_item_backup_manual AS SELECT * FROM sale_item;
  CREATE TABLE sale_payment_backup_manual AS SELECT * FROM sale_payment;
  CREATE TABLE operation_backup_manual AS SELECT * FROM operation WHERE sale_id IS NOT NULL;
  ```

---

## 🧹 Fase 2: Limpeza dos Dados (10 minutos)

### ✅ 2.1 Executar Limpeza

**Local**: Supabase Studio → SQL Editor

- [ ] **Abrir arquivo**: `clean_sales_now.sql`
- [ ] **Copiar todo o conteúdo** do arquivo
- [ ] **Colar no SQL Editor** do Supabase
- [ ] **Executar o script** (botão "Run")
- [ ] **Verificar mensagens** de sucesso no output

**Resultado esperado**:
```
✅ LIMPEZA CONCLUÍDA COM SUCESSO!
Todas as tabelas de vendas foram zeradas.
```

### ✅ 2.2 Validar Limpeza

- [ ] **Verificar tabelas vazias**
  ```sql
  SELECT 
      'sale' as tabela, COUNT(*) as registros FROM sale
  UNION ALL
  SELECT 'sale_item', COUNT(*) FROM sale_item
  UNION ALL
  SELECT 'sale_payment', COUNT(*) FROM sale_payment;
  ```
  **Resultado esperado**: Todas com 0 registros

---

## 🔧 Fase 3: Migração da Estrutura (20 minutos)

### ✅ 3.1 Executar Migração Principal

**Local**: Supabase Studio → SQL Editor

- [ ] **Abrir arquivo**: `migration_sale_upgrade.sql`
- [ ] **Dividir em blocos** (Supabase tem limite de caracteres):

  **Bloco 1 - Estrutura básica** (copiar e executar):
  ```sql
  -- Seções 1-5 do migration_sale_upgrade.sql
  -- (Backup, novos campos, constraints, migração de dados)
  ```

  **Bloco 2 - Tabelas auxiliares** (copiar e executar):
  ```sql
  -- Seções 6-7 do migration_sale_upgrade.sql
  -- (exchange_rate_history, audit_log, deleted_sales_log, funções)
  ```

  **Bloco 3 - Triggers e views** (copiar e executar):
  ```sql
  -- Seções 8-11 do migration_sale_upgrade.sql
  -- (Triggers, views, índices, comentários)
  ```

- [ ] **Verificar execução** de cada bloco
- [ ] **Anotar erros** se houver

### ✅ 3.2 Validar Migração

- [ ] **Verificar novos campos**
  ```sql
  SELECT column_name, data_type, is_nullable
  FROM information_schema.columns 
  WHERE table_name = 'sale' 
    AND column_name IN ('sale_number', 'total_amount_usd', 'created_by_user_id')
  ORDER BY column_name;
  ```

- [ ] **Verificar novas tabelas**
  ```sql
  SELECT table_name 
  FROM information_schema.tables 
  WHERE table_name IN ('exchange_rate_history', 'audit_log', 'deleted_sales_log');
  ```

---

## 🔗 Fase 4: Funções Flutter (15 minutos)

### ✅ 4.1 Instalar Funções

**Local**: Supabase Studio → SQL Editor

- [ ] **Abrir arquivo**: `flutter_functions_compatible.sql`
- [ ] **Dividir em blocos menores** (funções individuais):

  **Bloco 1 - Funções básicas**:
  ```sql
  -- set_current_user_context
  -- can_delete_sale
  ```

  **Bloco 2 - Funções de exclusão**:
  ```sql
  -- delete_sale_with_validation
  -- approve_sale_deletion
  ```

  **Bloco 3 - Funções de consulta**:
  ```sql
  -- get_audit_log
  -- get_deleted_sales
  -- get_audit_statistics
  ```

  **Bloco 4 - Funções auxiliares**:
  ```sql
  -- check_user_permissions
  -- get_audit_details
  ```

### ✅ 4.2 Testar Funções

- [ ] **Testar função básica**
  ```sql
  SELECT get_latest_exchange_rate('USD');
  ```
  **Resultado esperado**: `1.0`

- [ ] **Testar função de estatísticas**
  ```sql
  SELECT * FROM get_audit_statistics();
  ```
  **Resultado esperado**: Dados de estatística (pode ser zeros)

---

## ✅ Fase 5: Validação Completa (10 minutos)

### ✅ 5.1 Executar Validação

**Local**: Supabase Studio → SQL Editor

- [ ] **Abrir arquivo**: `validation_tests.sql`
- [ ] **Executar por seções** (dividir o arquivo):

  **Seção 1 - Estrutura**:
  ```sql
  -- Verificação da estrutura da tabela (seção 1-2)
  ```

  **Seção 2 - Funcionalidades**:
  ```sql
  -- Verificação das funções (seção 3-6)
  ```

  **Seção 3 - Relatórios**:
  ```sql
  -- Relatório final (seção 7-10)
  ```

### ✅ 5.2 Verificar Resultados

- [ ] **Todas as verificações passaram**
- [ ] **Mensagem final**: "✅ VALIDAÇÃO CONCLUÍDA!"
- [ ] **Sem erros críticos**

---

## 🧪 Fase 6: Teste da Aplicação (15 minutos)

### ✅ 6.1 Teste Flutter

- [ ] **Abrir aplicação Flutter**
- [ ] **Testar funcionalidades básicas**:
  - [ ] Listar vendas (deve mostrar lista vazia)
  - [ ] Criar nova venda
  - [ ] Editar venda
  - [ ] Visualizar detalhes
  - [ ] Navegar entre telas

- [ ] **Verificar se não há erros** no console
- [ ] **Confirmar compatibilidade** total

### ✅ 6.2 Teste das Novas Funcionalidades

**Local**: Supabase Studio → SQL Editor

- [ ] **Criar venda de teste**
  ```sql
  INSERT INTO sale (customer_id, total_amount, total_amount_usd, status, payment_status, sale_date)
  VALUES (1, 500.00, 100.00, 'pending', 'pending', CURRENT_DATE);
  ```

- [ ] **Testar verificação de exclusão**
  ```sql
  SELECT * FROM can_delete_sale(1);
  ```

- [ ] **Testar contexto de usuário**
  ```sql
  SELECT set_current_user_context(
    (SELECT id FROM auth.users LIMIT 1),
    'test-session',
    '127.0.0.1'::inet
  );
  ```

---

## 📊 Fase 7: Configuração Final (10 minutos)

### ✅ 7.1 Configurar RLS (Row Level Security)

**Local**: Supabase Studio → Authentication → Policies

- [ ] **Ir para "Policies"**
- [ ] **Configurar políticas para tabela `sale`**:
  ```sql
  -- Política de leitura
  CREATE POLICY "Users can view sales" ON sale
    FOR SELECT USING (auth.role() = 'authenticated');
  
  -- Política de inserção
  CREATE POLICY "Users can insert sales" ON sale
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');
  
  -- Política de atualização
  CREATE POLICY "Users can update sales" ON sale
    FOR UPDATE USING (auth.role() = 'authenticated');
  ```

- [ ] **Habilitar RLS** nas tabelas:
  ```sql
  ALTER TABLE sale ENABLE ROW LEVEL SECURITY;
  ALTER TABLE sale_item ENABLE ROW LEVEL SECURITY;
  ALTER TABLE sale_payment ENABLE ROW LEVEL SECURITY;
  ```

### ✅ 7.2 Configurar Permissões

- [ ] **Verificar usuários** no Supabase Auth
- [ ] **Configurar roles** se necessário
- [ ] **Testar acesso** com usuário real

---

## 🎯 Fase 8: Monitoramento (5 minutos)

### ✅ 8.1 Configurar Logs

**Local**: Supabase Studio → Logs

- [ ] **Verificar logs** de SQL
- [ ] **Configurar alertas** se disponível
- [ ] **Monitorar performance** das consultas

### ✅ 8.2 Documentar Implementação

- [ ] **Anotar versão** do Supabase usada
- [ ] **Documentar customizações** feitas
- [ ] **Criar lista** de backups criados
- [ ] **Registrar data/hora** da implementação

---

## 🚨 Troubleshooting

### Problemas Comuns no Supabase Studio

**1. Erro: "Query too long"**
- ✅ **Solução**: Dividir script em blocos menores
- ✅ **Executar** uma seção por vez

**2. Erro: "Permission denied"**
- ✅ **Verificar**: Se está logado como owner do projeto
- ✅ **Verificar**: Permissões do usuário

**3. Erro: "Function already exists"**
- ✅ **Usar**: `CREATE OR REPLACE FUNCTION` ao invés de `CREATE FUNCTION`

**4. Timeout na execução**
- ✅ **Dividir**: Scripts grandes em partes menores
- ✅ **Aguardar**: Entre execuções

### Rollback de Emergência

**Se algo der errado**:

```sql
-- 1. Restaurar tabelas originais
DROP TABLE IF EXISTS sale;
CREATE TABLE sale AS SELECT * FROM sale_backup_manual;

-- 2. Restaurar outras tabelas
DROP TABLE IF EXISTS sale_item;
CREATE TABLE sale_item AS SELECT * FROM sale_item_backup_manual;

-- 3. Remover tabelas criadas
DROP TABLE IF EXISTS audit_log;
DROP TABLE IF EXISTS deleted_sales_log;
DROP TABLE IF EXISTS exchange_rate_history;
```

---

## ✅ Checklist Final

### Antes de Finalizar

- [ ] ✅ Backup criado e verificado
- [ ] ✅ Dados antigos limpos
- [ ] ✅ Migração executada sem erros
- [ ] ✅ Funções instaladas e testadas
- [ ] ✅ Validação completa passou
- [ ] ✅ Flutter funcionando normalmente
- [ ] ✅ Novas funcionalidades testadas
- [ ] ✅ RLS configurado
- [ ] ✅ Documentação atualizada

### Pós-Implementação

- [ ] 📧 **Notificar equipe** sobre conclusão
- [ ] 📚 **Treinar usuários** nas novas funcionalidades
- [ ] 📊 **Monitorar performance** por 1 semana
- [ ] 🔄 **Planejar** remoção dos backups (após 30 dias)

---

## 📞 Suporte

**Em caso de problemas**:

1. **Verificar logs** no Supabase Studio
2. **Consultar documentação** do Supabase
3. **Usar rollback** se necessário
4. **Contatar suporte** técnico

---

## 📝 Notas de Implementação

**Data da implementação**: ___________  
**Implementado por**: ___________  
**Versão do Supabase**: ___________  
**Observações**: 

___________________________________________  
___________________________________________  
___________________________________________  

---

**🎉 Implementação concluída com sucesso!**

O sistema está pronto para uso com:
- ✅ Compatibilidade total com código existente
- ✅ Sistema de auditoria completo
- ✅ Controles avançados de segurança
- ✅ Padronização monetária em USD
- ✅ Funcionalidades de aprovação

**Próximo passo**: Começar a usar as novas funcionalidades gradualmente!
# ✅ Checklist de Implementação - Supabase Studio
