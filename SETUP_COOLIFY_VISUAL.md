# 🎯 Setup Rápido - Coolify (Guia Visual)

## 📋 Pré-requisitos

- ✅ Coolify instalado: https://waha.axioscode.com/
- ✅ Repositório correto: `GranamyrBR/deploy_lt`
- ✅ VPS com Caddy configurado

---

## 🚀 Configuração em 5 Minutos

### 1️⃣ Remover Aplicação Antiga (Se existir)

```
Coolify Dashboard
  └─ Applications
      └─ [Aplicação antiga com lecodeploy]
          └─ Settings
              └─ Danger Zone
                  └─ Delete Application ❌
```

---

### 2️⃣ Criar Nova Aplicação

```
Coolify Dashboard
  └─ + New
      └─ Application
          └─ Git Repository
```

**Configurações:**

| Campo | Valor |
|-------|-------|
| **Source** | GitHub |
| **Repository** | `GranamyrBR/deploy_lt` ✅ |
| **Branch** | `main` |
| **Build Pack** | `Dockerfile` |
| **Dockerfile** | `./Dockerfile` |
| **Port** | `80` |
| **Auto Deploy** | ✅ **ENABLED** |

---

### 3️⃣ Configurar Domínio

```
Application Settings
  └─ Domains
      └─ + Add Domain
          └─ axioscode.com
              └─ HTTPS: ✅ Enabled
```

---

### 4️⃣ Variáveis de Ambiente

```
Application Settings
  └─ Environment Variables
      └─ + Add Variable
```

**Variáveis necessárias:**

```bash
SUPABASE_URL=https://sup.axioscode.com
SUPABASE_ANON_KEY=sua-chave-aqui
GOOGLE_MAPS_API_KEY=sua-chave-aqui
OPENAI_API_KEY=sua-chave-aqui
APP_ENV=production
```

---

### 5️⃣ Deploy!

```
Application
  └─ Deploy (botão verde)
      └─ Aguardar 3-5 minutos
          └─ ✅ Deployed!
```

---

## ✅ Verificação

### 1. App Funcionando
```
https://axioscode.com/
```

### 2. Cache Busting Ativo
Abra o console do navegador:
```javascript
window.appUpdate.version
// Resultado esperado: "3464ac8-1736279123"
```

### 3. Version File
```bash
curl https://axioscode.com/version.txt
# Resultado esperado: 3464ac8-1736279123
```

### 4. Headers Cache
```bash
curl -I https://axioscode.com/main.dart.js?v=123
# Esperado: Cache-Control: public, max-age=31536000, immutable
```

---

## 🔄 Deploy Automático

Com **Auto Deploy** habilitado:

```
Push para GitHub
    ↓
Coolify detecta automaticamente
    ↓
Build + Deploy automático
    ↓
App atualizado em ~3-5 min
```

**Não precisa de GitHub Actions ou webhooks manuais!**

---

## 🎉 Pronto!

Agora toda vez que fizer push para `main`:
- ✅ Deploy automático
- ✅ Build com cache busting
- ✅ Versão atualizada
- ✅ Usuários recebem update em 5 min

---

## 📞 Suporte

- [Documentação Completa](COOLIFY_SETUP.md)
- [Reconfiguração](COOLIFY_RECONFIGURE.md)
- [Cache Busting Strategy](docs/CACHE_BUSTING_STRATEGY.md)

---

**Tempo total:** ~5 minutos  
**Dificuldade:** ⭐⭐ (Fácil)  
**Status:** ✅ Pronto para usar
