import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/dashboard_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/app_version_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/responsive_utils.dart';
import 'package:flutter/foundation.dart'; // Added for kDebugMode
import 'statistics_modal.dart';

// Data class for navigation items
class _NavItemData {
  final IconData icon;
  final String title;
  final DashboardPage page;
  final String requiredPermission;
  final Color? iconColor;
  final bool isSubmenuItem;
  final String parentTitle;

  _NavItemData({
    required this.icon,
    required this.title,
    required this.page,
    required this.requiredPermission,
    this.iconColor,
    this.isSubmenuItem = false,
    this.parentTitle = '',
  });
}

// Function to get colored icon for navigation items
Widget _buildColoredIcon(_NavItemData item, bool isSelected, ThemeData theme) {
  const iconSize = 20.0;
  final primary = theme.colorScheme.primary;
  final onSurface = theme.colorScheme.onSurface;

  // Default color logic
  Color iconColor = isSelected ? primary : onSurface.withValues(alpha: 0.7);

  // Override with specific colors for certain items
  if (item.iconColor != null) {
    iconColor =
        isSelected ? item.iconColor! : item.iconColor!.withValues(alpha: 0.8);
  }

  // Special handling for WhatsApp icon
  if (item.title == 'WhatsApp Leads') {
    return Container(
      width: iconSize,
      height: iconSize,
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFF25D366)
            : const Color(0xFF25D366).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Icon(
        Icons.chat_bubble,
        size: iconSize * 0.6,
        color: Colors.white,
      ),
    );
  }

  // Special handling for Google Calendar icon
  if (item.title == 'Google Calendar') {
    return Icon(
      Icons.calendar_today,
      size: iconSize,
      color: isSelected
          ? const Color(0xFF4285F4)
          : const Color(0xFF4285F4).withValues(alpha: 0.8),
    );
  }

  return Icon(
    item.icon,
    size: iconSize,
    color: iconColor,
  );
}

class Sidebar extends ConsumerStatefulWidget {
  final Function(DashboardPage)? onPageChanged;

  const Sidebar({super.key, this.onPageChanged});

