# 🔧 GUIA DE CORREÇÃO DA CONSTRAINT DE PAYMENT_STATUS

## ❌ PROBLEMA IDENTIFICADO

**CAUSA RAIZ ENCONTRADA**: Existem **duas constraints conflitantes** na tabela `sale`:

1. ✅ `sale_payment_status_check` - aceita valores em **inglês**: 'pending', 'partial', 'paid', 'overdue', 'refunded'
2. ❌ `sale_payment_status_valid` - aceita valores em **português**: 'Pendente', 'Pago', 'Parcial', 'Cancelado', 'Reembolsado'

O código Flutter está enviando valores em inglês ('pending'), mas a constraint `sale_payment_status_valid` só aceita português, causando o erro.

## 🎯 SOLUÇÃO DEFINITIVA

**SIMPLES**: Remover apenas a constraint problemática `sale_payment_status_valid`.

Execute este comando **diretamente no Supabase Studio**:

### 1. Acesse o Supabase Studio
- Vá para: https://sup.axioscode.com
- Faça login
- Vá para "SQL Editor"

### 2. Execute APENAS este comando:

```sql
-- Remover a constraint problemática
ALTER TABLE sale DROP CONSTRAINT sale_payment_status_valid;
```

### 3. (Opcional) Verificar se funcionou:

```sql
-- Verificar constraints restantes
SELECT 
    conname as constraint_name,
    pg_get_constraintdef(c.oid) as constraint_definition
FROM pg_constraint c
JOIN pg_namespace n ON n.oid = c.connamespace
JOIN pg_class cl ON cl.oid = c.conrelid
WHERE cl.relname = 'sale' 
  AND n.nspname = 'public'
  AND contype = 'c'
  AND conname LIKE '%payment_status%'
ORDER BY conname;
```

**Resultado esperado**: Apenas `sale_payment_status_check` deve aparecer.

## ✅ VERIFICAÇÃO

Após executar o comando:

1. Volte para a aplicação Flutter
2. Tente criar uma nova venda
3. **O erro deve ter sido resolvido!** ✅

## 🎯 POR QUE ISSO RESOLVE?

- ✅ A constraint `sale_payment_status_check` (que permanece) aceita valores em inglês
- ❌ A constraint `sale_payment_status_valid` (que foi removida) só aceitava português
- 🎯 O código Flutter usa valores em inglês ('pending', 'paid', etc.)
- ✅ Agora não há mais conflito!

## 📝 RESULTADO ESPERADO

Após a correção:
- ✅ Criar vendas sem erro
- ✅ Status de pagamento funcionando: 'pending', 'partial', 'paid', 'overdue', 'refunded'
- ✅ Aplicação funcionando normalmente
# 🔧 GUIA DE CORREÇÃO DA CONSTRAINT DE PAYMENT_STATUS
