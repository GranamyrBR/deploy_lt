# 🚀 Configuração de Deploy Automático - Coolify

## 📋 Informações do Servidor

- **VPS**: Hostinger (KVM)
- **Gerenciador**: Coolify
- **Coolify URL**: https://waha.axioscode.com/
- **Proxy**: Caddy
- **Domínio Produção**: https://axioscode.com/
- **Repositório**: https://github.com/GranamyrBR/deploy_lt ✅ (Correto)
- **⚠️ Repositório Antigo (NÃO USAR)**: https://github.com/GranamyrBR/lecodeploy (Contaminado)

---

## 🎯 Como Funciona o Deploy Automático

### Fluxo:
```
Push para main → GitHub Actions → 
→ Trigger Coolify Webhook → 
→ Coolify puxa código do GitHub → 
→ Build Flutter Web → 
→ Deploy em https://axioscode.com/
```

---

## 🔧 Configuração no Coolify

### Passo 1: Configurar Repositório no Coolify

⚠️ **IMPORTANTE**: Se você está vindo do repositório `lecodeploy` (contaminado), veja: [COOLIFY_RECONFIGURE.md](COOLIFY_RECONFIGURE.md)

1. Acesse: https://waha.axioscode.com/
2. Vá em **Projects** ou **Applications**
3. Selecione a aplicação **Lecotour Dashboard** (ou crie uma nova)
4. Na aba **Source** ou **Git**:
   - **Repository**: `GranamyrBR/deploy_lt` ✅ (Repositório correto)
   - **Branch**: `main`
   - **Auto Deploy from Git**: ✅ **ENABLED** (webhook automático!)
5. **Build Pack**: Dockerfile
6. **Dockerfile Location**: `./Dockerfile` (raiz do projeto)
7. **Port**: 80 (Caddy serve na porta 80)
8. **Publish Directory**: `/web` (Caddy serve automaticamente)

### Passo 2: Obter Webhook URL

No Coolify, na mesma tela:
1. Procure por **"Deploy Webhook"** ou **"Webhook URL"**
2. Copie a URL completa

**Formato esperado:**
```
https://waha.axioscode.com/api/v1/deploy?uuid=<APPLICATION_UUID>&force=true
```

**Para encontrar o UUID:**
- Na URL da página da aplicação no Coolify
- Ou em Settings > General

### Passo 3: Adicionar ao GitHub Secrets

1. Vá em: https://github.com/GranamyrBR/deploy_lt/settings/secrets/actions
2. Clique em **"New repository secret"**
3. **Name**: `COOLIFY_WEBHOOK_URL`
4. **Value**: Cole a URL do webhook do Coolify
5. Clique em **"Add secret"**

---

## ✅ Testando o Deploy

### Deploy Automático:
Faça qualquer commit e push para `main`:
```bash
git add .
git commit -m "test: deploy automático"
git push origin main
```

O workflow será disparado automaticamente!

### Deploy Manual:
1. Vá em: https://github.com/GranamyrBR/deploy_lt/actions
2. Selecione **"Deploy to Production (Coolify)"**
3. Clique em **"Run workflow"**
4. Selecione branch `main`
5. Clique em **"Run workflow"**

---

## 📊 Monitoramento

### GitHub Actions:
- URL: https://github.com/GranamyrBR/deploy_lt/actions
- Mostra se o webhook foi chamado com sucesso

### Coolify:
- URL: https://waha.axioscode.com/
- Mostra o progresso real do deploy
- Logs de build
- Status da aplicação

### Aplicação:
- URL: https://axioscode.com/
- Verifique se as mudanças foram aplicadas

---

## ⏱️ Tempo de Deploy

- **GitHub Actions**: ~10 segundos (apenas chama webhook)
- **Coolify Build**: ~2-5 minutos (puxa código + build + deploy)
- **Total**: ~2-5 minutos

---

## 🐛 Troubleshooting

### Webhook retorna erro 404:
- Verifique se a URL do webhook está correta
- Confirme que a aplicação existe no Coolify
- Verifique o UUID

### Deploy não acontece:
- Verifique se "Auto Deploy" está habilitado no Coolify
- Veja os logs no Coolify
- Confirme que o branch está correto (main)

### Build falha no Coolify:
- Verifique os logs de build no Coolify
- Pode ser falta de variáveis de ambiente
- Pode ser erro de compilação

---

## 🔐 Variáveis de Ambiente no Coolify

**IMPORTANTE**: Flutter Web usa variáveis de ambiente de forma especial:

1. **Build time**: `.env` é necessário para compilar (já incluído no repo com placeholders)
2. **Runtime**: Variáveis são injetadas via `window.ENV` no HTML

### Como configurar no Coolify:

1. Vá na aplicação → Tab **"Environment Variables"**
2. Adicione as variáveis (Coolify injeta automaticamente via Caddy):
   - `SUPABASE_URL=https://sup.axioscode.com`
   - `SUPABASE_ANON_KEY=sua-chave-real`
   - `GOOGLE_MAPS_API_KEY=sua-chave`
   - `OPENAI_API_KEY=sua-chave`
   - etc...

3. Coolify/Caddy irá:
   - Injetar essas variáveis no `index.html`
   - Disponibilizar via `window.ENV`
   - Flutter Web lê de `Environment.get('KEY')`

---

## 📝 Notas

- O workflow `.github/workflows/deploy-production.yml` já está criado
- Ele apenas **dispara** o deploy
- O build real acontece no **Coolify**
- Coolify gerencia todo o processo de deploy
- Caddy atualiza automaticamente o proxy

---

## ✅ Checklist de Configuração

- [ ] Aplicação configurada no Coolify
- [ ] Repositório GitHub conectado
- [ ] Auto Deploy habilitado
- [ ] Webhook URL copiada
- [ ] Secret `COOLIFY_WEBHOOK_URL` adicionado no GitHub
- [ ] Workflow testado com sucesso
- [ ] Variáveis de ambiente configuradas no Coolify
- [ ] Deploy funcionando em https://axioscode.com/

---

**Última atualização**: 2026-01-07
