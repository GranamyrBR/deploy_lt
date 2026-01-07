# 📝 Notas de Implementação - Cache Busting Strategy

## ✅ O que foi implementado

### 1. **Cache Busting Automático**
- ✅ Script `cache-bust-build.sh` para builds locais
- ✅ Integração no `Dockerfile` para builds automatizados
- ✅ Versionamento baseado em `git-hash-timestamp`
- ✅ Meta tag com versão no `index.html`
- ✅ Arquivo `version.txt` para verificação de updates

### 2. **Auto-Update Detection**
- ✅ Script `web/cache-bust-loader.js` 
- ✅ Verificação a cada 5 minutos
- ✅ Verificação quando aba fica visível
- ✅ Prompt para usuário atualizar ou agendar
- ✅ Limpeza completa de cache (service worker + browser cache)

### 3. **Headers HTTP Otimizados**
- ✅ Caddy configurado com estratégia de cache inteligente:
  - Assets versionados (?v=): cache 1 ano
  - Imagens/fontes: cache 30 dias
  - Service worker: sem cache
  - version.txt: sem cache
  - HTML: sem cache

### 4. **Deferred Loading**
- ✅ Arquivo `lib/config/deferred_imports.dart` criado
- ✅ Integrado no `main.dart` (Web only)
- ✅ Preload em background após 3 segundos
- ⚠️ Necessário refatorar imports nas telas (próximo passo)

### 5. **Documentação**
- ✅ `docs/CACHE_BUSTING_STRATEGY.md` completo
- ✅ Este arquivo de notas de implementação

---

## 🔧 Como usar

### Build Local:
```bash
# Opção 1: Script otimizado com cache busting
./cache-bust-build.sh

# Opção 2: Build normal do Flutter
flutter build web --release
```

### Build Docker:
```bash
# O cache busting é aplicado automaticamente
docker build -t lecotour .
```

### Deploy:
```bash
# Push para main dispara deploy automático
git add .
git commit -m "feat: implement cache busting strategy"
git push origin main
```

---

## ⚠️ Próximos Passos

### 1. **Testar Build Local**
```bash
./cache-bust-build.sh
cd build/web
python3 -m http.server 8000
# Abrir http://localhost:8000
# Verificar no console: window.appUpdate.version
```

### 2. **Testar Build Docker**
```bash
docker build -t lecotour-test .
docker run -p 8080:80 lecotour-test
# Abrir http://localhost:8080
```

### 3. **Refatorar Imports para Deferred Loading**

Atualmente as bibliotecas pesadas são importadas diretamente:
```dart
// ❌ Import direto (carrega tudo no início)
import 'package:syncfusion_flutter_charts/charts.dart';
```

Precisa ser refatorado para:
```dart
// ✅ Import diferido (carrega sob demanda)
import 'package:syncfusion_flutter_charts/charts.dart' deferred as charts;

// Antes de usar:
await loadCharts();
```

**Arquivos que precisam de refatoração:**
- [ ] `lib/widgets/cost_center_syncfusion_dashboard.dart`
- [ ] `lib/widgets/cost_center_comprehensive_charts.dart`
- [ ] `lib/widgets/activities_chart.dart`
- [ ] `lib/widgets/sales_chart.dart`
- [ ] `lib/widgets/weekly_distribution_chart.dart`
- [ ] `lib/widgets/google_maps_widget.dart`
- [ ] `lib/services/pdf_generator_simple.dart`
- [ ] Outros que usam Syncfusion/Maps/PDF

### 4. **Adicionar Loading States**

Quando usar deferred loading, adicionar feedback visual:
```dart
bool _chartsLoaded = false;

@override
void initState() {
  super.initState();
  _loadCharts();
}

Future<void> _loadCharts() async {
  await loadCharts();
  setState(() => _chartsLoaded = true);
}

@override
Widget build(BuildContext context) {
  if (!_chartsLoaded) {
    return Center(child: CircularProgressIndicator());
  }
  
  // Usar charts.SfCartesianChart...
}
```

### 5. **Configurar Variáveis de Ambiente no Coolify**

No Coolify, adicionar as variáveis:
```
APP_ENV=production
SUPABASE_URL=https://sup.axioscode.com
SUPABASE_ANON_KEY=sua-chave
GOOGLE_MAPS_API_KEY=sua-chave
OPENAI_API_KEY=sua-chave
```

### 6. **Testar Auto-Update em Produção**

1. Deploy versão 1
2. Abrir app em navegador
3. Verificar versão no console: `window.appUpdate.version`
4. Deploy versão 2
5. Aguardar 5 minutos
6. Verificar se prompt de atualização aparece

---

## 📊 Métricas Esperadas

### Bundle Size:
```
Antes: ~5-8 MB (tudo carregado)
Depois: ~2-3 MB (inicial) + ~3-5 MB (deferred, carregado em background)
```

### Tempo de Carga:
```
Antes: 3-5 segundos (first paint)
Depois: 1-2 segundos (first paint)
```

### Update Time:
```
Antes: Horas/dias (usuários presos no cache)
Depois: 5-10 minutos (auto-update)
```

---

## 🐛 Troubleshooting

### Build falha no sed (macOS):
```bash
# Erro: sed: invalid command code
# Solução: instalar GNU sed
brew install gnu-sed
# Adicionar ao PATH ou usar gsed
```

### Version não aparece no index.html:
```bash
# Verificar se o placeholder existe
grep "{{APP_VERSION}}" web/index.html

# Se não existir, adicionar manualmente:
<meta name="app-version" content="{{APP_VERSION}}">
```

### Auto-update não funciona:
```bash
# 1. Verificar se version.txt existe
curl https://axioscode.com/version.txt

# 2. Verificar cache headers
curl -I https://axioscode.com/version.txt
# Deve retornar: Cache-Control: no-store

# 3. Verificar console do navegador
# Deve aparecer: "✅ Cache busting loader inicializado"
```

### Deferred loading não carrega:
```dart
// Verificar no console se há erros
// Verificar se a biblioteca está sendo usada antes de carregar
await loadCharts(); // Carregar ANTES de usar

// Se falhar, importar normalmente (fallback)
```

---

## 📚 Recursos Adicionais

- [Documentação completa](docs/CACHE_BUSTING_STRATEGY.md)
- [Artigo original - Lukas Nevosad](https://lukasnevosad.medium.com/our-flutter-web-strategy-for-deferred-loading-instant-updates-happy-users-45ed90a7727c)
- [Flutter Deferred Loading](https://docs.flutter.dev/perf/deferred-components)

---

**Status:** ✅ Implementado, aguardando testes
**Próximo:** Testar build e refatorar imports
**Autor:** @GranamyrBR
**Data:** 2026-01-07
