# 🔐 Coolify - Repositório GitHub Privado

## 🎯 Métodos para Conectar Repositório Privado

---

## Método 1: GitHub App (Recomendado se funcionar) ⭐

### Passo 1: Instalar Coolify GitHub App

1. No Coolify, vá em **Sources** (barra lateral)
2. Clique em **"+ Add"**
3. Selecione **"GitHub App"**
4. Clique em **"Install GitHub App"**

### Passo 2: No GitHub

Você será redirecionado para GitHub:
1. URL será algo como: `https://github.com/apps/coolify-[seu-servidor]`
2. Clique em **"Install"** ou **"Configure"**
3. Selecione onde instalar:
   - **Only select repositories** → Escolha `deploy_lt` ✅
4. Clique em **"Install"**

### Passo 3: Se der erro 500

**Solução:** Pode ser problema de callback URL ou firewall. Use Método 2.

---

## Método 2: Deploy Key (SSH) - Mais Confiável ✅

### Passo 1: Gerar Deploy Key no Servidor

**SSH no servidor Coolify:**

```bash
# SSH na sua VPS onde o Coolify está
ssh root@SEU_IP_VPS  # ou root@axioscode.com se configurado

# Gerar chave SSH (se não existir)
ssh-keygen -t ed25519 -C "coolify-deploy-lt" -f ~/.ssh/coolify_deploy_lt -N ""

# Ver a chave pública
cat ~/.ssh/coolify_deploy_lt.pub
```

**COPIE** a saída (começa com `ssh-ed25519`).

### Passo 2: Adicionar Deploy Key no GitHub

1. Vá em: https://github.com/GranamyrBR/deploy_lt/settings/keys
2. Clique em **"Add deploy key"**
3. Preencha:
   - **Title**: `Coolify Production Server`
   - **Key**: Cole a chave pública que copiou
   - **Allow write access**: ❌ Deixe desmarcado (somente leitura)
4. Clique em **"Add key"**

### Passo 3: Configurar Source no Coolify

1. No Coolify, vá em **Sources**
2. Clique em **"+ Add"**
3. Selecione **"Git with SSH"** ou **"Private Key (Git)"**
4. Preencha:
   ```
   Name: deploy_lt_source
   Private Key: [Cole o conteúdo de ~/.ssh/coolify_deploy_lt]
   ```

Para pegar a chave privada:
```bash
cat ~/.ssh/coolify_deploy_lt
```
Cole TODO o conteúdo (incluindo `-----BEGIN` e `-----END`).

### Passo 4: Criar Aplicação

1. **+ New** → **Application** → **Git Repository**
2. Preencha:
   ```
   Source: deploy_lt_source (que você acabou de criar)
   Git Repository URL: git@github.com:GranamyrBR/deploy_lt.git
   Branch: main
   ```
3. Continue com Build Pack: `Dockerfile`, Port: `80`, etc.

---

## Método 3: Personal Access Token (PAT)

### Passo 1: Criar Token no GitHub

1. Vá em: https://github.com/settings/tokens/new
2. Preencha:
   - **Note**: `Coolify Deploy - deploy_lt`
   - **Expiration**: `1 year` (ou escolha)
   - **Select scopes**:
     - ✅ `repo` (Full control of private repositories)
3. Clique em **"Generate token"**
4. **COPIE O TOKEN** (você só verá uma vez!)

Exemplo: `ghp_abc123xyz...`

### Passo 2: Configurar no Coolify

1. No Coolify, vá em **Sources**
2. Clique em **"+ Add"**
3. Selecione **"GitHub"** ou **"Git"**
4. Use uma dessas opções:

**Opção A - URL com token embutido:**
```
https://ghp_SEU_TOKEN_AQUI@github.com/GranamyrBR/deploy_lt.git
```

**Opção B - Campos separados:**
```
Git Repository URL: https://github.com/GranamyrBR/deploy_lt.git
Username: seu-usuario-github
Password/Token: ghp_SEU_TOKEN_AQUI
```

### Passo 3: Criar Aplicação

Use o Source criado normalmente.

---

## 🔄 Configurar Auto Deploy (Webhook)

### Passo 1: Pegar URL do Webhook no Coolify

1. Na sua aplicação criada
2. Vá em **Settings** → **Git** ou **Webhooks**
3. **COPIE** a webhook URL:
   ```
   https://axioscode.com/api/v1/deploy/webhooks/[ID_UNICO]
   ```

### Passo 2: Adicionar Webhook no GitHub

1. Vá em: https://github.com/GranamyrBR/deploy_lt/settings/hooks
2. Clique em **"Add webhook"**
3. Preencha:
   ```
   Payload URL: [Cole a URL do Coolify]
   Content type: application/json
   Secret: [Deixe vazio ou use o do Coolify se houver]
   Which events: Just the push event ✅
   Active: ✅
   ```
4. Clique em **"Add webhook"**

### Testar Webhook

```bash
# Faça um push qualquer
git commit --allow-empty -m "test: trigger webhook"
git push origin main

# No GitHub, vá em Settings → Webhooks
# Clique no webhook criado
# Veja "Recent Deliveries" - deve mostrar status 200
```

---

## ✅ Resumo - Qual Método Usar?

| Método | Recomendação | Quando Usar |
|--------|--------------|-------------|
| **GitHub App** | ⭐⭐⭐ | Se funcionar (erro 500 = pular) |
| **Deploy Key (SSH)** | ⭐⭐⭐ | Mais confiável, seguro |
| **Personal Token** | ⭐⭐ | Rápido mas menos seguro |

---

## 🐛 Troubleshooting

### Erro: "Permission denied (publickey)"
```bash
# A Deploy Key não foi adicionada corretamente
# Verifique no GitHub se a chave está lá
# Verifique se a chave privada está correta no Coolify
```

### Erro: "Repository not found"
```bash
# Token sem permissão ou URL errada
# Verifique se o token tem scope 'repo'
# Verifique se a URL está correta (HTTPS vs SSH)
```

### Webhook não dispara
```bash
# Verifique no GitHub: Settings → Webhooks
# Veja "Recent Deliveries"
# Se erro: verifique firewall da VPS
# Coolify precisa ser acessível pelo GitHub
```

### Erro 500 no GitHub App
```bash
# Problema comum quando:
# - Coolify não está com HTTPS correto
# - Firewall bloqueando callback
# - Problema temporário do GitHub
# 
# Solução: Use Deploy Key (Método 2)
```

---

## 🎯 Recomendação Final

**Use Deploy Key (Método 2)** - É o mais confiável e seguro!

1. ✅ Não expira (diferente de tokens)
2. ✅ Mais seguro (read-only)
3. ✅ Não depende de GitHub App (que pode dar erro)
4. ✅ Funciona 100% das vezes

---

**Precisa de ajuda em algum passo específico?**
