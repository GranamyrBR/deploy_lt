#!/bin/bash
# ============================================
# Optimized Flutter Web Build Script
# Based on best practices from Flutter performance guides
# ============================================

set -e

echo "🚀 Starting optimized Flutter Web build..."
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Clean previous builds
echo -e "${BLUE}🧹 Cleaning previous builds...${NC}"
flutter clean
rm -rf build/web

# Get dependencies
echo -e "${BLUE}📦 Getting dependencies...${NC}"
flutter pub get

# Run code generation if needed
echo -e "${BLUE}⚙️  Running code generation...${NC}"
flutter pub run build_runner build --delete-conflicting-outputs || echo "⚠️  No code generation needed"

# Build with optimizations
echo -e "${BLUE}🔨 Building Flutter Web with optimizations...${NC}"
echo ""

flutter build web \
  --release \
  --web-renderer html \
  --dart-define=FLUTTER_WEB_USE_SKIA=false \
  --dart-define=FLUTTER_WEB_CANVASKIT_URL=https://unpkg.com/canvaskit-wasm@0.38.0/bin/ \
  --no-source-maps \
  --pwa-strategy offline-first \
  --base-href="/" \
  --no-tree-shake-icons=false

echo ""
echo -e "${GREEN}✅ Build completed successfully!${NC}"
echo ""

# Show build size
echo -e "${YELLOW}📊 Build Statistics:${NC}"
du -sh build/web
echo ""
echo -e "${YELLOW}📦 Main bundle size:${NC}"
ls -lh build/web/main.dart.js
echo ""
echo -e "${YELLOW}🗂️  Total files:${NC}"
find build/web -type f | wc -l
echo ""

# Check for large files
echo -e "${YELLOW}⚠️  Large files (>1MB):${NC}"
find build/web -type f -size +1M -exec ls -lh {} \; | awk '{ print $9 ": " $5 }' || echo "None found"
echo ""

echo -e "${GREEN}🎉 Ready for deployment!${NC}"
echo ""
echo "To test locally:"
echo "  cd build/web && python3 -m http.server 8000"
echo ""
echo "To deploy with Docker:"
echo "  docker build -t lecotour-dashboard ."
echo "  docker run -p 8080:80 lecotour-dashboard"
