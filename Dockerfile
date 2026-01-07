# ============================================
# Dockerfile para Deploy com Build Local
# Coolify/Caddy serve arquivos de /web automaticamente
# ============================================
FROM busybox:latest

# Copia os arquivos web já buildados localmente para /web
# Coolify/Caddy irá servir automaticamente deste diretório
COPY build/web /web

# Keep container alive for Caddy to serve files
CMD ["sh", "-c", "echo '✅ Files ready at /web for Caddy' && tail -f /dev/null"]
