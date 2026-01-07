# ============================================
# Dockerfile para Deploy com Build Local
# Apenas copia arquivos já compilados
# ============================================
FROM busybox:latest

# Copia os arquivos web já buildados localmente
COPY build/web /web

# Coolify/Caddy will serve files from /web automatically
CMD ["echo", "Pre-built files ready! Caddy will serve /web directory"]
