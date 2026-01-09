# ============================================
# Dockerfile para Deploy com Build Local + Versionamento
# Suporta múltiplas versões e rollback instantâneo
# ============================================
FROM caddy:2-alpine

# Build arguments (versão e hash do git)
ARG BUILD_VERSION=1.0.0
ARG BUILD_HASH=unknown

RUN addgroup -g 1001 -S caddy && \
    adduser -S -D -H -u 1001 -s /sbin/nologin -G caddy caddy || true
RUN apk add --no-cache curl jq

# Criar estrutura de diretórios para versionamento
RUN mkdir -p /web/versions /var/log/caddy

# Copiar build para diretório versionado
COPY build/web /web/versions/${BUILD_VERSION}

# Criar symlink 'current' apontando para a versão atual
RUN ln -sfn /web/versions/${BUILD_VERSION} /web/current

# Criar metadata de versão
RUN echo "{\"version\":\"${BUILD_VERSION}\",\"hash\":\"${BUILD_HASH}\",\"timestamp\":\"$(date -Iseconds)\",\"deployed\":\"$(date '+%Y-%m-%d %H:%M:%S')\"}" > /web/versions/${BUILD_VERSION}/version-meta.json

# Copiar version.json para raiz (API de versão)
RUN if [ -f /web/versions/${BUILD_VERSION}/version.json ]; then \
      cp /web/versions/${BUILD_VERSION}/version.json /web/version.json; \
    else \
      echo "{\"version\":\"${BUILD_VERSION}\",\"hash\":\"${BUILD_HASH}\"}" > /web/version.json; \
    fi

# Configuração do Caddy (atualizada para servir de /web/current)
COPY Caddyfile /etc/caddy/Caddyfile

# Ajustar Caddyfile para usar /web/current
RUN sed -i 's|root \* /usr/share/caddy|root * /web/current|g' /etc/caddy/Caddyfile

# Permissões
RUN chown -R caddy:caddy /var/log/caddy /etc/caddy /web

USER caddy
EXPOSE 8080

# Healthcheck aprimorado (verifica versão também)
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD curl -fs http://localhost:8080/ && curl -fs http://localhost:8080/version.json || exit 1

CMD ["caddy", "run", "--config", "/etc/caddy/Caddyfile", "--adapter", "caddyfile"]
