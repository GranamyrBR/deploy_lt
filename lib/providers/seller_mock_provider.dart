import 'package:flutter_riverpod/flutter_riverpod.dart';


class SellerMetricPoint {
  final String label;
  final double value;
  SellerMetricPoint(this.label, this.value);
}

class SellerMockData {
  final String sellerId;
  final String sellerName;
  final double totalRevenueUsd;
  final double totalDiscountUsd;
  final int operationsCount;
  final int pendingOperationsCount;
  final int whatsappConvertedContacts;
  final double driversCommissionUsd;
  final List<SellerMetricPoint> monthlyRevenue;
  final List<SellerMetricPoint> discountBreakdown;
  final List<SellerMetricPoint> conversionFunnel;
  final List<SellerMetricPoint> topCustomers;
  final List<SellerMetricPoint> topProducts;
  final bool isLoading;
  final String? errorMessage;

  SellerMockData({
    required this.sellerId,
    required this.sellerName,
    required this.totalRevenueUsd,
    required this.totalDiscountUsd,
    required this.operationsCount,
    required this.pendingOperationsCount,
    required this.whatsappConvertedContacts,
    required this.driversCommissionUsd,
    required this.monthlyRevenue,
    required this.discountBreakdown,
    required this.conversionFunnel,
    required this.topCustomers,
    required this.topProducts,
    this.isLoading = false,
    this.errorMessage,
  });
}

class SellerMockNotifier extends StateNotifier<SellerMockData> {
  SellerMockNotifier()
      : super(
          SellerMockData(
            sellerId: 'seller_001',
            sellerName: 'Vendedor Demo',
            totalRevenueUsd: 18250,
            totalDiscountUsd: 950,
            operationsCount: 48,
            pendingOperationsCount: 7,
            whatsappConvertedContacts: 26,
            driversCommissionUsd: 3850,
            monthlyRevenue: [
              SellerMetricPoint('Jan', 2500),
              SellerMetricPoint('Fev', 2800),
              SellerMetricPoint('Mar', 3200),
              SellerMetricPoint('Abr', 2100),
              SellerMetricPoint('Mai', 3400),
              SellerMetricPoint('Jun', 3250),
            ],
            discountBreakdown: [
              SellerMetricPoint('Campanhas', 520),
              SellerMetricPoint('Negociação', 310),
              SellerMetricPoint('Cortesias', 120),
            ],
            conversionFunnel: [
              SellerMetricPoint('Leads WhatsApp', 120),
              SellerMetricPoint('Qualificados', 64),
              SellerMetricPoint('Propostas', 42),
              SellerMetricPoint('Vendas', 26),
            ],
            topCustomers: [
              SellerMetricPoint('Agência Alpha', 5200),
              SellerMetricPoint('Cliente Beta', 3800),
              SellerMetricPoint('Cliente Gamma', 2800),
              SellerMetricPoint('Agência Delta', 2200),
              SellerMetricPoint('Cliente Sigma', 1850),
            ],
            topProducts: [
              SellerMetricPoint('JFK IN-4', 6200),
              SellerMetricPoint('EWR OUT-4', 4100),
              SellerMetricPoint('Tour 3H', 3300),
              SellerMetricPoint('Transfer MIA', 2550),
              SellerMetricPoint('IN Chicago', 2000),
            ],
          ),
        );

  void refreshMock() {
    state = state;
  }
}

final sellerMockProvider = StateNotifierProvider<SellerMockNotifier, SellerMockData>((ref) {
  return SellerMockNotifier();
});

final sellerPeriodProvider = StateProvider<String>((ref) => 'YTD');