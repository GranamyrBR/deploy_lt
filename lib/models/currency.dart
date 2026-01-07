import 'package:json_annotation/json_annotation.dart';

part 'currency.g.dart';

@JsonSerializable()
class Currency {
  final int currencyId;
  final String? currencyCode;
  final String? currencyName;
  final double? exchangeRateToUsd;

  Currency({
    required this.currencyId,
    this.currencyCode,
    this.currencyName,
    this.exchangeRateToUsd,
  });

  factory Currency.fromJson(Map<String, dynamic> json) => Currency(
    currencyId: json['currency_id'] as int,
    currencyCode: json['currency_code'] as String?,
    currencyName: json['currency_name'] as String?,
    exchangeRateToUsd: json['exchange_rate_to_usd'] != null ? (json['exchange_rate_to_usd'] as num).toDouble() : null,
  );

  Map<String, dynamic> toJson() => {
    'currency_id': currencyId,
    'currency_code': currencyCode,
    'currency_name': currencyName,
    'exchange_rate_to_usd': exchangeRateToUsd,
  };

  // Helper methods
  String get displayName => '${currencyName ?? 'Unknown'} (${currencyCode ?? 'N/A'})';
  
  // Conversão entre moedas
  double convertToUsd(double amount) => exchangeRateToUsd != null ? amount / exchangeRateToUsd! : amount;
  double convertFromUsd(double usdAmount) => exchangeRateToUsd != null ? usdAmount * exchangeRateToUsd! : usdAmount;
  
  // Conversão entre duas moedas usando USD como intermediário
  double convertTo(double amount, Currency targetCurrency) {
    final usdAmount = convertToUsd(amount);
    return targetCurrency.convertFromUsd(usdAmount);
  }

  // Formatação de valores
  String formatAmount(double amount) {
    switch (currencyCode) {
      case 'BRL':
        return 'R\$ ${amount.toStringAsFixed(2)}';
      case 'USD':
        return 'US\$ ${amount.toStringAsFixed(2)}';
      case 'EUR':
        return '€${amount.toStringAsFixed(2)}';
      default:
        return '${amount.toStringAsFixed(2)} ${currencyCode ?? 'N/A'}';
    }
  }
} 
