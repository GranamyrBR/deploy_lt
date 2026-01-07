# 🗽 Lecotour Dashboard

Dashboard de gerenciamento para Lecotour - Receptivos em Nova York

## 📋 Sobre o Projeto

Sistema web de gerenciamento completo para operadora de turismo, desenvolvido em Flutter Web com backend Supabase. Oferece controle de vendas, cotações, clientes, operações e análises em tempo real.

## ✨ Principais Funcionalidades

### 🎯 Gestão de Vendas
- Sistema completo de vendas com múltiplos itens
- Controle de status (rascunho, confirmada, cancelada, etc.)
- Rastreamento de pagamentos e comissões
- Integração com WhatsApp para comunicação

### 📊 Dashboard Executivo
- Visão geral de vendas e métricas em tempo real
- Gráficos e análises de performance
- Dashboard específico para vendedores
- Sistema Kanban para gestão de vendas

### 💰 Sistema de Cotações Premium
- Geração automática de cotações em PDF
- Controle de status das cotações
- Histórico e rastreamento completo
- Templates personalizáveis

### 👥 Gestão de Clientes
- Perfil completo de clientes com histórico
- Múltiplas visualizações (lista, grade, modal)
- Análise de comportamento e métricas
- Integração com sistema de vendas

### 🎫 Gestão de Operações
- Controle de passeios e serviços
- Gerenciamento de fornecedores
- Calendário de operações
- Controle de inventário

### 🔐 Sistema de Autenticação e Permissões
- Login seguro via Supabase Auth
- Controle de acesso baseado em roles
- Perfis: Admin, Manager, Seller, Viewer
- Auditoria completa de ações

## 🛠️ Stack Tecnológica

### Frontend
- **Flutter Web** (SDK >=3.1.0 <4.0.0)
- **Riverpod** - Gerenciamento de estado
- **Provider** - Estado complementar
- **EasyLocalization** - Internacionalização (PT-BR/EN)

### Backend & Database
- **Supabase** - Backend as a Service
  - PostgreSQL Database
  - Real-time subscriptions
  - Row Level Security (RLS)
  - Edge Functions
- **Firebase** - Hosting e Functions complementares

### Principais Pacotes
```yaml
dependencies:
  flutter_riverpod: ^2.4.9
  supabase_flutter: ^2.9.1
  easy_localization: ^3.0.5
  pdf: ^3.11.1
  intl: ^0.19.0
  url_launcher: ^6.2.2
  file_picker: ^6.1.1
```

## 📁 Estrutura do Projeto

```
lecotour_dashboard/
├── lib/
│   ├── config/           # Configurações (Supabase, Firebase)
│   ├── design/           # Tema, cores, estilos
│   ├── models/           # Modelos de dados
│   ├── providers/        # Riverpod providers
│   ├── screens/          # Telas do aplicativo
│   ├── services/         # Serviços e APIs
│   ├── utils/            # Utilitários
│   ├── widgets/          # Componentes reutilizáveis
│   └── main.dart         # Entry point
├── supabase/
│   ├── migrations/       # Migrações do banco
│   └── functions/        # Edge Functions
├── functions/            # Firebase Functions
├── assets/               # Recursos (imagens, traduções)
├── test/                 # Testes unitários
├── integration_test/     # Testes de integração
└── docs/                 # Documentação técnica
```

## 🚀 Começando

### Pré-requisitos

- Flutter SDK 3.1.0 ou superior
- Dart SDK 3.1.0 ou superior
- Conta Supabase configurada
- Node.js (para Firebase Functions)

### Instalação

1. **Clone o repositório**
```bash
git clone <repository-url>
cd lecotour_dashboard
```

2. **Instale as dependências**
```bash
flutter pub get
cd functions && npm install && cd ..
```

3. **Configure o ambiente**

Crie um arquivo `.env` na raiz:
```env
SUPABASE_URL=sua_url_supabase
SUPABASE_ANON_KEY=sua_chave_anonima
```

4. **Execute o projeto**
```bash
flutter run -d chrome
```

### Configuração do Supabase

1. Execute as migrações do banco:
```bash
cd supabase
supabase db push
```

2. Configure as variáveis de ambiente no Supabase Dashboard

3. Ative Row Level Security (RLS) nas tabelas

Consulte `docs/database/` para mais detalhes sobre o schema.

## 🧪 Testes

```bash
# Testes unitários
flutter test

# Testes de integração
flutter test integration_test/

# Cobertura
flutter test --coverage
```

## 📱 Build para Produção

### Web
```bash
flutter build web --release
```

### Android
```bash
flutter build apk --release
flutter build appbundle --release
```

### iOS
```bash
flutter build ipa --release
```

## 🌍 Internacionalização

O projeto suporta:
- 🇧🇷 Português (Brasil) - padrão
- 🇺🇸 English

Traduções em: `assets/translations/`

## 📚 Documentação

- [Database Schema](docs/database/DATABASE_SCHEMA_GUIDE.md)
- [Database ERD](docs/database/DATABASE_ERD.md)
- [Sistema de Cotações](docs/guides/COTACOES_PREMIUM_GUIDE.md)
- [Guia de Segurança Web](docs/guides/SECURITY_GUIDE_WEB.md)
- [Sistema de Auditoria](docs/SISTEMA_AUDITORIA.md)

## 🔐 Segurança

- Autenticação via Supabase Auth
- Row Level Security (RLS) em todas as tabelas
- Controle de acesso baseado em roles
- Auditoria completa de ações sensíveis
- Validação de dados no cliente e servidor

## 🤝 Contribuindo

1. Fork o projeto
2. Crie uma branch para sua feature (`git checkout -b feature/AmazingFeature`)
3. Commit suas mudanças (`git commit -m 'Add some AmazingFeature'`)
4. Push para a branch (`git push origin feature/AmazingFeature`)
5. Abra um Pull Request

## 📝 Changelog

Veja [CHANGELOG.md](CHANGELOG.md) para histórico de versões.

## 📄 Licença

Este projeto é proprietário e confidencial.

## 👥 Equipe

Desenvolvido por Lecotour Team

## 📞 Suporte

Para suporte, entre em contato através de:
- Email: suporte@lecotour.com
- WhatsApp: +1 (XXX) XXX-XXXX

---

**Lecotour Dashboard** - Gerenciamento profissional de turismo em Nova York 🗽
