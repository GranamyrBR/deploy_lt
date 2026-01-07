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

# Build Flutter Web with optimizations
# - release mode for production
# - pwa-strategy for offline support
# - base-href for proper routing
RUN flutter build web \
    --release \
    --pwa-strategy=offline-first \
    --base-href="/"

# ============================================
# Stage 2: Static files only (Caddy will serve)
# ============================================
FROM busybox:latest

# Copy Flutter web build
COPY --from=build /app/build/web /web

# Coolify/Caddy will serve files from /web automatically
# No need for web server in container - Caddy handles it!

CMD ["echo", "Build complete! Caddy will serve /web directory"]
