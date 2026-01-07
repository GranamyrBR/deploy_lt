# ============================================
# Dockerfile para Coolify com Caddy
# Build Flutter Web - Caddy serve automaticamente
# OTIMIZADO: Cache de dependências + Build paralelo
# ============================================
FROM ghcr.io/cirruslabs/flutter:stable AS build

# Set working directory
WORKDIR /app

# Copy pubspec files first (for better caching)
COPY pubspec.yaml pubspec.lock ./

# Get dependencies (cached unless pubspec changes)
RUN flutter pub get

# Copy only necessary files for code generation
COPY lib/config/ ./lib/config/
COPY .env .env

# Generate ONLY env.g.dart (faster than full build_runner)
RUN flutter pub run build_runner build --delete-conflicting-outputs \
    --build-filter="lib/config/env.g.dart" || true

# Copy the rest of the application
COPY . .

# Build Flutter Web with optimizations
# - release mode for production
# - pwa-strategy for offline-first support
# - base-href for proper routing
# - no-tree-shake-icons speeds up build (icons already optimized)
RUN flutter build web \
    --release \
    --pwa-strategy=offline-first \
    --base-href="/" \
    --dart-define=FLUTTER_WEB_USE_SKIA=false \
    --no-tree-shake-icons

# Apply cache busting - inject version into files
RUN cd build/web && \
    BUILD_VERSION=$(date +%s) && \
    BUILD_HASH=$(git rev-parse --short HEAD 2>/dev/null || echo "docker") && \
    VERSION="${BUILD_HASH}-${BUILD_VERSION}" && \
    echo "Cache busting version: ${VERSION}" && \
    \
    # Update index.html with version
    sed -i "s|{{APP_VERSION}}|${VERSION}|g" index.html && \
    sed -i "s|main\.dart\.js|main.dart.js?v=${VERSION}|g" index.html && \
    sed -i "s|flutter_service_worker\.js|flutter_service_worker.js?v=${VERSION}|g" index.html && \
    \
    # Create version file
    echo "${VERSION}" > version.txt && \
    \
    # Add version to service worker
    sed -i "1i// Version: ${VERSION}" flutter_service_worker.js || true

# ============================================
# Stage 2: Static files only (Caddy will serve)
# ============================================
FROM busybox:latest

# Copy Flutter web build
COPY --from=build /app/build/web /web

# Coolify/Caddy will serve files from /web automatically
# No need for web server in container - Caddy handles it!

CMD ["echo", "Build complete! Caddy will serve /web directory"]
