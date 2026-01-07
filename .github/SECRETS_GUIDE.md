# 🔐 Guia de Configuração de Secrets

Este documento explica como configurar os secrets necessários para o projeto Lecotour Dashboard no GitHub Actions.

## 📋 Secrets Necessários

### Obrigatórios

#### `SUPABASE_URL`
- **Descrição**: URL do projeto Supabase
- **Formato**: `https://seu-projeto.supabase.co`
- **Onde encontrar**: 
  1. Acesse [Supabase Dashboard](https://app.supabase.com)
  2. Selecione seu projeto
  3. Settings > API
  4. Copie "Project URL"

#### `SUPABASE_ANON_KEY`
- **Descrição**: Chave anônima pública do Supabase
- **Formato**: String longa começando com `eyJ...`
- **Onde encontrar**:
  1. Supabase Dashboard > Settings > API
  2. Copie "Project API keys" > "anon" > "public"

### Opcionais (para funcionalidades específicas)

#### `FIREBASE_API_KEY`
- **Descrição**: API Key do Firebase
- **Onde encontrar**: Firebase Console > Project Settings > General > Web API Key

#### `FIREBASE_PROJECT_ID`
- **Descrição**: ID do projeto Firebase
- **Onde encontrar**: Firebase Console > Project Settings > General > Project ID

#### `FIREBASE_SERVICE_ACCOUNT`
- **Descrição**: JSON do service account para deploy automático
- **Onde obter**:
  1. Firebase Console > Project Settings
  2. Service Accounts tab
  3. Generate new private key
  4. Copie TODO o conteúdo do JSON

#### `WHATSAPP_API_TOKEN`
- **Descrição**: Token da API do WhatsApp Business
- **Onde obter**: WhatsApp Business API Dashboard

## 🚀 Métodos de Configuração

### Método 1: Interface Web do GitHub (Recomendado)

1. Acesse: https://github.com/GranamyrBR/deploy_lt/settings/secrets/actions

2. Clique em **"New repository secret"**

3. Para cada secret:
   - **Name**: Nome exato do secret (ex: `SUPABASE_URL`)
   - **Value**: Valor do secret
   - Clique em **"Add secret"**

4. Repita para todos os secrets necessários

### Método 2: GitHub CLI (Automático)

Se você tem o GitHub CLI instalado:

```bash
# Executar script auxiliar
bash .github/scripts/setup-secrets.sh
```

Este script irá:
- ✅ Verificar se gh CLI está instalado
- ✅ Verificar autenticação
- ✅ Solicitar valores para cada secret
- ✅ Configurar automaticamente no GitHub

### Método 3: GitHub CLI (Manual)

```bash
# Instalar GitHub CLI (se necessário)
# macOS:   brew install gh
# Windows: winget install GitHub.cli
# Linux:   https://github.com/cli/cli#installation

# Login
gh auth login

# Adicionar secrets individualmente
gh secret set SUPABASE_URL -b"https://seu-projeto.supabase.co"
gh secret set SUPABASE_ANON_KEY -b"sua_chave_aqui"

# Para JSON grande (service account), use arquivo:
gh secret set FIREBASE_SERVICE_ACCOUNT < service-account.json

# Ver secrets configurados
gh secret list
```

## 🔍 Como Obter Firebase Service Account

### Passo a Passo Detalhado:

1. **Acesse Firebase Console**
   - URL: https://console.firebase.google.com
   - Selecione seu projeto

2. **Vá para Project Settings**
   - Clique no ícone de engrenagem ⚙️
   - Clique em "Project Settings"

3. **Abra Service Accounts**
   - Clique na aba "Service Accounts"
   - Você verá informações sobre service accounts

4. **Gere Nova Private Key**
   - Clique em "Generate new private key"
   - Confirme clicando em "Generate key"
   - Um arquivo JSON será baixado automaticamente

5. **Configure no GitHub**
   - Abra o arquivo JSON baixado
   - Copie TODO o conteúdo
   - No GitHub Secrets, crie novo secret:
     - Name: `FIREBASE_SERVICE_ACCOUNT`
     - Value: [Cole todo o JSON]

⚠️ **IMPORTANTE**: 
- Nunca faça commit deste arquivo JSON
- Mantenha-o seguro e não compartilhe
- Você pode deletar o arquivo após configurar o secret

## ✅ Verificar Configuração

### Ver Secrets Configurados

**Via Web:**
https://github.com/GranamyrBR/deploy_lt/settings/secrets/actions

**Via CLI:**
```bash
gh secret list
```

### Testar Workflows

1. Acesse: https://github.com/GranamyrBR/deploy_lt/actions

2. Selecione um workflow (ex: "Dependency Updates")

3. Clique em "Run workflow" > "Run workflow"

4. Verifique se executa sem erros de "secret not found"

### Verificar nos Logs

Quando um workflow usa secrets, eles aparecem mascarados:

```
Using SUPABASE_URL: ***
Using SUPABASE_ANON_KEY: ***
```

Se você ver valores reais expostos nos logs, há um problema de configuração!

## 🔒 Segurança dos Secrets

### O que o GitHub faz:

✅ **Criptografa** secrets em repouso
✅ **Mascara** valores nos logs (aparece como `***`)
✅ **Não expõe** em pull requests de forks
✅ **Limita acesso** apenas a workflows autorizados

### Boas Práticas:

- ❌ Nunca faça commit de secrets no código
- ❌ Nunca logue valores de secrets diretamente
- ❌ Nunca compartilhe secrets em issues/PRs
- ✅ Use secrets para todas as credenciais
- ✅ Rotacione secrets periodicamente
- ✅ Use secrets de ambiente quando possível
- ✅ Limite acesso ao repositório

## 🧪 Testando a Configuração

Após configurar os secrets, teste:

### Teste 1: Workflow Manual

```bash
# Via GitHub CLI
gh workflow run dependency-update.yml
```

Ou via interface web:
1. Actions > Dependency Updates
2. Run workflow > Run workflow

### Teste 2: Push de Teste

Faça um commit simples e verifique se os workflows executam:

```bash
git commit --allow-empty -m "test: verify GitHub Actions"
git push
```

### Teste 3: Verificar Logs

Nos logs do workflow, você deve ver:

```
✅ Environment variables loaded
✅ SUPABASE_URL: ***
✅ SUPABASE_ANON_KEY: ***
```

## 📊 Checklist de Configuração

Use este checklist para garantir que tudo está configurado:

### Secrets Obrigatórios
- [ ] `SUPABASE_URL` configurado
- [ ] `SUPABASE_ANON_KEY` configurado

### Secrets Opcionais (se usar Firebase)
- [ ] `FIREBASE_API_KEY` configurado
- [ ] `FIREBASE_PROJECT_ID` configurado
- [ ] `FIREBASE_SERVICE_ACCOUNT` configurado (para deploy)

### Secrets Opcionais (se usar WhatsApp)
- [ ] `WHATSAPP_API_TOKEN` configurado

### Validação
- [ ] Secrets visíveis em Settings > Secrets
- [ ] Workflow executado manualmente com sucesso
- [ ] Secrets aparecem mascarados nos logs
- [ ] Nenhum erro de "secret not found"

## ❓ Troubleshooting

### Erro: "secret not found"

**Causa**: Secret não foi configurado ou nome está errado

**Solução**: 
1. Verifique o nome exato do secret
2. Verifique se está em Repository Secrets (não Environment Secrets)
3. Reconfigure o secret

### Erro: "Invalid JSON" (Firebase Service Account)

**Causa**: JSON do service account está malformado

**Solução**:
1. Baixe novamente o service account do Firebase
2. Copie TODO o conteúdo do arquivo
3. Não edite manualmente o JSON

### Secret aparece exposto nos logs

**Causa**: Valor foi impresso diretamente (echo, console.log, etc)

**Solução**:
1. Remova qualquer log direto de secrets
2. Use variáveis de ambiente corretamente
3. GitHub só mascara valores exatos dos secrets

## 🆘 Suporte

Se encontrar problemas:

1. Verifique a [documentação oficial do GitHub](https://docs.github.com/actions/security-guides/encrypted-secrets)
2. Abra uma issue com label `help wanted`
3. Entre em contato com o time de desenvolvimento

---

**Última atualização**: 2026-01-07
**Versão**: 1.0
