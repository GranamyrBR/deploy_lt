# ============================================
# Dockerfile para Coolify com Caddy
# Build Flutter Web - Caddy serve automaticamente
# ============================================
FROM ghcr.io/cirruslabs/flutter:stable AS build

# Set working directory
WORKDIR /app

# Copy pubspec files first (for better caching)
COPY pubspec.yaml pubspec.lock ./

# Get dependencies
RUN flutter pub get

# Copy the rest of the application
COPY . .

# Generate code (envied)
RUN flutter pub run build_runner build --delete-conflicting-outputs || true

# Build Flutter Web with optimizations + Cache Busting
# - release mode for production
# - pwa-strategy for offline support
# - base-href for proper routing
# - split-debug-info for smaller bundle
# - deferred loading enabled
RUN flutter build web \
    --release \
    --pwa-strategy=offline-first \
    --base-href="/" \
    --dart-define=FLUTTER_WEB_USE_SKIA=false \
    --web-renderer=canvaskit \
    --split-debug-info=build/debug_info

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
