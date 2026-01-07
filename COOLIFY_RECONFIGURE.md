# 🔧 Reconfigurar Coolify - Repositório Correto

## ⚠️ Problema Identificado

- **Repositório errado** no Coolify: `lecodeploy` (contaminado)
- **Repositório correto**: `deploy_lt` (com cache busting)

---

## ✅ Solução: Recriar Aplicação no Coolify

### Passo 1: Remover Aplicação Antiga

1. Acesse: https://axioscode.com/ (Coolify Dashboard)
2. Vá em **Applications** ou **Projects**
3. Encontre a aplicação antiga (usando `lecodeploy`)
4. Clique em **Settings** > **Danger Zone**
5. Clique em **Delete Application**
6. Confirme a exclusão

---

### Passo 2: Criar Nova Aplicação

#### 2.1 - Criar Aplicação
1. No Coolify, clique em **+ New**
2. Selecione **Application**
3. Escolha **Git Repository**

#### 2.2 - Conectar GitHub
1. **Source**: GitHub
2. Se não conectado:
   - Clique em **Connect GitHub**
   - Autorize o Coolify no GitHub
   - Selecione a organização **GranamyrBR**

#### 2.3 - Selecionar Repositório
1. **Repository**: `GranamyrBR/deploy_lt` ✅
2. **Branch**: `main`
3. Clique em **Continue**

#### 2.4 - Configurar Build
1. **Build Pack**: `Dockerfile`
2. **Dockerfile Location**: `./Dockerfile` (raiz)
3. **Port**: `80` (Caddy serve na porta 80)
4. **Publish Directory**: `/web` (onde o Caddy serve)

#### 2.5 - Configurar Domínio
1. **Domain**: `axioscode.com`
2. Ou adicionar depois em **Domains** > **Add Domain**
3. **HTTPS**: ✅ Enabled (Let's Encrypt automático)

#### 2.6 - Auto Deploy
1. **Auto Deploy from Git**: ✅ **ENABLED** 
2. Isso cria webhook automático no GitHub!
3. Coolify detecta pushes e faz deploy automaticamente

---

### Passo 3: Configurar Variáveis de Ambiente

1. Vá em **Environment Variables**
2. Adicione as variáveis necessárias:

```bash
# Supabase
SUPABASE_URL=https://sup.axioscode.com
SUPABASE_ANON_KEY=sua-chave-anon-key

# Google
GOOGLE_MAPS_API_KEY=sua-chave-google-maps

# OpenAI
OPENAI_API_KEY=sua-chave-openai

# Ambiente
APP_ENV=production
FLUTTER_ENV=production
```

3. Clique em **Save**

---

### Passo 4: Primeiro Deploy

1. Clique em **Deploy** ou **Start Build**
2. Acompanhe os logs
3. Aguarde ~3-5 minutos

**O que vai acontecer:**
```bash
✅ Pull do GitHub (deploy_lt)
✅ Flutter build web --release
✅ Aplicar cache busting (versão: 3464ac8-timestamp)
✅ Gerar /web/version.txt
✅ Caddy serve em axioscode.com
```

---

### Passo 5: Verificar Webhook GitHub (Opcional)

Se quiser usar GitHub Actions também:

1. Vá em: https://github.com/GranamyrBR/deploy_lt/settings/hooks
2. Verifique se o Coolify criou o webhook automaticamente
3. Deve aparecer: `https://axioscode.com/api/v1/...`

**Nota:** Com **Auto Deploy** habilitado, o webhook é criado automaticamente!

---

## 🎯 Após Configuração

### 1. Testar Deploy Automático
```bash
# Fazer qualquer mudança
git commit --allow-empty -m "test: trigger coolify deploy"
git push origin main
```

### 2. Verificar App
```
https://axioscode.com/
```

### 3. Verificar Cache Busting (Console)
```javascript
window.appUpdate.version
// Deve retornar: "3464ac8-1736279xxx"
```

### 4. Verificar version.txt
```bash
curl https://axioscode.com/version.txt
```

---

## 📊 Vantagens da Integração Direta

Com **Auto Deploy** habilitado:

✅ **Push para main** → Deploy automático (sem GitHub Actions)
✅ **Webhook gerenciado** pelo Coolify (não precisa configurar manualmente)
✅ **Mais rápido** (sem intermediários)
✅ **Logs no Coolify** (tudo em um lugar)
✅ **Rollback fácil** (interface visual)

---

## ⚙️ Configuração do Dockerfile (Já está pronta!)

O Dockerfile já está configurado com:
- ✅ Flutter build web otimizado
- ✅ Cache busting automático
- ✅ Versionamento git-hash-timestamp
- ✅ Caddy servindo /web
- ✅ Headers otimizados via Caddyfile

**Não precisa modificar nada!**

---

## 🐛 Troubleshooting

### Build falha no Coolify:
```bash
# Ver logs no Coolify
# Pode ser:
# - Falta de variáveis de ambiente (.env)
# - Erro no Dockerfile
# - Dependências Flutter
```

### Domain não funciona:
```bash
# Verificar DNS:
# axioscode.com deve apontar para o IP da VPS

# Verificar no Coolify:
# Settings > Domains
# Certificado SSL deve estar ativo
```

### Cache busting não funciona:
```bash
# Verificar se o build rodou corretamente
# Verificar version.txt no servidor
curl https://axioscode.com/version.txt

# Verificar console do browser
# Deve aparecer: "✅ Cache busting loader inicializado"
```

---

## ✅ Checklist

- [ ] Aplicação antiga removida do Coolify
- [ ] Nova aplicação criada com `deploy_lt`
- [ ] Auto Deploy habilitado
- [ ] Variáveis de ambiente configuradas
- [ ] Primeiro build com sucesso
- [ ] App acessível em axioscode.com
- [ ] Cache busting funcionando
- [ ] version.txt disponível

---

## 📚 Recursos

- **Coolify Docs**: https://coolify.io/docs
- **GitHub Repo**: https://github.com/GranamyrBR/deploy_lt
- **App Produção**: https://axioscode.com/
- **Coolify Dashboard**: https://axioscode.com/

---

**Última atualização:** 2026-01-07  
**Status:** Aguardando reconfiguração no Coolify
