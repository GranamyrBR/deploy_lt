# 🛠️ GUIA PRÁTICO DE IMPLEMENTAÇÃO - VPS COM SUPABASE LOCAL
## Passo a Passo para Deploy em Produção

---

## 📋 CHECKLIST PRÉ-DEPLOYMENT

### 1. Preparação do Projeto

```bash
# ✅ Verificar dependências
flutter pub get
flutter analyze
flutter test --coverage

# ✅ Build Web
flutter build web --release

# ✅ Verificar variáveis de ambiente
cat .env
# Deve conter:
# SUPABASE_URL=http://vps-ip:8000
# SUPABASE_ANON_KEY=eyJ...
# SUPABASE_SERVICE_KEY=eyJ...
# GOOGLE_MAPS_API_KEY=...

# ✅ Verificar Docker
docker --version
docker-compose --version
```

### 2. Validação de Segurança

```bash
# ✅ Escanear dependências
flutter pub deps
npm audit (para Firebase Functions)

# ✅ Verificar secrets no git
git log --full-history --oneline | head -20
git log -p -- .env 2>/dev/null

# ✅ Validar SSL/TLS
openssl req -x509 -newkey rsa:2048 -keyout key.pem -out cert.pem -days 365

# ✅ Testar CORS
curl -H "Origin: http://localhost:3000" \
  -H "Access-Control-Request-Method: GET" \
  -X OPTIONS http://vps-ip/api
```

---

## 🖥️ SETUP DO VPS

### 1. Provisionar VPS

**Opções Recomendadas:**

#### DigitalOcean (Recomendado)
```bash
# 1. Criar droplet
# - Ubuntu 22.04 LTS
# - 4GB RAM / 2 vCPU / 80GB SSD
# - $12/mês (annual discount = $10/mês)
# - Ativar backups automáticos (+$2/mês)

# 2. SSH Key setup
ssh-keygen -t ed25519 -C "admin@lecotour.com"
# Adicionar public key no console

# 3. Conectar inicial
ssh -i ~/.ssh/id_ed25519 root@VPS_IP
```

#### Linode
```bash
# Similar ao DigitalOcean
# Vantagem: Melhor performance em CPU
# Preço: $12/mês (annual)
```

#### Hetzner Cloud
```bash
# Mais barato que DO/Linode
# Preço: €5-10/mês (~$5-11)
# EU data centers (ótimo para LGPD/GDPR)
```

### 2. Hardening Inicial do VPS

```bash
#!/bin/bash
# hardening.sh

# 1. Atualizar sistema
apt-get update && apt-get upgrade -y
apt-get install -y curl wget git htop net-tools

# 2. Firewall UFW
apt-get install -y ufw
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp          # SSH
ufw allow 80/tcp          # HTTP
ufw allow 443/tcp         # HTTPS
ufw allow 5432/tcp from 10.0.0.0/8  # PostgreSQL (apenas rede interna)
ufw enable

# 3. SSH Hardening
sed -i 's/#Port 22/Port 2222/' /etc/ssh/sshd_config
sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
systemctl restart sshd

# 4. Criar usuário não-root
useradd -m -s /bin/bash vpsadmin
usermod -aG sudo vpsadmin

# 5. Fail2Ban
apt-get install -y fail2ban
systemctl enable fail2ban
systemctl start fail2ban

# 6. Auto-update de segurança
apt-get install -y unattended-upgrades apt-listchanges
systemctl enable unattended-upgrades
systemctl start unattended-upgrades

echo "✅ VPS hardening completo!"
```

**Executar:**
```bash
chmod +x hardening.sh
./hardening.sh
```

---

## 🐳 DOCKER & SUPABASE SETUP

### 1. Instalar Docker

```bash
#!/bin/bash
# docker-install.sh

# 1. Dependências
apt-get install -y apt-transport-https ca-certificates curl software-properties-common

# 2. Docker Repository
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

# 3. Instalar Docker
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# 4. Docker Compose (v2 - já incluído, ou v1 legado)
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# 5. Adicionar usuário ao grupo docker
usermod -aG docker vpsadmin

echo "✅ Docker instalado!"
```

