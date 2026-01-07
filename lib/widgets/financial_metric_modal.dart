import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/financial_metric.dart';

class FinancialMetricModal extends StatefulWidget {
  final FinancialMetric? metric;
  final Function(FinancialMetric) onSave;

  const FinancialMetricModal({
    Key? key,
    this.metric,
    required this.onSave,
  }) : super(key: key);

  @override
  State<FinancialMetricModal> createState() => _FinancialMetricModalState();
}

class _FinancialMetricModalState extends State<FinancialMetricModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _currentValueController;
  late TextEditingController _previousValueController;
  late TextEditingController _unitController;
  late TextEditingController _targetValueController;
  late TextEditingController _alertThresholdController;
  
  String _selectedCategory = 'revenue';
  bool _isActive = true;

  final List<Map<String, String>> _categories = [
    {'value': 'revenue', 'label': 'Receita'},
    {'value': 'expense', 'label': 'Despesa'},
    {'value': 'profit', 'label': 'Lucro'},
    {'value': 'cash_flow', 'label': 'Fluxo de Caixa'},
    {'value': 'cost', 'label': 'Custo'},
    {'value': 'investment', 'label': 'Investimento'},
    {'value': 'debt', 'label': 'Dívida'},
    {'value': 'tax', 'label': 'Imposto'},
    {'value': 'commission', 'label': 'Comissão'},
    {'value': 'other', 'label': 'Outro'},
  ];

  @override
  void initState() {
    super.initState();
    
    final metric = widget.metric;
    
    _nameController = TextEditingController(text: metric?.name ?? '');
    _descriptionController = TextEditingController(text: metric?.description ?? '');
    _currentValueController = TextEditingController(
      text: metric?.currentValue.toString() ?? '0.00'
    );
    _previousValueController = TextEditingController(
      text: metric?.previousValue.toString() ?? '0.00'
    );
    _unitController = TextEditingController(text: metric?.unit ?? 'R\$');
    _targetValueController = TextEditingController(text: metric?.targetValue ?? '');
    _alertThresholdController = TextEditingController(text: metric?.alertThreshold ?? '');
    
    _selectedCategory = metric?.category ?? 'revenue';
    _isActive = metric?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _currentValueController.dispose();
    _previousValueController.dispose();
    _unitController.dispose();
    _targetValueController.dispose();
    _alertThresholdController.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (_formKey.currentState!.validate()) {
      final now = DateTime.now();
      final metric = FinancialMetric(
        id: widget.metric?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        currentValue: double.tryParse(_currentValueController.text) ?? 0.0,
        previousValue: double.tryParse(_previousValueController.text) ?? 0.0,
        unit: _unitController.text.trim(),
        category: _selectedCategory,
        createdAt: widget.metric?.createdAt ?? now,
        updatedAt: now,
        isActive: _isActive,
        targetValue: _targetValueController.text.trim().isEmpty ? null : _targetValueController.text.trim(),
        alertThreshold: _alertThresholdController.text.trim().isEmpty ? null : _alertThresholdController.text.trim(),
      );

      widget.onSave(metric);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.metric != null;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
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
                color: isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditing ? 'Editar Métrica' : 'Nova Métrica',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            
            // Form
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Name Field
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nome da Métrica *',
                          hintText: 'Ex: Receita Mensal, Lucro Bruto',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Por favor, insira o nome da métrica';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Description Field
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Descrição',
                          hintText: 'Descreva o propósito desta métrica',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      
                      // Category Dropdown
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Categoria *',
                          border: OutlineInputBorder(),
                        ),
                        items: _categories.map((category) {
                          return DropdownMenuItem<String>(
                            value: category['value'],
                            child: Text(category['label']!),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCategory = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Unit Field
                      TextFormField(
                        controller: _unitController,
                        decoration: const InputDecoration(
                          labelText: 'Unidade *',
                          hintText: 'Ex: R\$, %, unidades',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Por favor, insira a unidade';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Current Value Field
                      TextFormField(
                        controller: _currentValueController,
                        decoration: const InputDecoration(
                          labelText: 'Valor Atual *',
                          hintText: '0.00',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                        ],
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Por favor, insira o valor atual';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Por favor, insira um número válido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Previous Value Field
                      TextFormField(
                        controller: _previousValueController,
                        decoration: const InputDecoration(
                          labelText: 'Valor Anterior',
                          hintText: '0.00 (para cálculo de variação)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Target Value Field
                      TextFormField(
                        controller: _targetValueController,
                        decoration: const InputDecoration(
                          labelText: 'Valor Alvo',
                          hintText: 'Meta desejada (opcional)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Alert Threshold Field
                      TextFormField(
                        controller: _alertThresholdController,
                        decoration: const InputDecoration(
                          labelText: 'Limite de Alerta',
                          hintText: 'Valor mínimo para alerta (opcional)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Active Switch
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Métrica Ativa',
                            style: TextStyle(fontSize: 16),
                          ),
                          Switch(
                            value: _isActive,
                            onChanged: (value) {
                              setState(() {
                                _isActive = value;
                              });
                            },
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 8),
                      Text(
                        'Métricas inativas não aparecem no dashboard',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Footer
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E88E5),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: Text(isEditing ? 'Atualizar' : 'Criar'),
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