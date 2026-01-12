import 'package:flutter/material.dart';

/// Tipos de bagagem e itens especiais
enum LuggageType {
  // Bagagens padrão
  carryOn('Bagagem de Mão', 'Até 10kg', '55x40x20cm', Icons.work_outline),
  checked('Bagagem Despachada', '23kg', '158cm linear', Icons.luggage),
  largeChecked('Bagagem Grande', 'Até 32kg', '203cm linear', Icons.cases_outlined),
  personal('Item Pessoal', 'Até 5kg', '40x30x15cm', Icons.backpack_outlined),
  
  // Itens especiais para transporte
  babySeat('Cadeirinha de Bebê', 'Até 10kg', 'Assento infantil', Icons.child_care),
  stroller('Carrinho de Bebê', 'Até 15kg', 'Carrinho dobrável', Icons.baby_changing_station),
  wheelchair('Cadeira de Rodas', 'Até 50kg', 'Equipamento médico', Icons.accessible);

  final String label;
  final String weight;
  final String dimensions;
  final IconData icon;

  const LuggageType(this.label, this.weight, this.dimensions, this.icon);
  
  bool get isSpecialItem => this == babySeat || this == stroller || this == wheelchair;
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
    super.key,
    this.initialLuggage,
    required this.onChanged,
    this.showHelp = true,
  });

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
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
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

            // Bagagens padrão em 2 linhas usando Wrap
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: LuggageType.values.where((t) => !t.isSpecialItem).map((type) {
                final item = _luggageItems.firstWhere((i) => i.type == type);
                return _buildCompactLuggageItem(context, item);
              }).toList(),
            ),
            
            const SizedBox(height: 16),
            
            // Divisor para itens especiais
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'Itens Especiais',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Itens especiais em 1 linha usando Wrap
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: LuggageType.values.where((t) => t.isSpecialItem).map((type) {
                final item = _luggageItems.firstWhere((i) => i.type == type);
                return _buildCompactLuggageItem(context, item);
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactLuggageItem(BuildContext context, LuggageItem item) {
    final isSelected = item.quantity > 0;
    final isSpecial = item.type.isSpecialItem;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected 
            ? (isSpecial ? Colors.purple.shade50 : Colors.blue.shade50)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected 
              ? (isSpecial ? Colors.purple.shade300 : Colors.blue.shade300)
              : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Ícone
          Icon(
            item.type.icon,
            color: isSelected 
                ? (isSpecial ? Colors.purple.shade700 : Colors.blue.shade700)
                : Colors.grey.shade600,
            size: 20,
          ),
          const SizedBox(width: 8),
          
          // Label e peso/dimensões
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                item.type.label,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  item.type.weight,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          
          // Controles horizontais
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Botão decrementar
              SizedBox(
                width: 24,
                height: 24,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  onPressed: item.quantity > 0
                      ? () => _updateQuantity(item.type, item.quantity - 1)
                      : null,
                  icon: const Icon(Icons.remove_circle_outline, size: 18),
                  color: Colors.red.shade400,
                ),
              ),
              
              // Quantidade
              Container(
                width: 35,
                height: 28,
                alignment: Alignment.center,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  item.quantity.toString(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              
              // Botão incrementar
              SizedBox(
                width: 24,
                height: 24,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  onPressed: item.quantity < 99
                      ? () => _updateQuantity(item.type, item.quantity + 1)
                      : null,
                  icon: const Icon(Icons.add_circle_outline, size: 18),
                  color: Colors.green.shade400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

}
