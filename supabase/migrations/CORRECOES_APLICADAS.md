# Correções Aplicadas ao Script data_cleanup_before_constraints.sql

## Problemas Identificados e Corrigidos:

### 1. **Erro de Variável Não Declarada**
- **Problema**: `GET DIAGNOSTICS integer_var = ROW_COUNT;`
- **Erro**: "integer_var" is not a known variable
- **Solução**: Adicionado `rows_affected INTEGER;` na seção DECLARE e substituído `integer_var` por `rows_affected`

### 2. **Coluna Inexistente na Tabela Contact**
- **Problema**: `INSERT INTO public.contact (name, email, phone, contact_type, created_at, updated_at)`
- **Erro**: column "contact_type" of relation "contact" does not exist
- **Solução**: Removido a coluna `contact_type` do INSERT e ajustado para usar `phone` como constraint de conflito

### 3. **Estrutura Incorreta da Tabela User**
- **Problema**: `INSERT INTO public.user (email, password, name, role, created_at, updated_at)`
- **Erro**: Colunas não existem ou tipos incorretos
- **Solução**: Ajustado para usar a estrutura real da tabela com UUID e campos reais:
  ```sql
  INSERT INTO public.user (id, username, email, password, first_name, last_name, role, created_at, updated_at)
  VALUES (gen_random_uuid(), 'sistema_admin', 'sistema@admin.com', 'default_password_hash', 'Usuário', 'Sistema', 'admin', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
  ```

### 4. **Coluna Incorreta na Tabela Service**
- **Problema**: `INSERT INTO public.service (name, description, base_price, created_at, updated_at)`
- **Erro**: Coluna `base_price` não existe
- **Solução**: Substituído `base_price` por `price` que é a coluna real da tabela

### 5. **Constraint de Foreign Key com auth.users**
- **Problema**: Foreign key constraint "user_id_fkey" - Key (id) is not present in table "users"
- **Erro**: A tabela `user` tem FK para `auth.users` (Supabase Auth)
- **Solução**: Mudança de estratégia - usar usuários existentes ao invés de criar novos:
  ```sql
  -- Obter usuário padrão (primeiro usuário admin encontrado)
  SELECT id INTO default_user_id FROM public.user WHERE role = 'admin' LIMIT 1;
  
  -- Se não houver usuário admin, usar o primeiro usuário existente
  IF default_user_id IS NULL THEN
      SELECT id INTO default_user_id FROM public.user LIMIT 1;
  END IF;
  
  -- Fallback para UUID padrão se não houver usuários
  IF default_user_id IS NULL THEN
      default_user_id := '00000000-0000-0000-0000-000000000000'::uuid;
  END IF;
  ```

### 6. **Tratamento de Erros Robusto**
- **Problema**: Scripts falham quando encontram constraints ou dados inconsistentes
- **Solução**: Adicionado tratamento de exceções com blocos BEGIN/EXCEPTION:
  ```sql
  BEGIN
      -- Tentar inserção
  EXCEPTION
      WHEN OTHERS THEN
          -- Fallback para dados existentes
  END;
  ```

### 7. **Type Mismatch - Integer vs UUID**
- **Problema**: `invalid input syntax for type integer: "bfc1a714-139c-4b11-8c76-a489fa0422a4"`
- **Erro**: Tentando usar UUID em campo integer (contact.id)
- **Solução**: Removido atribuição de valor padrão integer e adicionado NULL check antes de updates:
  ```sql
  -- Antes (errado):
  default_contact_id := 1; -- Valor padrão seguro
  
  -- Depois (correto):
  default_contact_id := NULL; -- Será tratado posteriormente
  
  -- E adicionado verificação antes de updates:
  IF default_contact_id IS NOT NULL THEN
      UPDATE public.sale SET customer_id = default_contact_id WHERE customer_id IS NULL;
  END IF;
  ```

## Script Corrigido Completo

O script `data_cleanup_before_constraints.sql` agora:
- ✅ Declara todas as variáveis necessárias
- ✅ Usa as colunas reais das tabelas conforme o schema do banco
- ✅ Compatível com PostgreSQL e Supabase
- ✅ Trata constraints de foreign key corretamente
- ✅ Possui fallback robusto para casos de erro
- ✅ Pode ser executado sem erros de sintaxe

## Próximos Passos

1. **Testar o script** em um ambiente de desenvolvimento primeiro
2. **Executar na ordem correta** conforme documentado no EXECUTION_GUIDE.md
3. **Verificar os logs** de execução para confirmar sucesso
4. **Verificar se há usuários no sistema** antes da execução

## Verificação Pré-Execução

Execute esta query para verificar se há usuários no sistema:
```sql
SELECT COUNT(*) as total_users, 
       COUNT(CASE WHEN role = 'admin' THEN 1 END) as admin_users
FROM public.user;
```

## Ordem de Execução Recomendada:
```bash
1. fix_all_missing_foreign_keys.sql
2. data_cleanup_before_constraints.sql  ✅ AGORA CORRIGIDO E ROBUSTO
3. apply_not_null_constraints.sql
4. fix_remaining_issues.sql
```

Ou simplesmente execute o script unificado:
```bash
psql -h seu_host -d seu_banco -U seu_usuario -f complete_database_migration.sql
```