import 'package:flutter/material.dart';
import 'dart:async';
import '../utils/timezone_utils.dart';
import '../design/design_tokens.dart';

class DigitalClockWidget extends StatefulWidget {
  final bool compact;
  const DigitalClockWidget({super.key, this.compact = false});

  @override
  State<DigitalClockWidget> createState() => _DigitalClockWidgetState();
}

class _DigitalClockWidgetState extends State<DigitalClockWidget> {
  Timer? _timer;
  Map<String, String> _timezoneInfo = {};

  @override
  void initState() {
    super.initState();
    _updateTime();
    // Atualiza a cada segundo
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateTime();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateTime() {
    setState(() {
      _timezoneInfo = TimezoneUtils.getTimezoneInfo();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool compact = widget.compact;
    final EdgeInsets containerPadding = compact ? const EdgeInsets.all(12) : const EdgeInsets.all(16);
    final double titleIconSize = compact ? DesignTokens.iconSizeSm : 20;
    final TextStyle titleStyle = compact
        ? DesignTokens.titleSmall.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          )
        : DesignTokens.headlineSmall.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          );
    final TextStyle timeStyle = compact
        ? DesignTokens.titleLarge.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w700,
            fontFeatures: const [FontFeature.tabularFigures()],
          )
        : DesignTokens.headlineMedium.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w700,
            fontFeatures: const [FontFeature.tabularFigures()],
          );
    final double insideIconSize = compact ? DesignTokens.iconSizeSm : 16;
    final double verticalSpacing = compact ? 8 : 16;
    return Container(
      padding: containerPadding,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Título
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: titleIconSize,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Horários Mundiais',
                style: titleStyle,
              ),
            ],
          ),
          SizedBox(height: verticalSpacing),
          
          // Horários em linha horizontal
          Row(
            children: [
              Expanded(
                child: _buildTimeZoneCard(
                  'Estados Unidos',
                  _timezoneInfo['newYorkTime'] ?? '--:--',
                  'Nova York',
                  Icons.location_city,
                  Colors.orange,
                  timeStyle,
                  insideIconSize,
                ),
              ),
              SizedBox(width: compact ? 12 : 16),
              Expanded(
                child: _buildTimeZoneCard(
                  'Brasil',
                  _timezoneInfo['saoPauloTime'] ?? '--:--',
                  'São Paulo',
                  Icons.location_on,
                  Theme.of(context).colorScheme.primary,
                  timeStyle,
                  insideIconSize,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeZoneCard(
    String country,
    String time,
    String city,
    IconData icon,
    Color accentColor,
    TextStyle timeTextStyle,
    double iconSize,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              size: iconSize,
              color: accentColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  country,
                  style: DesignTokens.bodySmall.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  city,
                  style: DesignTokens.bodySmall.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: timeTextStyle.copyWith(color: accentColor),
          ),
        ],
      ),
    );
  }
}