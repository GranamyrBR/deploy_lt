# 🚀 Estratégia de Cache Busting e Deferred Loading

Baseado no artigo de [Lukas Nevosad](https://lukasnevosad.medium.com/our-flutter-web-strategy-for-deferred-loading-instant-updates-happy-users-45ed90a7727c)

---

## 📋 Problema Original

Flutter Web possui desafios com cache:
- **Service Worker agressivo**: Usuários ficam presos em versões antigas
- **Bundle grande**: Todo o código é carregado de uma vez
- **Updates lentos**: Demora para usuários receberem novas versões

---

## ✅ Nossa Solução

### 1️⃣ **Cache Busting Automático**

Cada build gera uma versão única baseada em:
```
git-hash-timestamp
Exemplo: a1b2c3d-1704654321
```

**Como funciona:**
- Durante o build, todos os assets recebem `?v=VERSION`
- `index.html` tem meta tag com versão atual
- `version.txt` é criado com a versão (sem cache)

**Arquivos afetados:**
```
main.dart.js?v=a1b2c3d-1704654321
flutter_service_worker.js?v=a1b2c3d-1704654321
```

### 2️⃣ **Headers HTTP Otimizados (Caddy)**

```
✅ Assets versionados (?v=):     Cache 1 ano (immutable)
✅ Imagens/Fontes:                Cache 30 dias
✅ Service Worker:                No cache (must-revalidate)
✅ version.txt:                   No cache (sempre fresh)
✅ HTML/JS loader:                No cache (sempre fresh)
```

### 3️⃣ **Auto-Update Detection**

O arquivo `cache-bust-loader.js` verifica atualizações:

- **A cada 5 minutos** em background
- **Quando a aba fica visível** novamente
- **Na primeira carga** (após 5s)

**Quando detecta nova versão:**
1. Pergunta ao usuário se quer atualizar
2. Se recusar: agenda update para próximo reload
3. Se aceitar: limpa cache e recarrega

**Limpeza completa:**
```javascript
1. Desregistra service workers
2. Limpa todos os caches
3. Reload com bypass de cache
```

### 4️⃣ **Deferred Loading**

Bibliotecas pesadas são carregadas sob demanda:

**Bibliotecas deferidas:**
- 📊 Syncfusion Charts
- 📅 Calendar
- 🗺️ Google Maps
- 📄 PDF Generator
- 📊 DataGrid

**Estratégia:**
1. App carrega rápido (bundle inicial menor)
2. Após 3 segundos, carrega bibliotecas em background
3. Usuário não percebe delay
4. Próximas telas carregam instantaneamente

**Uso:**
```dart
import 'package:lecotour_dashboard/config/deferred_imports.dart';

// No main.dart após login/splash
await initDeferredLoading();

// Ou carregar sob demanda
await loadCharts();  // Antes de abrir tela de gráficos
```

---

## 🛠️ Como Funciona o Build

### Build Local:
```bash
# Usar o script otimizado
./cache-bust-build.sh

# Resultado:
# - build/web/version.txt com versão
# - Assets versionados
# - index.html atualizado
```

### Build Docker (Coolify):
```bash
# O Dockerfile já aplica cache busting automaticamente
docker build -t lecotour .

# Durante o build:
# 1. Flutter build web
# 2. Gera versão: git-hash-timestamp
# 3. Injeta versão em index.html
# 4. Cria version.txt
# 5. Atualiza service worker
```

---

## 📊 Resultados Esperados

### Antes:
- ❌ Usuários presos em versões antigas
- ❌ Cache agressivo do service worker
- ❌ Bundle inicial grande (~5MB+)
- ❌ Deploy = esperar horas para usuários atualizarem

### Depois:
- ✅ Usuários recebem updates automaticamente
- ✅ Cache inteligente (longo para assets, zero para HTML)
- ✅ Bundle inicial menor (~2-3MB)
- ✅ Deploy = usuários atualizados em 5 minutos

---

## 🐛 Debug

### Ver versão atual no console:
```javascript
window.appUpdate.version
// Retorna: "a1b2c3d-1704654321"
```

### Forçar verificação de update:
```javascript
window.appUpdate.check()
```

### Forçar update imediato:
```javascript
window.appUpdate.force()
```

### Ver logs:
```javascript
// Console do navegador mostra:
// ✅ Cache busting loader inicializado
// 📌 Versão atual: a1b2c3d-1704654321
// 🔄 Nova versão disponível: b2c3d4e-1704654999
```

---

## 📝 Checklist de Implementação

- [x] Script de build com cache busting (`cache-bust-build.sh`)
- [x] Loader JavaScript para auto-update (`cache-bust-loader.js`)
- [x] Atualizar `index.html` com meta version
- [x] Atualizar `Caddyfile` com headers otimizados
- [x] Atualizar `Dockerfile` para aplicar versioning
- [x] Configurar deferred imports (`deferred_imports.dart`)
- [ ] Testar build local
- [ ] Testar build Docker
- [ ] Deploy em staging
- [ ] Verificar auto-update funcionando
- [ ] Deploy em produção

---

## 🔗 Referências

- [Artigo Original - Lukas Nevosad](https://lukasnevosad.medium.com/our-flutter-web-strategy-for-deferred-loading-instant-updates-happy-users-45ed90a7727c)
- [Flutter Web Deferred Loading](https://docs.flutter.dev/perf/deferred-components)
- [Cache Control Headers](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Cache-Control)
- [Service Worker API](https://developer.mozilla.org/en-US/docs/Web/API/Service_Worker_API)

---

**Última atualização:** 2026-01-07
**Autor:** @GranamyrBR
**Status:** ✅ Implementado, aguardando testes
