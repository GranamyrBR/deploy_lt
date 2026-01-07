import 'package:flutter/material.dart';

class ResponsiveUtils {
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 768;
  }

  static bool isTablet(BuildContext context) {
    return MediaQuery.of(context).size.width >= 768 && 
           MediaQuery.of(context).size.width < 1024;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= 1024;
  }

  // Detecta MacBook 13,3" e telas similares (1280x800)
  static bool isSmallDesktop(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return size.width >= 1024 && size.width <= 1366 && size.height <= 900;
  }

  static bool isSmallScreen(BuildContext context) {
    return MediaQuery.of(context).size.width < 600;
  }

  static bool isMediumScreen(BuildContext context) {
    return MediaQuery.of(context).size.width >= 600 && 
           MediaQuery.of(context).size.width < 1200;
  }

  static bool isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width >= 1200;
  }

  // Detecta se precisa de layout compacto (altura limitada)
  static bool needsCompactLayout(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return size.height <= 900 || isSmallDesktop(context);
  }

  // Breakpoints específicos
  static const double mobileBreakpoint = 768;
  static const double tabletBreakpoint = 1024;
  static const double desktopBreakpoint = 1200;
  static const double smallDesktopBreakpoint = 1366;

  // Espaçamentos responsivos
  static EdgeInsets getScreenPadding(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.all(16.0);
    } else if (isTablet(context)) {
      return const EdgeInsets.all(24.0);
    } else {
      return const EdgeInsets.all(32.0);
    }
  }

  static EdgeInsets getCardPadding(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.all(16.0);
    } else if (isTablet(context)) {
      return const EdgeInsets.all(20.0);
    } else {
      return const EdgeInsets.all(24.0);
    }
  }

  static double getCardSpacing(BuildContext context) {
    if (isMobile(context)) {
      return 12.0;
    } else if (isTablet(context)) {
      return 16.0;
    } else {
      return 24.0;
    }
  }

  // Grid responsivo
  static int getGridCrossAxisCount(BuildContext context, {int mobile = 1, int tablet = 2, int desktop = 3}) {
    if (isMobile(context)) {
      return mobile;
    } else if (isTablet(context)) {
      return tablet;
    } else {
      return desktop;
    }
  }

  // Aspect ratio responsivo
  static double getCardAspectRatio(BuildContext context, {double mobile = 1.2, double tablet = 1.5, double desktop = 1.8}) {
    if (isMobile(context)) {
      return mobile;
    } else if (isTablet(context)) {
      return tablet;
    } else {
      return desktop;
    }
  }

  // Tamanhos de fonte responsivos
  static double getResponsiveFontSize(BuildContext context, {
    double mobile = 14,
    double tablet = 16,
    double desktop = 18,
  }) {
    if (isMobile(context)) {
      return mobile;
    } else if (isTablet(context)) {
      return tablet;
    } else {
      return desktop;
    }
  }

  // Altura de containers responsiva
  static double getContainerHeight(BuildContext context, {
    double mobile = 200,
    double tablet = 300,
    double desktop = 400,
  }) {
    if (isMobile(context)) {
      return mobile;
    } else if (isTablet(context)) {
      return tablet;
    } else {
      return desktop;
    }
  }

  // Largura máxima de conteúdo
  static double getMaxContentWidth(BuildContext context) {
    if (isMobile(context)) {
      return double.infinity;
    } else if (isTablet(context)) {
      return 800;
    } else {
      return 1200;
    }
  }

  // Sidebar width responsiva
  static double getSidebarWidth(BuildContext context) {
    if (isMobile(context)) {
      return 0; // Mobile não tem sidebar fixa
    } else if (isTablet(context)) {
      return 220; // Largura aumentada para melhor leitura
    } else {
      return 240; // Largura aumentada para melhor leitura
    }
  }

  // Layout responsivo para cards
  static Widget responsiveCardLayout(BuildContext context, {
    required List<Widget> children,
    double spacing = 16,
  }) {
    if (isMobile(context)) {
      return Column(
        children: children.map((child) => Padding(
          padding: EdgeInsets.only(bottom: spacing),
          child: child,
        )).toList(),
      );
    } else {
      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: children,
      );
    }
  }

  // Layout responsivo para tabelas
  static Widget responsiveTableLayout(BuildContext context, {
    required Widget mobileLayout,
    required Widget desktopLayout,
  }) {
    if (isMobile(context)) {
      return mobileLayout;
    } else {
      return desktopLayout;
    }
  }

  // Animações responsivas
  static Duration getAnimationDuration(BuildContext context) {
    if (isMobile(context)) {
      return const Duration(milliseconds: 200);
    } else {
      return const Duration(milliseconds: 300);
    }
  }

  // Curvas de animação responsivas
  static Curve getAnimationCurve(BuildContext context) {
    if (isMobile(context)) {
      return Curves.easeInOut;
    } else {
      return Curves.easeOutCubic;
    }
  }
}

// Widget responsivo que se adapta ao tamanho da tela
class ResponsiveWidget extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveWidget({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    if (ResponsiveUtils.isDesktop(context) && desktop != null) {
      return desktop!;
    } else if (ResponsiveUtils.isTablet(context) && tablet != null) {
      return tablet!;
    } else {
      return mobile;
    }
  }
}

// Container responsivo com largura máxima
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double? maxWidth;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.padding,
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? ResponsiveUtils.getMaxContentWidth(context),
        ),
        child: Padding(
          padding: padding ?? ResponsiveUtils.getScreenPadding(context),
          child: child,
        ),
      ),
    );
  }
}

// Grid responsivo
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final int? mobileCrossAxisCount;
  final int? tabletCrossAxisCount;
  final int? desktopCrossAxisCount;
  final double? spacing;
  final double? runSpacing;
  final double? childAspectRatio;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.mobileCrossAxisCount,
    this.tabletCrossAxisCount,
    this.desktopCrossAxisCount,
    this.spacing,
    this.runSpacing,
    this.childAspectRatio,
  });

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = ResponsiveUtils.getGridCrossAxisCount(
      context,
      mobile: mobileCrossAxisCount ?? 1,
      tablet: tabletCrossAxisCount ?? 2,
      desktop: desktopCrossAxisCount ?? 3,
    );

    final aspectRatio = childAspectRatio ?? ResponsiveUtils.getCardAspectRatio(context);
    final gridSpacing = spacing ?? ResponsiveUtils.getCardSpacing(context);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: gridSpacing,
        mainAxisSpacing: runSpacing ?? gridSpacing,
        childAspectRatio: aspectRatio,
      ),
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );
  }
}
