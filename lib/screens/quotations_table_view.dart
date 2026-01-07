import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class QuotationsTableView extends StatelessWidget {
  final List<Map<String, dynamic>> quotations;
  final bool isDark;
  final void Function(Map<String, dynamic>) onQuotationTap;
  final String sortField;
  final bool sortAscending;
  final void Function(String) onSort;
  final void Function(Map<String, dynamic>)? onEdit;
  final void Function(Map<String, dynamic>)? onDuplicate;
  final void Function(Map<String, dynamic>)? onDelete;

  const QuotationsTableView({
    super.key,
    required this.quotations,
    required this.isDark,
    required this.onQuotationTap,
    required this.sortField,
    required this.sortAscending,
    required this.onSort,
    this.onEdit,
    this.onDuplicate,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    // 🔧 LARGURA TOTAL CALCULADA: soma de todas as colunas
    const double totalWidth = 150 + 200 + 150 + 120 + 180 + 100 + 130 + 140; // = 1170
    
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          // Header com scroll horizontal sincronizado
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const ClampingScrollPhysics(),
            child: Container(
              width: totalWidth,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.grey[100],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  _buildHeader('Nº Cotação', 150, 'quotation_number'),
                  _buildHeader('Cliente', 200, 'client_name'),
                  _buildHeader('Destino', 150, 'destination'),
                  _buildHeader('Status', 120, 'status'),
                  _buildHeader('Viagem', 180, 'travel_date'),
                  _buildHeader('Urgência', 100, 'urgency'),
                  _buildHeader('Valor', 130, 'total'),
                  SizedBox(
                    width: 140,
                    child: Center(
                      child: Text(
                        'Ações',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Body com scroll horizontal sincronizado
          Expanded(
            child: quotations.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Nenhuma cotação encontrada',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const ClampingScrollPhysics(),
                    child: SizedBox(
                      width: totalWidth,
                      child: ListView.builder(
                        itemCount: quotations.length,
                        itemBuilder: (context, index) => _buildRow(quotations[index]),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(String title, double width, String field) {
    final isActive = sortField == field;

    return SizedBox(
      width: width,
      child: InkWell(
        onTap: () => onSort(field),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                    color: isActive ? Colors.blue : null,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              if (isActive)
                Icon(
                  sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 14,
                  color: Colors.blue,
                )
              else
                Icon(
                  Icons.unfold_more,
                  size: 14,
                  color: Colors.grey[400],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(Map<String, dynamic> quotation) {
    final status = quotation['status'] ?? 'draft';
    final total = quotation['total'] ?? 0.0;
    final currency = quotation['currency'] ?? 'USD';
    final clientName = quotation['client_name'] ?? 'Cliente';
    final destination = quotation['destination'] ?? '-';
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

    return InkWell(
      onTap: () => onQuotationTap(quotation),
      child: Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: travelDate != null ? urgencyBg : null, // 🆕 Background por urgência
          border: Border(
            bottom: BorderSide(
              color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
              width: 1,
            ),
            left: borderWidth > 0 
                ? BorderSide(color: urgencyColor, width: borderWidth) // 🆕 Borda lateral colorida
                : BorderSide.none,
          ),
        ),
        child: Row(
          children: [
            // Número
            SizedBox(
              width: 150,
              child: Row(
                children: [
                  Icon(_getStatusIcon(status), size: 16, color: statusColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      quotationNumber,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            // Cliente
            SizedBox(
              width: 200,
              child: Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.blue[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      clientName,
                      style: const TextStyle(fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            // Destino
            SizedBox(
              width: 150,
              child: Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.purple[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      destination,
                      style: const TextStyle(fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            // Status
            SizedBox(
              width: 120,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor, width: 1),
                ),
                child: Text(
                  _getStatusLabel(status),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            // 🆕 Viagem (IDA e VOLTA)
            SizedBox(
              width: 180,
              child: travelDate != null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.flight_takeoff, size: 14, color: urgencyColor),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('dd/MM/yy', 'pt_BR').format(travelDate),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: urgencyColor,
                              ),
                            ),
                          ],
                        ),
                        if (returnDate != null)
                          Row(
                            children: [
                              Icon(Icons.flight_land, size: 14, color: urgencyColor),
                              const SizedBox(width: 4),
                              Text(
                                DateFormat('dd/MM/yy', 'pt_BR').format(returnDate),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: urgencyColor,
                                ),
                              ),
                            ],
                          ),
                      ],
                    )
                  : Text(
                      'Sem data',
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
            ),
            // 🆕 Urgência
            SizedBox(
              width: 100,
              child: Center(
                child: travelDate != null && daysUntilTravel <= 14
                    ? Container(
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
                      )
                    : const SizedBox.shrink(),
              ),
            ),
            // Valor
            SizedBox(
              width: 130,
              child: Text(
                NumberFormat.currency(
                  symbol: currency == 'USD' ? '\$' : 'R\$',
                  decimalDigits: 2,
                ).format(total),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.green[700],
                ),
              ),
            ),
            // Ações
            SizedBox(
              width: 140,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.open_in_new, size: 18),
                    color: Colors.blue[600],
                    onPressed: () => onQuotationTap(quotation),
                    tooltip: 'Abrir',
                  ),
                  if (onEdit != null)
                    IconButton(
                      icon: const Icon(Icons.edit, size: 18),
                      color: Colors.blue[600],
                      onPressed: () => onEdit!(quotation),
                      tooltip: 'Editar',
                    ),
                  if (onDuplicate != null)
                    IconButton(
                      icon: const Icon(Icons.content_copy, size: 18),
                      color: Colors.orange[600],
                      onPressed: () => onDuplicate!(quotation),
                      tooltip: 'Duplicar',
                    ),
                  if (onDelete != null)
                    IconButton(
                      icon: const Icon(Icons.delete, size: 18),
                      color: Colors.red[600],
                      onPressed: () => onDelete!(quotation),
                      tooltip: 'Deletar',
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'draft':
        return Colors.grey;
      case 'sent':
        return Colors.blue;
      case 'viewed':
        return Colors.orange;
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'expired':
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'draft':
        return 'Rascunho';
      case 'sent':
        return 'Enviada';
      case 'viewed':
        return 'Visualizada';
      case 'accepted':
        return 'Aceita';
      case 'rejected':
        return 'Rejeitada';
      case 'expired':
        return 'Expirada';
      default:
        return status;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'draft':
        return Icons.edit;
      case 'sent':
        return Icons.send;
      case 'viewed':
        return Icons.visibility;
      case 'accepted':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'expired':
        return Icons.access_time;
      default:
        return Icons.help;
    }
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
    if (days < 0) return Colors.grey.shade400;
    if (days <= 3) return Colors.red.shade700;
    if (days <= 7) return Colors.orange.shade600;
    if (days <= 14) return Colors.amber.shade500;
    if (days <= 30) return Colors.green.shade500;
    if (days <= 90) return Colors.blue.shade400;
    if (days <= 999) return Colors.indigo.shade300;
    return Colors.grey.shade400;
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
    if (days <= 3) return '🔥 ${days}D';
    if (days <= 7) return '⚠️ ${days}D';
    if (days <= 14) return '📅 ${days}D';
    if (days <= 30) return '✅ ${days}D';
    if (days <= 90) return '📆 ${days}D';
    if (days <= 999) return '🗓️ ${days}D';
    return '❓';
  }

  double _getUrgencyBorderWidth(int days) {
    if (days <= 3) return 4.0;
    if (days <= 7) return 3.0;
    if (days <= 14) return 2.0;
    return 0.0;
  }
}

