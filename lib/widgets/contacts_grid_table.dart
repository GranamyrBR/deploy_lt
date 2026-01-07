import 'package:flutter/material.dart';

class ContactsGridTable extends StatefulWidget {
  final List<Map<String, dynamic>> contacts;
  final Future<List<Map<String, dynamic>>> Function({int limit, int offset, String? search, int? sortColumnIndex, bool ascending})? loader;
  final void Function(Map<String, dynamic>) onOpenProfileModal;
  final void Function(Map<String, dynamic>) onOpenProfilePage;
  final void Function(Map<String, dynamic>) onOpenWhatsApp;
  final void Function(Map<String, dynamic>) onCreateSale;

  const ContactsGridTable({
    super.key,
    required this.contacts,
    this.loader,
    required this.onOpenProfileModal,
    required this.onOpenProfilePage,
    required this.onOpenWhatsApp,
    required this.onCreateSale,
  });

  @override
  State<ContactsGridTable> createState() => _ContactsGridTableState();
}

class _ContactsGridTableState extends State<ContactsGridTable> {
  final Set<int> _selected = {};
  String _search = '';
  int? _sortColumnIndex;
  bool _sortAscending = true;
  int _offset = 0;
  final int _limit = 100;
  bool _isLoading = false;
  bool _hasMore = true;
  List<Map<String, dynamic>> _page = [];

  List<Map<String, dynamic>> get _rows {
    final base = widget.loader != null ? _page : widget.contacts;
    final data = base.where((c) {
      if (_search.isEmpty) return true;
      final q = _search.toLowerCase();
      return (c['name'] ?? '').toString().toLowerCase().contains(q) ||
          (c['email'] ?? '').toString().toLowerCase().contains(q) ||
          (c['phone'] ?? '').toString().toLowerCase().contains(q) ||
          (c['city'] ?? '').toString().toLowerCase().contains(q) ||
          (c['country'] ?? '').toString().toLowerCase().contains(q) ||
          (c['account']?['name'] ?? '').toString().toLowerCase().contains(q) ||
          (c['contact_category']?['name'] ?? '').toString().toLowerCase().contains(q);
    }).toList();
    if (_sortColumnIndex != null) {
      data.sort((a, b) {
        dynamic av;
        dynamic bv;
        switch (_sortColumnIndex) {
          case 0:
            av = a['name'];
            bv = b['name'];
            break;
          case 1:
            av = a['email'];
            bv = b['email'];
            break;
          case 2:
            av = a['phone'];
            bv = b['phone'];
            break;
          case 3:
            av = a['city'];
            bv = b['city'];
            break;
          case 4:
            av = a['country'];
            bv = b['country'];
            break;
          case 5:
            av = a['account']?['name'];
            bv = b['account']?['name'];
            break;
          case 6:
            av = a['contact_category']?['name'];
            bv = b['contact_category']?['name'];
            break;
          case 7:
            av = a['updated_at'];
            bv = b['updated_at'];
            break;
          default:
            av = a['name'];
            bv = b['name'];
        }
        final sa = (av ?? '').toString().toLowerCase();
        final sb = (bv ?? '').toString().toLowerCase();
        final cmp = sa.compareTo(sb);
        return _sortAscending ? cmp : -cmp;
      });
    }
    return data;
  }

  @override
  void initState() {
    super.initState();
    if (widget.loader != null) _fetchPage(reset: true);
  }

