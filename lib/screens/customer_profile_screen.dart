import 'package:flutter/material.dart';
import '../widgets/customer_profile_view.dart';

class CustomerProfileScreen extends StatelessWidget {
  final int customerId;
  final String customerName;

  const CustomerProfileScreen({
    super.key,
    required this.customerId,
    required this.customerName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.person),
            const SizedBox(width: 8),
            Expanded(child: Text(customerName, overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
      body: Container(
        color: theme.colorScheme.surface,
        child: Column(
          children: [
            Expanded(
              child: CustomerProfileView(
                customerId: customerId,
                customerName: customerName,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

