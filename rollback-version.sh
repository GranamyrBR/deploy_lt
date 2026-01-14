#!/bin/bash

# ════════════════════════════════════════════════════════════
# 🔄 ROLLBACK PARA VERSÃO ANTERIOR
# ════════════════════════════════════════════════════════════
# 
# Uso:
#   ./rollback-version.sh [versao]
#
# Exemplos:
#   ./rollback-version.sh v1.0.0    (volta para v1.0.0)
#   ./rollback-version.sh           (lista versões disponíveis)
# ════════════════════════════════════════════════════════════

set -e

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

# Se não passar versão, lista as disponíveis
if [ -z "$1" ]; then
    print_info "═══════════════════════════════════════════"
    print_info "📋 Versões Disponíveis"
    print_info "═══════════════════════════════════════════"
    echo ""
    
    git tag -l --sort=-version:refname | while read tag; do
        COMMIT_DATE=$(git log -1 --format=%ai "$tag")
        COMMIT_MSG=$(git tag -l --format='%(contents:subject)' "$tag")
        echo "  🏷️  $tag"
        echo "      📅 $COMMIT_DATE"
        echo "      📝 $COMMIT_MSG"
        echo ""
    done
    
    echo ""
    print_info "Para fazer rollback:"
    echo "  ./rollback-version.sh <versão>"
    echo ""
    exit 0
fi

TARGET_VERSION="$1"

# Verificar se a tag existe
if ! git tag -l | grep -q "^$TARGET_VERSION$"; then
    print_error "Versão $TARGET_VERSION não encontrada!"
    echo ""
    echo "Versões disponíveis:"
    git tag -l --sort=-version:refname
    exit 1
fi

# Obter versão atual
CURRENT_VERSION=$(git describe --tags --abbrev=0 2>/dev/null || echo "unknown")

print_warning "═══════════════════════════════════════════"
print_warning "⚠️  ATENÇÃO: ROLLBACK"
print_warning "═══════════════════════════════════════════"
echo ""
echo "Versão atual: $CURRENT_VERSION"
echo "Versão alvo:  $TARGET_VERSION"
echo ""
read -p "Tem certeza que deseja fazer rollback? (y/n) " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_info "Rollback cancelado."
    exit 0
fi

echo ""
print_info "═══════════════════════════════════════════"
print_info "🔄 Iniciando Rollback"
print_info "═══════════════════════════════════════════"
echo ""

# 1. Checkout da tag
print_info "1️⃣ Fazendo checkout da versão $TARGET_VERSION..."
git checkout "$TARGET_VERSION"
print_success "Checkout concluído!"
echo ""

# 2. Criar branch temporária se necessário
CURRENT_BRANCH=$(git branch --show-current)
if [ -z "$CURRENT_BRANCH" ]; then
    print_info "2️⃣ Criando branch temporária rollback-$TARGET_VERSION..."
    git checkout -b "rollback-$TARGET_VERSION"
    print_success "Branch criada!"
else
    print_info "2️⃣ Branch atual: $CURRENT_BRANCH"
fi
echo ""

# 3. Instruções
print_info "═══════════════════════════════════════════"
print_success "✅ Rollback preparado!"
print_info "═══════════════════════════════════════════"
echo ""
echo "📊 Status:"
echo "  Versão atual:    $CURRENT_VERSION"
echo "  Versão checkout: $TARGET_VERSION"
echo ""
echo "🚀 Próximos passos:"
echo ""
echo "  OPÇÃO 1: Deploy direto desta versão"
echo "    1. Force push para deploy-prebuilt:"
echo "       git push origin HEAD:deploy-prebuilt --force"
echo "    2. Acesse Coolify e faça redeploy"
echo ""
echo "  OPÇÃO 2: Criar nova tag de rollback"
echo "    1. ./deploy-versioned.sh patch"
echo "    2. Adicione na descrição: 'Rollback para $TARGET_VERSION'"
echo ""
echo "  OPÇÃO 3: Cancelar rollback"
echo "    git checkout deploy-prebuilt"
echo ""

print_warning "⚠️  Não esqueça de fazer redeploy no Coolify após o push!"
echo ""
