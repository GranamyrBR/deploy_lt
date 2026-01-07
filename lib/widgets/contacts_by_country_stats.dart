import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/contacts_service.dart';

class ContactsByCountryStats extends StatefulWidget {
  final ContactsService? contactsService;
  const ContactsByCountryStats({super.key, this.contactsService});

  @override
  State<ContactsByCountryStats> createState() => _ContactsByCountryStatsState();
}

class _ContactsByCountryStatsState extends State<ContactsByCountryStats> {
  late final ContactsService _service;
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _rows = [];

  // Filtros
  DateTimeRange? _range;
  String? _categoryName;
  String _search = '';
  bool _sortAscending = false; // ordenar por total desc por padrão

  @override
  void initState() {
    super.initState();
    _service = widget.contactsService ?? ContactsService();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final start = _range?.start;
      final end = _range?.end;
      final data = await _service.getContactsCountByCountry(
        start: start,
        end: end,
        categoryName: _categoryName,
        search: _search.trim().isEmpty ? null : _search.trim(),
      );
      data.sort((a, b) => (_sortAscending ? (a['total'] as int).compareTo(b['total'] as int) : (b['total'] as int).compareTo(a['total'] as int)));
      setState(() {
        _rows = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Erro ao carregar estatísticas: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildFilters(context),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(child: Text(_error!))
                  : _buildBody(context),
        ),
      ],
    );
  }

  Widget _buildFilters(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          OutlinedButton.icon(
            onPressed: () async {
              final now = DateTime.now();
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(now.year - 3),
                lastDate: DateTime(now.year + 1),
                initialDateRange: _range,
              );
              if (picked != null) {
                setState(() => _range = picked);
                _fetch();
              }
            },
            icon: const Icon(Icons.calendar_today, size: 16),
            label: Text(_range == null
                ? 'Período: Todos'
                : 'Período: ${_range!.start.toString().split(' ').first} - ${_range!.end.toString().split(' ').first}'),
          ),
          SizedBox(
            width: 220,
            child: TextField(
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Buscar país'),
              onChanged: (v) {
                setState(() => _search = v);
                _fetch();
              },
            ),
          ),
          FilterChip(
            label: Text(_sortAscending ? 'Ordenar: Crescente' : 'Ordenar: Decrescente'),
            selected: !_sortAscending,
            onSelected: (_) {
              setState(() => _sortAscending = !_sortAscending);
              _fetch();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final isWide = constraints.maxWidth > 900;
      return Row(
        children: [
          Expanded(child: _buildTable(context)),
          if (isWide) const VerticalDivider(width: 1),
          if (isWide)
            SizedBox(width: constraints.maxWidth * 0.4, child: _buildChart(context)),
        ],
      );
    });
  }

  Widget _buildTable(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('País')),
          DataColumn(label: Text('Total')),
          DataColumn(label: Text('Percentual')),
        ],
        rows: _rows
            .where((r) => _search.isEmpty || (r['country'] as String).toLowerCase().contains(_search.toLowerCase()))
            .map((r) {
          return DataRow(cells: [
            DataCell(Text(r['country'] as String)),
            DataCell(Text((r['total'] as int).toString())),
            DataCell(Text('${(r['percent'] as double).toStringAsFixed(1)}%')),
          ]);
        }).toList(),
      ),
    );
  }

  Widget _buildChart(BuildContext context) {
    final top = _rows.take(8).toList();
    final bars = top
        .asMap()
        .entries
        .map((e) => BarChartGroupData(x: e.key, barRods: [BarChartRodData(toY: (e.value['total'] as int).toDouble(), color: Theme.of(context).colorScheme.primary)]))
        .toList();
    return Padding(
      padding: const EdgeInsets.all(12),
      child: BarChart(
        BarChartData(
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx >= 0 && idx < top.length) {
                    final label = (top[idx]['country'] as String);
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(label.length > 8 ? '${label.substring(0, 8)}…' : label, style: const TextStyle(fontSize: 10)),
                    );
                  }
                  return const SizedBox.shrink();
                },
                reservedSize: 68,
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(show: true),
          barGroups: bars,
        ),
      ),
    );
  }
}

