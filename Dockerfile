# ============================================
# Dockerfile para Deploy com Build Local
# Usa nginx para servir arquivos estáticos
# ============================================
FROM nginx:alpine

# Remove configuração padrão do nginx
RUN rm -rf /usr/share/nginx/html/*

# Copia os arquivos web já buildados localmente
COPY build/web /usr/share/nginx/html

# Copia configuração customizada do nginx (se existir)
# COPY nginx.conf /etc/nginx/nginx.conf

# Expõe porta 80
EXPOSE 80

# Inicia nginx
CMD ["nginx", "-g", "daemon off;"]