### 2. Supabase Self-Hosted

```bash
#!/bin/bash
# supabase-setup.sh

cd /opt
git clone --depth 1 https://github.com/supabase/supabase.git
cd supabase/docker

# 1. Copiar .env template
cp .env.example .env

# 2. Configurar .env
cat > .env << 'EOF'
# Supabase Configuration
POSTGRES_PASSWORD=SuperSecure2024!@#$%
JWT_SECRET=$(openssl rand -base64 32)
ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
SERVICE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

# Domain
SITE_URL=https://lecotour.com
API_EXTERNAL_URL=https://api.lecotour.com

# Email
SMTP_ADMIN_EMAIL=admin@lecotour.com
SMTP_HOST=smtp.sendgrid.net
SMTP_PORT=587
SMTP_USER=apikey
SMTP_PASS=SG.your-sendgrid-key...

# Outros
ENABLE_EMAIL_AUTOCONFIRM=false
ENABLE_PHONE_AUTOCONFIRM=false
EOF

# 3. Iniciar containers
docker-compose -f docker-compose.yml up -d

# 4. Aguardar inicialização
sleep 60

# 5. Verificar status
docker-compose ps

echo "✅ Supabase iniciado! Acesse: http://localhost:3000"
```

---

## 🗄️ POSTGRESQL HARDENING

### 1. Restaurar Banco de Dados

```bash
#!/bin/bash
# restore-db.sh

# 1. Fazer backup da estrutura local
pg_dump -h localhost -U postgres -d lecotour_db --schema-only > schema-backup.sql

# 2. Restaurar dados existentes
PGPASSWORD=SuperSecure2024!@#$% psql -h localhost -U postgres -d lecotour -f DB_schema.sql

# 3. Restaurar dados (se tiver export)
# PGPASSWORD=... psql -h localhost -U postgres -d lecotour -f data.sql

# 4. Executar migrations
PGPASSWORD=... psql -h localhost -U postgres -d lecotour -f migration_sale_upgrade.sql

# 5. Verificar integridade
PGPASSWORD=... psql -h localhost -U postgres -d lecotour -c "SELECT count(*) FROM account;"

echo "✅ Banco restaurado!"
```

### 2. Políticas de RLS

```bash
#!/bin/bash
# enable-rls.sh

PGPASSWORD=SuperSecure2024!@#$% psql -h localhost -U postgres -d lecotour << 'EOF'

-- 1. Habilitar RLS
ALTER TABLE sale ENABLE ROW LEVEL SECURITY;
ALTER TABLE account ENABLE ROW LEVEL SECURITY;
ALTER TABLE contact ENABLE ROW LEVEL SECURITY;
ALTER TABLE sale_payment ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_log ENABLE ROW LEVEL SECURITY;

-- 2. Criar políticas de exemplo

-- Vendedores veem só suas próprias vendas
CREATE POLICY "seller_own_sales" ON sale
  FOR SELECT USING (
    auth.uid()::text = created_by_user_id OR
    EXISTS (
      SELECT 1 FROM "user" 
      WHERE id = auth.uid()::uuid 
      AND is_admin = true
    )
  );

-- Admin vê tudo
CREATE POLICY "admin_all_access" ON sale
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM "user" 
      WHERE id = auth.uid()::uuid 
      AND is_admin = true
    )
  );

-- Audit log: apenas admin
CREATE POLICY "audit_admin_only" ON audit_log
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM "user" 
      WHERE id = auth.uid()::uuid 
      AND is_admin = true
    )
  );

-- 3. Verificar
SELECT tablename, rowsecurity FROM pg_tables WHERE rowsecurity = true;

EOF

echo "✅ RLS habilitado!"
```

---

## 🔐 SSL/TLS & NGINX

### 1. Nginx Reverse Proxy

