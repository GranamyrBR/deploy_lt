import 'package:flutter/material.dart';

class ContactsMultiView extends StatefulWidget {
  final List<Map<String, dynamic>> contacts;
  final void Function(Map<String, dynamic>) onOpenProfileModal;
  final void Function(Map<String, dynamic>) onOpenProfilePage;
  final void Function(Map<String, dynamic>) onOpenWhatsApp;
  final void Function(Map<String, dynamic>) onCreateSale;

  const ContactsMultiView({
    super.key,
    required this.contacts,
    required this.onOpenProfileModal,
    required this.onOpenProfilePage,
    required this.onOpenWhatsApp,
    required this.onCreateSale,
  });

  @override
  State<ContactsMultiView> createState() => _ContactsMultiViewState();
}

class _ContactsMultiViewState extends State<ContactsMultiView> {
  final Set<int> _selectedIds = {};
  String _search = '';
  String _sortField = 'name';
  bool _ascending = true;
  String _groupMode = 'none';

  List<Map<String, dynamic>> get _filtered {
    final items = widget.contacts.where((c) {
      final name = (c['name'] ?? '').toString().toLowerCase();
      final email = (c['email'] ?? '').toString().toLowerCase();
      final phone = (c['phone'] ?? '').toString().toLowerCase();
      final query = _search.toLowerCase();
      if (query.isEmpty) return true;
      return name.contains(query) || email.contains(query) || phone.contains(query);
    }).toList();
    items.sort((a, b) {
      final av = (a[_sortField] ?? '').toString();
      final bv = (b[_sortField] ?? '').toString();
      final cmp = av.toLowerCase().compareTo(bv.toLowerCase());
      return _ascending ? cmp : -cmp;
    });
    return items;
  }

