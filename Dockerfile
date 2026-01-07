# ============================================
# Dockerfile para Deploy com Build Local
# Apenas copia arquivos já compilados
# ============================================
FROM busybox:latest

# Copia os arquivos web já buildados localmente
COPY build/web /web

# Keep container running for Caddy to serve files
CMD ["sh", "-c", "echo 'Pre-built files ready! Caddy will serve /web directory' && tail -f /dev/null"]
