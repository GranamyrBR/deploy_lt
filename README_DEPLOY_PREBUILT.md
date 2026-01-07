# 🚀 Deploy com Build Local (Pre-Built)

Esta branch usa **build local** para acelerar drasticamente o deploy.

## 📋 Como Funciona

### ❌ Método Antigo (Lento):
- Coolify baixa código
- Docker build executa flutter pub get (~30s)
- Docker build executa build_runner (~112s)
- Docker build executa flutter build web (~2-3min)
- **Total: 5-7 minutos**

### ✅ Método Novo (Rápido):
- Build **local** na sua máquina (~2min)
- Commit dos arquivos estáticos (build/web)
- Docker apenas **copia** arquivos
- **Total no servidor: 10-20 segundos** 🚀

## 🛠️ Como Usar

### 1. Build Local
```bash
# Execute o script
./build-and-deploy.sh

# Ou manualmente:
flutter build web --release
```

### 2. Commit e Push
```bash
git add build/web
git commit -m "build: update pre-built web files"
git push origin deploy/pre-built-web
```

### 3. Configurar Coolify
No Coolify, configure:
- **Branch:** `deploy/pre-built-web`
- **Dockerfile:** `Dockerfile.prebuilt`
- **Build Context:** `.`

## 📊 Vantagens

✅ **Deploy 30x mais rápido** (10s vs 5min)  
✅ **Menos recursos no servidor** (só copia arquivos)  
✅ **Build local mais rápido** (sem overhead do Docker)  
✅ **Controle total** sobre o que vai para produção  
✅ **Testes locais** antes de fazer deploy  

## 📂 Estrutura

```
deploy/pre-built-web/
├── Dockerfile.prebuilt       # Dockerfile simples (só COPY)
├── .dockerignore.prebuilt    # Ignora tudo exceto build/web
├── build-and-deploy.sh       # Script automatizado
├── build/web/                # Arquivos buildados (commitados)
└── README_DEPLOY_PREBUILT.md # Este arquivo
```

## ⚠️ Importante

- Esta branch **commita** `build/web/` (diferente da main)
- Sempre rode `build-and-deploy.sh` antes de fazer push
- Não misture código-fonte da main com esta branch
- Use esta branch **apenas para deploy**

## 🔄 Workflow Recomendado

```bash
# 1. Desenvolva na branch main
git checkout main
# ... faça suas alterações ...

# 2. Quando pronto para deploy
git checkout deploy/pre-built-web
git merge main  # Traz alterações da main

# 3. Build local
./build-and-deploy.sh

# 4. Commit e deploy
git add build/web
git commit -m "build: update from main $(date +%Y-%m-%d)"
git push origin deploy/pre-built-web

# 5. Coolify detecta e deploya em ~10 segundos!
```

## 🎯 Resultado Esperado

Deploy completo no Coolify em **10-20 segundos** ao invés de **5-7 minutos**!
