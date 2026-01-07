import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../services/quotation_service.dart';
import '../services/quotation_to_sale_converter.dart';
import '../models/enhanced_quotation_model.dart';
import '../screens/create_sale_screen_v2.dart';
import '../widgets/quotation_detail_dialog_premium.dart';
import '../widgets/enhanced_quotation_dialog.dart';
import 'quotations_table_view.dart';
import '../widgets/quotation_tag_selector.dart';
import '../screens/quotation_tags_management_screen.dart';

class QuotationsScreenPremium extends ConsumerStatefulWidget {
  const QuotationsScreenPremium({Key? key}) : super(key: key);

  @override
  ConsumerState<QuotationsScreenPremium> createState() => _QuotationsScreenPremiumState();
}

class _QuotationsScreenPremiumState extends ConsumerState<QuotationsScreenPremium> {
  final _quotationService = QuotationService();
  List<Map<String, dynamic>> _quotations = [];
  List<Map<String, dynamic>> _filteredQuotations = [];
  bool _isLoading = true;
  
  // Filtros
  String? _selectedStatus;
  DateTimeRange? _dateRange;
  String _searchQuery = '';
  String _viewMode = 'cards'; // cards, list ou table
  String? _travelPeriodFilter; // Novo: filtro por período de viagem
  
  // Ordenação
  String _sortField = 'travel_date'; // Mudado para data de viagem
  bool _sortAscending = true; // Mais próximas primeiro

  @override
  void initState() {
    super.initState();
    _loadQuotations();
  }

