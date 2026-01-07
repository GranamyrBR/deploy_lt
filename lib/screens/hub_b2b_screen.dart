import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/base_screen_layout.dart';
import '../providers/dashboard_provider.dart';

class HubB2BScreen extends ConsumerWidget {
  const HubB2BScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return BaseScreenLayout(
      title: 'Hub B2B',
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Central B2B',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            
            // Main grid of cards
            Expanded(
              child: _buildMainGrid(context, ref),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMainGrid(BuildContext context, WidgetRef ref) {
    return Wrap(
      spacing: 24,
      runSpacing: 24,
      children: [
        _buildHubCard(
          context,
          Icons.leaderboard,
          'Ranking de Agências',
          onTap: () {
            ref.read(dashboardPageProvider.notifier).state = DashboardPage.hubB2BAgencyRanking;
          }
        ),
        _buildHubCard(
          context,
          Icons.business_center,
          'Oportunidades',
          onTap: () {
            ref.read(dashboardPageProvider.notifier).state = DashboardPage.hubB2BOpportunities;
          }
        ),
        _buildHubCard(
          context,
          Icons.description,
          'Documentos',
          onTap: () {
            ref.read(dashboardPageProvider.notifier).state = DashboardPage.hubB2BDocuments;
          }
        ),
        _buildHubCard(
          context,
          Icons.dashboard,
          'Dashboard B2B',
          onTap: () {
            ref.read(dashboardPageProvider.notifier).state = DashboardPage.hubB2BDashboard;
          }
        ),
        _buildHubCard(
          context,
          Icons.business,
          'Agências',
          onTap: () {
            ref.read(dashboardPageProvider.notifier).state = DashboardPage.hubB2BAgencies;
          }
        ),

      ],
    );
  }

  Widget _buildHubCard(BuildContext context, IconData icon, String label, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 160,
          height: 140,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
