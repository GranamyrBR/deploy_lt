import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/exchange_rate_provider.dart';
import '../design/design_tokens.dart';

class ExchangeRateDisplay extends ConsumerStatefulWidget {
  const ExchangeRateDisplay({super.key});

  @override
  ConsumerState<ExchangeRateDisplay> createState() => _ExchangeRateDisplayState();
}

class _ExchangeRateDisplayState extends ConsumerState<ExchangeRateDisplay> {
  final _manualRateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Inicializar o controller com o valor do provider
    final manualRate = ref.read(manualExchangeRateProvider);
    _manualRateController.text = manualRate.toStringAsFixed(4);
  }

  @override
  void dispose() {
    _manualRateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exchangeRateAsync = ref.watch(exchangeRateProvider);
    final margin = ref.watch(tourismDollarMarginProvider);
    final tourismRate = ref.watch(tourismDollarRateProvider);
    final manualRate = ref.watch(manualExchangeRateProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Listener para atualizar o campo de texto quando o provider mudar (ex: pelo slider)
    ref.listen<double>(manualExchangeRateProvider, (previous, next) {
      if (double.tryParse(_manualRateController.text) != next) {
        _manualRateController.text = next.toStringAsFixed(4);
      }
    });
    
    // Cores baseadas no tema
    final backgroundColor = isDark ? const Color(0xFF23262F) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF181A20);
    final textSecondaryColor = isDark ? const Color(0xFFB0B3B8) : const Color(0xFF5F6368);
    final borderColor = isDark ? const Color(0xFF2C2F36) : const Color(0xFFE0E0E0);
    const primaryColor = Color(0xFFFFD600);

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(DesignTokens.radius12),
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(DesignTokens.spacing8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Text(
                      'Câmbio USD/BRL',
                      style: DesignTokens.titleMedium.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Fonte: BCB dólar',
                      style: DesignTokens.bodySmall.copyWith(
                        color: textSecondaryColor,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.refresh,
                  color: primaryColor,
                  size: 18,
                ),
                onPressed: () {
                  ref.invalidate(exchangeRateProvider);
                },
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spacing8),
          exchangeRateAsync.when(
            data: (data) {
              final bid = data['bid'] as double;
              final ask = data['ask'] as double;
              final timestamp = data['timestamp'] as String;
              final source = data['source'] as String? ?? 'API';
              final isOffline = source == 'Fallback';
              
              return Column(
                children: [
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Compra:',
                        style: DesignTokens.bodySmall.copyWith(
                          color: textSecondaryColor,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        'R\$ ${bid.toStringAsFixed(4)}',
                        style: DesignTokens.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                          color: textColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Venda:',
                        style: DesignTokens.bodySmall.copyWith(
                          color: textSecondaryColor,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        'R\$ ${ask.toStringAsFixed(4)}',
                        style: DesignTokens.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                          color: textColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: DesignTokens.spacing4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Dólar Turismo:',
                        style: DesignTokens.bodySmall.copyWith(
                          color: textSecondaryColor,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        'R\$ ${tourismRate.toStringAsFixed(4)}',
                        style: DesignTokens.bodySmall.copyWith(
                          fontWeight: FontWeight.bold,
                          color: DesignTokens.info,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: DesignTokens.spacing4),
                  // Campo manual para valor personalizado
                  Row(
                    children: [
                      Text(
                        'Valor Manual: ',
                        style: DesignTokens.bodySmall.copyWith(
                          color: textSecondaryColor,
                          fontSize: 11,
                        ),
                      ),
                      Expanded(
                        child: SizedBox(
                          height: 32,
                          child: TextFormField(
                            controller: _manualRateController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: DesignTokens.bodySmall.copyWith(
                              color: textColor,
                              fontSize: 11,
                            ),
                            decoration: InputDecoration(
                              hintText: '5.0000',
                              hintStyle: TextStyle(
                                color: textSecondaryColor.withValues(alpha: 0.5),
                                fontSize: 11,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4),
                                borderSide: BorderSide(
                                  color: borderColor,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4),
                                borderSide: BorderSide(
                                  color: borderColor,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4),
                                borderSide: const BorderSide(
                                  color: primaryColor,
                                  width: 1,
                                ),
                              ),
                              filled: true,
                              fillColor: backgroundColor,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 4,
                              ),
                            ),
                            onChanged: (value) {
                              final newRate = double.tryParse(value);
                              if (newRate != null && newRate > 0) {
                                ref.read(manualExchangeRateProvider.notifier).state = newRate;
                                // Calcular e atualizar a margem correspondente
                                final askRate = ref.read(exchangeRateProvider).asData?.value['ask'] as double? ?? newRate;
                                final newMargin = ((newRate / askRate) - 1) * 100;
                                ref.read(tourismDollarMarginProvider.notifier).state = newMargin.clamp(0, 20);
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'Margem: ',
                        style: DesignTokens.bodySmall.copyWith(
                          color: textSecondaryColor,
                          fontSize: 11,
                        ),
                      ),
                      Expanded(
                        child: SizedBox(
                          height: 20,
                          child: Slider(
                            value: margin,
                            min: 0,
                            max: 20,
                            divisions: 40,
                            activeColor: primaryColor,
                            inactiveColor: borderColor,
                            label: '${margin.toStringAsFixed(1)}%',
                            onChanged: (value) {
                              ref.read(tourismDollarMarginProvider.notifier).state = value;
                              // Atualizar o valor manual com base na nova margem
                              final askRate = ref.read(exchangeRateProvider).asData?.value['ask'] as double? ?? 5.0;
                              final newManualRate = askRate * (1 + value / 100);
                              ref.read(manualExchangeRateProvider.notifier).state = newManualRate;
                            },
                          ),
                        ),
                      ),
                      Text(
                        '${margin.toStringAsFixed(1)}%',
                        style: DesignTokens.bodySmall.copyWith(
                          color: textColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(
                color: primaryColor,
              ),
            ),
            error: (error, stack) => Column(
              children: [
                Icon(
                  Icons.cloud_off,
                  color: Colors.orange[600],
                  size: 24,
                ),
                const SizedBox(height: DesignTokens.spacing8),
                Text(
                  'APIs de câmbio indisponíveis',
                  style: DesignTokens.bodySmall.copyWith(
                    color: Colors.orange[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Usando valores de fallback',
                  style: DesignTokens.bodySmall.copyWith(
                    color: textSecondaryColor,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: DesignTokens.spacing8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        ref.invalidate(exchangeRateProvider);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Reconectar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(String timestamp) {
    try {
      DateTime date;
      
      // Tentar parse como ISO string primeiro
      if (timestamp.contains('T') || timestamp.contains('-')) {
        date = DateTime.parse(timestamp);
      } else {
        // Assumir que é timestamp em milissegundos ou segundos
        final timestampInt = int.parse(timestamp);
        
        // Se o timestamp é muito grande, já está em milissegundos
        // Se for menor, está em segundos e precisa ser convertido
        if (timestampInt > 9999999999) {
          // Timestamp em milissegundos
          date = DateTime.fromMillisecondsSinceEpoch(timestampInt);
        } else {
          // Timestamp em segundos
          date = DateTime.fromMillisecondsSinceEpoch(timestampInt * 1000);
        }
      }
      
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      // Se falhar, mostrar timestamp simplificado
      return DateTime.now().toString().substring(0, 16).replaceFirst(' ', ' ');
    }
  }
}
