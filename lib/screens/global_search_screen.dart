import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/global_search_providers.dart';
import '../widgets/base_screen_layout.dart'; // Added import for BaseScreenLayout
import '../widgets/standard_search_bar.dart'; // Added import for StandardSearchBar
import '../utils/smart_search_mixin.dart';

class GlobalSearchScreen extends ConsumerStatefulWidget {
  const GlobalSearchScreen({super.key});


  @override
  ConsumerState<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends ConsumerState<GlobalSearchScreen> with SmartSearchMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreenLayout(
      title: 'Busca Global',
      actions: [
        // The original AppBar actions are removed as per the edit hint.
      ],
      searchBar: StandardSearchBar(
        controller: _searchController,
        hintText: 'Buscar em tudo...',
        onChanged: (v) {
          setState(() => _searchTerm = v.trim().toLowerCase());
        },
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // The original TextField is removed as per the edit hint.
            const SizedBox(height: 24),
            Expanded(
              child: _searchTerm.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'Digite algo para buscar',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Busque em: Contatos, Vendas, Usuários, Agências, Motoristas, Monday e Leads Tintim',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : _buildResults(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    // Busca em todas as tabelas
    final contactAsync = ref.watch(globalContactSearchProvider(_searchTerm));
    final saleAsync = ref.watch(globalSalesSearchProvider(_searchTerm));
    final userAsync = ref.watch(globalUserSearchProvider(_searchTerm));
    final agencyAsync = ref.watch(globalAgencySearchProvider(_searchTerm));
    final driverAsync = ref.watch(globalDriverSearchProvider(_searchTerm));
    final mondayAsync = ref.watch(globalMondaySearchProvider(_searchTerm));
    final leadTintimAsync = ref.watch(globalLeadTintimSearchProvider(_searchTerm));

    return ListView(
      children: [
        _buildSectionTitle('Contatos', Icons.person),
        contactAsync.when(
          data: (contacts) {
            if (contacts.isEmpty) return const ListTile(title: Text('Nenhum contato encontrado.'));
            return Column(
              children: contacts.map((c) => ListTile(
                leading: const Icon(Icons.person),
                title: Text(c.name ?? 'Sem nome'),
                subtitle: Text('${c.email ?? ''}  ${c.phone ?? ''}'),
                onTap: () {
                  // Navegar para detalhes do contato
                },
              )).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListTile(title: Text('Erro: $e')),
        ),
        
        _buildSectionTitle('Vendas', Icons.shopping_cart),
        saleAsync.when(
          data: (sales) {
            if (sales.isEmpty) return const ListTile(title: Text('Nenhuma venda encontrada.'));
            return Column(
              children: sales.map((s) => ListTile(
                leading: const Icon(Icons.shopping_cart),
                title: Text('Venda #${s.id} - ${s.contactName}'),
                subtitle: Text('Valor: ${s.totalAmountFormatted} | Status: ${s.status ?? ''}'),
                onTap: () {
                  // Navegar para detalhes da venda
                },
              )).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListTile(title: Text('Erro: $e')),
        ),
        
        _buildSectionTitle('Usuários', Icons.people),
        userAsync.when(
          data: (users) {
            if (users.isEmpty) return const ListTile(title: Text('Nenhum usuário encontrado.'));
            return Column(
              children: users.map((u) => ListTile(
                leading: const Icon(Icons.people),
                title: Text(u.name),
                subtitle: Text('${u.username} | ${u.email}'),
                onTap: () {
                  // Navegar para detalhes do usuário
                },
              )).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListTile(title: Text('Erro: $e')),
        ),
        
        _buildSectionTitle('Agências', Icons.business),
        agencyAsync.when(
          data: (agencies) {
            if (agencies.isEmpty) return const ListTile(title: Text('Nenhuma agência encontrada.'));
            return Column(
              children: agencies.map((a) => ListTile(
                leading: const Icon(Icons.business),
                title: Text(a.name ?? 'Sem nome'),
                subtitle: Text('${a.email} | ${a.phone}'),
                onTap: () {
                  // Navegar para detalhes da agência
                },
              )).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListTile(title: Text('Erro: $e')),
        ),
        
        _buildSectionTitle('Motoristas', Icons.drive_eta),
        driverAsync.when(
          data: (drivers) {
            if (drivers.isEmpty) return const ListTile(title: Text('Nenhum motorista encontrado.'));
            return Column(
              children: drivers.map((d) => ListTile(
                leading: const Icon(Icons.drive_eta),
                title: Text(d.name ?? 'Sem nome'),
                subtitle: Text('${d.cityName} | ${d.phone}'),
                onTap: () {
                  // Navegar para detalhes do motorista
                },
              )).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListTile(title: Text('Erro: $e')),
        ),
        
        _buildSectionTitle('Monday', Icons.calendar_today),
        mondayAsync.when(
          data: (mondayEntries) {
            if (mondayEntries.isEmpty) return const ListTile(title: Text('Nenhum registro encontrado.'));
            return Column(
              children: mondayEntries.map((m) => ListTile(
                leading: const Icon(Icons.calendar_today),
                title: Text(m.name ?? 'Sem nome'),
                subtitle: Text('${m.email ?? ''} | ${m.contactCategoryName ?? 'Sem status'} | ${m.telefone ?? ''}'),
                onTap: () {
                  // Navegar para detalhes do registro
                },
              )).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListTile(title: Text('Erro: $e')),
        ),
        
        _buildSectionTitle('Leads Tintim', Icons.phone),
        leadTintimAsync.when(
          data: (leads) {
            if (leads.isEmpty) return const ListTile(title: Text('Nenhum lead encontrado.'));
            return Column(
              children: leads.map((lead) => ListTile(
                leading: const Icon(Icons.phone, color: Colors.green),
                title: Text(lead.name ?? 'Sem nome'),
                subtitle: Text('${lead.phone ?? ''} | ${lead.status?.name ?? 'Sem status'} | ${lead.source ?? ''}'),
                onTap: () {
                  // Navegar para detalhes do lead
                },
              )).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListTile(title: Text('Erro: $e')),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
} 
