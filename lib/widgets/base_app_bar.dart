import 'package:flutter/material.dart';

class BaseAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color? backgroundColor;
  final List<Widget>? actions;
  final bool showBackButton;
  final PreferredSizeWidget? bottom;
  final double height;

  const BaseAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.backgroundColor,
    this.actions,
    this.showBackButton = false,
    this.bottom,
    this.height = 64.0, // Altura compacta padrão (antes era kToolbarHeight = 56)
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headerIcon = icon ?? _getDefaultIcon(title);
    final headerSubtitle = subtitle ?? _getDefaultSubtitle(title);
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark 
              ? [Colors.blue.shade900, Colors.purple.shade900]
              : [Colors.blue.shade600, Colors.purple.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            child: Row(
              children: [
                // Ícone
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(headerIcon, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                
                // Título e Subtítulo
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        headerSubtitle,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Actions
                if (showBackButton)
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Voltar',
                  ),
                if (actions != null)
                  ...actions!.map((action) => IconTheme(
                    data: const IconThemeData(color: Colors.white),
                    child: action,
                  )),
              ],
            ),
          ),
          if (bottom != null) bottom!,
        ],
      ),
    );
  }

  @override
  Size get preferredSize => bottom == null 
    ? Size.fromHeight(height)
    : Size.fromHeight(height + 48.0);
    
  // Helper: Ícone padrão
  IconData _getDefaultIcon(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('operaç')) return Icons.local_shipping;
    if (lower.contains('financ')) return Icons.attach_money;
    if (lower.contains('venda') || lower.contains('seller')) return Icons.shopping_cart;
    if (lower.contains('dashboard')) return Icons.dashboard;
    return Icons.business;
  }
  
  // Helper: Subtítulo padrão
  String _getDefaultSubtitle(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('operaç')) return 'Gestão de Operações e Rotas';
    if (lower.contains('financ')) return 'Análise Financeira e Métricas';
    if (lower.contains('venda') || lower.contains('seller')) return 'Dashboard de Vendas';
    if (lower.contains('dashboard')) return 'Visão Geral do Sistema';
    return 'Sistema de Gestão';
  }
}
