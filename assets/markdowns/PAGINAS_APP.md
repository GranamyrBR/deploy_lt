# 📋 Mapeamento de Páginas do App Lecotour Dashboard

Este arquivo contém o mapeamento completo das páginas do app web para seus respectivos arquivos `.dart`.

## 🏠 Páginas Principais

| **Página do App** | **Arquivo .dart** | **Descrição** |
|-------------------|-------------------|---------------|
| **Dashboard (Home)** | `lib/screens/dashboard_screen.dart` | Página principal do dashboard |
| **Vendas** | `lib/screens/sales_screen.dart` | Lista de vendas |
| **Criar Venda V2** | `lib/screens/create_sale_screen_v2.dart` | Criar nova venda (versão 2) |
| **Faturas Provisórias** | `lib/screens/provisional_invoices_screen.dart` | Faturas provisórias |
| **Contatos** | `lib/screens/contacts_screen.dart` | Gerenciamento de contatos |
| **Voos** | `lib/screens/flights_screen.dart` | Busca e gerenciamento de voos |
| **WhatsApp Leads** | `lib/screens/whatsapp_leads_screen.dart` | Leads do WhatsApp |
| **Motoristas** | `lib/screens/drivers_screen.dart` | Gerenciamento de motoristas |
| **Carros** | `lib/screens/cars_screen.dart` | Gerenciamento de veículos |
| **Agências** | `lib/screens/agencies_screen.dart` | Gerenciamento de agências |
| **Usuários** | `lib/screens/users_screen.dart` | Gerenciamento de usuários |
| **Monday** | `lib/screens/monday_screen.dart` | Integração com Monday.com |
| **Busca Global** | `lib/screens/global_search_screen.dart` | Busca global no sistema |
| **Timeline Demo** | `lib/screens/timeline_demo_screen.dart` | Demonstração de timeline |
| **Operações** | `lib/screens/operations_dashboard_screen.dart` | Dashboard de operações |
| **Google Calendar** | `lib/screens/google_calendar_screen.dart` | Integração com Google Calendar |
| **Nova York** | `lib/screens/new_york_screen.dart` | Informações sobre Nova York |
| **B2B Dashboard** | `lib/screens/b2b_dashboard_screen.dart` | Dashboard B2B |
| **Ciclo de Serviço** | `lib/screens/complete_service_cycle_screen.dart` | Ciclo completo de atendimento |
| **Hub B2B** | `lib/screens/hub_b2b_screen.dart` | Hub B2B principal |

## 🔧 Páginas B2B (Submenu)

| **Página B2B** | **Arquivo .dart** | **Descrição** |
|----------------|-------------------|---------------|
| **Ranking de Agências** | `lib/screens/agency_ranking_screen.dart` | Ranking de agências B2B |
| **Oportunidades** | `lib/screens/b2b_opportunities_screen.dart` | Oportunidades B2B |
| **Documentos** | `lib/screens/b2b_documents_screen.dart` | Documentos B2B |
| **Agências B2B** | `lib/screens/hub_b2b_agencies_screen.dart` | Agências B2B |
| **Contatos B2B** | `lib/screens/b2b_contacts_screen.dart` | Contatos B2B |

## 📁 Estrutura de Arquivos Importantes

### **Navegação e Roteamento**
- **Rotas principais**: `lib/main.dart`
- **Navegação**: `lib/widgets/sidebar.dart`
- **Dashboard**: `lib/screens/dashboard_screen.dart`
- **Provider de páginas**: `lib/providers/dashboard_provider.dart`

### **Todas as Telas**
- **Pasta principal**: `lib/screens/`
- **Widgets**: `lib/widgets/`
- **Providers**: `lib/providers/`
- **Serviços**: `lib/services/`

## 🔍 Como Descobrir Mais Páginas

### **1. Verificar o Sidebar**
```bash
grep -n "DashboardPage\." lib/widgets/sidebar.dart
```

### **2. Verificar o Dashboard**
```bash
grep -n "case DashboardPage" lib/screens/dashboard_screen.dart
```

### **3. Verificar Navegação**
```bash
grep -n "Navigator\.push" lib/screens/*.dart
```

### **4. Listar Todas as Telas**
```bash
ls -la lib/screens/
```

## 📊 Enum DashboardPage

```dart
enum DashboardPage {
  home,
  globalSearch,
  sales,
  createSaleV2,
  provisionalInvoices,
  services,
  contacts,
  drivers,
  vehicles,
  cars,
  agencies,
  flights,
  whatsappLeads,
  users,
  monday,
  timelineDemo,
  operations,
  saleWithOperation,
  googleCalendar,
  newYork,
  b2b,

  hubB2B,
  // B2B Hub submenu items
  hubB2BAgencyRanking,
  hubB2BOpportunities,
  hubB2BDocuments,
  hubB2BDashboard,
  hubB2BAgencies,

}
```

## 🚀 Comandos Úteis

### **Executar o App**
```bash
# Modo debug
flutter run -d chrome --web-port=8080

# Modo release
flutter run -d chrome --web-port=8080 --release

# Limpar cache
flutter clean && flutter pub get
```

### **Buscar por Páginas Específicas**
```bash
# Buscar por nome de tela
grep -r "Screen()" lib/screens/

# Buscar por imports de telas
grep -r "import.*screen" lib/
```

## 📝 Notas

- **Arquivos de backup**: Alguns arquivos têm versões `.backup` ou `_backup`
- **Arquivos temporários**: Arquivos começando com `._` são temporários do sistema
- **Arquivos quebrados**: `cars_screen_broken.dart` é uma versão com problemas

---

**Última atualização**: $(date)
**Versão do app**: 1.0.0+1
# 📋 Mapeamento de Páginas do App Lecotour Dashboard
