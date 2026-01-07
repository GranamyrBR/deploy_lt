# 🌐 Endereços do Projeto - Referência Rápida

## ✅ Endereços Corretos

| Serviço | URL | Descrição |
|---------|-----|-----------|
| **Coolify Dashboard** | https://axioscode.com/ | Painel de controle do Coolify |
| **App Flutter** | https://waha.axioscode.com/ | Aplicação Lecotour Dashboard |
| **Supabase** | https://sup.axioscode.com | Banco de dados |

---

## 📝 Notas Importantes

### Coolify Dashboard (https://axioscode.com/)
- Interface web do Coolify
- Gerenciamento de aplicações
- Configuração de Sources, Webhooks, Env Vars
- Logs de deploy e build

### App Flutter (https://waha.axioscode.com/)
- Aplicação principal do Lecotour Dashboard
- Servida via Caddy pelo Coolify
- Build automático via Dockerfile
- Cache busting habilitado

### Supabase (https://sup.axioscode.com)
- Backend as a Service
- PostgreSQL database
- Auth, Storage, Realtime
- Edge Functions

---

## 🔧 Configurações de DNS

```
axioscode.com         → IP_VPS (Coolify)
waha.axioscode.com    → IP_VPS (App Flutter via Coolify)
sup.axioscode.com     → IP_SUPABASE ou proxy
```

---

## 📚 Documentação Relacionada

- [COOLIFY_SETUP.md](COOLIFY_SETUP.md) - Setup do Coolify
- [COOLIFY_RECONFIGURE.md](COOLIFY_RECONFIGURE.md) - Reconfiguração
- [COOLIFY_GITHUB_PRIVATE_REPO.md](COOLIFY_GITHUB_PRIVATE_REPO.md) - Repos privados

---

**Última atualização:** 2026-01-07  
**Status:** ✅ Endereços corrigidos
