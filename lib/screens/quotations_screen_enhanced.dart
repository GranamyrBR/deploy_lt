import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../services/quotation_service.dart';
import '../models/enhanced_quotation_model.dart';
import '../widgets/quotation_management_dialog.dart';
import '../widgets/enhanced_quotation_dialog.dart';

class QuotationsScreenEnhanced extends ConsumerStatefulWidget {
  const QuotationsScreenEnhanced({super.key});

  @override
  ConsumerState<QuotationsScreenEnhanced> createState() => _QuotationsScreenEnhancedState();
}

class _QuotationsScreenEnhancedState extends ConsumerState<QuotationsScreenEnhanced> {
  final _quotationService = QuotationService();
  List<Map<String, dynamic>> _quotations = [];
  List<Map<String, dynamic>> _filteredQuotations = [];
  bool _isLoading = true;
  
  // Filtros
  String? _selectedStatus;
  DateTimeRange? _dateRange;
  List<String> _selectedTags = [];
  String _searchQuery = '';
  bool _showOnlyFollowUps = false;

  @override
  void initState() {
    super.initState();
    _loadQuotations();
  }

  Future<void> _loadQuotations() async {
    setState(() => _isLoading = true);
    
    try {
      final data = await _quotationService.getQuotations(
        filter: const QuotationFilter(limit: 200),
      );
      
      if (mounted) {
        setState(() {
          _quotations = data;
          _applyFilters();
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Erro ao carregar cotações: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _applyFilters() {
    _filteredQuotations = _quotations.where((q) {
      // Filtro de status
      if (_selectedStatus != null && q['status'] != _selectedStatus) {
        return false;
      }
      
      // Filtro de data
      if (_dateRange != null) {
        final quotationDate = DateTime.parse(q['quotation_date'] ?? q['created_at']);
        if (quotationDate.isBefore(_dateRange!.start) || 
            quotationDate.isAfter(_dateRange!.end)) {
          return false;
        }
      }
      
      // Filtro de busca
      if (_searchQuery.isNotEmpty) {
        final searchLower = _searchQuery.toLowerCase();
        final clientName = (q['client_name'] ?? '').toString().toLowerCase();
        final quotationNumber = (q['quotation_number'] ?? '').toString().toLowerCase();
        final destination = (q['destination'] ?? '').toString().toLowerCase();
        
        if (!clientName.contains(searchLower) && 
            !quotationNumber.contains(searchLower) &&
            !destination.contains(searchLower)) {
          return false;
        }
      }
      
      // Filtro de follow-ups pendentes
      if (_showOnlyFollowUps) {
        final followUpDate = q['follow_up_date'];
        if (followUpDate == null) return false;
        final followUp = DateTime.parse(followUpDate);
        if (followUp.isAfter(DateTime.now())) return false;
      }
      
      // Filtro de tags
      if (_selectedTags.isNotEmpty) {
        final quotationTags = (q['tags'] as List?)?.cast<String>() ?? [];
        if (!_selectedTags.any((tag) => quotationTags.contains(tag))) {
          return false;
        }
      }
      
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cotações'),
        actions: [
          // Contador de follow-ups pendentes
          _buildFollowUpBadge(),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFiltersDialog,
            tooltip: 'Filtros',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadQuotations,
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de busca e filtros ativos
          _buildSearchAndFiltersBar(),
          
          // Lista de cotações
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredQuotations.isEmpty
                    ? _buildEmptyState()
                    : _buildQuotationsList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateQuotationDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Nova Cotação'),
      ),
    );
  }

  Widget _buildFollowUpBadge() {
    final pendingFollowUps = _quotations.where((q) {
      final followUpDate = q['follow_up_date'];
      if (followUpDate == null) return false;
      final followUp = DateTime.parse(followUpDate);
      return followUp.isBefore(DateTime.now()) || 
             followUp.difference(DateTime.now()).inHours < 24;
    }).length;

    if (pendingFollowUps == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Chip(
        avatar: const Icon(Icons.notification_important, size: 16, color: Colors.white),
        label: Text(
          '$pendingFollowUps Follow-up${pendingFollowUps > 1 ? 's' : ''}',
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
        backgroundColor: Colors.red,
        onDeleted: () {
          setState(() {
            _showOnlyFollowUps = !_showOnlyFollowUps;
            _applyFilters();
          });
        },
        deleteIcon: Icon(
          _showOnlyFollowUps ? Icons.close : Icons.filter_alt,
          size: 16,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildSearchAndFiltersBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Barra de busca
          TextField(
            decoration: InputDecoration(
              hintText: 'Buscar por cliente, número ou destino...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                          _applyFilters();
                        });
                      },
                    )
                  : null,
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
                _applyFilters();
              });
            },
          ),
          
          const SizedBox(height: 12),
          
          // Chips de filtros ativos
          if (_hasActiveFilters()) _buildActiveFiltersChips(),
        ],
      ),
    );
  }

  bool _hasActiveFilters() {
    return _selectedStatus != null ||
           _dateRange != null ||
           _selectedTags.isNotEmpty ||
           _showOnlyFollowUps;
  }

  Widget _buildActiveFiltersChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (_selectedStatus != null)
          Chip(
            label: Text('Status: $_selectedStatus'),
            onDeleted: () {
              setState(() {
                _selectedStatus = null;
                _applyFilters();
              });
            },
          ),
        if (_dateRange != null)
          Chip(
            label: Text(
              'Período: ${DateFormat('dd/MM').format(_dateRange!.start)} - ${DateFormat('dd/MM').format(_dateRange!.end)}',
            ),
            onDeleted: () {
              setState(() {
                _dateRange = null;
                _applyFilters();
              });
            },
          ),
        if (_showOnlyFollowUps)
          Chip(
            label: const Text('Follow-ups Pendentes'),
            backgroundColor: Colors.red.shade100,
            onDeleted: () {
              setState(() {
                _showOnlyFollowUps = false;
                _applyFilters();
              });
            },
          ),
        ..._selectedTags.map((tag) => Chip(
          label: Text(tag),
          onDeleted: () {
            setState(() {
              _selectedTags.remove(tag);
              _applyFilters();
            });
          },
        )),
        TextButton.icon(
          onPressed: () {
            setState(() {
              _selectedStatus = null;
              _dateRange = null;
              _selectedTags.clear();
              _showOnlyFollowUps = false;
              _applyFilters();
            });
          },
          icon: const Icon(Icons.clear_all, size: 16),
          label: const Text('Limpar Filtros'),
        ),
      ],
    );
  }

  Widget _buildQuotationsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredQuotations.length,
      itemBuilder: (context, index) {
        final quotation = _filteredQuotations[index];
        return _buildQuotationCard(quotation);
      },
    );
  }

  Widget _buildQuotationCard(Map<String, dynamic> quotation) {
    final status = quotation['status'] ?? 'draft';
    final total = quotation['total'] ?? 0.0;
    final currency = quotation['currency'] ?? 'USD';
    final clientName = quotation['client_name'] ?? 'Cliente';
    final destination = quotation['destination'] ?? '';
    final quotationNumber = quotation['quotation_number'] ?? '';
    final quotationDate = DateTime.parse(quotation['quotation_date'] ?? quotation['created_at']);
    final followUpDate = quotation['follow_up_date'] != null 
        ? DateTime.parse(quotation['follow_up_date'])
        : null;
    final tags = (quotation['tags'] as List?)?.cast<String>() ?? [];
    
    final isFollowUpDue = followUpDate != null && followUpDate.isBefore(DateTime.now());
    final isFollowUpSoon = followUpDate != null && 
        followUpDate.isAfter(DateTime.now()) &&
        followUpDate.difference(DateTime.now()).inHours < 24;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isFollowUpDue 
            ? const BorderSide(color: Colors.red, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => _openQuotationDetails(quotation),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Número e Status
              Row(
                children: [
                  Expanded(
                    child: Text(
                      quotationNumber,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  _buildStatusChip(status),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Cliente e Destino
              Row(
                children: [
                  const Icon(Icons.person, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      clientName,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
              
              if (destination.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        destination,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ],
              
              const SizedBox(height: 12),
              
              // Valor e Data
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      NumberFormat.currency(symbol: currency == 'USD' ? '\$' : 'R\$').format(total),
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    DateFormat('dd/MM/yyyy').format(quotationDate),
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
              
              // Follow-up Alert
              if (isFollowUpDue || isFollowUpSoon) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isFollowUpDue ? Colors.red.shade50 : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isFollowUpDue ? Colors.red : Colors.orange,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.alarm,
                        size: 16,
                        color: isFollowUpDue ? Colors.red : Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isFollowUpDue 
                              ? 'Follow-up ATRASADO!'
                              : 'Follow-up hoje: ${DateFormat('HH:mm').format(followUpDate)}',
                          style: TextStyle(
                            color: isFollowUpDue ? Colors.red.shade700 : Colors.orange.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              // Tags
              if (tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: tags.map((tag) => Chip(
                    label: Text(tag, style: const TextStyle(fontSize: 11)),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    visualDensity: VisualDensity.compact,
                  )).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;
    
    switch (status.toLowerCase()) {
      case 'draft':
        color = Colors.grey;
        label = 'Rascunho';
        break;
      case 'sent':
        color = Colors.blue;
        label = 'Enviado';
        break;
      case 'viewed':
        color = Colors.purple;
        label = 'Visualizado';
        break;
      case 'accepted':
        color = Colors.green;
        label = 'Aceito';
        break;
      case 'rejected':
        color = Colors.red;
        label = 'Rejeitado';
        break;
      case 'expired':
        color = Colors.orange;
        label = 'Expirado';
        break;
      default:
        color = Colors.grey;
        label = status;
    }
    
    return Chip(
      label: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.description_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            _hasActiveFilters() 
                ? 'Nenhuma cotação encontrada com os filtros aplicados'
                : 'Nenhuma cotação cadastrada',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
          ),
          if (_hasActiveFilters()) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _selectedStatus = null;
                  _dateRange = null;
                  _selectedTags.clear();
                  _showOnlyFollowUps = false;
                  _applyFilters();
                });
              },
              icon: const Icon(Icons.clear_all),
              label: const Text('Limpar Filtros'),
            ),
          ],
        ],
      ),
    );
  }

  void _showFiltersDialog() {
    showDialog(
      context: context,
      builder: (context) => _FiltersDialog(
        selectedStatus: _selectedStatus,
        dateRange: _dateRange,
        selectedTags: _selectedTags,
        allTags: _getAllTags(),
        onApply: (status, dateRange, tags) {
          setState(() {
            _selectedStatus = status;
            _dateRange = dateRange;
            _selectedTags = tags;
            _applyFilters();
          });
        },
      ),
    );
  }

  List<String> _getAllTags() {
    final allTags = <String>{};
    for (var q in _quotations) {
      final tags = (q['tags'] as List?)?.cast<String>() ?? [];
      allTags.addAll(tags);
    }
    return allTags.toList()..sort();
  }

  void _showCreateQuotationDialog() {
    showDialog(
      context: context,
      builder: (context) => const EnhancedQuotationDialog(),
    ).then((_) => _loadQuotations());
  }

  void _openQuotationDetails(Map<String, dynamic> quotation) async {
    final quotationId = quotation['id'];
    
    try {
      final fullQuotation = await _quotationService.getById(quotationId);
      if (fullQuotation == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cotação não encontrada')),
          );
        }
        return;
      }

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => QuotationManagementDialog(
            quotation: Quotation.fromJson(fullQuotation.quotation),
          ),
        ).then((_) => _loadQuotations());
      }
    } catch (e) {
      print('Erro ao abrir cotação: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao abrir: $e')),
        );
      }
    }
  }
}

