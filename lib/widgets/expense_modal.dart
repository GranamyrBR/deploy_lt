import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/cost_center.dart';

class ExpenseModal extends StatefulWidget {
  final Expense? expense;
  final String costCenterId;
  final VoidCallback? onSave;

  const ExpenseModal({
    Key? key,
    this.expense,
    required this.costCenterId,
    this.onSave,
  }) : super(key: key);

  @override
  _ExpenseModalState createState() => _ExpenseModalState();
}

class _ExpenseModalState extends State<ExpenseModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _descriptionController;
  late TextEditingController _amountController;
  late TextEditingController _vendorController;
  late TextEditingController _notesController;
  
  DateTime _selectedDate = DateTime.now();
  String _selectedCategory = 'Outros';
  ExpenseType _selectedExpenseType = ExpenseType.VARIABLE;
  String? _receiptUrl;

  final List<String> _categories = [
    'Alimentação',
    'Transporte',
    'Hospedagem',
    'Combustível',
    'Manutenção',
    'Material de Escritório',
    'Serviços',
    'Impostos',
    'Seguros',
    'Telecomunicações',
    'Marketing',
    'Treinamento',
    'Viagem',
    'Outros',
  ];

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(text: widget.expense?.description ?? '');
    _amountController = TextEditingController(
      text: widget.expense?.amount.toStringAsFixed(2) ?? ''
    );
    _vendorController = TextEditingController(text: widget.expense?.vendor ?? '');
    _notesController = TextEditingController(text: widget.expense?.notes ?? '');
    
    if (widget.expense != null) {
      _selectedDate = widget.expense!.date;
      _selectedCategory = widget.expense!.category;
      _selectedExpenseType = widget.expense!.type;
      _receiptUrl = widget.expense!.receiptUrl;
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _vendorController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      locale: const Locale('pt', 'BR'),
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  String? _validateAmount(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor, informe o valor';
    }
    final amount = double.tryParse(value.replaceAll(',', '.'));
    if (amount == null || amount <= 0) {
      return 'Por favor, informe um valor válido';
    }
    return null;
  }

  void _saveExpense() {
    if (_formKey.currentState!.validate()) {
      final amount = double.parse(_amountController.text.replaceAll(',', '.'));
      
      final expense = Expense(
        id: widget.expense?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        costCenterId: widget.costCenterId,
        description: _descriptionController.text,
        amount: amount,
        date: _selectedDate,
        category: _selectedCategory,
        type: _selectedExpenseType,
        vendor: _vendorController.text.isEmpty ? null : _vendorController.text,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        receiptUrl: _receiptUrl,
        createdAt: widget.expense?.createdAt ?? DateTime.now(),
      );

      Navigator.of(context).pop(expense);
      widget.onSave?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.expense != null;
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.5,
        constraints: const BoxConstraints(maxWidth: 600),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEditing ? 'Editar Despesa' : 'Nova Despesa',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Descrição *',
                    hintText: 'Descreva a despesa',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, informe a descrição';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _amountController,
                        decoration: const InputDecoration(
                          labelText: 'Valor *',
                          hintText: '0,00',
                          border: OutlineInputBorder(),
                          prefixText: 'R\$ ',
                        ),
                        keyboardType: TextInputType.number,
                        validator: _validateAmount,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: InkWell(
                        onTap: _selectDate,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Data *',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(
                            DateFormat('dd/MM/yyyy').format(_selectedDate),
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<ExpenseType>(
                        value: _selectedExpenseType,
                        decoration: const InputDecoration(
                          labelText: 'Tipo de Despesa *',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: ExpenseType.FIXED,
                            child: Text('Despesa Fixa'),
                          ),
                          DropdownMenuItem(
                            value: ExpenseType.VARIABLE,
                            child: Text('Despesa Variável'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedExpenseType = value!;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Categoria *',
                          border: OutlineInputBorder(),
                        ),
                        items: _categories.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCategory = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _vendorController,
                  decoration: const InputDecoration(
                    labelText: 'Fornecedor',
                    hintText: 'Nome do fornecedor',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Observações',
                    hintText: 'Observações adicionais',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // TODO: Implementar upload de recibo
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Funcionalidade de upload em desenvolvimento'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.attach_file),
                        label: Text(_receiptUrl == null ? 'Anexar Recibo' : 'Recibo Anexado'),
                      ),
                    ),
                    if (_receiptUrl != null) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            _receiptUrl = null;
                          });
                        },
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 24),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: _saveExpense,
                      icon: const Icon(Icons.save),
                      label: Text(isEditing ? 'Salvar Alterações' : 'Criar Despesa'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}