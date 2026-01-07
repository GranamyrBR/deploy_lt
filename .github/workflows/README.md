# 🤖 GitHub Actions Workflows

Documentação dos workflows automatizados do Lecotour Dashboard.

## 📋 Workflows Disponíveis

### 1. CI/CD Pipeline (`ci-cd.yml`)

**Trigger:** Push ou PR nas branches `main` e `develop`

**Jobs:**
- ✅ **Test**: Análise estática, testes e cobertura
- 🏗️ **Build Web**: Build da aplicação web (apenas em push para main)
- 🚀 **Deploy Firebase**: Deploy automático para Firebase Hosting (main)
- 📢 **Notify**: Notificações do status do pipeline

**Artefatos gerados:**
- Cobertura de testes (codecov)
- Build web (7 dias de retenção)

### 2. PR Checks (`pr-checks.yml`)

**Trigger:** Abertura ou atualização de Pull Requests

**Validações:**
- Formatação de código
- Análise estática (com `--fatal-infos`)
- Execução de testes
- Validação de mensagem de commit (Conventional Commits)

### 3. Dependency Updates (`dependency-update.yml`)

**Trigger:** 
- Agendado: Toda segunda-feira às 9h
- Manual: `workflow_dispatch`

**Funcionalidades:**
- Verifica dependências desatualizadas
- Gera relatório JSON
- Adiciona resumo no GitHub

### 4. Code Quality (`code-quality.yml`)

**Trigger:** Push ou PR nas branches `main` e `develop`

**Análises:**
- Métricas de código (arquivos, linhas, testes)
- Busca por TODOs
- Análise estática detalhada
- Scan de segurança (secrets expostos)

**Artefatos gerados:**
- Relatório de análise

## 🔒 Secrets Necessários

Configure no GitHub: **Settings > Secrets and variables > Actions**

### Obrigatórios:
```
FIREBASE_SERVICE_ACCOUNT - Service account do Firebase para deploy
```

### Opcionais:
```
CODECOV_TOKEN - Token do Codecov para upload de cobertura
SLACK_WEBHOOK - Webhook para notificações no Slack
```

## 🚀 Como Usar

### Executar Workflow Manualmente

1. Vá para **Actions** no GitHub
2. Selecione o workflow desejado
3. Clique em **Run workflow**

### Habilitar/Desabilitar Workflows

Edite o arquivo do workflow e modifique a seção `on:` ou desabilite no GitHub Actions.

### Adicionar Novo Workflow

1. Crie arquivo em `.github/workflows/nome.yml`
2. Use a sintaxe do GitHub Actions
3. Faça commit e push

## 📊 Status Badges

Adicione ao README.md:

```markdown
![CI/CD](https://github.com/GranamyrBR/deploy_lt/workflows/CI%2FCD%20Pipeline/badge.svg)
![PR Checks](https://github.com/GranamyrBR/deploy_lt/workflows/PR%20Checks/badge.svg)
![Code Quality](https://github.com/GranamyrBR/deploy_lt/workflows/Code%20Quality/badge.svg)
```

## 🔧 Customização

### Alterar Schedule

Edite a seção `cron` no workflow:
```yaml
schedule:
  - cron: '0 9 * * 1'  # Min Hora Dia Mês DiaSemana
```

### Adicionar Notificações Slack

Adicione ao final do job:
```yaml
- name: 📢 Slack Notification
  uses: 8398a7/action-slack@v3
  with:
    status: ${{ job.status }}
    webhook_url: ${{ secrets.SLACK_WEBHOOK }}
  if: always()
```

### Modificar Flutter Version

Altere em todos os workflows:
```yaml
- name: 🎯 Setup Flutter
  uses: subosito/flutter-action@v2
  with:
    flutter-version: '3.16.0'  # Alterar aqui
    channel: 'stable'
```

## 📚 Recursos

- [GitHub Actions Documentation](https://docs.github.com/actions)
- [Flutter CI/CD](https://docs.flutter.dev/deployment/cd)
- [Firebase Hosting Deploy](https://github.com/FirebaseExtended/action-hosting-deploy)

## 🐛 Troubleshooting

### Workflow falha no teste
- Verifique os logs no GitHub Actions
- Execute localmente: `flutter test`
- Verifique se todas as dependências estão atualizadas

### Build web falha
- Verifique erros de compilação
- Execute localmente: `flutter build web --release`
- Verifique configuração do `web/index.html`

### Deploy Firebase falha
- Verifique se `FIREBASE_SERVICE_ACCOUNT` está configurado
- Verifique permissões do service account
- Teste deploy local: `firebase deploy --only hosting`

## 📝 Manutenção

- ✅ Revisar workflows mensalmente
- ✅ Atualizar versões de actions
- ✅ Monitorar tempo de execução
- ✅ Otimizar cache quando necessário