  void _toggleSelect(int id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildToolbar(context),
        Expanded(child: _buildBody(context)),
        _buildFooter(context),
      ],
    );
  }

  Widget _buildToolbar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Buscar por nome, email ou telefone',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
          const SizedBox(width: 12),
          DropdownButton<String>(
            value: _sortField,
            items: const [
              DropdownMenuItem(value: 'name', child: Text('Nome')),
              DropdownMenuItem(value: 'email', child: Text('Email')),
              DropdownMenuItem(value: 'phone', child: Text('Telefone')),
              DropdownMenuItem(value: 'updated_at', child: Text('Atualizado')),
            ],
            onChanged: (v) => setState(() => _sortField = v ?? 'name'),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => setState(() => _ascending = !_ascending),
            icon: Icon(_ascending ? Icons.arrow_upward : Icons.arrow_downward),
            tooltip: _ascending ? 'Crescente' : 'Decrescente',
          ),
          const SizedBox(width: 12),
          DropdownButton<String>(
            value: _groupMode,
            items: const [
              DropdownMenuItem(value: 'none', child: Text('Sem agrupamento')),
              DropdownMenuItem(value: 'agency', child: Text('Agência')),
              DropdownMenuItem(value: 'category', child: Text('Categoria')),
            ],
            onChanged: (v) => setState(() => _groupMode = v ?? 'none'),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_groupMode == 'none') return _buildGrid(context);
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final c in _filtered) {
      final key = _groupMode == 'agency'
          ? (c['account']?['name']?.toString() ?? 'Sem agência')
          : (c['contact_category']?['name']?.toString() ?? 'Sem categoria');
      grouped.putIfAbsent(key, () => []).add(c);
    }

    final keys = grouped.keys.toList()..sort();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: keys.map((key) {
          final items = grouped[key]!;
          return _buildGroupSection(context, key, items);
        }).toList(),
      ),
    );
  }

  Widget _buildGroupSection(BuildContext context, String title, List<Map<String, dynamic>> items) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                Container(width: 4, height: 20, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('$title • ${items.length}', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                _buildSummaryBar(context, items),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _buildGroupGrid(context, items),
        ],
      ),
    );
  }

  Widget _buildGroupGrid(BuildContext context, List<Map<String, dynamic>> items) {
    return LayoutBuilder(builder: (context, constraints) {
      int crossAxisCount = 1;
      if (constraints.maxWidth > 1200) {
        crossAxisCount = 4;
      } else if (constraints.maxWidth > 900) {
        crossAxisCount = 3;
      } else if (constraints.maxWidth > 600) {
        crossAxisCount = 2;
      }
      return GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 2.0,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final c = items[index];
          return _buildContactCard(context, c, index);
        },
      );
    });
  }

  Widget _buildSummaryBar(BuildContext context, List<Map<String, dynamic>> items) {
    final byCountry = <String, int>{};
    for (final c in items) {
      final country = (c['country'] ?? 'N/A').toString();
      byCountry[country] = (byCountry[country] ?? 0) + 1;
    }
    final total = items.length;
    final top = byCountry.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final show = top.take(3).toList();
    return SizedBox(
      height: 16,
      width: 180,
      child: Row(
        children: show.map((e) {
          final fraction = total == 0 ? 0.0 : e.value / total;
          final width = 180 * fraction;
          final color = _countryColor(e.key);
          return Container(
            width: width,
            height: 16,
            color: color,
          );
        }).toList(),
      ),
    );
  }

  Color _countryColor(String key) {
    final k = key.toLowerCase();
    if (k.contains('brasil') || k.contains('brazil')) return Colors.green;
    if (k.contains('united') || k.contains('usa') || k.contains('estados')) return Colors.blue;
    return Colors.orange;
  }

  Widget _buildContactCard(BuildContext context, Map<String, dynamic> c, int index) {
    final id = c['id'] as int? ?? index;
    final selected = _selectedIds.contains(id);
    return Material(
      elevation: selected ? 3 : 1,
      color: selected ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _toggleSelect(id),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Checkbox(value: selected, onChanged: (_) => _toggleSelect(id)),
                    Expanded(
                      child: Text(
                        (c['name'] ?? 'Cliente').toString(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (v) {
                        if (v == 'profile_modal') widget.onOpenProfileModal(c);
                        if (v == 'profile_page') widget.onOpenProfilePage(c);
                        if (v == 'sale') widget.onCreateSale(c);
                        if (v == 'whatsapp') widget.onOpenWhatsApp(c);
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'profile_modal', child: Text('Perfil (Modal)')),
                        PopupMenuItem(value: 'profile_page', child: Text('Abrir Página')),
                        PopupMenuItem(value: 'sale', child: Text('Nova Venda')),
                        PopupMenuItem(value: 'whatsapp', child: Text('WhatsApp')),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _chip(context, Icons.email, (c['email'] ?? '').toString()),
                    _chip(context, Icons.phone, (c['phone'] ?? '').toString()),
                    if (c['city'] != null) _chip(context, Icons.location_city, c['city'].toString()),
                    if (c['country'] != null) _chip(context, Icons.public, c['country'].toString()),
                    if (c['account']?['name'] != null) _chip(context, Icons.business, c['account']['name'].toString()),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => widget.onOpenProfileModal(c),
                        icon: const Icon(Icons.analytics, size: 16),
                        label: const Text('Perfil'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => widget.onOpenProfilePage(c),
                        icon: const Icon(Icons.open_in_new, size: 16),
                        label: const Text('Página'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(onPressed: () => widget.onCreateSale(c), icon: const Icon(Icons.shopping_cart)),
                    IconButton(onPressed: () => widget.onOpenWhatsApp(c), icon: const Icon(Icons.chat_bubble)),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildGrid(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      int crossAxisCount = 1;
      if (constraints.maxWidth > 1200) {
        crossAxisCount = 4;
      } else if (constraints.maxWidth > 900) {
        crossAxisCount = 3;
      } else if (constraints.maxWidth > 600) {
        crossAxisCount = 2;
      }
      final data = _filtered;
      return GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 2.0,
        ),
        itemCount: data.length,
        itemBuilder: (context, index) {
          final c = data[index];
          final id = c['id'] as int? ?? index;
          final selected = _selectedIds.contains(id);
          return Material(
            elevation: selected ? 3 : 1,
            color: selected ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _toggleSelect(id),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: SingleChildScrollView(
                  child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Checkbox(value: selected, onChanged: (_) => _toggleSelect(id)),
                        Expanded(
                          child: Text(
                            (c['name'] ?? 'Cliente').toString(),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        PopupMenuButton<String>(
                          onSelected: (v) {
                            if (v == 'profile_modal') widget.onOpenProfileModal(c);
                            if (v == 'profile_page') widget.onOpenProfilePage(c);
                            if (v == 'sale') widget.onCreateSale(c);
                            if (v == 'whatsapp') widget.onOpenWhatsApp(c);
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(value: 'profile_modal', child: Text('Perfil (Modal)')),
                            PopupMenuItem(value: 'profile_page', child: Text('Abrir Página')),
                            PopupMenuItem(value: 'sale', child: Text('Nova Venda')),
                            PopupMenuItem(value: 'whatsapp', child: Text('WhatsApp')),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _chip(context, Icons.email, (c['email'] ?? '').toString()),
                        _chip(context, Icons.phone, (c['phone'] ?? '').toString()),
                        if (c['city'] != null) _chip(context, Icons.location_city, c['city'].toString()),
                        if (c['country'] != null) _chip(context, Icons.public, c['country'].toString()),
                        if (c['account']?['name'] != null) _chip(context, Icons.business, c['account']['name'].toString()),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => widget.onOpenProfileModal(c),
                            icon: const Icon(Icons.analytics, size: 16),
                            label: const Text('Perfil'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => widget.onOpenProfilePage(c),
                            icon: const Icon(Icons.open_in_new, size: 16),
                            label: const Text('Página'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => widget.onCreateSale(c),
                          icon: const Icon(Icons.shopping_cart),
                          tooltip: 'Nova Venda',
                        ),
                        IconButton(
                          onPressed: () => widget.onOpenWhatsApp(c),
                          icon: const Icon(Icons.chat_bubble),
                          tooltip: 'WhatsApp',
                        ),
                      ],
                    )
                  ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    });
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          Text('Selecionados: ${_selectedIds.length}'),
          const Spacer(),
          Text('Total: ${_filtered.length}'),
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, IconData icon, String text) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 4),
          Text(text, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
