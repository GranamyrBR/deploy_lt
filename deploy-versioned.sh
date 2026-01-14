#!/bin/bash

# ════════════════════════════════════════════════════════════
# 🚀 DEPLOY VERSIONADO COM ROLLBACK
# ════════════════════════════════════════════════════════════
# 
# Uso:
#   ./deploy-versioned.sh [tipo_versao]
#
# Tipos de versão:
#   patch  → v1.0.0 → v1.0.1 (pequenas correções)
#   minor  → v1.0.1 → v1.1.0 (novas features)
#   major  → v1.1.0 → v2.0.0 (mudanças grandes)
#
# Exemplo:
#   ./deploy-versioned.sh minor
# ════════════════════════════════════════════════════════════

set -e

# Cor para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para imprimir com cores
print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Verificar se está na branch correta
CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" != "deploy-prebuilt" ]; then
    print_warning "Você está na branch: $CURRENT_BRANCH"
    read -p "Continuar mesmo assim? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Verificar se há mudanças não commitadas
if [[ -n $(git status -s) ]]; then
    print_error "Há mudanças não commitadas!"
    git status -s
    exit 1
fi

# Obter última tag
LAST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "v0.0.0")
print_info "Última versão: $LAST_TAG"

# Parse da versão atual
IFS='.' read -r -a VERSION_PARTS <<< "${LAST_TAG#v}"
MAJOR="${VERSION_PARTS[0]}"
MINOR="${VERSION_PARTS[1]}"
PATCH="${VERSION_PARTS[2]}"

# Determinar nova versão
VERSION_TYPE="${1:-patch}"

case "$VERSION_TYPE" in
    major)
        MAJOR=$((MAJOR + 1))
        MINOR=0
        PATCH=0
        ;;
    minor)
        MINOR=$((MINOR + 1))
        PATCH=0
        ;;
    patch)
        PATCH=$((PATCH + 1))
        ;;
    *)
        print_error "Tipo de versão inválido: $VERSION_TYPE"
        echo "Use: patch, minor ou major"
        exit 1
        ;;
esac

NEW_VERSION="v${MAJOR}.${MINOR}.${PATCH}"

print_info "Nova versão será: $NEW_VERSION"
echo ""
read -p "Descrição das mudanças: " DESCRIPTION

if [ -z "$DESCRIPTION" ]; then
    DESCRIPTION="Atualização versão $NEW_VERSION"
fi

echo ""
print_info "═══════════════════════════════════════════"
print_info "📦 Iniciando Build e Deploy Versionado"
print_info "═══════════════════════════════════════════"
echo ""

# 1. Build do Flutter
print_info "1️⃣ Construindo Flutter Web..."
flutter build web --release --no-tree-shake-icons

if [ $? -ne 0 ]; then
    print_error "Build falhou!"
    exit 1
fi
print_success "Build completo!"
echo ""

# 2. Commitar build
print_info "2️⃣ Commitando build..."
git add -f build/web
git commit -m "build: $NEW_VERSION - $DESCRIPTION"
print_success "Build commitado!"
echo ""

# 3. Criar tag
print_info "3️⃣ Criando tag $NEW_VERSION..."
git tag -a "$NEW_VERSION" -m "$NEW_VERSION - $DESCRIPTION

📋 Mudanças:
$DESCRIPTION

📦 Build Info:
- Data: $(date '+%Y-%m-%d %H:%M:%S')
- Branch: $CURRENT_BRANCH
- Commit: $(git rev-parse --short HEAD)

🔄 Para fazer rollback:
git checkout $NEW_VERSION
"
print_success "Tag criada!"
echo ""

# 4. Push
print_info "4️⃣ Enviando para GitHub..."
git push origin "$CURRENT_BRANCH"
git push origin "$NEW_VERSION"
print_success "Enviado para GitHub!"
echo ""

# 5. Resumo
print_info "═══════════════════════════════════════════"
print_success "🎉 Deploy versionado concluído!"
print_info "═══════════════════════════════════════════"
echo ""
echo "📊 Resumo:"
echo "  Versão anterior: $LAST_TAG"
echo "  Versão nova:     $NEW_VERSION"
echo "  Tipo:            $VERSION_TYPE"
echo "  Descrição:       $DESCRIPTION"
echo ""
echo "🔗 Links:"
echo "  Tag no GitHub: https://github.com/GranamyrBR/deploy_lt/releases/tag/$NEW_VERSION"
echo ""
echo "🚀 Próximos passos:"
echo "  1. Acesse Coolify: https://axioscode.com/"
echo "  2. Faça deploy manual (ou aguarde auto-deploy)"
echo "  3. Teste a nova versão"
echo ""
echo "🔄 Para fazer rollback:"
echo "  git checkout $LAST_TAG"
echo "  git push origin deploy-prebuilt --force"
echo "  (E redeploy no Coolify)"
echo ""
print_success "Pronto! 🎉"
