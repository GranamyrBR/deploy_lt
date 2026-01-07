# ============================================
# Dockerfile para Deploy com Build Local
# Nginx serve os arquivos para o Caddy do Coolify
# ============================================
FROM nginx:alpine

# Remove arquivos padrão do nginx
RUN rm -rf /usr/share/nginx/html/*

# Copia os arquivos web já buildados localmente
COPY build/web /usr/share/nginx/html

# Configuração mínima do nginx para SPA
RUN echo 'server { \
    listen 80; \
    root /usr/share/nginx/html; \
    index index.html; \
    location / { \
        try_files $uri $uri/ /index.html; \
    } \
    # Cache headers \
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf)$ { \
        expires 1y; \
        add_header Cache-Control "public, immutable"; \
    } \
}' > /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
