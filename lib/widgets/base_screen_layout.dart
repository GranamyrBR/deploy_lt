import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../design/design_tokens.dart';
import 'standard_app_header.dart';

class BaseScreenLayout extends ConsumerWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final List<Widget>? actions;
  final Widget child;
  final bool showBackButton;
  final bool showDrawer;
  final VoidCallback? onBackPressed;
  final Widget? searchBar;
  final Color? backgroundColor;
  final EdgeInsets? padding;

  const BaseScreenLayout({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.actions,
    required this.child,
    this.showBackButton = false,
    this.showDrawer = true,
    this.onBackPressed,
    this.searchBar,
    this.backgroundColor,
    this.padding,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Mapear título para ícone padrão se não fornecido
    final headerIcon = icon ?? _getDefaultIcon(title);
    final headerSubtitle = subtitle ?? _getDefaultSubtitle(title);
    
    return Scaffold(
      backgroundColor: backgroundColor ?? (isDark ? Colors.grey[900] : Colors.grey[50]),
      body: Column(
        children: [
          // 🆕 Usar StandardAppHeader
          StandardAppHeader(
            title: title,
            subtitle: headerSubtitle,
            icon: headerIcon,
            isDark: isDark,
            actions: [
              if (showBackButton)
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
                  tooltip: 'Voltar',
                ),
              if (actions != null) 
                ...actions!.map((action) => _wrapActionWithWhiteColor(action)),
            ],
          ),
          
          if (searchBar != null) searchBar!,
          
          Expanded(
            child: Container(
              padding: padding ?? const EdgeInsets.all(16),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
  
  // Helper: Ícone padrão baseado no título
  IconData _getDefaultIcon(String title) {
    switch (title.toLowerCase()) {
      case 'contatos':
      case 'clientes':
        return Icons.people;
      case 'vendas':
      case 'vendas realizadas':
        return Icons.shopping_cart;
      case 'operações':
        return Icons.local_shipping;
      case 'leads whatsapp':
      case 'whatsapp':
        return Icons.chat;
      case 'motoristas':
        return Icons.person;
      case 'veículos':
      case 'carros':
        return Icons.directions_car;
      case 'agências':
        return Icons.business;
      case 'usuários':
        return Icons.manage_accounts;
      case 'faturas provisórias':
        return Icons.receipt_long;
      default:
        return Icons.dashboard;
    }
  }
  
  // Helper: Subtítulo padrão baseado no título
  String _getDefaultSubtitle(String title) {
    switch (title.toLowerCase()) {
      case 'contatos':
      case 'clientes':
        return 'Gestão de Clientes e Contatos';
      case 'vendas':
      case 'vendas realizadas':
        return 'Gestão de Vendas e Pedidos';
      case 'operações':
        return 'Gestão de Operações e Rotas';
      case 'leads whatsapp':
      case 'whatsapp':
        return 'Gestão de Leads do WhatsApp';
      case 'motoristas':
        return 'Gestão de Motoristas';
      case 'veículos':
      case 'carros':
        return 'Gestão de Frota';
      case 'agências':
        return 'Gestão de Agências Parceiras';
      case 'usuários':
        return 'Gestão de Usuários do Sistema';
      case 'faturas provisórias':
        return 'Gestão de Faturas e Pagamentos';
      default:
        return 'Sistema de Gestão';
    }
  }
  
  // Helper: Garante que os ícones dos actions sejam brancos
  Widget _wrapActionWithWhiteColor(Widget action) {
    if (action is IconButton) {
      return IconButton(
        icon: IconTheme(
          data: const IconThemeData(color: Colors.white),
          child: action.icon,
        ),
        onPressed: action.onPressed,
        tooltip: action.tooltip,
      );
    }
    // Se não for IconButton, envolve em IconTheme
    return IconTheme(
      data: const IconThemeData(color: Colors.white),
      child: action,
    );
  }
}

 
