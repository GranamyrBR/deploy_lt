import 'package:flutter/material.dart';

/// Tipos de veículos baseados na tabela 'cars'
enum VehicleType {
  suv('SUV', 'Sport Utility Vehicle - 5-7 passageiros', Icons.directions_car, 7),
  van('VAN', 'Van - 8-14 passageiros', Icons.airport_shuttle, 14),
  minibus('Micro-ônibus', 'Micro-ônibus - 15-25 passageiros', Icons.directions_bus, 25),
  bus('Ônibus', 'Ônibus - 26+ passageiros', Icons.directions_bus_filled, 50),
  sedan('Sedan', 'Sedan - 3-4 passageiros', Icons.car_rental, 4),
  luxury('Luxo', 'Veículo de Luxo - 3-4 passageiros', Icons.emoji_transportation, 4);

  final String label;
  final String description;
  final IconData icon;
  final int maxPassengers;

  const VehicleType(this.label, this.description, this.icon, this.maxPassengers);
}

/// Modelo de dados para veículo selecionado
class VehicleSelection {
  final VehicleType type;
  int quantity;

  VehicleSelection({required this.type, this.quantity = 0});

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'label': type.label,
    'quantity': quantity,
    'maxPassengers': type.maxPassengers,
  };

  factory VehicleSelection.fromJson(Map<String, dynamic> json) {
    return VehicleSelection(
      type: VehicleType.values.firstWhere((t) => t.name == json['type']),
      quantity: json['quantity'] ?? 0,
    );
  }
}

/// Widget moderno de seleção de veículos para cotações
/// Design clean e intuitivo, otimizado para múltiplas colunas
class VehicleSelectorWidget extends StatefulWidget {
  final List<VehicleSelection>? initialVehicles;
  final ValueChanged<List<VehicleSelection>> onChanged;
  final int? passengerCount;

  const VehicleSelectorWidget({
    super.key,
    this.initialVehicles,
    required this.onChanged,
    this.passengerCount,
  });

  @override
  State<VehicleSelectorWidget> createState() => _VehicleSelectorWidgetState();
}

class _VehicleSelectorWidgetState extends State<VehicleSelectorWidget> {
  late List<VehicleSelection> _vehicleSelections;

  @override
  void initState() {
    super.initState();
    _vehicleSelections = widget.initialVehicles ??
        VehicleType.values.map((type) => VehicleSelection(type: type)).toList();
  }

  void _updateQuantity(VehicleType type, int quantity) {
    setState(() {
      final index = _vehicleSelections.indexWhere((item) => item.type == type);
      if (index != -1) {
        _vehicleSelections[index].quantity = quantity.clamp(0, 99);
      }
      widget.onChanged(_vehicleSelections);
    });
  }

  int _getTotalVehicles() {
    return _vehicleSelections.fold(0, (sum, item) => sum + item.quantity);
  }

  int _getTotalCapacity() {
    return _vehicleSelections.fold(0, (sum, item) => 
      sum + (item.quantity * item.type.maxPassengers));
  }

  @override
  Widget build(BuildContext context) {
    final totalVehicles = _getTotalVehicles();
    final totalCapacity = _getTotalCapacity();
    final passengerCount = widget.passengerCount ?? 0;
    final hasEnoughCapacity = totalCapacity >= passengerCount;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header compacto
            Row(
              children: [
                Icon(Icons.directions_car, color: Theme.of(context).primaryColor, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Veículos',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                if (totalVehicles > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$totalVehicles ${totalVehicles == 1 ? "veículo" : "veículos"}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                const Spacer(),
                if (passengerCount > 0) ...[
                  Icon(
                    hasEnoughCapacity ? Icons.check_circle : Icons.warning,
                    size: 16,
                    color: hasEnoughCapacity ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$totalCapacity/$passengerCount',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: hasEnoughCapacity ? Colors.green : Colors.orange,
                    ),
                  ),
                ],
              ],
            ),
            
            const SizedBox(height: 12),

            // Layout em 2 linhas usando Wrap
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: VehicleType.values.map((type) {
                final item = _vehicleSelections.firstWhere((i) => i.type == type);
                return _buildCompactVehicleCard(context, item);
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactVehicleCard(BuildContext context, VehicleSelection item) {
    final isSelected = item.quantity > 0;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue.shade50 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? Colors.blue.shade300 : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Ícone
          Icon(
            item.type.icon,
            color: isSelected ? Colors.blue.shade700 : Colors.grey.shade600,
            size: 20,
          ),
          const SizedBox(width: 8),
          
          // Label e paxs
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
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${item.type.maxPassengers} pax',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade800,
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
              
              // Campo de quantidade
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
