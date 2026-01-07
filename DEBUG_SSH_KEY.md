# 🔍 Debug - SSH Key GitHub

## Problema: "Key is invalid. You must supply a key in OpenSSH public key format"

---

## ✅ Formato Correto da Chave Pública

### Deve ser UMA ÚNICA LINHA:
```
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGbXnjJPiLj... root@servidor
```

Ou para RSA:
```
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC5s... root@servidor
```

### ❌ Formatos INCORRETOS:

**Múltiplas linhas:**
```
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGbXn
jJPiLj...
root@servidor
```

**Chave privada (tem BEGIN/END):**
```
-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAAAABG5vbmU...
-----END OPENSSH PRIVATE KEY-----
```

**Com espaços extras ou quebras:**
```
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAA
IGbXnjJPiLj... root@servidor
```

---

## 🔧 Como Pegar a Chave Correta

### No servidor Coolify:

```bash
# SSH no servidor
ssh root@SEU_IP_VPS

# Listar chaves disponíveis
ls -la ~/.ssh/*.pub

# Ver chave pública (escolha uma):
cat ~/.ssh/id_ed25519.pub        # Se usou ed25519
cat ~/.ssh/id_rsa.pub            # Se usou RSA
cat ~/.ssh/coolify_deploy_lt.pub # Se criou com esse nome
```

### Copiar EXATAMENTE como aparece:

```bash
# Copiar para clipboard (Linux com xclip)
cat ~/.ssh/coolify_deploy_lt.pub | xclip -selection clipboard

# Ou simplesmente ver e copiar manualmente
cat ~/.ssh/coolify_deploy_lt.pub
```

**IMPORTANTE:** Copie a linha INTEIRA, sem quebras!

---

## 🎯 Adicionar no GitHub - Passo a Passo

### 1. Se não tem chave, criar:

```bash
ssh root@SEU_IP_VPS

# Criar nova chave
ssh-keygen -t ed25519 -C "coolify@axioscode.com" -f ~/.ssh/coolify_deploy -N ""

# Ver chave pública
cat ~/.ssh/coolify_deploy.pub
```

### 2. Copiar a chave:

Selecione TODA a linha e copie. Exemplo:
```
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMgKxYsLm9T1q2b3N4c5P6d7r8S9t0U1v2w3X4y5z6A7 coolify@axioscode.com
```

### 3. Adicionar no GitHub:

1. Vá em: https://github.com/GranamyrBR/deploy_lt/settings/keys
2. Clique em **"Add deploy key"**
3. **Title**: `Coolify Production`
4. **Key**: Cole a chave (deve ser uma linha só)
5. **NÃO marque** "Allow write access"
6. Clique em **"Add key"**

Se der erro "Key is invalid":
- ✅ Verifique se copiou a linha inteira
- ✅ Verifique se não tem quebras de linha
- ✅ Verifique se é a chave .pub (pública), não a privada
- ✅ Verifique se começa com ssh-ed25519 ou ssh-rsa

---

## 🔐 Personal Access Token (Alternativa Mais Simples)

Se SSH continuar dando problema, use token:

### 1. Criar Token:

**Nova Interface GitHub (2024+):**
1. https://github.com/settings/tokens
2. Clique em **"Generate new token"**
3. Escolha:
   - **"Tokens (classic)"** ← Use esse! ✅
   - Ou **"Fine-grained tokens"** (mais complexo)

**Para Token Classic:**
1. **Note**: `Coolify Deploy - deploy_lt`
2. **Expiration**: Custom (1 year ou mais)
3. **Select scopes**:
   - ✅ `repo` (marque TUDO em repo)
   - ✅ `workflow` (se usar GitHub Actions)
4. Clique em **"Generate token"**
5. **COPIE O TOKEN** (começa com `ghp_...`)
6. Guarde em lugar seguro (só aparece uma vez!)

### 2. Usar no Coolify:

**Opção A - URL com token:**
```
https://ghp_SEU_TOKEN_AQUI@github.com/GranamyrBR/deploy_lt.git
```

**Opção B - Campos separados (se disponível):**
- URL: `https://github.com/GranamyrBR/deploy_lt.git`
- Username: `GranamyrBR`
- Password: `ghp_SEU_TOKEN_AQUI`

---

## 🧪 Testar SSH Key Localmente

No servidor:

```bash
# Testar conexão SSH com GitHub
ssh -T git@github.com -i ~/.ssh/coolify_deploy

# Se funcionar, verá:
# Hi GranamyrBR! You've successfully authenticated...
```

Se der erro, a chave não está funcionando.

---

## ✅ Checklist

Deploy Key (SSH):
- [ ] Chave gerada no servidor
- [ ] Chave pública copiada (uma linha só)
- [ ] Deploy key adicionada no GitHub
- [ ] Chave privada configurada no Coolify Source
- [ ] Teste SSH funciona: `ssh -T git@github.com -i ~/.ssh/chave`

Personal Access Token:
- [ ] Token gerado no GitHub (classic)
- [ ] Token copiado (começa com ghp_)
- [ ] URL com token configurada no Coolify
- [ ] Scope `repo` marcado

---

**Qual método você quer usar?**
1. 🔑 SSH Deploy Key (mais seguro, mais complexo)
2. 🎫 Personal Access Token (mais simples, funciona sempre) ⭐
