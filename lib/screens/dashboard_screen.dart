import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/responsive_utils.dart';
import '../widgets/sidebar.dart';
import '../widgets/dashboard_content.dart';
import '../widgets/base_app_bar.dart';
import '../widgets/theme_test_widget.dart';
import '../providers/dashboard_provider.dart';
import '../models/user_roles.dart';
import '../providers/auth_provider.dart';
import 'flights_screen.dart';
import 'contacts_screen.dart';
import 'drivers_screen.dart';
import 'cars_screen.dart';
import 'agencies_screen.dart';
import 'whatsapp_leads_screen.dart';
import 'users_screen.dart';
import 'sales_screen.dart';
import 'provisional_invoices_screen.dart';
import 'quotations_screen_premium.dart';
import 'quotation_tags_management_screen.dart';
import 'monday_screen.dart';
import 'global_search_screen.dart';
import 'timeline_demo_screen.dart';
import 'operations_dashboard_screen.dart';
import 'google_calendar_screen.dart';
import 'new_york_screen.dart';
import 'b2b_dashboard_screen.dart';

import 'firebase_accounts_screen.dart';
import 'services_management_screen.dart';
import 'products_management_screen.dart';
import 'hub_b2b_screen.dart';
import 'agency_ranking_screen.dart';
import 'b2b_opportunities_screen.dart';
import 'b2b_documents_screen.dart';

import 'create_sale_screen_v2.dart';
import 'financial_dashboard_screen.dart';
import 'cost_center_management_screen.dart';
import 'seller_dashboard_screen.dart';
import 'infotravel_screen.dart';
import 'ai_assistant_screen.dart';