```bash
#!/bin/bash
# nginx-setup.sh

apt-get install -y nginx certbot python3-certbot-nginx

# 1. Criar config
cat > /etc/nginx/sites-available/lecotour << 'EOF'
upstream supabase {
    server localhost:8000;
}

upstream api {
    server localhost:3000;
}

server {
    listen 80;
    server_name api.lecotour.com lecotour.com www.lecotour.com;
    
    # Redirect HTTP para HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name api.lecotour.com;
    
    # SSL Configuration
    ssl_certificate /etc/letsencrypt/live/api.lecotour.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.lecotour.com/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    
    # Security Headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-Frame-Options "DENY" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "no-referrer" always;
    
    # Logging
    access_log /var/log/nginx/lecotour-access.log;
    error_log /var/log/nginx/lecotour-error.log;
    
    # Rate Limiting
    limit_req_zone $binary_remote_addr zone=api_limit:10m rate=10r/s;
    limit_req zone=api_limit burst=20 nodelay;
    
    # Proxy
    location / {
        proxy_pass http://supabase;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # WebSocket support
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}

server {
    listen 443 ssl http2;
    server_name lecotour.com www.lecotour.com;
    
    ssl_certificate /etc/letsencrypt/live/lecotour.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/lecotour.com/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    
    # Servir web estático
    root /var/www/lecotour/web;
    index index.html index.htm;
    
    location / {
        try_files $uri $uri/ /index.html;
    }
    
    location /api {
        proxy_pass http://api;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

# 2. Habilitar site
ln -s /etc/nginx/sites-available/lecotour /etc/nginx/sites-enabled/
rm /etc/nginx/sites-enabled/default

# 3. Testar config
nginx -t

# 4. Iniciar
systemctl restart nginx

# 5. Certificado Let's Encrypt
certbot certonly --nginx -d lecotour.com -d www.lecotour.com -d api.lecotour.com

# 6. Auto-renew
systemctl enable certbot.timer
systemctl start certbot.timer

echo "✅ Nginx configurado com SSL!"
```

---

## 💾 BACKUP AUTOMÁTICO

### 1. Backup Local + Remoto

```bash
#!/bin/bash
# backup-setup.sh

# Criar diretório
mkdir -p /opt/backups/{daily,weekly,monthly}

# 1. Script de backup
cat > /opt/backups/backup.sh << 'BACKUPEOF'
#!/bin/bash

BACKUP_DIR="/opt/backups"
DATE=$(date +%Y%m%d_%H%M%S)
RETENTION_DAYS=30

# Database backup
PGPASSWORD=SuperSecure2024!@#$% pg_dump \
  -h localhost \
  -U postgres \
  -d lecotour \
  --format=custom \
  --file=$BACKUP_DIR/daily/db_$DATE.dump

# Compress
gzip -9 $BACKUP_DIR/daily/db_$DATE.dump

# Upload para S3
aws s3 cp $BACKUP_DIR/daily/db_$DATE.dump.gz \
  s3://lecotour-backups/database/$DATE.dump.gz \
  --sse AES256

# Limpeza local (manter últimos 30 dias)
find $BACKUP_DIR/daily -name "db_*.dump.gz" -mtime +$RETENTION_DAYS -delete

echo "✅ Backup realizado: db_$DATE.dump.gz"
BACKUPEOF

chmod +x /opt/backups/backup.sh

# 2. Cron job
crontab -e
# Adicionar linha:
# 0 2 * * * /opt/backups/backup.sh >> /var/log/backup.log 2>&1

# 3. AWS S3 setup
# aws configure (pedir credentials)
# Criar bucket: aws s3 mb s3://lecotour-backups

# 4. Testar backup
/opt/backups/backup.sh

echo "✅ Backup automático configurado!"
```

### 2. Restauração de Backup

```bash
#!/bin/bash
# restore-backup.sh

# Baixar do S3
aws s3 cp s3://lecotour-backups/database/LATEST.dump.gz ./restore.dump.gz

# Descompactar
gunzip restore.dump.gz

# Restaurar
PGPASSWORD=SuperSecure2024!@#$% pg_restore \
  -h localhost \
  -U postgres \
  -d lecotour_restore \
  --verbose \
  restore.dump

echo "✅ Backup restaurado em lecotour_restore"
echo "Verificar dados e fazer RENAME da database"
```

---

## 📊 MONITORAMENTO

### 1. Prometheus + Grafana

