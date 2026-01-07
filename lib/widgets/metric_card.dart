import 'package:flutter/material.dart';
import '../design/design_tokens.dart';
import '../utils/responsive_utils.dart';
import 'base_components.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

class MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String percentage;
  final bool isPositive;
  final Color color;
  final IconData icon;
  final double? numericValue;

  const MetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.percentage,
    required this.isPositive,
    required this.color,
    required this.icon,
    this.numericValue,
  });

  Color _getGradientColor() {
    if (numericValue == null) return color;

    // Gradiente baseado no valor: vermelho (baixo) -> verde (alto)
    if (numericValue! <= 0) return Colors.red;
    if (numericValue! >= 100000) return Colors.green;

    // Interpolação entre vermelho e verde
    final ratio = (numericValue! / 100000).clamp(0.0, 1.0);
    return Color.lerp(Colors.red, Colors.green, ratio)!;
  }

  @override
  Widget build(BuildContext context) {
    final gradientColor = _getGradientColor();
    final needsCompact = ResponsiveUtils.needsCompactLayout(context);
    final isMobile = ResponsiveUtils.isMobile(context);

    // Ajustes responsivos
    final cardPadding =
        needsCompact ? const EdgeInsets.all(16) : const EdgeInsets.all(20);

    final iconSize = needsCompact ? 24.0 : 32.0;
    final iconContainerSize = needsCompact ? 40.0 : 48.0;
    final titleFontSize = needsCompact ? 11.0 : 13.0;
    final valueFontSize = needsCompact ? 20.0 : 28.0;
    final percentageFontSize = needsCompact ? 10.0 : 12.0;
    final gaugeHeight = needsCompact ? 16.0 : 20.0;

    return ModernCard(
      child: Container(
        padding: cardPadding,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header com ícone e título
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ícone com background colorido
                Container(
                  width: iconContainerSize,
                  height: iconContainerSize,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        gradientColor.withValues(alpha: 0.2),
                        gradientColor.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: gradientColor.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    icon,
                    size: iconSize,
                    color: gradientColor,
                  ),
                ),
                const SizedBox(width: 12),
                // Título e valor
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Título
                      Text(
                        title,
                        style: DesignTokens.bodyMedium.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                          fontSize: titleFontSize,
                          letterSpacing: 0.5,
                        ),
                        maxLines: 2,
                        softWrap: true,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // Valor principal
                      Text(
                        value,
                        style: DesignTokens.headlineSmall.copyWith(
                          color: gradientColor,
                          fontWeight: FontWeight.bold,
                          fontSize: valueFontSize,
                          height: 1.1,
                          letterSpacing: -0.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Barra de progresso
            if (numericValue != null && numericValue! > 0) ...[
              SizedBox(
                height: gaugeHeight,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(gaugeHeight / 2),
                  child: SfLinearGauge(
                    minimum: 0,
                    maximum: numericValue! * 1.2,
                    showTicks: false,
                    showLabels: false,
                    axisTrackStyle: LinearAxisTrackStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withValues(alpha: 0.5),
                      edgeStyle: LinearEdgeStyle.bothCurve,
                    ),
                    ranges: [
                      LinearGaugeRange(
                        startValue: 0,
                        endValue: numericValue!,
                        color: gradientColor,
                        edgeStyle: LinearEdgeStyle.bothCurve,
                        position: LinearElementPosition.cross,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],

            // Informação adicional
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: needsCompact ? 8 : 10,
                vertical: needsCompact ? 4 : 6,
              ),
              decoration: BoxDecoration(
                color: isPositive
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isPositive
                      ? Colors.green.withValues(alpha: 0.2)
                      : Colors.red.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Text(
                percentage,
                style: DesignTokens.bodyMedium.copyWith(
                  color: isPositive ? Colors.green : Colors.red,
                  fontWeight: FontWeight.w600,
                  fontSize: percentageFontSize,
                  letterSpacing: 0.3,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
                softWrap: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