  Future<void> _loadQuotations() async {
    setState(() => _isLoading = true);
    
    try {
      final data = await _quotationService.getQuotations(
        filter: QuotationFilter(limit: 200),
      );
      
      if (mounted) {
        setState(() {
          // 🆕 FILTRAR COTAÇÕES CANCELADAS (soft delete)
          // Apenas gestores podem ver canceladas através de tela específica
          _quotations = data.where((q) => q['status'] != 'cancelled').toList();
          _applyFilters();
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Erro ao carregar cotações: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Erro ao carregar: $e')),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  void _applyFilters() {
    _filteredQuotations = _quotations.where((q) {
      if (_selectedStatus != null && q['status'] != _selectedStatus) return false;
      
      if (_dateRange != null) {
        final quotationDate = DateTime.parse(q['quotation_date'] ?? q['created_at']);
        if (quotationDate.isBefore(_dateRange!.start) || 
            quotationDate.isAfter(_dateRange!.end)) return false;
      }
      
      // 🆕 FILTRO POR PERÍODO DE VIAGEM
      if (_travelPeriodFilter != null) {
        final travelDateStr = q['travel_date'];
        if (travelDateStr == null) return false;
        
        final travelDate = DateTime.tryParse(travelDateStr);
        if (travelDate == null) return false;
        
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final travelDay = DateTime(travelDate.year, travelDate.month, travelDate.day);
        
        DateTime endDate;
        switch (_travelPeriodFilter) {
          case 'today':
            endDate = today;
            break;
          case 'week':
            endDate = today.add(const Duration(days: 7));
            break;
          case 'month':
            endDate = today.add(const Duration(days: 30));
            break;
          case 'bimester':
            endDate = today.add(const Duration(days: 60));
            break;
          case 'trimester':
            endDate = today.add(const Duration(days: 90));
            break;
          default:
            endDate = today.add(const Duration(days: 365));
        }
        
        if (travelDay.isBefore(today) || travelDay.isAfter(endDate)) return false;
      }
      
      if (_searchQuery.isNotEmpty) {
        final searchLower = _searchQuery.toLowerCase();
        final clientName = (q['client_name'] ?? '').toString().toLowerCase();
        final quotationNumber = (q['quotation_number'] ?? '').toString().toLowerCase();
        final destination = (q['destination'] ?? '').toString().toLowerCase();
        
        if (!clientName.contains(searchLower) && 
            !quotationNumber.contains(searchLower) &&
            !destination.contains(searchLower)) return false;
      }
      
      return true;
    }).toList();
    
    _sortQuotations();
  }

  void _sortQuotations() {
    _filteredQuotations.sort((a, b) {
      dynamic aValue;
      dynamic bValue;
      
      switch (_sortField) {
        case 'quotation_number':
          aValue = a['quotation_number'] ?? '';
          bValue = b['quotation_number'] ?? '';
          break;
        case 'client_name':
          aValue = a['client_name'] ?? '';
          bValue = b['client_name'] ?? '';
          break;
        case 'destination':
          aValue = a['destination'] ?? '';
          bValue = b['destination'] ?? '';
          break;
        case 'status':
          aValue = a['status'] ?? '';
          bValue = b['status'] ?? '';
          break;
        case 'travel_date': // 🆕 Ordenar por data de viagem
          aValue = DateTime.tryParse(a['travel_date'] ?? '') ?? DateTime(2099);
          bValue = DateTime.tryParse(b['travel_date'] ?? '') ?? DateTime(2099);
          break;
        case 'quotation_date':
          aValue = DateTime.tryParse(a['quotation_date'] ?? a['created_at'] ?? '') ?? DateTime(1970);
          bValue = DateTime.tryParse(b['quotation_date'] ?? b['created_at'] ?? '') ?? DateTime(1970);
          break;
        case 'total':
          aValue = a['total'] ?? 0.0;
          bValue = b['total'] ?? 0.0;
          break;
        default:
          return 0;
      }
      
      int comparison;
      if (aValue is DateTime && bValue is DateTime) {
        comparison = aValue.compareTo(bValue);
      } else if (aValue is num && bValue is num) {
        comparison = aValue.compareTo(bValue);
      } else {
        comparison = aValue.toString().compareTo(bValue.toString());
      }
      
      return _sortAscending ? comparison : -comparison;
    });
  }

  // 🆕 MÉTODOS HELPER PARA URGÊNCIA
  int _calculateDaysUntilTravel(String? travelDateStr) {
    if (travelDateStr == null) return 999;
    final travelDate = DateTime.tryParse(travelDateStr);
    if (travelDate == null) return 999;
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final travelDay = DateTime(travelDate.year, travelDate.month, travelDate.day);
    
    return travelDay.difference(today).inDays;
  }

  Color _getUrgencyColor(int days) {
    if (days < 0) return Colors.grey.shade400; // Já passou
    if (days <= 3) return Colors.red.shade700; // CRÍTICO
    if (days <= 7) return Colors.orange.shade600; // URGENTE
    if (days <= 14) return Colors.amber.shade500; // PRÓXIMO
    if (days <= 30) return Colors.green.shade500; // NORMAL
    if (days <= 90) return Colors.blue.shade400; // FUTURO
    if (days <= 999) return Colors.indigo.shade300; // DISTANTE
    return Colors.grey.shade400; // SEM DATA
  }

  Color _getUrgencyBackgroundColor(int days) {
    if (days < 0) return Colors.grey.shade100;
    if (days <= 3) return Colors.red.shade50;
    if (days <= 7) return Colors.orange.shade50;
    if (days <= 14) return Colors.amber.shade50;
    if (days <= 30) return Colors.green.shade50;
    if (days <= 90) return Colors.blue.shade50;
    if (days <= 999) return Colors.indigo.shade50;
    return Colors.grey.shade50;
  }

  String _getUrgencyLabel(int days) {
    if (days < 0) return '⏱️ PASSOU';
    if (days == 0) return '🔥 HOJE!';
    if (days == 1) return '🔥 AMANHÃ!';
    if (days <= 3) return '🔥 ${days}D - URGENTE';
    if (days <= 7) return '⚠️ ${days}D - ATENÇÃO';
    if (days <= 14) return '📅 ${days}D - PRÓXIMA';
    if (days <= 30) return '✅ ${days}D';
    if (days <= 90) return '📆 ${days}D';
    if (days <= 999) return '🗓️ ${days}D';
    return '❓ SEM DATA';
  }

  double _getUrgencyBorderWidth(int days) {
    if (days <= 3) return 4.0; // Borda grossa
    if (days <= 7) return 3.0; // Borda média
    if (days <= 14) return 2.0; // Borda fina
    return 0.0; // Sem borda
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      body: Column(
        children: [
          // Header Premium
          _buildPremiumHeader(isDark),
          
          // Stats Cards
          _buildStatsCards(isDark),
          
          // Filtros e Busca
          _buildFiltersBar(isDark),
          
          // Lista de Cotações
          Expanded(
            child: _isLoading
                ? _buildLoadingState()
                : _filteredQuotations.isEmpty
                    ? _buildEmptyState(isDark)
                    : _viewMode == 'cards' 
                        ? _buildCardsView(isDark)
                        : _viewMode == 'list'
                            ? _buildListView(isDark)
                            : _buildTableView(isDark),
          ),
        ],
      ),
      floatingActionButton: _buildFAB(isDark),
    );
  }

  Widget _buildPremiumHeader(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark 
              ? [Colors.blue.shade900, Colors.purple.shade900]
              : [Colors.blue.shade600, Colors.purple.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.receipt_long, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cotações',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Gestão Completa de Propostas',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _loadQuotations,
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                tooltip: 'Atualizar',
              ),
              PopupMenuButton<String>(
                icon: Icon(
                  _viewMode == 'cards' 
                      ? Icons.view_module
                      : _viewMode == 'list'
                          ? Icons.view_list
                          : Icons.table_chart,
                  color: Colors.white,
                ),
                tooltip: 'Modo de Visualização',
                onSelected: (value) {
                  setState(() {
                    _viewMode = value;
                  });
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'cards',
                    child: Row(
                      children: [
                        Icon(Icons.view_module),
                        SizedBox(width: 12),
                        Text('Cards'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'list',
                    child: Row(
                      children: [
                        Icon(Icons.view_list),
                        SizedBox(width: 12),
                        Text('Lista'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'table',
                    child: Row(
                      children: [
                        Icon(Icons.table_chart),
                        SizedBox(width: 12),
                        Text('Tabela'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards(bool isDark) {
    final total = _quotations.length;
    final pending = _quotations.where((q) => q['status'] == 'sent' || q['status'] == 'viewed').length;
    final accepted = _quotations.where((q) => q['status'] == 'accepted').length;
    final totalValue = _quotations.fold<double>(0, (sum, q) => sum + ((q['total'] ?? 0) as num).toDouble());
    
    final pendingFollowUps = _quotations.where((q) {
      final followUpDate = q['follow_up_date'];
      if (followUpDate == null) return false;
      return DateTime.parse(followUpDate).isBefore(DateTime.now().add(const Duration(days: 1)));
    }).length;
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildStatCard(
              icon: Icons.description_outlined,
              title: 'Total',
              value: total.toString(),
              color: Colors.blue,
              isDark: isDark,
            ),
            _buildStatCard(
              icon: Icons.hourglass_empty,
              title: 'Pendentes',
              value: pending.toString(),
              color: Colors.orange,
              isDark: isDark,
            ),
            _buildStatCard(
              icon: Icons.check_circle_outline,
              title: 'Aceitas',
              value: accepted.toString(),
              color: Colors.green,
              isDark: isDark,
            ),
            _buildStatCard(
              icon: Icons.attach_money,
              title: 'Valor Total',
              value: NumberFormat.compact().format(totalValue),
              color: Colors.purple,
              isDark: isDark,
            ),
            if (pendingFollowUps > 0)
              _buildStatCard(
                icon: Icons.notification_important,
                title: 'Follow-ups Urgentes',
                value: pendingFollowUps.toString(),
                color: Colors.red,
                isDark: isDark,
                isPulse: true,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required bool isDark,
    bool isPulse = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isPulse ? Border.all(color: color, width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: isPulse ? color.withOpacity(0.3) : Colors.black.withOpacity(0.05),
            blurRadius: isPulse ? 15 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Barra de Busca
          TextField(
            decoration: InputDecoration(
              hintText: '🔍 Buscar por cliente, número ou destino...',
              filled: true,
              fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              prefixIcon: Icon(Icons.search, color: Colors.blue[600]),
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
          
          // Filtros Rápidos - STATUS
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(
                  label: 'Todos',
                  icon: Icons.all_inclusive,
                  color: Colors.grey,
                  isSelected: _selectedStatus == null,
                  onTap: () {
                    setState(() {
                      _selectedStatus = null;
                      _applyFilters();
                    });
                  },
                  isDark: isDark,
                ),
                _buildFilterChip(
                  label: 'Rascunho',
                  icon: Icons.edit_note,
                  color: Colors.grey,
                  isSelected: _selectedStatus == 'draft',
                  onTap: () {
                    setState(() {
                      _selectedStatus = 'draft';
                      _applyFilters();
                    });
                  },
                  isDark: isDark,
                ),
                _buildFilterChip(
                  label: 'Enviado',
                  icon: Icons.send,
                  color: Colors.blue,
                  isSelected: _selectedStatus == 'sent',
                  onTap: () {
                    setState(() {
                      _selectedStatus = 'sent';
                      _applyFilters();
                    });
                  },
                  isDark: isDark,
                ),
                _buildFilterChip(
                  label: 'Visualizado',
                  icon: Icons.visibility,
                  color: Colors.purple,
                  isSelected: _selectedStatus == 'viewed',
                  onTap: () {
                    setState(() {
                      _selectedStatus = 'viewed';
                      _applyFilters();
                    });
                  },
                  isDark: isDark,
                ),
                _buildFilterChip(
                  label: 'Aceito',
                  icon: Icons.check_circle,
                  color: Colors.green,
                  isSelected: _selectedStatus == 'accepted',
                  onTap: () {
                    setState(() {
                      _selectedStatus = 'accepted';
                      _applyFilters();
                    });
                  },
                  isDark: isDark,
                ),
                _buildFilterChip(
                  label: 'Rejeitado',
                  icon: Icons.cancel,
                  color: Colors.red,
                  isSelected: _selectedStatus == 'rejected',
                  onTap: () {
                    setState(() {
                      _selectedStatus = 'rejected';
                      _applyFilters();
                    });
                  },
                  isDark: isDark,
                ),
                const SizedBox(width: 8),
                _buildDateRangeButton(isDark),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // 🆕 FILTROS TEMPORAIS - PERÍODO DE VIAGEM
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Text(
                  '✈️ Viagem em:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(width: 12),
                _buildFilterChip(
                  label: 'Hoje',
                  icon: Icons.today,
                  color: Colors.red,
                  isSelected: _travelPeriodFilter == 'today',
                  onTap: () {
                    setState(() {
                      _travelPeriodFilter = _travelPeriodFilter == 'today' ? null : 'today';
                      _applyFilters();
                    });
                  },
                  isDark: isDark,
                ),
                _buildFilterChip(
                  label: 'Esta Semana',
                  icon: Icons.date_range,
                  color: Colors.orange,
                  isSelected: _travelPeriodFilter == 'week',
                  onTap: () {
                    setState(() {
                      _travelPeriodFilter = _travelPeriodFilter == 'week' ? null : 'week';
                      _applyFilters();
                    });
                  },
                  isDark: isDark,
                ),
                _buildFilterChip(
                  label: 'Este Mês',
                  icon: Icons.calendar_month,
                  color: Colors.amber,
                  isSelected: _travelPeriodFilter == 'month',
                  onTap: () {
                    setState(() {
                      _travelPeriodFilter = _travelPeriodFilter == 'month' ? null : 'month';
                      _applyFilters();
                    });
                  },
                  isDark: isDark,
                ),
                _buildFilterChip(
                  label: 'Bimestre',
                  icon: Icons.event_note,
                  color: Colors.green,
                  isSelected: _travelPeriodFilter == 'bimester',
                  onTap: () {
                    setState(() {
                      _travelPeriodFilter = _travelPeriodFilter == 'bimester' ? null : 'bimester';
                      _applyFilters();
                    });
                  },
                  isDark: isDark,
                ),
                _buildFilterChip(
                  label: 'Trimestre',
                  icon: Icons.calendar_view_month,
                  color: Colors.blue,
                  isSelected: _travelPeriodFilter == 'trimester',
                  onTap: () {
                    setState(() {
                      _travelPeriodFilter = _travelPeriodFilter == 'trimester' ? null : 'trimester';
                      _applyFilters();
                    });
                  },
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : color),
            const SizedBox(width: 6),
            Text(label),
          ],
        ),
        selected: isSelected,
        onSelected: (_) => onTap(),
        backgroundColor: isDark ? Colors.grey[800] : Colors.grey[100],
        selectedColor: color,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        side: BorderSide(
          color: isSelected ? color : Colors.transparent,
          width: 2,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  Widget _buildDateRangeButton(bool isDark) {
    return OutlinedButton.icon(
      onPressed: () async {
        final range = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          initialDateRange: _dateRange,
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(
                  primary: Colors.blue.shade600,
                ),
              ),
              child: child!,
            );
          },
        );
        if (range != null) {
          setState(() {
            _dateRange = range;
            _applyFilters();
          });
        }
      },
      icon: Icon(
        Icons.calendar_today,
        size: 16,
        color: _dateRange != null ? Colors.blue : (isDark ? Colors.white70 : Colors.black54),
      ),
      label: Text(
        _dateRange != null
            ? '${DateFormat('dd/MM').format(_dateRange!.start)} - ${DateFormat('dd/MM').format(_dateRange!.end)}'
            : 'Período',
        style: TextStyle(
          color: isDark ? Colors.white70 : Colors.black87,
        ),
      ),
      style: OutlinedButton.styleFrom(
        backgroundColor: _dateRange != null 
            ? Colors.blue.withOpacity(0.1) 
            : (isDark ? Colors.grey[800] : Colors.grey[100]),
        side: BorderSide(
          color: _dateRange != null ? Colors.blue : Colors.transparent,
          width: 2,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  Widget _buildCardsView(bool isDark) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 3 : 
                       MediaQuery.of(context).size.width > 800 ? 2 : 1,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.2, // 🔧 Reduzido de 1.4 para 1.2 para dar mais altura
      ),
      itemCount: _filteredQuotations.length,
      itemBuilder: (context, index) {
        return _buildPremiumCard(_filteredQuotations[index], isDark);
      },
    );
  }

  Widget _buildListView(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredQuotations.length,
      itemBuilder: (context, index) {
        return _buildListItem(_filteredQuotations[index], isDark);
      },
    );
  }

  Widget _buildTableView(bool isDark) {
    return QuotationsTableView(
      quotations: _filteredQuotations,
      isDark: isDark,
      onQuotationTap: _openQuotationDetails,
      sortField: _sortField,
      sortAscending: _sortAscending,
      onSort: (field) {
        setState(() {
          if (_sortField == field) {
            _sortAscending = !_sortAscending;
          } else {
            _sortField = field;
            _sortAscending = true;
          }
          _sortQuotations();
        });
      },
      onEdit: _editQuotation,
      onDuplicate: _duplicateQuotation,
      onDelete: _deleteQuotation,
    );
  }


  Widget _buildPremiumCard(Map<String, dynamic> quotation, bool isDark) {
    final status = quotation['status'] ?? 'draft';
    final total = quotation['total'] ?? 0.0;
    final currency = quotation['currency'] ?? 'USD';
    final clientName = quotation['client_name'] ?? 'Cliente';
    final destination = quotation['destination'] ?? 'Destino não informado';
    final quotationNumber = quotation['quotation_number'] ?? '';
    final quotationDate = DateTime.parse(quotation['quotation_date'] ?? quotation['created_at']);
    
    // 🆕 DATAS DE VIAGEM
    final travelDateStr = quotation['travel_date'];
    final returnDateStr = quotation['return_date'];
    final travelDate = travelDateStr != null ? DateTime.tryParse(travelDateStr) : null;
    final returnDate = returnDateStr != null ? DateTime.tryParse(returnDateStr) : null;
    final daysUntilTravel = _calculateDaysUntilTravel(travelDateStr);
    
    // 🆕 CORES DE URGÊNCIA
    final urgencyColor = _getUrgencyColor(daysUntilTravel);
    final urgencyBg = _getUrgencyBackgroundColor(daysUntilTravel);
    final urgencyLabel = _getUrgencyLabel(daysUntilTravel);
    final borderWidth = _getUrgencyBorderWidth(daysUntilTravel);
    
    final statusColor = _getStatusColor(status);
    
    return Card(
      elevation: borderWidth > 0 ? 8 : 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: borderWidth > 0
            ? BorderSide(color: urgencyColor, width: borderWidth)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => _openQuotationDetails(quotation),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: travelDate != null ? urgencyBg : (isDark ? Colors.grey[850] : Colors.white),
          ),
          child: Stack(
            children: [
              // Content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header com Status
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _getStatusIcon(status),
                            color: statusColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                quotationNumber,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                _getStatusLabel(status),
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // 🆕 DATAS DE VIAGEM - DESTAQUE PRINCIPAL
                    if (travelDate != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: urgencyColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: urgencyColor.withOpacity(0.5),
                            width: 2,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.flight_takeoff, size: 20, color: urgencyColor),
                                const SizedBox(width: 8),
                                Text(
                                  'IDA: ${DateFormat('dd/MM/yyyy (EEE)', 'pt_BR').format(travelDate)}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: urgencyColor,
                                  ),
                                ),
                              ],
                            ),
                            if (returnDate != null) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(Icons.flight_land, size: 20, color: urgencyColor),
                                  const SizedBox(width: 8),
                                  Text(
                                    'VOLTA: ${DateFormat('dd/MM/yyyy (EEE)', 'pt_BR').format(returnDate)}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: urgencyColor,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    
                    // Cliente
                    Row(
                      children: [
                        Icon(Icons.person_outline, size: 18, color: Colors.blue[600]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            clientName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Destino
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 18, color: Colors.purple[600]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            destination,
                            style: const TextStyle(fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // 🏷️ TAGS
                    FutureBuilder(
                      future: ref.read(quotationTagProvider).getTagsByQuotationId(quotation['id']),
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                          return QuotationTagDisplay(
                            tags: snapshot.data!,
                            maxVisible: 3,
                            size: 20,
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                    
                    const Spacer(),
                    
                    const Divider(),
                    
                    // Footer
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Valor',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                ),
                              ),
                              Text(
                                NumberFormat.currency(
                                  symbol: currency == 'USD' ? '\$' : 'R\$',
                                  decimalDigits: 2,
                                ).format(total),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Criado em',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                              ),
                            ),
                            Text(
                              DateFormat('dd/MM/yy').format(quotationDate),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // 🆕 Badge de Urgência e Menu de Ações
              Positioned(
                top: 12,
                right: 12,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Badge de urgência
                    if (travelDate != null && daysUntilTravel <= 14)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: urgencyColor,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: urgencyColor.withOpacity(0.5),
                              blurRadius: daysUntilTravel <= 3 ? 12 : 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (daysUntilTravel <= 3)
                              const Icon(Icons.priority_high, color: Colors.white, size: 16)
                            else if (daysUntilTravel <= 7)
                              const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 16)
                            else
                              const Icon(Icons.calendar_today, color: Colors.white, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              urgencyLabel,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    // 🆕 Menu de Ações CRUD
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert, color: Colors.grey[700], size: 20),
                        onSelected: (value) => _handleCardAction(value, quotation),
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'convert_to_sale',
                            child: Row(
                              children: [
                                Icon(Icons.point_of_sale, color: Colors.green, size: 20),
                                SizedBox(width: 12),
                                Text('💰 Criar Venda', style: TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, color: Colors.blue, size: 20),
                                SizedBox(width: 12),
                                Text('Editar'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'tags',
                            child: Row(
                              children: [
                                Icon(Icons.label, color: Colors.purple, size: 20),
                                SizedBox(width: 12),
                                Text('Gerenciar Tags'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'duplicate',
                            child: Row(
                              children: [
                                Icon(Icons.content_copy, color: Colors.orange, size: 20),
                                SizedBox(width: 12),
                                Text('Duplicar'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red, size: 20),
                                SizedBox(width: 12),
                                Text('Deletar'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListItem(Map<String, dynamic> quotation, bool isDark) {
    final status = quotation['status'] ?? 'draft';
    final total = quotation['total'] ?? 0.0;
    final currency = quotation['currency'] ?? 'USD';
    final clientName = quotation['client_name'] ?? 'Cliente';
    final destination = quotation['destination'] ?? '';
    final quotationNumber = quotation['quotation_number'] ?? '';
    final quotationDate = DateTime.parse(quotation['quotation_date'] ?? quotation['created_at']);
    
    // 🆕 DATAS DE VIAGEM E URGÊNCIA
    final travelDateStr = quotation['travel_date'];
    final returnDateStr = quotation['return_date'];
    final travelDate = travelDateStr != null ? DateTime.tryParse(travelDateStr) : null;
    final returnDate = returnDateStr != null ? DateTime.tryParse(returnDateStr) : null;
    final daysUntilTravel = _calculateDaysUntilTravel(travelDateStr);
    
    final urgencyColor = _getUrgencyColor(daysUntilTravel);
    final urgencyBg = _getUrgencyBackgroundColor(daysUntilTravel);
    final urgencyLabel = _getUrgencyLabel(daysUntilTravel);
    final borderWidth = _getUrgencyBorderWidth(daysUntilTravel);
    
    final statusColor = _getStatusColor(status);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: borderWidth > 0 ? 4 : 2,
      color: travelDate != null ? urgencyBg : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: borderWidth > 0
            ? BorderSide(color: urgencyColor, width: borderWidth)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => _openQuotationDetails(quotation),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Leading - Status Icon
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_getStatusIcon(status), color: statusColor),
              ),
              
              const SizedBox(width: 16),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Número da cotação
                    Text(
                      quotationNumber,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    
                    // Cliente e Destino
                    Text('👤 $clientName'),
                    if (destination.isNotEmpty) Text('📍 $destination'),
                    
                    const SizedBox(height: 8),
                    
                    // 🏷️ TAGS
                    FutureBuilder(
                      future: ref.read(quotationTagProvider).getTagsByQuotationId(quotation['id']),
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: QuotationTagDisplay(
                              tags: snapshot.data!,
                              maxVisible: 2,
                              size: 18,
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                    
                    // 🆕 DATAS DE VIAGEM
                    if (travelDate != null) ...[
                      Row(
                        children: [
                          Icon(Icons.flight_takeoff, size: 16, color: urgencyColor),
                          const SizedBox(width: 4),
                          Text(
                            'IDA: ${DateFormat('dd/MM/yyyy', 'pt_BR').format(travelDate)}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: urgencyColor,
                            ),
                          ),
                          if (returnDate != null) ...[
                            const SizedBox(width: 12),
                            Icon(Icons.flight_land, size: 16, color: urgencyColor),
                            const SizedBox(width: 4),
                            Text(
                              'VOLTA: ${DateFormat('dd/MM', 'pt_BR').format(returnDate)}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: urgencyColor,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ] else ...[
                      Text(
                        '📅 Criado: ${DateFormat('dd/MM/yyyy').format(quotationDate)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ],
                ),
              ),
              
              // Trailing - Status, Urgência, Valor e Ações
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Badge de Status
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getStatusLabel(status),
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // 🆕 Badge de Urgência
                      if (travelDate != null && daysUntilTravel <= 14)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: urgencyColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            urgencyLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      
                      const SizedBox(height: 8),
                      
                      // Valor
                      Text(
                        NumberFormat.currency(
                          symbol: currency == 'USD' ? '\$' : 'R\$',
                          decimalDigits: 2,
                        ).format(total),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green[600],
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(width: 8),
                  
                  // 🆕 Menu de Ações CRUD
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                    onSelected: (value) => _handleCardAction(value, quotation),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, color: Colors.blue, size: 18),
                            SizedBox(width: 8),
                            Text('Editar'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'tags',
                        child: Row(
                          children: [
                            Icon(Icons.label, color: Colors.purple, size: 18),
                            SizedBox(width: 8),
                            Text('Gerenciar Tags'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'duplicate',
                        child: Row(
                          children: [
                            Icon(Icons.content_copy, color: Colors.orange, size: 18),
                            SizedBox(width: 8),
                            Text('Duplicar'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red, size: 18),
                            SizedBox(width: 8),
                            Text('Deletar'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
          ),
          const SizedBox(height: 16),
          Text(
            'Carregando cotações...',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.description_outlined,
              size: 80,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Nenhuma cotação encontrada',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.grey[300] : Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedStatus != null || _dateRange != null || _searchQuery.isNotEmpty
                ? 'Tente ajustar os filtros'
                : 'Crie sua primeira cotação',
            style: TextStyle(
              color: isDark ? Colors.grey[500] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          if (_selectedStatus != null || _dateRange != null || _searchQuery.isNotEmpty)
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _selectedStatus = null;
                  _dateRange = null;
                  _searchQuery = '';
                  _applyFilters();
                });
              },
              icon: const Icon(Icons.clear_all),
              label: const Text('Limpar Filtros'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFAB(bool isDark) {
    return FloatingActionButton.extended(
      onPressed: () => _showCreateQuotationDialog(),
      icon: const Icon(Icons.add_rounded, size: 28),
      label: const Text(
        'Nova Cotação',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: Colors.blue.shade600,
      elevation: 8,
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return Colors.grey;
      case 'sent':
        return Colors.blue;
      case 'viewed':
        return Colors.purple;
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'expired':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return Icons.edit_note;
      case 'sent':
        return Icons.send;
      case 'viewed':
        return Icons.visibility;
      case 'accepted':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'expired':
        return Icons.timer_off;
      default:
        return Icons.description;
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return 'RASCUNHO';
      case 'sent':
        return 'ENVIADO';
      case 'viewed':
        return 'VISUALIZADO';
      case 'accepted':
        return 'ACEITO ✓';
      case 'rejected':
        return 'REJEITADO';
      case 'expired':
        return 'EXPIRADO';
      default:
        return status.toUpperCase();
    }
  }

  void _showCreateQuotationDialog() {
    showDialog<void>(
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
        // 🔧 Combinar quotation com items para criar o objeto completo
        final quotationData = Map<String, dynamic>.from(fullQuotation.quotation);
        quotationData['items'] = fullQuotation.items;
        
        showDialog<void>(
          context: context,
          builder: (context) => QuotationDetailDialogPremium(
            quotation: Quotation.fromJson(quotationData),
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

  // 🆕 CRUD ACTIONS
  Future<void> _handleCardAction(String action, Map<String, dynamic> quotation) async {
    switch (action) {
      case 'convert_to_sale':
        await _convertQuotationToSale(quotation);
        break;
      case 'edit':
        await _editQuotation(quotation);
        break;
      case 'tags':
        await _manageQuotationTags(quotation);
        break;
      case 'duplicate':
        await _duplicateQuotation(quotation);
        break;
      case 'delete':
        await _deleteQuotation(quotation);
        break;
    }
  }

  Future<void> _convertQuotationToSale(Map<String, dynamic> quotationData) async {
    try {
      // Carregar cotação completa com itens
      final fullQuotation = await _quotationService.getById(quotationData['id']);
      if (fullQuotation == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cotação não encontrada')),
          );
        }
        return;
      }

      // Combinar quotation com items
      final quotationMap = Map<String, dynamic>.from(fullQuotation.quotation);
      quotationMap['items'] = fullQuotation.items;
      final quotation = Quotation.fromJson(quotationMap);

      // Validar
      final validation = QuotationToSaleConverter.canConvert(quotation);
      
      if (!validation.isValid) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.error, color: Colors.red),
                  SizedBox(width: 12),
                  Text('Não é possível converter'),
                ],
              ),
              content: Text(validation.errorMessage),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
        return;
      }

      // Mostrar avisos se houver
      if (validation.hasWarnings && mounted) {
        final proceed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.warning, color: Colors.orange),
                SizedBox(width: 12),
                Text('Atenção'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Avisos encontrados:'),
                const SizedBox(height: 12),
                Text(validation.warningMessage),
                const SizedBox(height: 12),
                const Text('Deseja continuar?'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('Continuar'),
              ),
            ],
          ),
        );
        
        if (proceed != true) return;
      }

      // Navegar para tela de venda com contato pré-selecionado
      if (mounted) {
        final result = await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => CreateSaleScreenV2(
              contact: quotation.clientContact,
            ),
          ),
        );

        // Feedback de sucesso
        if (result != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Venda criada com sucesso a partir da cotação!'),
                ],
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      print('Erro ao converter cotação: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao converter: $e')),
        );
      }
    }
  }

  Future<void> _manageQuotationTags(Map<String, dynamic> quotation) async {
    // Carregar tags disponíveis e tags já atribuídas
    final tagProvider = ref.read(quotationTagProvider);
    await tagProvider.loadTags();
    
    final currentTags = await tagProvider.getTagsByQuotationId(quotation['id']);
    final currentTagIds = currentTags.map((t) => t.id).toList();
    
    if (!mounted) return;
    
    final selectedTagIds = await showDialog<List<int>>(
      context: context,
      builder: (context) => _TagSelectionDialog(
        quotationNumber: quotation['quotation_number'] ?? '',
        availableTags: tagProvider.activeTags,
        selectedTagIds: currentTagIds,
      ),
    );
    
    if (selectedTagIds != null) {
      try {
        // Atualizar tags
        final success = await tagProvider.updateQuotationTags(
          quotationId: quotation['id'],
          tagIds: selectedTagIds,
          assignedBy: 'user', // TODO: pegar do auth
        );
        
        if (mounted) {
          if (success) {
            // Recarregar a lista para mostrar novas tags
            setState(() {});
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white),
                    SizedBox(width: 12),
                    Text('🏷️ Tags atualizadas com sucesso!'),
                  ],
                ),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('❌ Erro ao atualizar tags'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Erro: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _editQuotation(Map<String, dynamic> quotation) async {
    try {
      final fullQuotation = await _quotationService.getById(quotation['id']);
      if (fullQuotation == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cotação não encontrada')),
          );
        }
        return;
      }

      if (mounted) {
        // 🔧 Combinar quotation com items para criar o objeto completo
        final quotationData = Map<String, dynamic>.from(fullQuotation.quotation);
        quotationData['items'] = fullQuotation.items;
        
        // Abre o dialog de detalhes que já tem funcionalidade de edição
        await showDialog(
          context: context,
          builder: (context) => QuotationDetailDialogPremium(
            quotation: Quotation.fromJson(quotationData),
          ),
        );
        
        // Recarrega lista após fechar
        await _loadQuotations();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao editar: $e')),
        );
      }
    }
  }

  Future<void> _duplicateQuotation(Map<String, dynamic> quotation) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.content_copy, color: Colors.orange),
            SizedBox(width: 12),
            Text('Duplicar Cotação'),
          ],
        ),
        content: Text(
          'Deseja criar uma cópia de ${quotation['quotation_number']}?\n\nA nova cotação será criada como rascunho.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.content_copy),
            label: const Text('Duplicar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        setState(() => _isLoading = true);
        
        final newId = await _quotationService.duplicateQuotation(
          quotation['id'],
          createdBy: 'system',
        );

        if (mounted) {
          setState(() => _isLoading = false);
          await _loadQuotations();
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('📋 Cotação duplicada com sucesso! ID: $newId'),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Erro ao duplicar: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteQuotation(Map<String, dynamic> quotation) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red[700]),
            const SizedBox(width: 12),
            const Text('Confirmar Exclusão'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tem certeza que deseja deletar a cotação ${quotation['quotation_number']}?',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Esta ação não pode ser desfeita!',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.delete),
            label: const Text('Deletar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        setState(() => _isLoading = true);
        
        final success = await _quotationService.deleteQuotation(quotation['id']);
        
        if (mounted) {
          setState(() => _isLoading = false);
          
          if (success) {
            await _loadQuotations();
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white),
                    SizedBox(width: 12),
                    Text('🗑️ Cotação deletada com sucesso!'),
                  ],
                ),
                backgroundColor: Colors.red,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('❌ Erro ao deletar cotação'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Erro ao deletar: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

// ============================================================================
// DIALOG DE SELEÇÃO DE TAGS
// ============================================================================

class _TagSelectionDialog extends StatefulWidget {
  final String quotationNumber;
  final List<dynamic> availableTags;
  final List<int> selectedTagIds;

  const _TagSelectionDialog({
    required this.quotationNumber,
    required this.availableTags,
    required this.selectedTagIds,
  });

  @override
  State<_TagSelectionDialog> createState() => _TagSelectionDialogState();
}

class _TagSelectionDialogState extends State<_TagSelectionDialog> {
  late List<int> _selectedIds;

  @override
  void initState() {
    super.initState();
    _selectedIds = List.from(widget.selectedTagIds);
  }

  void _toggleTag(int tagId) {
    setState(() {
      if (_selectedIds.contains(tagId)) {
        _selectedIds.remove(tagId);
      } else {
        _selectedIds.add(tagId);
      }
    });
  }

  Color _parseColor(String hexColor) {
    try {
      return Color(int.parse(hexColor.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.blue;
    }
  }

  IconData _getIconData(String? iconName) {
    if (iconName == null) return Icons.label;
    
    final iconMap = {
      'star': Icons.star,
      'priority_high': Icons.priority_high,
      'groups': Icons.groups,
      'public': Icons.public,
      'business': Icons.business,
      'celebration': Icons.celebration,
      'repeat': Icons.repeat,
      'discount': Icons.discount,
      'label': Icons.label,
    };
    return iconMap[iconName] ?? Icons.label;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 500,
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple.shade600, Colors.blue.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.label, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Gerenciar Tags',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.quotationNumber,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Instruções
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Selecione as tags para esta cotação',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Contador
                    Text(
                      '${_selectedIds.length} tag${_selectedIds.length != 1 ? 's' : ''} selecionada${_selectedIds.length != 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Lista de Tags
                    if (widget.availableTags.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Icon(Icons.label_off, size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              Text(
                                'Nenhuma tag disponível',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: widget.availableTags.map((tag) {
                          final tagId = tag.id as int;
                          final isSelected = _selectedIds.contains(tagId);
                          final color = _parseColor(tag.color as String);

                          return InkWell(
                            onTap: () => _toggleTag(tagId),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected ? color : color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: color,
                                  width: isSelected ? 2 : 1,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: color.withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (tag.icon != null) ...[
                                    Icon(
                                      _getIconData(tag.icon as String?),
                                      size: 20,
                                      color: isSelected ? Colors.white : color,
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  Text(
                                    tag.name as String,
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : color,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (isSelected) ...[
                                    const SizedBox(width: 8),
                                    const Icon(Icons.check_circle, color: Colors.white, size: 18),
                                  ],
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[850] : Colors.grey[50],
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    offset: const Offset(0, -2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Limpar todas
                  TextButton.icon(
                    onPressed: _selectedIds.isEmpty
                        ? null
                        : () {
                            setState(() {
                              _selectedIds.clear();
                            });
                          },
                    icon: const Icon(Icons.clear_all),
                    label: const Text('Limpar Todas'),
                  ),

                  // Botões de ação
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context, _selectedIds),
                        icon: const Icon(Icons.check),
                        label: const Text('Salvar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

