# 🚀 GitHub Actions - Setup Completo

## 📋 Resumo da Configuração

Este documento resume toda a configuração de CI/CD implementada no projeto Lecotour Dashboard.

## ✅ O que foi Configurado

### 1. Workflows Automáticos

#### CI/CD Pipeline (`ci-cd.yml`)
- **Triggers**: Push e PR em `main` e `develop`
- **Jobs**:
  - ✅ Testes automáticos com cobertura
  - ✅ Build Web para produção
  - ✅ Deploy automático Firebase (quando habilitado)
  - ✅ Notificações de status

#### PR Checks (`pr-checks.yml`)
- **Triggers**: Abertura/atualização de PRs
- **Validações**:
  - ✅ Formatação de código
  - ✅ Análise estática rigorosa
  - ✅ Testes unitários
  - ✅ Conventional Commits

#### Dependency Updates (`dependency-update.yml`)
- **Trigger**: Schedule (segunda-feira 9h) + Manual
- **Funcionalidades**:
  - ✅ Verifica dependências desatualizadas
  - ✅ Gera relatórios automáticos

#### Code Quality (`code-quality.yml`)
- **Triggers**: Push e PR
- **Análises**:
  - ✅ Métricas de código
  - ✅ Scan de segurança
  - ✅ Busca por TODOs

### 2. Automações Adicionais

#### Dependabot (`dependabot.yml`)
- ✅ Atualização automática de Flutter/Dart (pub)
- ✅ Atualização automática de Firebase Functions (npm)
- ✅ Atualização automática de GitHub Actions
- ✅ PRs semanais às segundas-feiras
- ✅ Limit de 5 PRs simultâneos

### 3. Templates

#### Pull Request Template
- ✅ Checklist completo
- ✅ Descrição estruturada
- ✅ Tipos de mudança
- ✅ Critérios de aceitação

#### Issue Templates
- ✅ Bug Report (estruturado)
- ✅ Feature Request (padronizado)

### 4. Documentação

- ✅ `.github/workflows/README.md` - Guia dos workflows
- ✅ `.github/SECRETS_GUIDE.md` - Guia completo de secrets
- ✅ `.github/scripts/setup-secrets.sh` - Script de configuração

## 🔐 Configuração de Secrets

### Secrets Necessários

| Secret | Obrigatório | Descrição |
|--------|-------------|-----------|
| `SUPABASE_URL` | ✅ Sim | URL do projeto Supabase |
| `SUPABASE_ANON_KEY` | ✅ Sim | Chave anônima do Supabase |
| `FIREBASE_API_KEY` | ❌ Opcional | API Key do Firebase |
| `FIREBASE_PROJECT_ID` | ❌ Opcional | ID do projeto Firebase |
| `FIREBASE_SERVICE_ACCOUNT` | ❌ Deploy | Service account para deploy |
| `WHATSAPP_API_TOKEN` | ❌ Opcional | Token WhatsApp Business |

### Como Configurar

**Opção 1: Script Automático**
```bash
bash .github/scripts/setup-secrets.sh
```

**Opção 2: Interface Web**
1. Acesse: https://github.com/GranamyrBR/deploy_lt/settings/secrets/actions
2. New repository secret
3. Adicione cada secret

**Opção 3: GitHub CLI**
```bash
gh secret set SUPABASE_URL -b"https://seu-projeto.supabase.co"
gh secret set SUPABASE_ANON_KEY -b"sua_chave"
```

📚 **Guia Completo**: Ver `.github/SECRETS_GUIDE.md`

## 🎯 Próximos Passos

### 1. Configurar Secrets ✅ PRIORIDADE
```bash
# Via script
bash .github/scripts/setup-secrets.sh

# Ou via web
https://github.com/GranamyrBR/deploy_lt/settings/secrets/actions
```

### 2. Testar Workflows
```bash
# Executar workflow manualmente
gh workflow run dependency-update.yml

# Ou fazer push de teste
git commit --allow-empty -m "test: verify workflows"
git push
```

### 3. Configurar Proteções de Branch
1. Settings > Branches > Add rule
2. Branch name pattern: `main`
3. Configurar:
   - ☑️ Require pull request reviews (1 approver)
   - ☑️ Require status checks to pass before merging
   - ☑️ Require branches to be up to date
   - ☑️ Require conversation resolution

### 4. Habilitar Deploy Firebase (Opcional)
1. Obter service account do Firebase
2. Configurar secret `FIREBASE_SERVICE_ACCOUNT`
3. Workflows farão deploy automático em push para `main`

### 5. Adicionar Colaboradores
- Settings > Collaborators
- Convidar membros da equipe

## 📊 Monitoramento

### Visualizar Workflows
🔗 https://github.com/GranamyrBR/deploy_lt/actions

### Ver Secrets Configurados
🔗 https://github.com/GranamyrBR/deploy_lt/settings/secrets/actions

### Dependabot PRs
🔗 https://github.com/GranamyrBR/deploy_lt/network/updates

### Status Badges
Badges adicionados ao README.md:
- [![CI/CD Pipeline](badge)](link)
- [![PR Checks](badge)](link)
- [![Code Quality](badge)](link)

## 🐛 Troubleshooting

### Workflow Falha com "Secret not found"
**Solução**: Configurar o secret em Settings > Secrets

### Build Web Falha
**Solução**: 
1. Verificar se `SUPABASE_URL` e `SUPABASE_ANON_KEY` estão configurados
2. Testar localmente: `flutter build web --release`

### Deploy Firebase Falha
**Solução**:
1. Verificar se `FIREBASE_SERVICE_ACCOUNT` está configurado
2. Verificar permissões do service account
3. Verificar configuração do `firebase.json`

### Dependabot Não Cria PRs
**Solução**:
1. Verificar se Dependabot está habilitado: Settings > Code security
2. Verificar configuração em `.github/dependabot.yml`

## 📚 Recursos

- [GitHub Actions Docs](https://docs.github.com/actions)
- [Flutter CI/CD](https://docs.flutter.dev/deployment/cd)
- [Dependabot](https://docs.github.com/code-security/dependabot)
- [GitHub Secrets](https://docs.github.com/actions/security-guides/encrypted-secrets)

## ✅ Checklist Final

- [ ] Secrets configurados (mínimo: SUPABASE_URL e SUPABASE_ANON_KEY)
- [ ] Workflow executado com sucesso
- [ ] Proteções de branch configuradas
- [ ] Colaboradores adicionados (se necessário)
- [ ] Dependabot ativo
- [ ] Deploy Firebase configurado (opcional)
- [ ] Documentação revisada
- [ ] Time treinado nos processos

---

**Status**: ✅ Configuração completa e pronta para uso
**Próxima revisão**: Mensal