  Future<void> _fetchPage({bool reset = false}) async {
    if (widget.loader == null) return;
    setState(() { _isLoading = true; });
    if (reset) { _offset = 0; _hasMore = true; }
    final rows = await widget.loader!(
      limit: _limit,
      offset: _offset,
      search: _search,
      sortColumnIndex: _sortColumnIndex,
      ascending: _sortAscending,
    );
    setState(() {
      _page = rows;
      _hasMore = rows.length == _limit;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Buscar por nome, email, telefone, cidade, país, agência',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onChanged: (v) {
                    setState(() => _search = v);
                    if (widget.loader != null) _fetchPage(reset: true);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.table_rows, size: 18),
                    const SizedBox(width: 8),
                    Text('Total: ${_rows.length} • Selecionados: ${_selected.length}'),
                    const SizedBox(width: 12),
                    if (widget.loader != null) ...[
                      OutlinedButton(
                        onPressed: _isLoading ? null : () { setState(() { _offset = (_offset - _limit).clamp(0, _offset); }); _fetchPage(); },
                        child: const Text('Anterior'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: _isLoading || !_hasMore ? null : () { setState(() { _offset += _limit; }); _fetchPage(); },
                        child: const Text('Próximo'),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 1200),
              child: SingleChildScrollView(
                child: _isLoading && widget.loader != null
                    ? const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
                    : DataTable(
                      sortColumnIndex: _sortColumnIndex,
                      sortAscending: _sortAscending,
                      headingRowHeight: 44,
                      dataRowMinHeight: 56,
                      dataRowMaxHeight: 56,
                      columns: [
                        DataColumn(
                          label: const Text('Nome'),
                          onSort: (i, asc) {
                            setState(() { _sortColumnIndex = i; _sortAscending = asc; });
                            if (widget.loader != null) _fetchPage(reset: true);
                          },
                        ),
                        DataColumn(
                          label: const Text('Email'),
                          onSort: (i, asc) {
                            setState(() { _sortColumnIndex = i; _sortAscending = asc; });
                            if (widget.loader != null) _fetchPage(reset: true);
                          },
                        ),
                        DataColumn(
                          label: const Text('Telefone'),
                          onSort: (i, asc) {
                            setState(() { _sortColumnIndex = i; _sortAscending = asc; });
                            if (widget.loader != null) _fetchPage(reset: true);
                          },
                        ),
                        const DataColumn(label: Text('Cidade')),
                        const DataColumn(label: Text('País')),
                        const DataColumn(label: Text('Agência')),
                        const DataColumn(label: Text('Categoria')),
                        const DataColumn(label: Text('Atualizado')),
                        const DataColumn(label: Text('Ações')),
                      ],
                      rows: _rows.map((c) => _buildRow(context, c)).toList(),
                    ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  DataRow _buildRow(BuildContext context, Map<String, dynamic> c) {
    final id = c['id'] as int? ?? _rows.indexOf(c);
    final selected = _selected.contains(id);
    return DataRow(
      selected: selected,
      onSelectChanged: (_) {
        setState(() {
          if (selected) {
            _selected.remove(id);
          } else {
            _selected.add(id);
          }
        });
      },
      cells: [
        DataCell(Row(children: [
          Expanded(child: Text((c['name'] ?? 'Cliente').toString(), overflow: TextOverflow.ellipsis)),
        ])),
        DataCell(Text((c['email'] ?? '').toString(), overflow: TextOverflow.ellipsis)),
        DataCell(Text((c['phone'] ?? '').toString(), overflow: TextOverflow.ellipsis)),
        DataCell(Text((c['city'] ?? '').toString(), overflow: TextOverflow.ellipsis)),
        DataCell(Text((c['country'] ?? '').toString(), overflow: TextOverflow.ellipsis)),
        DataCell(_chip((c['account']?['name'] ?? '').toString(), Colors.blue)),
        DataCell(_chip((c['contact_category']?['name'] ?? '').toString(), Colors.green)),
        DataCell(Text((c['updated_at'] ?? '').toString(), overflow: TextOverflow.ellipsis)),
        DataCell(Row(children: [
          IconButton(onPressed: () => widget.onOpenProfileModal(c), icon: const Icon(Icons.analytics), tooltip: 'Perfil'),
          IconButton(onPressed: () => widget.onOpenProfilePage(c), icon: const Icon(Icons.open_in_new), tooltip: 'Página'),
          IconButton(onPressed: () => widget.onCreateSale(c), icon: const Icon(Icons.shopping_cart), tooltip: 'Nova Venda'),
          IconButton(onPressed: () => widget.onOpenWhatsApp(c), icon: const Icon(Icons.chat_bubble), tooltip: 'WhatsApp'),
        ])),
      ],
    );
  }

  Widget _chip(String text, Color color) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
    );
  }
}