```bash
#!/bin/bash
# monitoring-setup.sh

cd /opt

# 1. Prometheus
wget https://github.com/prometheus/prometheus/releases/download/v2.50.0/prometheus-2.50.0.linux-amd64.tar.gz
tar xvfz prometheus-2.50.0.linux-amd64.tar.gz
mv prometheus-2.50.0.linux-amd64 prometheus

# Config Prometheus
cat > prometheus/prometheus.yml << 'EOF'
global:
  scrape_interval: 15s
  evaluation_interval: 15s

alerting:
  alertmanagers:
    - static_configs:
        - targets:
            - localhost:9093

rule_files:
  - 'alert_rules.yml'

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
  
  - job_name: 'node'
    static_configs:
      - targets: ['localhost:9100']
  
  - job_name: 'postgres'
    static_configs:
      - targets: ['localhost:9187']
EOF

# 2. Grafana
wget https://dl.grafana.com/oss/release/grafana-10.2.0.linux-amd64.tar.gz
tar xvfz grafana-10.2.0.linux-amd64.tar.gz
mv grafana-10.2.0 grafana

# Iniciar
cd prometheus && ./prometheus --config.file=prometheus.yml &
cd ../grafana && ./bin/grafana-server &

echo "✅ Prometheus: http://localhost:9090"
echo "✅ Grafana: http://localhost:3000"
```

---

## 🔍 TESTES FINAIS

### 1. Health Checks

```bash
#!/bin/bash
# health-check.sh

echo "🔍 Testando componentes..."

# 1. Supabase
curl -s http://localhost:8000/health | jq .
echo "✅ Supabase OK" || echo "❌ Supabase FAIL"

# 2. PostgreSQL
PGPASSWORD=SuperSecure2024!@#$% psql -h localhost -U postgres -c "SELECT NOW();"
echo "✅ PostgreSQL OK" || echo "❌ PostgreSQL FAIL"

# 3. Nginx
curl -s -k https://api.lecotour.com/health | head -5
echo "✅ Nginx OK" || echo "❌ Nginx FAIL"

# 4. SSL/TLS
openssl s_client -connect api.lecotour.com:443 -servername api.lecotour.com -dates
echo "✅ SSL OK" || echo "❌ SSL FAIL"

# 5. Backup
ls -lh /opt/backups/daily/ | tail -5
echo "✅ Backup OK" || echo "❌ Backup FAIL"

# 6. Firewall
sudo ufw status
echo "✅ Firewall OK"

echo "✅ Todos os testes completados!"
```

---

## 📝 DOCUMENTAÇÃO FINAL

Criar arquivo `DEPLOYMENT.md` no repositório:

```markdown
# Deployment VPS - Checklist Final

## Pré-Deploy
- [ ] Testar em staging
- [ ] Backup completo feito
- [ ] DNS propagado (24-48h)
- [ ] SSL certificados gerados
- [ ] .env configurado

## Deploy
- [ ] VPS provisionado
- [ ] Docker instalado
- [ ] Supabase iniciado
- [ ] DB restaurado
- [ ] RLS políticas aplicadas
- [ ] Nginx configurado
- [ ] SSL ativo

## Pós-Deploy
- [ ] Health checks passando
- [ ] Backup automático testado
- [ ] Monitoring ativo
- [ ] Alertas funcionando
- [ ] Acesso VPN testado
- [ ] Logs sendo coletados

## SLA
- Uptime: 99.5% mínimo
- Recovery: < 30 min
- Backup: Diário + Semanal
- Update: Automático de segurança
```

---

## 🎯 PRÓXIMOS PASSOS

1. **Semana 1**: Setup infraestrutura
2. **Semana 2**: Configurar segurança
3. **Semana 3**: Deploy aplicação
4. **Semana 4**: Testes e validação
5. **Semana 5+**: Otimização e escalabilidade

**Contato para dúvidas**: devops@lecotour.com

---

**Versão**: 1.0  
**Data**: 12 de Novembro de 2025  
**Status**: Pronto para Implementação ✅

# 🛠️ GUIA PRÁTICO DE IMPLEMENTAÇÃO - VPS COM SUPABASE LOCAL
