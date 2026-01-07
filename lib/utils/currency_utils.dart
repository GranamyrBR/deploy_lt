import 'package:intl/intl.dart';

class CurrencyUtils {
  /// Formata um valor monetário em dólares (USD)
  static String formatCurrency(double value) {
    final formatter = NumberFormat.currency(
      locale: 'en_US',
      symbol: '\$',
      decimalDigits: 2,
    );
    return formatter.format(value);
  }

  /// Formata um valor monetário de forma compacta para gráficos
  static String formatCompactCurrency(double value) {
    if (value >= 1000000) {
      return '\$${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '\$${(value / 1000).toStringAsFixed(1)}K';
    } else {
      return '\$${value.toStringAsFixed(2)}';
    }
  }

  /// Converte um valor entre duas moedas usando uma taxa fixa
  /// Exemplo: await CurrencyUtils.convertCurrency('USD', 'BRL', 100);
  static Future<double> convertCurrency(String from, String to, double amount) async {
    if (from == 'USD' && to == 'BRL') {
      // Taxa fixa de 5.0 como fallback
      return amount * 5.0;
    }
    // Para outras moedas, retorna o valor original por enquanto
    return amount;
  }

  /// Obtém a cotação (taxa) entre duas moedas
  static Future<double> getRate(String from, String to) async {
    if (from == 'USD' && to == 'BRL') {
      // Taxa fixa de 5.0 como fallback
      return 5.0;
    }
    // Para outras moedas, retorna 1.0 por enquanto
    return 1.0;
  }
} 
