import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/exchange_rate_service.dart';

final exchangeRateServiceProvider = Provider((ref) => ExchangeRateService());

final exchangeRateProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final service = ref.read(exchangeRateServiceProvider);
  return await service.getExchangeRate();
});

final tourismDollarMarginProvider = StateProvider<double>((ref) => 5.0);

final tourismDollarRateProvider = Provider<double>((ref) {
  final exchangeRate = ref.watch(exchangeRateProvider);
  final margin = ref.watch(tourismDollarMarginProvider);
  final manualRate = ref.watch(manualExchangeRateProvider);
  
  return exchangeRate.when(
    data: (data) {
      final askRate = data['ask'] as double;
      // Se o valor manual foi alterado, usar ele diretamente
      if (manualRate != 5.0) {
        return manualRate;
      }
      // Senão, calcular com a margem
      return askRate * (1 + margin / 100);
    },
    loading: () => manualRate, // Usar valor manual se disponível
    error: (_, __) => manualRate, // Usar valor manual se disponível
  );
});

final manualExchangeRateProvider = StateProvider<double>((ref) => 5.0); 
