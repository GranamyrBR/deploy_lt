# ============================================
# Dockerfile para Deploy com Build Local
# Usa Caddy como no app antigo (lecodeploy)
# ============================================
FROM caddy:2-alpine

RUN addgroup -g 1001 -S caddy && \
    adduser -S -D -H -u 1001 -s /sbin/nologin -G caddy caddy || true
RUN apk add --no-cache curl

# Copia o build estático do Flutter Web
COPY build/web /usr/share/caddy

# Configuração do Caddy (SPA)
COPY Caddyfile /etc/caddy/Caddyfile

RUN mkdir -p /var/log/caddy && \
    chown -R caddy:caddy /var/log/caddy /etc/caddy /usr/share/caddy

USER caddy
EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD curl -fs http://localhost:8080/ || exit 1

CMD ["caddy", "run", "--config", "/etc/caddy/Caddyfile", "--adapter", "caddyfile"]
