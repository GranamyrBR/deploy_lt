import 'package:flutter/material.dart';
import '../services/contacts_service.dart';
import 'contacts_by_country_stats.dart';

class StatisticsModal extends StatefulWidget {
  final ContactsService? contactsService;
  const StatisticsModal({super.key, this.contactsService});

  @override
  State<StatisticsModal> createState() => _StatisticsModalState();
}

class _StatisticsModalState extends State<StatisticsModal> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final content = _buildContent();
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: Row(
                children: [
                  _buildNavigation(context),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      child: content,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        children: [
          Icon(Icons.bar_chart, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            'Estatísticas',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
            tooltip: 'Fechar',
          ),
        ],
      ),
    );
  }

  Widget _buildNavigation(BuildContext context) {
    return NavigationRail(
      selectedIndex: _selectedIndex,
      onDestinationSelected: (i) => setState(() => _selectedIndex = i),
      labelType: NavigationRailLabelType.all,
      minWidth: 72,
      groupAlignment: -1,
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.public),
          label: Text('Contatos por País'),
        ),
      ],
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return ContactsByCountryStats(contactsService: widget.contactsService);
      default:
        return const SizedBox.shrink();
    }
  }
}

