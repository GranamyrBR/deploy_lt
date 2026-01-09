# 🔐 GitHub Secrets para WhatsApp System

## 📋 Secrets Necessários

Configure estes secrets no GitHub para o workflow de deploy:

### 1. **Supabase**
```
SUPABASE_URL=https://seu-projeto.supabase.co
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### 2. **N8N**
```
N8N_URL=https://critical.axioscode.com
N8N_API_TOKEN=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI4NTRhNTA3MS0xNzg3LTQxMTktYTE0Ni04ZmE5Y2RiNzM1NWUiLCJpc3MiOiJuOG4iLCJhdWQiOiJwdWJsaWMtYXBpIiwiaWF0IjoxNzY3OTg1OTUzfQ.WzPZKM2YFKXobjwBv99NPkDjW_YUFdrgOGtLbBycBU4
N8N_WEBHOOK_PATH=/webhook/Leco_Flutter
```

### 3. **Evolution API**
```
EVOLUTION_API_URL=https://sua-evolution-api.com
EVOLUTION_API_KEY=sua-api-key-aqui
EVOLUTION_INSTANCE=lecotour
```

---

## 🔧 Como Adicionar no GitHub

### Via Web:
1. Vá para: https://github.com/GranamyrBR/deploy_lt/settings/secrets/actions
2. Clique em **New repository secret**
3. Adicione cada secret acima

### Via CLI:
```bash
gh secret set SUPABASE_URL --body "https://seu-projeto.supabase.co"
gh secret set N8N_API_TOKEN --body "eyJhbGci..."
# ... etc
```

---

## 🔒 Segurança

### ❌ NUNCA commite:
- API Keys
- Tokens
- Senhas
- URLs com credenciais embarcadas

### ✅ SEMPRE use:
- GitHub Secrets para CI/CD
- Variáveis de ambiente no Supabase
- Environment variables no N8N
- `.env` local (com `.gitignore`)

---

## 🎯 Para o N8N Workflow

No N8N, configure as variáveis de ambiente:

**Settings → Environments → Add Variable:**

```
SUPABASE_URL=https://seu-projeto.supabase.co
SUPABASE_SERVICE_ROLE_KEY=eyJ...
EVOLUTION_API_URL=https://sua-evolution.com
EVOLUTION_INSTANCE=lecotour
```

Depois, no workflow, use: `{{ $env.SUPABASE_URL }}`

---

## 📊 Verificar Secrets (sem expor valores)

```bash
# Listar secrets configurados
gh secret list

# Ver quando foi atualizado
gh secret list --json name,updatedAt
```

---

## 🚨 Se um Secret Vazar

1. **Revogue imediatamente** no serviço original
2. **Gere novo** token/key
3. **Atualize** o secret no GitHub
4. **Re-deploy** para aplicar novo valor

---

## ✅ Checklist

- [ ] SUPABASE_URL configurado
- [ ] SUPABASE_SERVICE_ROLE_KEY configurado
- [ ] N8N_API_TOKEN configurado
- [ ] N8N_WEBHOOK_PATH configurado
- [ ] EVOLUTION_API_URL configurado
- [ ] EVOLUTION_API_KEY configurado
- [ ] EVOLUTION_INSTANCE configurado
- [ ] Secrets verificados com `gh secret list`
- [ ] N8N environment variables configuradas

---

**Nunca exponha secrets no código ou logs!** 🔐
