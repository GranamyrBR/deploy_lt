import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tipografia moderna para o dashboard LecoTour
/// Baseada na fonte Inter, muito popular em dashboards profissionais
class ModernTypography {
  // Fonte principal
  static const String _primaryFont = 'Inter';
  
  // Fallback fonts
  static const List<String> _fallbackFonts = [
    '-apple-system',
    'BlinkMacSystemFont',
    'Segoe UI',
    'Roboto',
    'Helvetica Neue',
    'Arial',
    'sans-serif',
  ];

  /// Configuração de fonte principal
  static TextStyle get primaryFont => GoogleFonts.inter(
    fontWeight: FontWeight.w400,
  );

  /// Display Large - Para títulos principais
  static TextStyle displayLarge(BuildContext context) => GoogleFonts.inter(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    color: Theme.of(context).colorScheme.onSurface,
  );

  /// Display Medium - Para subtítulos grandes
  static TextStyle displayMedium(BuildContext context) => GoogleFonts.inter(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.25,
    color: Theme.of(context).colorScheme.onSurface,
  );

  /// Display Small - Para títulos de seção
  static TextStyle displaySmall(BuildContext context) => GoogleFonts.inter(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.25,
    color: Theme.of(context).colorScheme.onSurface,
  );

  /// Headline Large - Para títulos de página
  static TextStyle headlineLarge(BuildContext context) => GoogleFonts.inter(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.25,
    color: Theme.of(context).colorScheme.onSurface,
  );

  /// Headline Medium - Para títulos de card
  static TextStyle headlineMedium(BuildContext context) => GoogleFonts.inter(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.15,
    color: Theme.of(context).colorScheme.onSurface,
  );

  /// Headline Small - Para títulos menores
  static TextStyle headlineSmall(BuildContext context) => GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.15,
    color: Theme.of(context).colorScheme.onSurface,
  );

  /// Title Large - Para títulos de navegação
  static TextStyle titleLarge(BuildContext context) => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.15,
    color: Theme.of(context).colorScheme.onSurface,
  );

  /// Title Medium - Para títulos de item
  static TextStyle titleMedium(BuildContext context) => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.1,
    color: Theme.of(context).colorScheme.onSurface,
  );

  /// Title Small - Para títulos pequenos
  static TextStyle titleSmall(BuildContext context) => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.1,
    color: Theme.of(context).colorScheme.onSurface,
  );

  /// Body Large - Para texto principal
  static TextStyle bodyLarge(BuildContext context) => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.15,
    color: Theme.of(context).colorScheme.onSurface,
  );

  /// Body Medium - Para texto secundário
  static TextStyle bodyMedium(BuildContext context) => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
    color: Theme.of(context).colorScheme.onSurface,
  );

  /// Body Small - Para texto pequeno
  static TextStyle bodySmall(BuildContext context) => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    color: Theme.of(context).colorScheme.onSurface,
  );

  /// Label Large - Para labels grandes
  static TextStyle labelLarge(BuildContext context) => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    color: Theme.of(context).colorScheme.onSurface,
  );

  /// Label Medium - Para labels médios
  static TextStyle labelMedium(BuildContext context) => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    color: Theme.of(context).colorScheme.onSurface,
  );

  /// Label Small - Para labels pequenos
  static TextStyle labelSmall(BuildContext context) => GoogleFonts.inter(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    color: Theme.of(context).colorScheme.onSurface,
  );

  /// Sidebar Navigation - Estilo específico para navegação
  static TextStyle sidebarNavigation(BuildContext context, {bool isSelected = false}) => GoogleFonts.inter(
    fontSize: 15,
    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
    letterSpacing: isSelected ? -0.1 : 0.0,
    color: isSelected 
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.onSurface,
  );

  /// Sidebar Brand - Estilo para marca/logo
  static TextStyle sidebarBrand(BuildContext context) => GoogleFonts.inter(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    color: Theme.of(context).colorScheme.onSurface,
  );

  /// Sidebar Subtitle - Estilo para subtítulo da marca
  static TextStyle sidebarSubtitle(BuildContext context) => GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.2,
    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
  );

  /// User Info - Estilo para informações do usuário
  static TextStyle userInfo(BuildContext context) => GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
    color: Theme.of(context).colorScheme.onSurface,
  );

  /// User Role - Estilo para cargo/departamento do usuário
  static TextStyle userRole(BuildContext context) => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.2,
    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
  );

  /// Badge - Estilo para badges
  static TextStyle badge(BuildContext context, {Color? color}) => GoogleFonts.inter(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    color: color ?? Theme.of(context).colorScheme.onSurface,
  );

  /// Card Title - Estilo para títulos de cards
  static TextStyle cardTitle(BuildContext context) => GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.15,
    color: Theme.of(context).colorScheme.onSurface,
  );

  /// Card Subtitle - Estilo para subtítulos de cards
  static TextStyle cardSubtitle(BuildContext context) => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.1,
    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
  );

  /// Metric Value - Estilo para valores de métricas
  static TextStyle metricValue(BuildContext context) => GoogleFonts.inter(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.25,
    color: Theme.of(context).colorScheme.onSurface,
  );

  /// Metric Label - Estilo para labels de métricas
  static TextStyle metricLabel(BuildContext context) => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
  );

  /// Button Text - Estilo para texto de botões
  static TextStyle buttonText(BuildContext context) => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    color: Theme.of(context).colorScheme.onPrimary,
  );

  /// Input Label - Estilo para labels de input
  static TextStyle inputLabel(BuildContext context) => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    color: Theme.of(context).colorScheme.onSurface,
  );

  /// Input Text - Estilo para texto de input
  static TextStyle inputText(BuildContext context) => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.15,
    color: Theme.of(context).colorScheme.onSurface,
  );

  /// Helper Text - Estilo para texto de ajuda
  static TextStyle helperText(BuildContext context) => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
  );

  /// Error Text - Estilo para texto de erro
  static TextStyle errorText(BuildContext context) => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.4,
    color: Theme.of(context).colorScheme.error,
  );

  /// Success Text - Estilo para texto de sucesso
  static TextStyle successText(BuildContext context) => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.4,
    color: Colors.green[700],
  );

  /// Warning Text - Estilo para texto de aviso
  static TextStyle warningText(BuildContext context) => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.4,
    color: Colors.orange[700],
  );
}
