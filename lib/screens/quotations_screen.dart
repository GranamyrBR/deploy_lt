import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../services/quotation_service.dart';
import '../models/enhanced_quotation_model.dart';
import '../widgets/quotation_management_dialog.dart';
import '../widgets/enhanced_quotation_dialog.dart';

class QuotationsScreen extends ConsumerStatefulWidget {
  const QuotationsScreen({super.key});

  @override
  ConsumerState<QuotationsScreen> createState() => _QuotationsScreenState();
}

class _QuotationsScreenState extends ConsumerState<QuotationsScreen> {
  final _quotationService = QuotationService();
  List<Map<String, dynamic>> _quotations = [];
  bool _isLoading = true;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadQuotations();
  }

  Future<void> _loadQuotations() async {
    setState(() => _isLoading = true);
    
    try {
      final data = await _quotationService.getQuotations(
        filter: const QuotationFilter(limit: 100),
      );
      
      if (mounted) {
        setState(() {
          _quotations = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Erro ao carregar cotações: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar: $e')),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredQuotations {
    if (_selectedFilter == 'all') return _quotations;
    return _quotations.where((q) => q['status'] == _selectedFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cotacoes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadQuotations,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await showDialog(
            context: context,
            builder: (context) => const EnhancedQuotationDialog(),
          );
          if (result != null) {
            _loadQuotations();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Nova Cotacao'),
      ),
      body: Column(
        children: [
          // Filtros
          Container(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('Todas', 'all', theme),
                  const SizedBox(width: 8),
                  _buildFilterChip('Rascunho', 'draft', theme),
                  const SizedBox(width: 8),
                  _buildFilterChip('Enviadas', 'sent', theme),
                  const SizedBox(width: 8),
                  _buildFilterChip('Aceitas', 'accepted', theme),
                  const SizedBox(width: 8),
                  _buildFilterChip('Rejeitadas', 'rejected', theme),
                ],
              ),
            ),
          ),
          
          const Divider(height: 1),
          
          // Lista de cotações
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredQuotations.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.description_outlined,
                              size: 64,
                              color: theme.colorScheme.outline,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Nenhuma cotacao encontrada',
                              style: TextStyle(
                                fontSize: 16,
                                color: theme.colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadQuotations,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredQuotations.length,
                          itemBuilder: (context, index) {
                            final quotation = _filteredQuotations[index];
                            return _buildQuotationCard(quotation, theme);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, ThemeData theme) {
    final isSelected = _selectedFilter == value;
    final count = value == 'all' 
        ? _quotations.length 
        : _quotations.where((q) => q['status'] == value).length;
    
    return FilterChip(
      label: Text('$label ($count)'),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
      },
      selectedColor: theme.colorScheme.primaryContainer,
      checkmarkColor: theme.colorScheme.primary,
    );
  }

  Widget _buildQuotationCard(Map<String, dynamic> data, ThemeData theme) {
    final quotationNumber = data['quotation_number'] ?? 'N/A';
    final clientName = data['client_name'] ?? 'Cliente';
    final status = data['status'] ?? 'draft';
    final total = (data['total'] as num?)?.toDouble() ?? 0.0;
    final currency = data['currency'] ?? 'USD';
    final createdAt = data['created_at'] != null 
        ? DateTime.parse(data['created_at'])
        : DateTime.now();
    final travelDate = data['travel_date'] != null
        ? DateTime.parse(data['travel_date'])
        : null;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () async {
          // Carregar cotação completa
          final fullQuotation = await _quotationService.getById(data['id']);
          if (fullQuotation != null && mounted) {
            final quotation = Quotation.fromJson(fullQuotation.quotation);
            
            await showDialog(
              context: context,
              builder: (context) => QuotationManagementDialog(
                quotation: quotation,
                onQuotationUpdated: _loadQuotations,
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              quotationNumber,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildStatusBadge(status, theme),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          clientName,
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$currency ${total.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      Text(
                        DateFormat('dd/MM/yyyy').format(createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              if (travelDate != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.flight_takeoff,
                      size: 16,
                      color: theme.colorScheme.outline,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Viagem: ${DateFormat('dd/MM/yyyy').format(travelDate)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status, ThemeData theme) {
    Color backgroundColor;
    Color textColor;
    String label;
    
    switch (status) {
      case 'draft':
        backgroundColor = Colors.grey.shade200;
        textColor = Colors.grey.shade700;
        label = 'Rascunho';
        break;
      case 'sent':
        backgroundColor = Colors.blue.shade100;
        textColor = Colors.blue.shade700;
        label = 'Enviada';
        break;
      case 'accepted':
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade700;
        label = 'Aceita';
        break;
      case 'rejected':
        backgroundColor = Colors.red.shade100;
        textColor = Colors.red.shade700;
        label = 'Rejeitada';
        break;
      case 'expired':
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade700;
        label = 'Expirada';
        break;
      default:
        backgroundColor = Colors.grey.shade200;
        textColor = Colors.grey.shade700;
        label = status;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }
}


