import 'package:flutter/material.dart';
import '../models/cost_center.dart';

class CostCenterCard extends StatefulWidget {
  final CostCenter costCenter;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onAddExpense;

  const CostCenterCard({
    super.key,
    required this.costCenter,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onAddExpense,
  });

  @override
  State<CostCenterCard> createState() => _CostCenterCardState();
}

class _CostCenterCardState extends State<CostCenterCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final costCenter = widget.costCenter;
    final utilization = costCenter.utilizationPercentage;
    final isOverBudget = costCenter.spent > costCenter.budget;
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Card(
        elevation: _isHovered ? 6 : 2,
        shadowColor: isOverBudget 
          ? Colors.red.withValues(alpha: 0.3)
          : Colors.grey.withValues(alpha: 0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isOverBudget
              ? Colors.red.withValues(alpha: 0.5)
              : Colors.transparent,
            width: 2,
          ),
        ),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
                  isDarkMode ? const Color(0xFF1A1A1A) : const Color(0xFFF8F9FA),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header com título e ações
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            costCenter.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                            maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                          ),
                          if (costCenter.description.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              costCenter.description,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDarkMode ? Colors.white54 : Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (widget.onEdit != null || widget.onDelete != null)
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'edit' && widget.onEdit != null) {
                            widget.onEdit!();
                          } else if (value == 'delete' && widget.onDelete != null) {
                            widget.onDelete!();
                          } else if (value == 'expense' && widget.onAddExpense != null) {
                            widget.onAddExpense!();
                          }
                        },
                        itemBuilder: (context) => [
                          if (widget.onAddExpense != null)
                            const PopupMenuItem(
                              value: 'expense',
                              child: Row(
                                children: [
                                  Icon(Icons.add_shopping_cart, size: 16),
                                  SizedBox(width: 8),
                                  Text('Adicionar Despesa'),
                                ],
                              ),
                            ),
                          if (widget.onEdit != null)
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, size: 16),
                                  SizedBox(width: 8),
                                  Text('Editar'),
                                ],
                              ),
                            ),
                          if (widget.onDelete != null)
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, size: 16, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Excluir', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                        ],
                        child: Icon(
                          Icons.more_vert,
                          color: isDarkMode ? Colors.white54 : Colors.grey[600],
                          size: 16,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Métricas financeiras
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildMetricColumn(
                      'Orçamento',
                      'R\$ ${costCenter.budget.toStringAsFixed(2)}',
                      Colors.blue,
                    ),
                    _buildMetricColumn(
                      'Gasto',
                      'R\$ ${costCenter.spent.toStringAsFixed(2)}',
                      isOverBudget ? Colors.red : Colors.green,
                    ),
                    _buildMetricColumn(
                      'Disponível',
                      'R\$ ${costCenter.available.toStringAsFixed(2)}',
                      costCenter.available < 0 ? Colors.red : Colors.green,
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Barra de progresso
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Utilização',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDarkMode ? Colors.white54 : Colors.grey[600],
                          ),
                        ),
                        Text(
                          '${utilization.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: utilization > 90 ? Colors.red :
                                   utilization > 70 ? Colors.orange : Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: utilization / 100,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          utilization > 90 ? Colors.red :
                          utilization > 70 ? Colors.orange : Colors.green,
                        ),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
                
                // Status e informações adicionais
                if (isOverBudget || costCenter.expenses.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (isOverBudget)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.warning_amber_rounded, size: 12, color: Colors.red[700]),
                              const SizedBox(width: 4),
                              Text(
                                'Acima do orçamento',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.red[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      
                      if (costCenter.expenses.isNotEmpty) ...[
                        if (isOverBudget) const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.receipt, size: 12, color: Colors.blue[700]),
                              const SizedBox(width: 4),
                              Text(
                                '${costCenter.expenses.length} despesa${costCenter.expenses.length > 1 ? 's' : ''}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.blue[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
                
                // Status ativo/inativo
                if (!costCenter.isActive)
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.pause_circle_outline, size: 12, color: Colors.grey[700]),
                        const SizedBox(width: 4),
                        Text(
                          'Inativo',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricColumn(String label, String value, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}