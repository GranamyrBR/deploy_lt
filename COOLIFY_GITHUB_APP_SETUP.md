# 🔐 Configurar GitHub App no Coolify

## Por que você precisa disso?
- ✅ Acessar repositórios **privados**
- ✅ Deploy automático em pushes
- ✅ Não expor seu código publicamente
- ✅ Integração segura via OAuth

---

## 📋 Passo a Passo

### 1️⃣ No Coolify (criar GitHub App)

1. Acesse seu **Coolify Dashboard**
2. Vá em **Settings** → **Sources** (ou **Git Sources**)
3. Clique em **Add Source** ou **New GitHub App**
4. Escolha **GitHub**
5. Coolify vai gerar uma URL como:
   ```
   https://github.com/settings/apps/new?...
   ```
6. **Clique nessa URL** (vai abrir o GitHub)

---

### 2️⃣ No GitHub (criar a App)

A URL do Coolify já vem preenchida com os dados corretos:

**Dados da App:**
- **GitHub App name:** `coolify-seu-servidor` (ou qualquer nome)
- **Homepage URL:** URL do seu Coolify
- **Webhook URL:** `https://seu-coolify.com/webhooks/github`
- **Webhook secret:** (gerado automaticamente pelo Coolify)

**Permissões necessárias:**
- ✅ **Repository permissions:**
  - Contents: `Read-only`
  - Metadata: `Read-only`
  - Webhooks: `Read & write`
  - Deployments: `Read & write` (opcional)
  
- ✅ **Organization permissions:**
  - Members: `Read-only` (se usar org)

**Onde a app pode ser instalada:**
- Escolha: **Only on this account** (ou **Any account** se preferir)

3. Clique em **Create GitHub App**

---

### 3️⃣ Após criar a App

1. GitHub vai mostrar a página da App criada
2. Role até **Generate a private key**
3. Clique em **Generate a private key**
4. Um arquivo `.pem` será baixado
5. **Guarde esse arquivo com segurança!**

---

### 4️⃣ Voltar ao Coolify

1. Volte para o Coolify
2. Cole os dados da GitHub App:
   - **App ID:** (mostrado na página da App no GitHub)
   - **Client ID:** (mostrado na página da App)
   - **Client Secret:** (você precisa gerar: clique em "Generate a new client secret")
   - **Private Key:** (conteúdo do arquivo `.pem` baixado)
   - **Webhook Secret:** (já preenchido)

3. Clique em **Save**

---

### 5️⃣ Instalar a App no seu repositório

1. No GitHub, vá para a página da sua App:
   ```
   https://github.com/settings/apps/coolify-seu-nome
   ```
2. Clique em **Install App** (no menu lateral esquerdo)
3. Escolha onde instalar:
   - **Sua conta pessoal** ou
   - **Sua organização**
4. Escolha os repositórios:
   - **All repositories** ou
   - **Only select repositories** → Selecione `deploy_lt`
5. Clique em **Install**

---

### 6️⃣ Conectar no Coolify

1. No Coolify, vá para seu projeto
2. Em **Source**, agora você verá a GitHub App disponível
3. Selecione a App
4. Escolha o repositório `GranamyrBR/deploy_lt`
5. Branch: `deploy-prebuilt`

---

## 🔒 Tornar o Repositório Privado Novamente

Depois de configurar:

```bash
# No seu repositório local
gh repo edit --visibility private

# Ou via web:
# GitHub → Settings → Danger Zone → Change visibility → Make private
```

---

## ✅ Testar a Integração

1. Faça um commit na branch `deploy-prebuilt`
2. Push para o GitHub
3. Coolify deve detectar automaticamente
4. Deploy inicia em segundos! 🚀

---

## 🐛 Troubleshooting

### Erro: "Could not clone repository"
- ✅ Verifique se a App está instalada no repositório correto
- ✅ Verifique as permissões (Contents: Read)

### Erro: "Webhook not received"
- ✅ Verifique a Webhook URL no GitHub App settings
- ✅ Teste manualmente: GitHub App → Advanced → Recent Deliveries

### Erro: "Invalid private key"
- ✅ Certifique-se de copiar TODO o conteúdo do arquivo .pem
- ✅ Inclua `-----BEGIN RSA PRIVATE KEY-----` e `-----END RSA PRIVATE KEY-----`

---

## 📚 Documentação Oficial

- [Coolify Docs - GitHub Integration](https://coolify.io/docs/sources/github)
- [GitHub Apps Documentation](https://docs.github.com/en/developers/apps/getting-started-with-apps/about-apps)

---

## 🎯 Resultado Final

✅ Repositório privado  
✅ Deploy automático em push  
✅ Integração segura via OAuth  
✅ Sem necessidade de SSH keys  
✅ Controle granular de permissões  

**Seu código fica protegido e o deploy continua automático!** 🔐🚀