  @override
  ConsumerState<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends ConsumerState<Sidebar> {
  Set<String> expandedParents = {};
  bool _expandedInitialized = false;

  void toggleSubmenu(String title) {
    setState(() {
      if (expandedParents.contains(title)) {
        expandedParents.remove(title);
      } else {
        expandedParents.add(title);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentPage = ref.watch(dashboardPageProvider);
    final themeNotifier = ref.watch(themeProvider.notifier);
    final currentThemeMode = ref.watch(themeProvider);
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final isMobile = ResponsiveUtils.isMobile(context);
    final isTablet = ResponsiveUtils.isTablet(context);

    // Define the list of navigation items with permissions (em ordem alfabética)
    final List<_NavItemData> navItems = [
      _NavItemData(
          icon: Icons.search,
          title: 'Busca Global',
          page: DashboardPage.globalSearch,
          requiredPermission: 'view_dashboard'),

      _NavItemData(
          icon: Icons.dashboard,
          title: 'Dashboards',
          page: DashboardPage.home,
          requiredPermission: 'view_dashboard',
          iconColor: const Color(0xFF2196F3)),
      _NavItemData(
          icon: Icons.analytics,
          title: 'Gestão',
          page: DashboardPage.home,
          requiredPermission: 'view_dashboard',
          iconColor: const Color(0xFF1976D2),
          isSubmenuItem: true,
          parentTitle: 'Dashboards'),
      _NavItemData(
          icon: Icons.storefront,
          title: 'Vendedor',
          page: DashboardPage.sellerDashboard,
          requiredPermission: 'view_own_sales',
          iconColor: const Color(0xFF4CAF50),
          isSubmenuItem: true,
          parentTitle: 'Dashboards'),
      _NavItemData(
          icon: Icons.hub,
          title: 'B2B',
          page: DashboardPage.hubB2B,
          requiredPermission: 'view_dashboard',
          iconColor: const Color(0xFF3F51B5)),
      _NavItemData(
          icon: Icons.business,
          title: 'Agências',
          page: DashboardPage.hubB2BAgencies,
          requiredPermission: 'view_dashboard',
          iconColor: const Color(0xFF1E88E5),
          isSubmenuItem: true,
          parentTitle: 'B2B'),
      _NavItemData(
          icon: Icons.dashboard,
          title: 'Dashboard B2B',
          page: DashboardPage.hubB2BDashboard,
          requiredPermission: 'view_dashboard',
          iconColor: const Color(0xFF3949AB),
          isSubmenuItem: true,
          parentTitle: 'B2B'),
      _NavItemData(
          icon: Icons.travel_explore,
          title: 'Infotravel',
          page: DashboardPage.infotravel,
          requiredPermission: 'view_dashboard',
          iconColor: const Color(0xFF00ACC1),
          isSubmenuItem: true,
          parentTitle: 'B2B'),
      _NavItemData(
          icon: Icons.description,
          title: 'Documentos',
          page: DashboardPage.hubB2BDocuments,
          requiredPermission: 'view_dashboard',
          iconColor: const Color(0xFF5E35B1),
          isSubmenuItem: true,
          parentTitle: 'B2B'),
      _NavItemData(
          icon: Icons.receipt,
          title: 'Faturas',
          page: DashboardPage.provisionalInvoices,
          requiredPermission: 'view_invoice',
          iconColor: const Color(0xFFFF9800),
          isSubmenuItem: true,
          parentTitle: 'B2B'),
      _NavItemData(
          icon: Icons.business_center,
          title: 'Oportunidades',
          page: DashboardPage.hubB2BOpportunities,
          requiredPermission: 'view_dashboard',
          iconColor: const Color(0xFF00897B),
          isSubmenuItem: true,
          parentTitle: 'Hub B2B'),
      _NavItemData(
          icon: Icons.leaderboard,
          title: 'Ranking de Agências',
          page: DashboardPage.hubB2BAgencyRanking,
          requiredPermission: 'view_dashboard',
          iconColor: const Color(0xFFFBC02D),
          isSubmenuItem: true,
          parentTitle: 'Hub B2B'),
      _NavItemData(
          icon: Icons.people_alt,
          title: 'CRM',
          page: DashboardPage.contacts,
          requiredPermission: 'view_dashboard',
          iconColor: const Color(0xFF009688)),
      _NavItemData(
          icon: Icons.people,
          title: 'Contatos',
          page: DashboardPage.contacts,
          requiredPermission: 'view_contact',
          iconColor: const Color(0xFF2196F3),
          isSubmenuItem: true,
          parentTitle: 'CRM'),
      _NavItemData(
          icon: Icons.chat_bubble,
          title: 'WhatsApp Leads',
          page: DashboardPage.whatsappLeads,
          requiredPermission: 'view_leads',
          isSubmenuItem: true,
          parentTitle: 'CRM'),
      _NavItemData(
          icon: Icons.request_quote,
          title: 'Cotações',
          page: DashboardPage.quotations,
          requiredPermission: 'view_own_sales',
          iconColor: const Color(0xFFFF9800),
          isSubmenuItem: true,
          parentTitle: 'CRM'),
      _NavItemData(
          icon: Icons.label,
          title: 'Gerenciar Tags',
          page: DashboardPage.quotationTags,
          requiredPermission: 'view_own_sales',
          iconColor: const Color(0xFF9C27B0),
          isSubmenuItem: true,
          parentTitle: 'CRM'),
      _NavItemData(
          icon: Icons.tune,
          title: 'Configurações',
          page: DashboardPage.servicesManagement,
          requiredPermission: 'view_dashboard',
          iconColor: const Color(0xFF607D8B)),
      _NavItemData(
          icon: Icons.cloud,
          title: 'Contas Firebase',
          page: DashboardPage.firebaseAccounts,
          requiredPermission: 'view_dashboard',
          iconColor: const Color(0xFFFF5722),
          isSubmenuItem: true,
          parentTitle: 'Configurações'),
      _NavItemData(
          icon: Icons.inventory,
          title: 'Gerenciar Produtos',
          page: DashboardPage.productsManagement,
          requiredPermission: 'view_dashboard',
          iconColor: const Color(0xFF4CAF50),
          isSubmenuItem: true,
          parentTitle: 'Configurações'),
      _NavItemData(
          icon: Icons.room_service,
          title: 'Gerenciar Serviços',
          page: DashboardPage.servicesManagement,
          requiredPermission: 'view_dashboard',
          iconColor: const Color(0xFF2196F3),
          isSubmenuItem: true,
          parentTitle: 'Configurações'),
      _NavItemData(
          icon: Icons.admin_panel_settings,
          title: 'Usuários',
          page: DashboardPage.users,
          requiredPermission: 'manage_users',
          iconColor: const Color(0xFF795548),
          isSubmenuItem: true,
          parentTitle: 'Configurações'),
      _NavItemData(
          icon: Icons.account_balance,
          title: 'Financeiro',
          page: DashboardPage.financialHub,
          requiredPermission: 'view_dashboard',
          iconColor: const Color(0xFF4CAF50)),
      _NavItemData(
          icon: Icons.account_balance_wallet,
          title: 'Centro de Custos',
          page: DashboardPage.costCenterManagement,
          requiredPermission: 'view_dashboard',
          iconColor: const Color(0xFF388E3C),
          isSubmenuItem: true,
          parentTitle: 'Financeiro'),
      _NavItemData(
          icon: Icons.dashboard,
          title: 'Dashboard Financeiro',
          page: DashboardPage.financialDashboard,
          requiredPermission: 'view_dashboard',
          iconColor: const Color(0xFF2E7D32),
          isSubmenuItem: true,
          parentTitle: 'Financeiro'),
      _NavItemData(
          icon: Icons.settings,
          title: 'Operações',
          page: DashboardPage.operations,
          requiredPermission: 'view_operations',
          iconColor: const Color(0xFF607D8B)),
      _NavItemData(
          icon: Icons.directions_car,
          title: 'Carros',
          page: DashboardPage.cars,
          requiredPermission: 'view_driver',
          iconColor: const Color(0xFF795548),
          isSubmenuItem: true,
          parentTitle: 'Operações'),
      _NavItemData(
          icon: Icons.calendar_today,
          title: 'Google Calendar',
          page: DashboardPage.googleCalendar,
          requiredPermission: 'view_calendar',
          iconColor: const Color(0xFF4285F4),
          isSubmenuItem: true,
          parentTitle: 'Operações'),
      _NavItemData(
          icon: Icons.drive_eta,
          title: 'Motoristas',
          page: DashboardPage.drivers,
          requiredPermission: 'view_driver',
          iconColor: const Color(0xFF9C27B0),
          isSubmenuItem: true,
          parentTitle: 'Operações'),
      _NavItemData(
          icon: Icons.assignment,
          title: 'Operações',
          page: DashboardPage.operations,
          requiredPermission: 'view_operations',
          isSubmenuItem: true,
          parentTitle: 'Operações'),
      _NavItemData(
          icon: Icons.flight,
          title: 'Voos',
          page: DashboardPage.flights,
          requiredPermission: 'view_flights',
          iconColor: const Color(0xFF00BCD4),
          isSubmenuItem: true,
          parentTitle: 'Operações'),
      _NavItemData(
          icon: Icons.attach_money,
          title: 'Vendas',
          page: DashboardPage.sales,
          requiredPermission: 'view_own_sales',
          iconColor: const Color(0xFF4CAF50)),
      _NavItemData(
          icon: Icons.add_shopping_cart,
          title: 'Nova Venda',
          page: DashboardPage.createSaleV2,
          requiredPermission: 'create_sale',
          iconColor: const Color(0xFF2E7D32),
          isSubmenuItem: true,
          parentTitle: 'Vendas'),
      _NavItemData(
          icon: Icons.bar_chart,
          title: 'Vendas Realizadas',
          page: DashboardPage.sales,
          requiredPermission: 'view_own_sales',
          isSubmenuItem: true,
          parentTitle: 'Vendas'),
      _NavItemData(
          icon: Icons.location_city,
          title: 'Nova York',
          page: DashboardPage.newYork,
          requiredPermission: 'view_dashboard',
          iconColor: const Color(0xFFE91E63)),
      
      // AI Assistant - Nova categoria
      _NavItemData(
          icon: Icons.smart_toy,
          title: 'Assistente de IA',
          page: DashboardPage.aiAssistant,
          requiredPermission: 'view_dashboard',
          iconColor: const Color(0xFF9C27B0)),
      _NavItemData(
          icon: Icons.bar_chart,
          title: 'Estatísticas',
          page: DashboardPage.home,
          requiredPermission: 'view_dashboard',
          iconColor: const Color(0xFF03A9F4)),
      
    ];

    final accessibleItems = navItems.where((item) {
      if (user == null) return item.requiredPermission.isEmpty;
      final rp = item.requiredPermission;
      final aliasSeller = (rp == 'view_own_sales' || rp == 'create_sale') &&
          (user.hasPermission('seller') || user.hasPermission('vendor'));
      bool permOk(String p) {
        final a = (p == 'view_own_sales' || p == 'create_sale') &&
            (user.hasPermission('seller') || user.hasPermission('vendor'));
        final manageCounterpart = p.startsWith('view_') ? 'manage_${p.substring(5)}' : '';
        final hasManage = manageCounterpart.isNotEmpty && user.hasPermission(manageCounterpart);
        return user.hasPermission(p) || a || hasManage || user.isAdmin;
      }
      final hasSubmenuAccess = navItems.any((i) => i.isSubmenuItem && i.parentTitle == item.title && permOk(i.requiredPermission));
      final has = permOk(rp) || (!item.isSubmenuItem && hasSubmenuAccess);
      return has;
    }).toList();

    String? defaultExpandedParent;
    for (final i in accessibleItems) {
      if (i.page == currentPage && i.isSubmenuItem) {
        defaultExpandedParent = i.parentTitle;
        break;
      }
    }
    if (!_expandedInitialized) {
      if (defaultExpandedParent != null) {
        expandedParents.add(defaultExpandedParent);
      }
      _expandedInitialized = true;
    }

    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          // Header com logo - mais compacto
          Container(
            padding: EdgeInsets.all(isMobile
                ? 12
                : isTablet
                    ? 16
                    : 20),
            child: Row(
              children: [
                Container(
                  width: isMobile
                      ? 32
                      : isTablet
                          ? 36
                          : 40,
                  height: isMobile
                      ? 32
                      : isTablet
                          ? 36
                          : 40,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      'web/icons/lecotour.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.directions_car,
                          color: Colors.white,
                          size: isMobile
                              ? 16
                              : isTablet
                                  ? 18
                                  : 20,
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                if (!isMobile) ...[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lecotour',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                fontSize: isTablet ? 18 : 20,
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context).colorScheme.onSurface,
                                letterSpacing: -0.5,
                              ),
                        ),
                        Text(
                          'Dashboard',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontSize: 13,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.7),
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.2,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Navegação - mais compacta
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 6),
              itemCount: accessibleItems.length,
              itemBuilder: (context, index) {
                final item = accessibleItems[index];

                // Skip submenu items unless their parent is hovered, expanded, or one of them is selected
                if (item.isSubmenuItem &&
                    !expandedParents.contains(item.parentTitle)) {
                  return const SizedBox.shrink();
                }

                final isSelected = currentPage == item.page;
                final primary = Theme.of(context).colorScheme.primary;
                final onSurface = Theme.of(context).colorScheme.onSurface;
                final selectedBg =
                    Theme.of(context).brightness == Brightness.dark
                        ? primary.withValues(alpha: 0.2)
                        : primary.withValues(alpha: 0.12);
                final selectedBorder = primary.withValues(alpha: 0.4);

                // Check if this item has submenu items
                final hasSubmenu = accessibleItems
                    .any((i) => i.isSubmenuItem && i.parentTitle == item.title);

                return MouseRegion(
                  onEnter: (_) {},
                  onExit: (_) {},
                  child: Container(
                    margin: EdgeInsets.symmetric(
                      horizontal: item.isSubmenuItem ? 16 : 8,
                      vertical: 2,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () {
                          if (hasSubmenu && !item.isSubmenuItem) {
                            // Toggle submenu expansion on click for parent items
                            toggleSubmenu(item.title);
                          } else {
                            if (item.title == 'Estatísticas') {
                              showDialog(
                                context: context,
                                builder: (context) => const StatisticsModal(),
                              );
                            } else {
                              // Navigate to the page for submenu items or non-submenu items
                              ref
                                  .read(dashboardPageProvider.notifier)
                                  .update((state) => item.page);
                              widget.onPageChanged?.call(item.page);
                            }

                            // If this is a submenu item, keep its parent expanded
                            if (item.isSubmenuItem) {
                              setState(() {
                                expandedParents.add(item.parentTitle);
                              });
                            }
                          }
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: isMobile
                                ? 8
                                : item.isSubmenuItem
                                    ? 8
                                    : 12,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected ? selectedBg : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: isSelected
                                ? Border.all(
                                    color: selectedBorder,
                                    width: 1,
                                  )
                                : null,
                          ),
                          child: Row(
                            children: [
                              _buildColoredIcon(
                                  item, isSelected, Theme.of(context)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  item.isSubmenuItem
                                      ? '• ${item.title}'
                                      : item.title,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontSize: isMobile
                                            ? 14
                                            : item.isSubmenuItem
                                                ? 13
                                                : 15,
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.w500,
                                        color: isSelected ? primary : onSurface,
                                        letterSpacing: isSelected ? -0.1 : 0.0,
                                      ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (hasSubmenu)
                                GestureDetector(
                                  onTap: () {
                                    // Toggle submenu expansion on arrow click
                                    toggleSubmenu(item.title);
                                  },
                                  child: Icon(
                                    (expandedParents.contains(item.title))
                                        ? Icons.keyboard_arrow_down
                                        : Icons.keyboard_arrow_right,
                                    size: 16,
                                    color: onSurface.withValues(alpha: 0.7),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Footer com controle - melhor contraste
          if (!isMobile)
            Container(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  // Informações do sistema (modo desenvolvimento)
                  if (kDebugMode) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.blue.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'MODO DESENVOLVIMENTO',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue,
                                ),
                          ),
                          Text(
                            'Acesso total habilitado',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.blue.withValues(alpha: 0.7),
                                    ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Botão de tema - melhor contraste
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => themeNotifier.toggleTheme(),
                      icon: Icon(
                        currentThemeMode == ThemeMode.dark
                            ? Icons.light_mode
                            : Icons.dark_mode,
                        size: 16,
                      ),
                      label: Text(
                        currentThemeMode == ThemeMode.dark
                            ? 'Modo Claro'
                            : 'Modo Escuro',
                        style: const TextStyle(fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor:
                            Theme.of(context).colorScheme.onPrimary,
                        elevation: 2,
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Botão de desenvolvimento
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Sistema em modo desenvolvimento - Acesso total habilitado'),
                            backgroundColor: Colors.blue,
                          ),
                        );
                      },
                      icon: const Icon(Icons.developer_mode, size: 16),
                      label: const Text(
                        'Modo Dev',
                        style: TextStyle(fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Versão do App
                  Consumer(
                    builder: (context, ref, child) {
                      final versionAsync = ref.watch(appVersionProvider);
                      
                      return versionAsync.when(
                        data: (version) => Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    size: 14,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Versão do Sistema',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'v${version.version}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                version.buildTime.toString().split(' ')[0], // Mostra data do build
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      );
                    },
                  ),

                  const SizedBox(height: 12),

                  // Botão de Logout
                  Consumer(
                    builder: (context, ref, child) {
                      return SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            // Confirmar logout
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Sair do Sistema'),
                                content: const Text('Tem certeza que deseja sair?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(false),
                                    child: const Text('Cancelar'),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: () => Navigator.of(context).pop(true),
                                    icon: const Icon(Icons.logout),
                                    label: const Text('Sair'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            );

                            if (confirmed == true) {
                              await ref.read(authProvider.notifier).logout();
                              if (context.mounted) {
                                Navigator.of(context).pushReplacementNamed('/login');
                              }
                            }
                          },
                          icon: const Icon(Icons.logout, size: 16),
                          label: const Text(
                            'Sair',
                            style: TextStyle(fontSize: 13),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
