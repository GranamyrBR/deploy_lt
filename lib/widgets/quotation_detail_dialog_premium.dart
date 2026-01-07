import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/enhanced_quotation_model.dart';
import '../services/pdf_generator_simple.dart';
import '../services/quotation_email_service.dart';
import '../services/quotation_whatsapp_service.dart';
import '../services/quotation_service.dart';
import '../services/quotation_to_sale_converter.dart';
import '../screens/create_sale_screen_v2.dart';
import 'service_product_selection_dialog.dart';

class QuotationDetailDialogPremium extends ConsumerStatefulWidget {
  final Quotation quotation;

  const QuotationDetailDialogPremium({
    Key? key,
    required this.quotation,
  }) : super(key: key);

  @override
  ConsumerState<QuotationDetailDialogPremium> createState() =>
      _QuotationDetailDialogPremiumState();
}

class _QuotationDetailDialogPremiumState
    extends ConsumerState<QuotationDetailDialogPremium>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late List<QuotationItem> _items;
  final _quotationService = QuotationService();
  final _supabase = Supabase.instance.client;
  
  List<Map<String, dynamic>> _timeline = [];
  bool _isLoadingTimeline = false;
  bool _isSaving = false;
  final _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _items = List.from(widget.quotation.items);
    _loadTimeline();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadTimeline() async {
    setState(() => _isLoadingTimeline = true);
    
    try {
      final result = await _supabase.rpc<List<dynamic>>(
        'get_quotation_timeline',
        params: {'p_quotation_id': int.parse(widget.quotation.id)},
      );
      
      if (mounted) {
        setState(() {
          _timeline = (result as List).map((e) => Map<String, dynamic>.from(e)).toList();
          _isLoadingTimeline = false;
        });
      }
    } catch (e) {
      print('Erro ao carregar timeline: $e');
      if (mounted) {
        setState(() => _isLoadingTimeline = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[900] : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header Premium
            _buildPremiumHeader(isDark),
            
            // Tabs
            _buildTabs(isDark),
            
            // Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildDetailsTab(isDark),
                  _buildTimelineTab(isDark),
                  _buildActionsTab(isDark),
                ],
              ),
            ),
          ],
        ),
      ),
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
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.receipt_long, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.quotation.quotationNumber,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.quotation.clientName,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          if (_isSaving)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          else
            IconButton(
              onPressed: _saveChanges,
              icon: const Icon(Icons.save, color: Colors.white),
              tooltip: 'Salvar Alterações',
            ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Colors.white),
            tooltip: 'Fechar',
          ),
        ],
      ),
    );
  }

  Widget _buildTabs(bool isDark) {
    return Container(
      color: isDark ? Colors.grey[850] : Colors.grey[100],
      child: TabBar(
        controller: _tabController,
        indicatorColor: Colors.blue,
        indicatorWeight: 3,
        labelColor: Colors.blue,
        unselectedLabelColor: isDark ? Colors.grey[400] : Colors.grey[600],
        tabs: const [
          Tab(
            icon: Icon(Icons.details),
            text: 'Detalhes & CRUD',
          ),
          Tab(
            icon: Icon(Icons.timeline),
            text: 'Timeline & Follow-ups',
          ),
          Tab(
            icon: Icon(Icons.send),
            text: 'Ações',
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Resumo da Cotação
          _buildSummaryCard(isDark),
          
          const SizedBox(height: 24),
          
          // CRUD de Serviços e Produtos
          _buildCRUDSection(isDark),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(bool isDark) {
    final subtotal = _items.fold<double>(0, (sum, item) => sum + item.totalValue);
    final total = subtotal;
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.summarize, color: Colors.blue[600], size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Resumo Financeiro',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildSummaryRow('Subtotal', subtotal, isDark),
            _buildSummaryRow('Descontos', 0.0, isDark, isNegative: true),
            _buildSummaryRow('Impostos', 0.0, isDark),
            const Divider(height: 24),
            _buildSummaryRow(
              'TOTAL',
              total,
              isDark,
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, double value, bool isDark,
      {bool isNegative = false, bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          Text(
            '${isNegative ? '-' : ''}${NumberFormat.currency(symbol: '\$').format(value)}',
            style: TextStyle(
              fontSize: isTotal ? 20 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: isTotal
                  ? Colors.green[600]
                  : isNegative
                      ? Colors.red[600]
                      : (isDark ? Colors.white : Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCRUDSection(bool isDark) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.inventory_2, color: Colors.purple[600], size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Serviços e Produtos (CRUD)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _addItem,
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('Adicionar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            if (_items.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Nenhum item adicionado',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  return _buildItemCard(_items[index], index, isDark);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(QuotationItem item, int index, bool isDark) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                item.category == 'service' ? Icons.room_service : Icons.shopping_bag,
                color: Colors.blue[600],
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.description,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${NumberFormat.currency(symbol: '\$').format(item.value)} × ${item.quantity}',
                    style: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            
            // Quantity Controls
            Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => _updateQuantity(index, item.quantity - 1),
                    icon: const Icon(Icons.remove, size: 18),
                    color: Colors.red[600],
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  ),
                  Text(
                    '${item.quantity}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  IconButton(
                    onPressed: () => _updateQuantity(index, item.quantity + 1),
                    icon: const Icon(Icons.add, size: 18),
                    color: Colors.green[600],
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  ),
                ],
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Total
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Total',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey[500] : Colors.grey[600],
                  ),
                ),
                Text(
                  NumberFormat.currency(symbol: '\$').format(item.totalValue),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.green[600],
                  ),
                ),
              ],
            ),
            
            const SizedBox(width: 12),
            
            // Delete
            IconButton(
              onPressed: () => _deleteItem(index),
              icon: const Icon(Icons.delete_outline),
              color: Colors.red[600],
              tooltip: 'Remover',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineTab(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header com ações
          Row(
            children: [
              Icon(Icons.timeline, color: Colors.orange[600], size: 28),
              const SizedBox(width: 12),
              const Text(
                'Timeline & Follow-ups',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _scheduleFollowUp,
                icon: const Icon(Icons.alarm_add, size: 20),
                label: const Text('Agendar Follow-up'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Quick Note
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _noteController,
                      decoration: InputDecoration(
                        hintText: '💬 Adicionar nota rápida...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
                      ),
                      maxLines: 2,
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: _addNote,
                    icon: const Icon(Icons.send),
                    color: Colors.blue[600],
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.blue.withOpacity(0.1),
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Timeline
          Expanded(
            child: _isLoadingTimeline
                ? const Center(child: CircularProgressIndicator())
                : _timeline.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'Nenhum evento registrado',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _timeline.length,
                        itemBuilder: (context, index) {
                          return _buildTimelineItem(
                            _timeline[index],
                            index == _timeline.length - 1,
                            isDark,
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(Map<String, dynamic> event, bool isLast, bool isDark) {
    final eventType = event['event_type'] ?? '';
    final title = event['title'] ?? '';
    final description = event['description'];
    final createdBy = event['created_by'];
    final createdAt = DateTime.parse(event['created_at']);
    
    final icon = _getEventIcon(eventType);
    final color = _getEventColor(eventType);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator
          Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 3),
                ),
                child: Icon(icon, size: 22, color: color),
              ),
              if (!isLast)
                Container(
                  width: 3,
                  height: 60,
                  color: isDark ? Colors.grey[700] : Colors.grey[300],
                ),
            ],
          ),
          
          const SizedBox(width: 16),
          
          // Event content
          Expanded(
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: color.withOpacity(0.3)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    if (description != null && description.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        description,
                        style: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[700],
                          fontSize: 14,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('dd/MM/yyyy HH:mm').format(createdAt),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        if (createdBy != null) ...[
                          const SizedBox(width: 16),
                          Icon(Icons.person, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            createdBy,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bolt, color: Colors.amber[700], size: 28),
              const SizedBox(width: 12),
              const Text(
                'Ações Rápidas',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // 🎯 NOVO: Converter em Venda
          _buildActionCard(
            icon: Icons.point_of_sale,
            title: '💰 Criar Venda',
            description: 'Converter cotação em venda com dados pré-preenchidos',
            color: Colors.green,
            onTap: _convertToSale,
            isDark: isDark,
            isHighlighted: true,
          ),
          
          _buildActionCard(
            icon: Icons.picture_as_pdf,
            title: 'Gerar PDF',
            description: 'Criar PDF profissional da cotação',
            color: Colors.red,
            onTap: _generatePdf,
            isDark: isDark,
          ),
          _buildActionCard(
            icon: Icons.email,
            title: 'Enviar por E-mail',
            description: 'Enviar cotação para o cliente',
            color: Colors.blue,
            onTap: _sendEmail,
            isDark: isDark,
          ),
          _buildActionCard(
            icon: Icons.chat,
            title: 'Enviar por WhatsApp',
            description: 'Compartilhar via WhatsApp',
            color: const Color(0xFF25D366),
            onTap: _sendWhatsApp,
            isDark: isDark,
          ),
          _buildActionCard(
            icon: Icons.phone,
            title: 'Registrar Ligação',
            description: 'Adicionar registro de chamada',
            color: Colors.green,
            onTap: _registerCall,
            isDark: isDark,
          ),
          _buildActionCard(
            icon: Icons.copy,
            title: 'Duplicar Cotação',
            description: 'Criar cópia desta cotação',
            color: Colors.orange,
            onTap: _duplicateQuotation,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
    bool isHighlighted = false,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: isHighlighted ? 8 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isHighlighted 
            ? BorderSide(color: color, width: 2)
            : BorderSide.none,
      ),
      child: Container(
        decoration: isHighlighted
            ? BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withOpacity(0.1),
                    color.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              )
            : null,
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: isHighlighted ? FontWeight.w900 : FontWeight.bold,
              fontSize: isHighlighted ? 17 : 16,
            ),
          ),
          subtitle: Text(
            description,
            style: TextStyle(
              fontWeight: isHighlighted ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
          trailing: Icon(
            Icons.arrow_forward_ios,
            color: isHighlighted ? color : Colors.grey[400],
            size: 18,
          ),
          onTap: onTap,
        ),
      ),
    );
  }

  // Actions
  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);
    try {
      final updatedQuotation = widget.quotation.copyWith(items: _items);
      await _quotationService.saveQuotation(updatedQuotation);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Cotação salva com sucesso!'),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _addItem() async {
    await showDialog<void>(
      context: context,
      builder: (context) => ServiceProductSelectionDialog(
        onSelectionChanged: (services, products) {
          setState(() {
            // Add services
            for (var service in services) {
              _items.add(QuotationItem.fromDbService(
                service,
                date: widget.quotation.travelDate,
              ));
            }
            // Add products
            for (var product in products) {
              _items.add(QuotationItem.fromDbProduct(
                product,
                date: widget.quotation.travelDate,
              ));
            }
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  void _updateQuantity(int index, int newQuantity) {
    if (newQuantity < 1) return;
    setState(() {
      _items[index] = _items[index].copyWith(quantity: newQuantity);
    });
  }

  void _deleteItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  Future<void> _addNote() async {
    if (_noteController.text.trim().isEmpty) return;

    try {
      await _supabase.rpc<void>('add_quotation_timeline_event', params: {
        'p_quotation_id': int.parse(widget.quotation.id),
        'p_event_type': 'note',
        'p_title': 'Nota adicionada',
        'p_description': _noteController.text,
        'p_created_by': _supabase.auth.currentUser?.email ?? 'system',
      });

      _noteController.clear();
      await _loadTimeline();
    } catch (e) {
      print('Erro ao adicionar nota: $e');
    }
  }

  Future<void> _scheduleFollowUp() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (selectedDate == null) return;
    
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );
    
    if (selectedTime == null) return;
    
    final followUpDateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    try {
      await _supabase.from('quotation').update({
        'follow_up_date': followUpDateTime.toIso8601String(),
      }).eq('id', int.parse(widget.quotation.id));

      await _supabase.rpc<void>('add_quotation_timeline_event', params: {
        'p_quotation_id': int.parse(widget.quotation.id),
        'p_event_type': 'follow_up',
        'p_title': 'Follow-up agendado',
        'p_description': 'Agendado para ${DateFormat('dd/MM/yyyy HH:mm').format(followUpDateTime)}',
        'p_created_by': _supabase.auth.currentUser?.email ?? 'system',
      });

      await _loadTimeline();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Follow-up agendado para ${DateFormat('dd/MM/yyyy HH:mm').format(followUpDateTime)}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Erro: $e');
    }
  }

  Future<void> _generatePdf() async {
    try {
      await PdfGeneratorSimple.generatePdf(widget.quotation);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF gerado!')),
        );
      }
    } catch (e) {
      print('Erro: $e');
    }
  }

  Future<void> _sendEmail() async {
    try {
      await QuotationEmailService.sendQuotationEmail(
        quotation: widget.quotation,
        recipientEmail: widget.quotation.clientEmail,
        recipientName: widget.quotation.clientName,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email enviado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Erro: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao enviar email: $e')),
        );
      }
    }
  }

  Future<void> _sendWhatsApp() async {
    try {
      await QuotationWhatsAppService.sendQuotationWhatsApp(
        quotation: widget.quotation,
        phoneNumber: widget.quotation.clientPhone ?? '',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('WhatsApp enviado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Erro: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao enviar WhatsApp: $e')),
        );
      }
    }
  }

  Future<void> _registerCall() async {
    await _supabase.rpc<void>('add_quotation_timeline_event', params: {
      'p_quotation_id': int.parse(widget.quotation.id),
      'p_event_type': 'call',
      'p_title': 'Ligação realizada',
      'p_description': 'Contato telefônico com cliente',
      'p_created_by': _supabase.auth.currentUser?.email ?? 'system',
    });
    await _loadTimeline();
  }

  Future<void> _duplicateQuotation() async {
    // Implement duplication logic
  }

  Future<void> _convertToSale() async {
    // Validar se a cotação pode ser convertida
    final validation = QuotationToSaleConverter.canConvert(widget.quotation);
    
    if (!validation.isValid) {
      // Mostrar erros
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
              child: const Text('Continuar'),
            ),
          ],
        ),
      );
      
      if (proceed != true) return;
    }
    
    // Fechar dialog atual
    if (mounted) {
      Navigator.pop(context);
      
      // Abrir tela de criação de venda com contato pré-selecionado
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => CreateSaleScreenV2(
            contact: widget.quotation.clientContact,
          ),
        ),
      ).then((result) {
        // Se a venda foi criada com sucesso, mostrar notificação
        if (result != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Venda criada com sucesso!'),
                ],
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      });
    }
  }

  IconData _getEventIcon(String eventType) {
    switch (eventType) {
      case 'created': return Icons.add_circle;
      case 'sent': return Icons.send;
      case 'viewed': return Icons.visibility;
      case 'follow_up': return Icons.alarm;
      case 'status_change': return Icons.swap_horiz;
      case 'note': return Icons.note;
      case 'email': return Icons.email;
      case 'whatsapp': return Icons.chat;
      case 'call': return Icons.phone;
      default: return Icons.event;
    }
  }

  Color _getEventColor(String eventType) {
    switch (eventType) {
      case 'created': return Colors.blue;
      case 'sent': return Colors.green;
      case 'viewed': return Colors.purple;
      case 'follow_up': return Colors.orange;
      case 'status_change': return Colors.indigo;
      case 'note': return Colors.grey;
      case 'email': return Colors.teal;
      case 'whatsapp': return const Color(0xFF25D366);
      case 'call': return Colors.blue;
      default: return Colors.grey;
    }
  }
}

