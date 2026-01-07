import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Tipos de bagagem baseados nos padrões da indústria aérea
enum LuggageType {
  carryOn('Bagagem de Mão', 'Até 10kg', '55x40x20cm', Icons.work_outline),
  checked('Bagagem Despachada', '23kg', '158cm linear', Icons.luggage),
  largeChecked('Bagagem Grande', 'Até 32kg', '203cm linear', Icons.cases_outlined),
  personal('Item Pessoal', 'Até 5kg', '40x30x15cm', Icons.backpack_outlined);

  final String label;
  final String weight;
  final String dimensions;
  final IconData icon;

  const LuggageType(this.label, this.weight, this.dimensions, this.icon);
}

/// Modelo de dados para bagagem
class LuggageItem {
  final LuggageType type;
  int quantity;

  LuggageItem({required this.type, this.quantity = 0});

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'quantity': quantity,
    'label': type.label,
    'weight': type.weight,
    'dimensions': type.dimensions,
  };

  factory LuggageItem.fromJson(Map<String, dynamic> json) {
    return LuggageItem(
      type: LuggageType.values.firstWhere((t) => t.name == json['type']),
      quantity: json['quantity'] ?? 0,
    );
  }
}

/// Widget de seleção de bagagens para cotações
/// Ajuda motoristas a entenderem o volume de bagagens
class LuggageSelectorWidget extends StatefulWidget {
  final List<LuggageItem>? initialLuggage;
  final ValueChanged<List<LuggageItem>> onChanged;
  final bool showHelp;

  const LuggageSelectorWidget({
    Key? key,
    this.initialLuggage,
    required this.onChanged,
    this.showHelp = true,
  }) : super(key: key);

  @override
  State<LuggageSelectorWidget> createState() => _LuggageSelectorWidgetState();
}

class _LuggageSelectorWidgetState extends State<LuggageSelectorWidget> {
  late List<LuggageItem> _luggageItems;
  bool _showDetails = false;

  @override
  void initState() {
    super.initState();
    _luggageItems = widget.initialLuggage ??
        LuggageType.values.map((type) => LuggageItem(type: type)).toList();
  }

  void _updateQuantity(LuggageType type, int quantity) {
    setState(() {
      final index = _luggageItems.indexWhere((item) => item.type == type);
      if (index != -1) {
        _luggageItems[index].quantity = quantity.clamp(0, 99);
      }
      widget.onChanged(_luggageItems);
    });
  }

  int _getTotalPieces() {
    return _luggageItems.fold(0, (sum, item) => sum + item.quantity);
  }

  @override
  Widget build(BuildContext context) {
    final totalPieces = _getTotalPieces();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.luggage, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Bagagens',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                if (totalPieces > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$totalPieces ${totalPieces == 1 ? "peça" : "peças"}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                const Spacer(),
                if (widget.showHelp)
                  IconButton(
                    icon: Icon(
                      _showDetails ? Icons.expand_less : Icons.info_outline,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _showDetails = !_showDetails),
                    tooltip: 'Informações sobre bagagens',
                  ),
              ],
            ),
            
            const SizedBox(height: 16),

            // Help text
            if (_showDetails) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, size: 16, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Informações importantes',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• Informe a quantidade total de bagagens\n'
                      '• Ajuda o motorista a escolher o veículo adequado\n'
                      '• Dimensões baseadas nos padrões da aviação civil',
                      style: TextStyle(fontSize: 11, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Luggage items
            ...LuggageType.values.map((type) {
              final item = _luggageItems.firstWhere((i) => i.type == type);
              return _buildLuggageItem(context, item);
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildLuggageItem(BuildContext context, LuggageItem item) {
    final controller = TextEditingController(
      text: item.quantity > 0 ? item.quantity.toString() : '',
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: item.quantity > 0 ? Colors.green.shade50 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: item.quantity > 0 ? Colors.green.shade300 : Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: item.quantity > 0 ? Colors.green.shade100 : Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              item.type.icon,
              color: item.quantity > 0 ? Colors.green.shade700 : Colors.grey.shade600,
              size: 24,
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Label and info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.type.label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.type.weight} • ${item.type.dimensions}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Quantity controls
          Row(
            children: [
              // Decrement button
              IconButton(
                onPressed: item.quantity > 0
                    ? () => _updateQuantity(item.type, item.quantity - 1)
                    : null,
                icon: const Icon(Icons.remove_circle_outline),
                iconSize: 28,
                color: Colors.red.shade400,
                tooltip: 'Remover',
              ),
              
              // Quantity input
              SizedBox(
                width: 50,
                child: TextField(
                  controller: controller,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(2),
                  ],
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    hintText: '0',
                  ),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  onChanged: (value) {
                    final quantity = int.tryParse(value) ?? 0;
                    _updateQuantity(item.type, quantity);
                  },
                ),
              ),
              
              // Increment button
              IconButton(
                onPressed: item.quantity < 99
                    ? () => _updateQuantity(item.type, item.quantity + 1)
                    : null,
                icon: const Icon(Icons.add_circle_outline),
                iconSize: 28,
                color: Colors.green.shade400,
                tooltip: 'Adicionar',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
