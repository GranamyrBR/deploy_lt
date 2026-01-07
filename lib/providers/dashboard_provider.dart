import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:lecotour_dashboard/services/aviation_api_service.dart'; // Não é mais necessário aqui

// Enum para definir as páginas possíveis do dashboard
enum DashboardPage {
  home,
  globalSearch, // Nova página de busca global
  sales,
  createSaleV2, // Nova versão da página de criação de venda
  provisionalInvoices, // Nova página de faturas provisórias
  quotations, // Página de cotações
  quotationTags, // Gerenciamento de Tags de Cotações
  services,
  contacts,
  drivers,
  vehicles,
  cars, // Nova página de carros
  agencies,
  flights,
  whatsappLeads, // Nova página
  users, // Nova página de usuários
  monday, // Página Monday
  timelineDemo, // Nova página de demonstração de timeline
  operations, // Nova página de operações
  createOperationFromSale, // Nova página de criação de operação a partir de venda
  googleCalendar, // Nova página do Google Calendar
  newYork, // Nova página de Nova York
  b2b, // Dashboard B2B

  hubB2B, // Nova página Hub B2B
  // B2B Hub submenu items
  hubB2BAgencyRanking, // Ranking de Agências
  hubB2BOpportunities, // Oportunidades
  hubB2BDocuments, // Documentos
  hubB2BDashboard, // Dashboard B2B
  hubB2BAgencies, // Agências

  servicesAndProducts, // Gerenciamento de Serviços e Produtos
  servicesManagement, // CRUD de Serviços
  productsManagement, // CRUD de Produtos
  firebaseAccounts, // Gerenciamento de Contas Firebase

  // Hub de Gestão e Financeiro
  financialHub, // Hub de Gestão e Financeiro
  // Financial Hub submenu items
  financialDashboard, // Dashboard Financeiro
  costCenterManagement, // Centro de Custos
  sellerDashboard, // Dashboard do Vendedor
  sellerKanban, // Kanban do Vendedor
  
  // Infotravel Integration
  infotravel, // Integração Infotravel
  
  // AI Assistant
  aiAssistant, // Assistente de IA
}

// StateProvider para gerenciar a página atual do dashboard
final dashboardPageProvider =
    StateProvider<DashboardPage>((ref) => DashboardPage.home);
