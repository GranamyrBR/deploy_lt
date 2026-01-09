# 🔧 Fix N8N Webhook - Phone NULL

## Problema
Webhook está enviando leads sem telefone para Supabase, mas a coluna `phone` é obrigatória.

---

## Solução 1: Tornar Phone Opcional (RECOMENDADO)

Execute a migration no Supabase:
```sql
-- Arquivo: supabase/migrations/fix_leadstintim_phone_nullable.sql
```

Aplique via Supabase Dashboard:
1. SQL Editor → New Query
2. Cole o conteúdo do arquivo
3. Execute

---

## Solução 2: Ajustar N8N para enviar valor padrão

### No N8N Workflow:

**Adicione um nó "Set" antes do Supabase:**

```javascript
// Node: Set Default Values
{
  "phone": {{$json.phone || 'Não informado'}},
  "name": {{$json.name || 'Lead sem nome'}},
  // ... outros campos
}
```

**Ou use Function Node:**

```javascript
// Node: Validate Phone
const items = $input.all();

return items.map(item => {
  return {
    json: {
      ...item.json,
      phone: item.json.phone || 'Não informado',
      // Validar formato se tiver valor
      phone: item.json.phone ? item.json.phone.trim() : 'Não informado'
    }
  };
});
```

---

## Solução 3: Validação + Skip

**Skip leads sem telefone:**

```javascript
// Node: Filter - Only with Phone
// Expression: {{$json.phone}}
// Continue if: True (Is True)
```

Só insere no Supabase se tiver telefone.

---

## 🎯 Recomendação

**Use Solução 1** - Tornar phone opcional no banco:
- ✅ Flexível para captar leads sem telefone
- ✅ Não perde dados
- ✅ Pode filtrar/contatar depois
- ✅ Realista (nem todo lead tem telefone)

**Phone obrigatório só faz sentido se:**
- ❌ Você só trabalha com WhatsApp
- ❌ Telefone é requisito absoluto do negócio

---

## 📋 Checklist

- [ ] Escolher solução (1, 2 ou 3)
- [ ] Aplicar fix no Supabase OU N8N
- [ ] Testar webhook com lead sem telefone
- [ ] Verificar se insere corretamente
- [ ] Atualizar regras de validação no app Flutter

---

## 🧪 Teste

**Envie um webhook de teste:**

```bash
curl -X POST https://seu-n8n.com/webhook/lead-test \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Lead Teste",
    "source": "WhatsApp",
    "message": "Olá, gostaria de informações"
  }'
```

Deve inserir sem erro de `phone NULL`.
