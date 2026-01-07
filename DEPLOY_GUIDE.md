# 🚀 Guia Completo de Deploy - Lecotour Dashboard

## 📋 Índice

- [Visão Geral](#visão-geral)
- [Pré-requisitos](#pré-requisitos)
- [Deploy Local](#deploy-local)
- [Deploy com Docker](#deploy-com-docker)
- [Deploy no Coolify (VPS)](#deploy-no-coolify-vps)
- [Otimizações de Performance](#otimizações-de-performance)
- [Monitoramento](#monitoramento)
- [Troubleshooting](#troubleshooting)

---

## 🎯 Visão Geral

Este projeto utiliza uma arquitetura otimizada para Flutter Web com:

- **Build otimizado**: HTML renderer, tree-shaking, sem source maps
- **Nginx**: Servidor web de alta performance com caching agressivo
- **PWA**: Progressive Web App com service worker e offline-first
- **Docker Multi-stage**: Build leve e eficiente
- **Coolify**: Deploy automático via webhook

### 📊 Métricas de Performance

- **Bundle principal**: ~7.7MB (otimizado com tree-shaking)
- **Tempo de build**: ~2-3 minutos
- **First Load**: <3s (com cache)
- **PWA Score**: 90+ (Lighthouse)

---

## 🔧 Pré-requisitos

### Para Deploy Local

```bash
# Flutter SDK 3.1.0+
flutter --version

# Dependências instaladas
flutter pub get
```

### Para Deploy com Docker

```bash
# Docker 20.10+
docker --version

# Docker Compose (opcional)
docker-compose --version
```

### Para Deploy no Coolify

- VPS com Coolify instalado
- Domínio configurado (ex: axioscode.com)
- Acesso ao Coolify Dashboard
- Webhook configurado no GitHub

---

## 🏠 Deploy Local

### Método 1: Flutter Serve (Desenvolvimento)

```bash
# Modo desenvolvimento com hot reload
flutter run -d chrome

# Ou servir build de produção
flutter build web --release
cd build/web
python3 -m http.server 8000
```

Acesse: http://localhost:8000

### Método 2: Script Otimizado

```bash
# Usar script de build otimizado
./build-optimized.sh

# Servir com servidor local
cd build/web && python3 -m http.server 8000
```

---

## 🐳 Deploy com Docker

### Build da Imagem

```bash
# Build da imagem Docker
docker build -t lecotour-dashboard .

# Build com argumentos (opcional)
docker build \
  --build-arg SUPABASE_URL=https://your-project.supabase.co \
  --build-arg SUPABASE_ANON_KEY=your-key \
  -t lecotour-dashboard .
```

### Executar Container

```bash
# Executar em modo produção
docker run -d \
  --name lecotour \
  -p 8080:80 \
  -e SUPABASE_URL="https://your-project.supabase.co" \
  -e SUPABASE_ANON_KEY="your-key" \
  -e GOOGLE_MAPS_API_KEY="your-key" \
  -e OPENAI_API_KEY="your-key" \
  lecotour-dashboard

# Verificar logs
docker logs -f lecotour

# Verificar saúde
curl http://localhost:8080/health
```

Acesse: http://localhost:8080

### Docker Compose

```bash
# Criar arquivo .env com suas variáveis
cp .env.example .env

# Editar .env com suas credenciais
nano .env

# Iniciar com Docker Compose
docker-compose up -d

# Ver logs
docker-compose logs -f

# Parar
docker-compose down
```

---

## ☁️ Deploy no Coolify (VPS)

### Configuração Inicial no Coolify

1. **Acesse o Coolify Dashboard**
   - URL: https://axioscode.com/

2. **Criar Nova Aplicação**
   - Projects → New Application
   - Nome: `Lecotour Dashboard`
   - Tipo: `Docker`

3. **Configurar Repositório**
   - **Source**: GitHub
   - **Repository**: `https://github.com/GranamyrBR/deploy_lt`
   - **Branch**: `main`
   - **Build Pack**: `Dockerfile`
   - **Dockerfile Location**: `./Dockerfile`

4. **Configurar Domínio**
   - **Domain**: `axioscode.com`
   - **SSL**: Auto (Let's Encrypt)
   - **Force HTTPS**: ✅

5. **Variáveis de Ambiente**
   
   Adicionar na aba **Environment Variables**:
   
   ```
   SUPABASE_URL=https://your-project.supabase.co
   SUPABASE_ANON_KEY=your-anon-key-here
   GOOGLE_MAPS_API_KEY=your-google-maps-key
   OPENAI_API_KEY=your-openai-key
   ENVIRONMENT=production
   ENABLE_ANALYTICS=false
   ```

6. **Habilitar Auto Deploy**
   - Auto Deploy: ✅ Enabled
   - Deploy on Push: ✅ Enabled

7. **Copiar Webhook URL**
   - Vá em Settings → Deploy Webhook
   - Copie a URL (formato: `https://axioscode.com/api/v1/deploy?uuid=...`)

### Configurar GitHub Webhook

1. **Adicionar Secret no GitHub**
   - Vá em: https://github.com/GranamyrBR/deploy_lt/settings/secrets/actions
   - New repository secret
   - **Name**: `COOLIFY_WEBHOOK_URL`
   - **Value**: Cole a URL do webhook do Coolify

2. **Verificar Workflow**
   - O arquivo `.github/workflows/deploy-production.yml` já está configurado
   - Ele será disparado automaticamente em push para `main`

### Deploy Manual no Coolify

```bash
# Fazer commit e push
git add .
git commit -m "feat: atualização do dashboard"
git push origin main

# O GitHub Actions irá:
# 1. Executar testes (se configurado)
# 2. Chamar o webhook do Coolify
# 3. Coolify irá fazer pull e rebuild automaticamente
```

### Deploy Manual via Interface

1. Acesse o Coolify Dashboard
2. Vá na aplicação Lecotour Dashboard
3. Clique em **Deploy**
4. Aguarde o build (~2-5 minutos)

---

## ⚡ Otimizações de Performance

### 1. Build Otimizado

O Dockerfile já inclui otimizações:

```dockerfile
# HTML renderer (menor bundle, melhor compatibilidade)
--web-renderer html

# Tree-shaking de ícones (reduz ~99.4%)
--no-tree-shake-icons=false

# Sem source maps (reduz tamanho)
--no-source-maps

# PWA offline-first
--pwa-strategy offline-first
```

### 2. Nginx Caching

O `nginx.conf` configura cache agressivo:

- **Assets estáticos** (js, css, images): 1 ano
- **Service Worker**: 1 hora
- **index.html**: Sem cache (sempre atualizado)

### 3. Compressão Gzip

Reduz tamanho de transferência em ~70%:

```nginx
gzip on;
gzip_comp_level 6;
gzip_types text/plain text/css application/javascript ...
```

### 4. PWA e Service Worker

- **Offline first**: Funciona sem internet
- **Cache inteligente**: Assets em cache local
- **Instalável**: Pode ser instalado como app

### 5. Lazy Loading (Implementação Futura)

```dart
// Exemplo de lazy loading de rotas
import 'package:flutter/material.dart';

final routes = {
  '/': (context) => const DashboardScreen(),
  '/quotations': (context) => const LazyScreen(
    loader: () => import('./screens/quotations_screen.dart'),
  ),
};
```

---

## 📊 Monitoramento

### Health Check

```bash
# Verificar saúde da aplicação
curl https://axioscode.com/health

# Resposta esperada: "healthy"
```

### Logs do Container

```bash
# Via Docker
docker logs lecotour-dashboard -f

# Via Coolify
# Acesse Dashboard → Logs tab
```

### Métricas de Performance

```bash
# Lighthouse CLI
npm install -g lighthouse
lighthouse https://axioscode.com --view

# Ou via Chrome DevTools
# F12 → Lighthouse → Generate report
```

### Monitoramento de Uptime

Recomendações de ferramentas:

- **UptimeRobot** (gratuito): https://uptimerobot.com
- **Pingdom**: https://pingdom.com
- **StatusCake**: https://statuscake.com

---

## 🐛 Troubleshooting

### Build Falha no Docker

**Problema**: `flutter: command not found`

```bash
# Verificar se a imagem base está correta
docker pull ghcr.io/cirruslabs/flutter:stable
```

**Problema**: Dependências não instaladas

```bash
# Limpar cache e rebuildar
docker system prune -a
docker build --no-cache -t lecotour-dashboard .
```

### Nginx Não Inicia

**Problema**: Porta 80 já em uso

```bash
# Verificar portas em uso
netstat -tulpn | grep :80

# Mudar porta no docker run
docker run -p 8081:80 lecotour-dashboard
```

**Problema**: Erro de configuração do nginx

```bash
# Verificar sintaxe do nginx.conf
docker run --rm -v $(pwd)/nginx.conf:/etc/nginx/nginx.conf:ro nginx nginx -t
```

### Variáveis de Ambiente Não Carregam

**Problema**: env-config.js não é gerado

```bash
# Verificar se docker-entrypoint.sh tem permissão de execução
chmod +x docker-entrypoint.sh

# Verificar logs do container
docker logs lecotour-dashboard
```

### Coolify Deploy Falha

**Problema**: Webhook retorna 404

- Verificar UUID na URL do webhook
- Confirmar que aplicação existe no Coolify
- Verificar se Auto Deploy está habilitado

**Problema**: Build timeout

- Aumentar timeout no Coolify (Settings)
- Verificar se VPS tem recursos suficientes (RAM, CPU)
- Limpar cache do Docker no VPS

### Performance Lenta

**Problema**: Bundle muito grande

```bash
# Analisar bundle size
./build-optimized.sh

# Ver arquivos grandes
find build/web -size +1M -exec ls -lh {} \;
```

**Problema**: Carregamento lento inicial

- Habilitar preload de recursos críticos
- Otimizar imagens (usar WebP)
- Implementar lazy loading
- Adicionar CDN (Cloudflare)

---

## 📚 Recursos Adicionais

### Documentação Oficial

- **Flutter Web**: https://flutter.dev/web
- **Nginx**: https://nginx.org/en/docs/
- **Docker Multi-stage**: https://docs.docker.com/build/building/multi-stage/
- **Coolify**: https://coolify.io/docs

### Vídeos Recomendados

- [Awesome Flutter Web Hosting (Coolify)](https://www.youtube.com/watch?v=yBQ5Kc_7a0k)
- [Flutter Web Performance Playlist](https://www.youtube.com/watch?v=8qHf_RkK28U)

### Ferramentas Úteis

- **Lighthouse**: Auditoria de performance
- **WebPageTest**: Análise detalhada de loading
- **BundlePhobia**: Análise de dependências
- **Can I Use**: Compatibilidade de browsers

---

## ✅ Checklist de Deploy

### Pré-Deploy

- [ ] Código commitado e sem erros de lint
- [ ] Testes passando
- [ ] Variáveis de ambiente configuradas
- [ ] Build local testado
- [ ] Docker build testado localmente

### Deploy

- [ ] Push para branch `main`
- [ ] GitHub Actions executou com sucesso
- [ ] Coolify recebeu webhook
- [ ] Build completou no Coolify
- [ ] Health check retorna "healthy"
- [ ] Aplicação acessível no domínio

### Pós-Deploy

- [ ] Verificar logs por erros
- [ ] Testar funcionalidades principais
- [ ] Verificar performance (Lighthouse)
- [ ] Confirmar PWA instalável
- [ ] Testar em diferentes browsers
- [ ] Configurar monitoramento de uptime

---

## 🔐 Segurança

### Headers de Segurança

O nginx.conf já inclui:

```nginx
X-Frame-Options: SAMEORIGIN
X-Content-Type-Options: nosniff
X-XSS-Protection: 1; mode=block
Referrer-Policy: no-referrer-when-downgrade
```

### HTTPS

- Coolify configura automaticamente Let's Encrypt
- Certificado renovado automaticamente
- Force HTTPS habilitado

### Secrets

- **Nunca** commitar `.env` no Git
- Usar secrets do GitHub para CI/CD
- Usar variáveis de ambiente no Coolify
- Rotacionar chaves regularmente

---

## 📞 Suporte

Para problemas ou dúvidas:

1. Verificar este guia
2. Consultar logs do container
3. Verificar issues no GitHub
4. Contatar equipe de DevOps

---

**Última atualização**: 2026-01-07  
**Versão**: 1.0.0  
**Autor**: DevOps Team
