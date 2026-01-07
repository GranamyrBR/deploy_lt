# Scripts para Supabase - Lecotour Dashboard

## 📋 Resumo dos Arquivos

| Arquivo | Descrição | Quando Usar |
|---------|-----------|-------------|
| `migration_sale_upgrade.sql` | **Script principal** - Migração completa do sistema de vendas | ✅ **Recomendado para implementação** |
| `flutter_functions_compatible.sql` | Funções SQL para integração com Flutter | ✅ **Após migração principal** |
| `clean_sales_now.sql` | Limpeza completa de dados de vendas | ⚠️ Antes da migração |
| `validation_tests.sql` | Validação pós-migração | ✅ Sempre após aplicar migração |
| `COMANDOS_SUPABASE_STUDIO.sql` | Comandos organizados para Supabase Studio | 📖 Para execução passo a passo |

## 🚀 Execução da Migração (Recomendado)

### Para Implementação Completa

1. **Faça backup** no Dashboard do Supabase:
   - Settings → Database → Create Backup

2. **Limpe dados antigos**:
   - Execute `clean_sales_now.sql`

3. **Execute a migração principal**:
   - Execute `migration_sale_upgrade.sql` (em blocos)

4. **Instale funções Flutter**:
   - Execute `flutter_functions_compatible.sql`

5. **Valide os resultados**:
   - Execute `validation_tests.sql`
   - Verifique se não há erros

### Para Execução Guiada

1. **Siga o checklist**:
   - Use `CHECKLIST_IMPLEMENTACAO_SUPABASE.md`

2. **Execute comandos organizados**:
   - Use `COMANDOS_SUPABASE_STUDIO.sql`

3. **Valide cada fase**:
   - Verificações incluídas nos comandos

## ⚡ Script Principal: `migration_sale_upgrade.sql`

### O que faz:
- ✅ Atualiza tabela `sale` com novos campos
- ✅ Cria sistema de auditoria completo
- ✅ Adiciona controle de aprovações
- ✅ Padroniza valores monetários em USD
- ✅ Mantém compatibilidade com Flutter
- ✅ Cria tabelas auxiliares

### Novas tabelas criadas:
- `exchange_rate_history` - Histórico de taxas de câmbio
- `audit_log` - Log completo de auditoria
- `deleted_sales_log` - Log de vendas deletadas

### Novos campos na tabela `sale`:
- `sale_number` - Número único da venda
- `total_amount_usd` - Valor em USD
- `exchange_rate_used` - Taxa de câmbio utilizada
- `created_by_user_id` - Usuário que criou
- `deleted_at` - Data de exclusão (soft delete)
- `requires_approval` - Requer aprovação para exclusão

## 🔍 Validação

Após executar a migração, sempre execute `validation_tests.sql` para:
- ✅ Verificar se novos campos foram criados
- ✅ Confirmar que tabelas auxiliares existem
- ✅ Validar funções instaladas
- ✅ Testar funcionalidades básicas
- ✅ Verificar compatibilidade com Flutter

## ⚠️ Importante

### Antes de Executar:
1. **SEMPRE faça backup**
2. Teste em ambiente de desenvolvimento primeiro
3. Execute fora do horário de pico
4. Tenha o plano de rollback pronto

### Se der erro:
1. Verifique os logs no Dashboard
2. Use o backup para restaurar
3. Consulte o `supabase_setup_guide.md`
4. Execute os scripts em partes menores

## 🔧 Funcionalidades do Sistema Atualizado

### Sistema de Auditoria
- **Rastreamento completo** de todas as operações
- **Log de exclusões** com aprovação para vendas de alto valor
- **Contexto de usuário** para todas as operações

### Controle de Exclusões
- **Validação automática** antes de deletar vendas
- **Aprovação obrigatória** para vendas > $1000 USD
- **Soft delete** com possibilidade de recuperação

### Padronização Monetária
- **Valores em USD** como padrão
- **Taxas de câmbio** bloqueadas no momento da venda
- **Histórico de taxas** para relatórios precisos

## 🎯 Resultados Esperados

Após a migração bem-sucedida:
- ✅ Sistema de vendas atualizado e compatível
- ✅ Auditoria completa implementada
- ✅ Controles de segurança avançados
- ✅ Padronização monetária em USD
- ✅ Funcionalidades de aprovação ativas
- ✅ Zero impacto no código Flutter existente

## 📞 Suporte

Em caso de problemas:
1. Consulte o `supabase_setup_guide.md`
2. Verifique os logs do Supabase
3. Use o backup para restaurar se necessário
4. Execute a validação para diagnosticar

---

**💡 Dica**: Para implementação completa, siga o `CHECKLIST_IMPLEMENTACAO_SUPABASE.md` e use os comandos do `COMANDOS_SUPABASE_STUDIO.sql`. É organizado, seguro e eficiente!
# Scripts para Supabase - Lecotour Dashboard
