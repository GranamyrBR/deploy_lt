import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'sales_provider.dart'; // Import for salesServiceProvider

// =====================================================
// B2B METRICS PROVIDERS
// =====================================================

final b2bMetricsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final service = ref.watch(salesServiceProvider);
  return service.getB2BMetrics();
});

final provisionalInvoicePerformanceProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final service = ref.watch(salesServiceProvider);
  return service.getProvisionalInvoicePerformance();
});

final b2bMetricsByAccountProvider = FutureProvider.family<Map<String, dynamic>, int>((ref, accountId) async {
  final service = ref.watch(salesServiceProvider);
  return service.getB2BMetricsByAccount(accountId);
});

final b2bMetricsByPeriodProvider = FutureProvider.family<Map<String, dynamic>, Map<String, DateTime>>((ref, period) async {
  final service = ref.watch(salesServiceProvider);
  return service.getB2BMetricsByPeriod(
    startDate: period['startDate']!,
    endDate: period['endDate']!,
  );
});

// =====================================================
// PROVISIONAL INVOICE APPROVALS
// =====================================================

final provisionalInvoiceApprovalsProvider = FutureProvider.family<List<Map<String, dynamic>>, int>((ref, invoiceId) async {
  final service = ref.watch(salesServiceProvider);
  return service.getProvisionalInvoiceApprovals(invoiceId);
});

final provisionalInvoiceRemindersProvider = FutureProvider.family<List<Map<String, dynamic>>, int>((ref, invoiceId) async {
  final service = ref.watch(salesServiceProvider);
  return service.getProvisionalInvoiceReminders(invoiceId);
});

// =====================================================
// B2B DASHBOARD WIDGETS
// =====================================================

final b2bConversionRateProvider = FutureProvider<double>((ref) async {
  final metrics = await ref.watch(b2bMetricsProvider.future);
  return metrics['conversion_rate_percent'] ?? 0.0;
});

final b2bAverageResponseTimeProvider = FutureProvider<double>((ref) async {
  final metrics = await ref.watch(b2bMetricsProvider.future);
  return metrics['avg_days_to_first_view'] ?? 0.0;
});

final b2bAverageApprovalTimeProvider = FutureProvider<double>((ref) async {
  final metrics = await ref.watch(b2bMetricsProvider.future);
  return metrics['avg_days_to_approval'] ?? 0.0;
});

final b2bTotalValueProvider = FutureProvider<double>((ref) async {
  final metrics = await ref.watch(b2bMetricsProvider.future);
  return metrics['total_converted_value'] ?? 0.0;
});

// =====================================================
// B2B ALERTS AND NOTIFICATIONS
// =====================================================

final b2bExpiredProposalsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final service = ref.watch(salesServiceProvider);
  return service.getExpiredProposals();
});

final b2bUrgentProposalsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final service = ref.watch(salesServiceProvider);
  return service.getUrgentProposals();
});

final b2bOverdueProposalsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final service = ref.watch(salesServiceProvider);
  return service.getOverdueProposals();
});

// =====================================================
// B2B PERFORMANCE ANALYTICS
// =====================================================

final b2bPerformanceByAccountProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final service = ref.watch(salesServiceProvider);
  return service.getB2BPerformanceByAccount();
});

final b2bPerformanceByPeriodProvider = FutureProvider.family<List<Map<String, dynamic>>, Map<String, DateTime>>((ref, period) async {
  final service = ref.watch(salesServiceProvider);
  return service.getB2BPerformanceByPeriod(
    startDate: period['startDate']!,
    endDate: period['endDate']!,
  );
});

final b2bTopPerformersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final service = ref.watch(salesServiceProvider);
  return service.getB2BTopPerformers();
});

// =====================================================
// B2B WORKFLOW PROVIDERS
// =====================================================

final b2bWorkflowStagesProvider = FutureProvider<Map<String, int>>((ref) async {
  final service = ref.watch(salesServiceProvider);
  return service.getB2BWorkflowStages();
});

final b2bBottleneckAnalysisProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final service = ref.watch(salesServiceProvider);
  return service.getB2BBottleneckAnalysis();
});

// =====================================================
// B2B FORECASTING PROVIDERS
// =====================================================

final b2bForecastProvider = FutureProvider.family<Map<String, dynamic>, int>((ref, months) async {
  final service = ref.watch(salesServiceProvider);
  return service.getB2BForecast(months);
});

final b2bPipelineValueProvider = FutureProvider<double>((ref) async {
  final service = ref.watch(salesServiceProvider);
  return service.getB2BPipelineValue();
});

// =====================================================
// B2B COMPARISON PROVIDERS
// =====================================================

final b2bComparisonProvider = FutureProvider.family<Map<String, dynamic>, Map<String, dynamic>>((ref, comparison) async {
  final service = ref.watch(salesServiceProvider);
  return service.getB2BComparison(
    period1: comparison['period1'],
    period2: comparison['period2'],
    metric: comparison['metric'],
  );
});

// =====================================================
// B2B EXPORT PROVIDERS
// =====================================================

final b2bExportProvider = FutureProvider.family<String, Map<String, dynamic>>((ref, exportConfig) async {
  final service = ref.watch(salesServiceProvider);
  return service.exportB2BData(
    format: exportConfig['format'] ?? 'csv',
    filters: exportConfig['filters'] ?? {},
    period: exportConfig['period'],
  );
}); 
