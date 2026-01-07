import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/base_screen_layout.dart';
import '../models/agency.dart';
import '../providers/agency_provider.dart';
import 'agency_details_screen.dart';

class HubB2BAgenciesScreen extends ConsumerStatefulWidget {
  const HubB2BAgenciesScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HubB2BAgenciesScreen> createState() => _HubB2BAgenciesScreenState();
}

class _HubB2BAgenciesScreenState extends ConsumerState<HubB2BAgenciesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final agencyState = ref.watch(agencyProvider);
    final agencies = agencyState.agencies;

    // Filtrar agências por busca
    final filteredAgencies = agencies.where((agency) {
      if (_searchTerm.isEmpty) return true;
      final term = _searchTerm.toLowerCase();
      return agency.name.toLowerCase().contains(term) ||
          (agency.email?.toLowerCase().contains(term) ?? false) ||
          (agency.cityName?.toLowerCase().contains(term) ?? false) ||
          (agency.phone?.toLowerCase().contains(term) ?? false);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Agências (Hub B2B)',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        
        // Search bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar por nome, email, cidade, telefone...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onChanged: (v) => setState(() => _searchTerm = v.trim()),
          ),
        ),
        
        // Actions
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Atualizar'),
                onPressed: () => ref.read(agencyProvider.notifier).fetchAgencies(),
              ),
            ],
          ),
        ),
        
        // Content
        Expanded(
          child: agencyState.isLoading && agencies.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : agencyState.errorMessage != null && agencies.isEmpty
                  ? Center(child: Text('Erro: ${agencyState.errorMessage}'))
                  : filteredAgencies.isEmpty
                      ? const Center(child: Text('Nenhuma agência encontrada.'))
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredAgencies.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final agency = filteredAgencies[index];
                            return Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: agency.isActive ? Colors.green : Colors.red,
                                  child: Text(
                                    agency.name.isNotEmpty ? agency.name[0].toUpperCase() : '?',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                title: Text(agency.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (agency.email != null && agency.email!.isNotEmpty)
                                      Text(agency.email!),
                                    if (agency.phone != null && agency.phone!.isNotEmpty)
                                      Text(agency.phone!),
                                    if (agency.cityName != null && agency.cityName!.isNotEmpty)
                                      Text(agency.cityName!),
                                    if (agency.commissionRate != null)
                                      Text('Comissão: ${agency.commissionRate}%'),
                                  ],
                                ),
                                trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AgencyDetailsScreen(agency: agency),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
        ),
      ],
    );
  }
}
