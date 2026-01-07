# 🧹 Instruções de Limpeza do Projeto Lecotour Dashboard

## 📋 Resumo

Este documento contém as instruções para executar a limpeza profissional do projeto e inicializar um novo repositório Git.

## 🚀 Execução Rápida (Recomendado)

Execute o script principal que faz tudo automaticamente:

```bash
bash tmp_rovodev_EXECUTE_ME.sh
```

Este script irá:
1. ✅ Remover todos os arquivos desnecessários
2. ✅ Organizar a documentação
3. ✅ Inicializar novo repositório Git
4. ✅ Criar o commit inicial
5. ✅ Limpar scripts temporários

## 📝 Execução Manual (Passo a Passo)

Se preferir executar manualmente:

### Passo 1: Limpeza
```bash
bash tmp_rovodev_cleanup.sh
```

### Passo 2: Revisar mudanças
```bash
# Verificar o que foi removido/alterado
ls -la
du -sh *
```

### Passo 3: Inicializar Git
```bash
bash tmp_rovodev_init_git.sh
```

### Passo 4: Configurar ambiente
```bash
cp .env.example .env
# Edite o arquivo .env com suas credenciais
```

### Passo 5: Testar o projeto
```bash
flutter pub get
flutter analyze
flutter test
flutter run -d chrome
```

## 📦 O Que Será Removido

### ❌ Projetos não relacionados
- `My-Day/` (55MB) - projeto separado

### ❌ Arquivos temporários e de teste
- `check_*.dart` - scripts de verificação
- `test_*.dart` na raiz - testes temporários
- `tmp_rovodev_*.sh` - scripts de limpeza (após execução)

### ❌ Documentos de negócio
- `*.pdf` - cotações e documentos
- `*.xlsx` - planilhas
- Screenshots na raiz

### ❌ Metadata do macOS
- Todos os arquivos `._*`

### ❌ Node modules
- `functions/node_modules/` (167MB) - será recriado pelo npm

### ❌ Prompts de IA
- `consultant_agent_prompt*.md`
- `dart_flutter_postgres_consultant*.md`

## ✅ O Que Será Mantido/Criado

### ✨ Novos arquivos profissionais
- `README.md` - Documentação completa e profissional
- `.gitignore` - Configuração abrangente
- `CONTRIBUTING.md` - Guia de contribuição
- `.env.example` - Template de variáveis de ambiente
- `CHANGELOG.md` - Histórico de versões

### 📂 Estrutura essencial
```
lecotour_dashboard/
├── lib/              ✅ Código fonte Flutter
├── android/          ✅ Build Android
├── ios/              ✅ Build iOS
├── web/              ✅ Build Web
├── supabase/         ✅ Migrations e functions
├── functions/        ✅ Firebase functions
├── assets/           ✅ Recursos (imagens, traduções)
├── fonts/            ✅ Fontes customizadas
├── test/             ✅ Testes unitários
├── integration_test/ ✅ Testes de integração
└── docs/             ✅ Documentação técnica
```

## 📊 Economia de Espaço

Estimativa de redução:
- **My-Day/**: ~55MB
- **functions/node_modules/**: ~167MB
- **Arquivos temporários**: ~10MB
- **Total**: ~232MB removidos

## 🔍 Verificações Pós-Limpeza

### 1. Verificar estrutura
```bash
tree -L 2 -I 'node_modules|.git'
```

### 2. Verificar Git
```bash
git status
git log --oneline -5
```

### 3. Verificar dependências
```bash
flutter pub get
cd functions && npm install && cd ..
```

### 4. Executar análise
```bash
flutter analyze
```

### 5. Executar testes
```bash
flutter test
```

### 6. Build web
```bash
flutter build web --release
```

## 🌐 Configurar Repositório Remoto

Após a limpeza e inicialização do Git:

### GitHub
```bash
# Criar repositório no GitHub primeiro, depois:
git remote add origin https://github.com/seu-usuario/lecotour_dashboard.git
git branch -M main
git push -u origin main
```

### GitLab
```bash
git remote add origin https://gitlab.com/seu-usuario/lecotour_dashboard.git
git branch -M main
git push -u origin main
```

### Bitbucket
```bash
git remote add origin https://bitbucket.org/seu-usuario/lecotour_dashboard.git
git branch -M main
git push -u origin main
```

## 🔐 Configurar Variáveis de Ambiente

1. Copie o template:
```bash
cp .env.example .env
```

2. Edite `.env` com suas credenciais:
```env
SUPABASE_URL=https://seu-projeto.supabase.co
SUPABASE_ANON_KEY=sua_chave_anonima
```

3. **IMPORTANTE**: Nunca commit o arquivo `.env` (já está no .gitignore)

## 📚 Documentação Disponível

Após a limpeza, consulte:

- `README.md` - Visão geral e setup
- `CONTRIBUTING.md` - Como contribuir
- `CHANGELOG.md` - Histórico de versões
- `docs/database/` - Schema e ERD do banco
- `docs/guides/` - Guias técnicos específicos

## ⚠️ Avisos Importantes

1. **Backup**: Se tiver dúvidas, faça backup antes de executar
2. **Ambiente**: Os scripts foram testados em Linux/macOS
3. **Permissões**: Pode ser necessário `chmod +x` nos scripts
4. **Git**: A pasta `.git` antiga será removida
5. **Node modules**: Será necessário `npm install` novamente

## 🆘 Troubleshooting

### Script não executa
```bash
chmod +x tmp_rovodev_*.sh
```

### Git já inicializado
O script perguntará se deseja reinicializar

### Dependências não encontradas
```bash
flutter clean
flutter pub get
cd functions && npm install && cd ..
```

### Erro de permissão
```bash
sudo bash tmp_rovodev_EXECUTE_ME.sh
```

## ✅ Checklist Final

Após executar a limpeza:

- [ ] Projeto limpo e organizado
- [ ] README.md profissional criado
- [ ] .gitignore configurado
- [ ] Git inicializado com commit inicial
- [ ] .env configurado com credenciais
- [ ] Dependências instaladas (`flutter pub get`)
- [ ] Testes passando (`flutter test`)
- [ ] Análise sem erros (`flutter analyze`)
- [ ] App executando (`flutter run -d chrome`)
- [ ] Repositório remoto configurado
- [ ] Push inicial realizado

## 🎉 Conclusão

Após seguir estas instruções, você terá:
- ✅ Projeto limpo e profissional
- ✅ Estrutura organizada
- ✅ Documentação completa
- ✅ Repositório Git configurado
- ✅ Pronto para desenvolvimento em equipe

---

**Boa sorte com o projeto Lecotour Dashboard!** 🗽