class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _isSidebarOpen = false;
  bool _initialPageSet = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_initialPageSet) return;
      final authState = ref.read(authProvider);
      final u = authState.user;
      if (u != null) {
        final isAdmin = u.isAdmin;
        final isSeller = u.hasPermission('seller') ||
            u.hasPermission('vendor') ||
            u.hasPermission(UserRoles.VIEW_OWN_SALES);
        final current = ref.read(dashboardPageProvider);
        if (!isAdmin && isSeller && current == DashboardPage.home) {
          ref.read(dashboardPageProvider.notifier).state = DashboardPage.sellerDashboard;
        }
      }
      _initialPageSet = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentPage = ref.watch(dashboardPageProvider);
    final isMobile = ResponsiveUtils.isMobile(context);
    final sidebarWidth = ResponsiveUtils.getSidebarWidth(context);
    final authState = ref.watch(authProvider);
    final userName = authState.user?.name ?? 'Usuário';

    Widget buildContent(DashboardPage page) {
      switch (page) {
        case DashboardPage.home:
          return const DashboardContent();
        case DashboardPage.sales:
          return const SalesScreen();
        case DashboardPage.createSaleV2:
          return const CreateSaleScreenV2();
        case DashboardPage.provisionalInvoices:
          return const ProvisionalInvoicesScreen();
        case DashboardPage.quotations:
          return const QuotationsScreenPremium();
        case DashboardPage.quotationTags:
          return const QuotationTagsManagementScreen();
        case DashboardPage.contacts:
          return const ContactsScreen();
        case DashboardPage.flights:
          return const FlightsScreen();
        case DashboardPage.whatsappLeads:
          return const WhatsAppLeadsScreen();
        case DashboardPage.drivers:
          return const DriversScreen();
        case DashboardPage.cars:
          return const CarsScreen();
        case DashboardPage.agencies:
          return const AgenciesScreen();
        case DashboardPage.users:
          return const UsersScreen();
        case DashboardPage.services:
          return const ThemeTestWidget();
        case DashboardPage.monday:
          return const MondayScreen();
        case DashboardPage.globalSearch:
          return const GlobalSearchScreen();
        case DashboardPage.timelineDemo:
          return const TimelineDemoScreen();
        case DashboardPage.operations:
          return const OperationsDashboardScreen();
        // case DashboardPage.createOperationFromSale:
        //   return const CreateOperationFromSaleScreen(); // Removido - requer parâmetro sale
        case DashboardPage.googleCalendar:
          return const GoogleCalendarScreen();
        case DashboardPage.newYork:
          return const NewYorkScreen();
        case DashboardPage.b2b:
          return const B2BDashboardScreen();

        case DashboardPage.hubB2B:
          return const HubB2BScreen();
        // B2B Hub submenu screens
        case DashboardPage.hubB2BAgencyRanking:
          return const AgencyRankingScreen();
        case DashboardPage.hubB2BOpportunities:
          return const B2BOpportunitiesScreen();
        case DashboardPage.hubB2BDocuments:
          return const B2BDocumentsScreen();
        case DashboardPage.hubB2BDashboard:
          return const B2BDashboardScreen();
        case DashboardPage.hubB2BAgencies:
          return const AgenciesScreen();

        case DashboardPage.servicesManagement:
          return const ServicesManagementScreen();
        case DashboardPage.productsManagement:
          return const ProductsManagementScreen();
        case DashboardPage.firebaseAccounts:
          return const FirebaseAccountsScreen();
        case DashboardPage.financialHub:
          return const FinancialDashboardScreen();
        case DashboardPage.financialDashboard:
          return const FinancialDashboardScreen();
        case DashboardPage.costCenterManagement:
          return const CostCenterManagementScreen();
        case DashboardPage.sellerDashboard:
          return const SellerDashboardScreen();
        case DashboardPage.infotravel:
          return const InfotravelScreen();
        case DashboardPage.aiAssistant:
          return const AIAssistantScreen();
        default:
          return const Center(child: Text('Página não encontrada.'));
      }
    }

    // Layout responsivo
    if (isMobile) {
      return Scaffold(
        body: Stack(
          children: [
            // Conteúdo principal
            Container(
              color: Theme.of(context).colorScheme.surface,
              child: buildContent(currentPage),
            ),
            // Sidebar móvel (overlay)
            if (_isSidebarOpen)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.5),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 240,
                        child: Sidebar(
                          onPageChanged: (page) {
                            setState(() {
                              _isSidebarOpen = false;
                            });
                          },
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _isSidebarOpen = false;
                            });
                          },
                          child: Container(
                            color: Colors.transparent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        // App bar móvel com layout padronizado
        appBar: BaseAppBar(
          title: _getPageTitle(currentPage),
          showBackButton: false,
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: [
                  const Icon(Icons.person, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    userName,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                setState(() {
                  _isSidebarOpen = !_isSidebarOpen;
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.developer_mode),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Sistema em modo desenvolvimento'),
                    backgroundColor: Colors.blue,
                  ),
                );
              },
            ),
          ],
        ),
      );
    } else {
      // Layout desktop/tablet
      return Scaffold(
        body: Row(
          children: [
            // Sidebar fixa
            SizedBox(
              width: sidebarWidth,
              child: const Sidebar(),
            ),
            // Conteúdo principal
            Expanded(
              child: Container(
                color: Theme.of(context).colorScheme.surface,
                child: Column(
                  children: [
                    Expanded(
                      child: buildContent(currentPage),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  String _getPageTitle(DashboardPage page) {
    switch (page) {
      case DashboardPage.home:
        return 'Dashboard';
      case DashboardPage.sales:
        return 'Vendas Realizadas';
      case DashboardPage.createSaleV2:
        return 'Nova Venda V2';
      case DashboardPage.provisionalInvoices:
        return 'Faturas Provisórias';
      case DashboardPage.quotations:
        return 'Cotações';
      case DashboardPage.quotationTags:
        return 'Gerenciar Tags';
      case DashboardPage.contacts:
        return 'Clientes';
      case DashboardPage.flights:
        return 'Voos';
      case DashboardPage.whatsappLeads:
        return 'Leads WhatsApp';
      case DashboardPage.drivers:
        return 'Motoristas';
      case DashboardPage.cars:
        return 'Carros';
      case DashboardPage.agencies:
        return 'Agências';
      case DashboardPage.users:
        return 'Usuários';
      case DashboardPage.services:
        return 'Serviços';
      case DashboardPage.monday:
        return 'Monday';
      case DashboardPage.globalSearch:
        return 'Busca Global';
      case DashboardPage.timelineDemo:
        return 'Timeline Demo';
      case DashboardPage.operations:
        return 'Operações';
      // case DashboardPage.createOperationFromSale:
      //   return 'Criar Operação da Venda'; // Removido - requer parâmetro sale
      case DashboardPage.googleCalendar:
        return 'Google Calendar';
      case DashboardPage.newYork:
        return 'Nova York';
      case DashboardPage.b2b:
        return 'Dashboard B2B';

      case DashboardPage.hubB2B:
        return 'Hub B2B';
      // B2B Hub submenu titles
      case DashboardPage.hubB2BAgencyRanking:
        return 'Ranking de Agências';
      case DashboardPage.hubB2BOpportunities:
        return 'Oportunidades B2B';
      case DashboardPage.hubB2BDocuments:
        return 'Documentos B2B';
      case DashboardPage.hubB2BDashboard:
        return 'Dashboard B2B';
      case DashboardPage.hubB2BAgencies:
        return 'Agências';

      case DashboardPage.servicesManagement:
        return 'Gerenciamento de Serviços';
      case DashboardPage.productsManagement:
        return 'Gerenciamento de Produtos';
      case DashboardPage.firebaseAccounts:
        return 'Contas Firebase';
      case DashboardPage.financialHub:
        return 'Hub Financeiro';
      case DashboardPage.financialDashboard:
        return 'Dashboard Financeiro';
      case DashboardPage.costCenterManagement:
        return 'Centro de Custos';
      case DashboardPage.sellerDashboard:
        return 'Dashboard do Vendedor';
      case DashboardPage.aiAssistant:
        return 'Assistente de IA';
      default:
        return 'Dashboard';
    }
  }
}
