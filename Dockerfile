# ============================================
# Stage 1: Build Flutter Web Application
# ============================================
FROM ghcr.io/cirruslabs/flutter:stable AS build

# Set working directory
WORKDIR /app

# Copy pubspec files
COPY pubspec.yaml pubspec.lock ./

# Get dependencies
RUN flutter pub get

# Copy the rest of the application
COPY . .

# Build Flutter Web with optimizations
# - release mode for production
# - pwa-strategy for offline support and service worker
# - base-href for proper routing
RUN flutter build web \
    --release \
    --pwa-strategy=offline-first \
    --base-href="/"

# ============================================
# Stage 2: Serve with Nginx (Production)
# ============================================
FROM nginx:alpine

# Install tools for healthcheck
RUN apk add --no-cache curl

# Copy custom nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf

# Copy Flutter web build
COPY --from=build /app/build/web /usr/share/nginx/html

# Copy environment configuration script
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

# Expose port
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost/health || exit 1

# Use custom entrypoint for dynamic env vars
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]
