#!/bin/sh
# ============================================
# Docker Entrypoint for Flutter Web
# Injects environment variables at runtime
# ============================================

set -e

# Directory where Flutter web is served
WEB_DIR="/usr/share/nginx/html"

# Create env-config.js with runtime environment variables
cat > "$WEB_DIR/env-config.js" <<EOF
// Runtime environment configuration
// Generated at container startup
window.ENV_CONFIG = {
  SUPABASE_URL: "${SUPABASE_URL:-}",
  SUPABASE_ANON_KEY: "${SUPABASE_ANON_KEY:-}",
  GOOGLE_MAPS_API_KEY: "${GOOGLE_MAPS_API_KEY:-}",
  OPENAI_API_KEY: "${OPENAI_API_KEY:-}",
  ENVIRONMENT: "${ENVIRONMENT:-production}",
  API_BASE_URL: "${API_BASE_URL:-}",
  ENABLE_ANALYTICS: "${ENABLE_ANALYTICS:-false}",
  BUILD_DATE: "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
};
EOF

echo "✅ Environment configuration created at $WEB_DIR/env-config.js"
echo "🚀 Starting Nginx..."

# Execute the CMD from Dockerfile
exec "$@"