// Dialog de Filtros
class _FiltersDialog extends StatefulWidget {
  final String? selectedStatus;
  final DateTimeRange? dateRange;
  final List<String> selectedTags;
  final List<String> allTags;
  final Function(String?, DateTimeRange?, List<String>) onApply;

  const _FiltersDialog({
    required this.selectedStatus,
    required this.dateRange,
    required this.selectedTags,
    required this.allTags,
    required this.onApply,
  });

  @override
  State<_FiltersDialog> createState() => _FiltersDialogState();
}

class _FiltersDialogState extends State<_FiltersDialog> {
  late String? _status;
  late DateTimeRange? _dateRange;
  late List<String> _tags;

  @override
  void initState() {
    super.initState();
    _status = widget.selectedStatus;
    _dateRange = widget.dateRange;
    _tags = List.from(widget.selectedTags);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Filtros'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status
            const Text('Status:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['draft', 'sent', 'viewed', 'accepted', 'rejected', 'expired']
                  .map((status) => FilterChip(
                        label: Text(_getStatusLabel(status)),
                        selected: _status == status,
                        onSelected: (selected) {
                          setState(() {
                            _status = selected ? status : null;
                          });
                        },
                      ))
                  .toList(),
            ),
            
            const SizedBox(height: 16),
            
            // Período
            const Text('Período:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_dateRange == null 
                  ? 'Selecionar período...'
                  : '${DateFormat('dd/MM/yyyy').format(_dateRange!.start)} - ${DateFormat('dd/MM/yyyy').format(_dateRange!.end)}'),
              trailing: _dateRange != null 
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _dateRange = null),
                    )
                  : const Icon(Icons.calendar_today),
              onTap: () async {
                final range = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                  initialDateRange: _dateRange,
                );
                if (range != null) {
                  setState(() => _dateRange = range);
                }
              },
            ),
            
            const SizedBox(height: 16),
            
            // Tags
            if (widget.allTags.isNotEmpty) ...[
              const Text('Tags:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: widget.allTags
                    .map((tag) => FilterChip(
                          label: Text(tag),
                          selected: _tags.contains(tag),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _tags.add(tag);
                              } else {
                                _tags.remove(tag);
                              }
                            });
                          },
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () {
            setState(() {
              _status = null;
              _dateRange = null;
              _tags.clear();
            });
          },
          child: const Text('Limpar'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onApply(_status, _dateRange, _tags);
            Navigator.pop(context);
          },
          child: const Text('Aplicar'),
        ),
      ],
    );
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'draft': return 'Rascunho';
      case 'sent': return 'Enviado';
      case 'viewed': return 'Visualizado';
      case 'accepted': return 'Aceito';
      case 'rejected': return 'Rejeitado';
      case 'expired': return 'Expirado';
      default: return status;
    }
  }
}


