import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/customer_analytics_service.dart';
import 'customer_profile_view.dart';
import '../providers/accessibility_provider.dart';

class CustomerProfileModal extends ConsumerWidget {
  final int customerId;
  final String customerName;
  final CustomerAnalyticsService? analyticsService;

  const CustomerProfileModal({
    Key? key,
    required this.customerId,
    required this.customerName,
    this.analyticsService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isHighContrast = ref.watch(accessibilityProvider);
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Stack(
        children: [
          Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.9,
            decoration: BoxDecoration(
              color: isHighContrast ? Colors.black : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      const Spacer(),
                      const Text('Alto Contraste', style: TextStyle(fontSize: 12)),
                      Switch(
                        value: isHighContrast,
                        onChanged: (_) => ref.read(accessibilityProvider.notifier).toggle(),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: CustomerProfileView(
                    customerId: customerId,
                    customerName: customerName,
                    analyticsService: analyticsService,
                    highContrast: isHighContrast,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 8,
            top: 8,
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: Icon(Icons.close, size: 28, color: isHighContrast ? Colors.white70 : Colors.black54),
            ),
          ),
        ],
      ),
    );
  }
}
