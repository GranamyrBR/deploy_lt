/// Modelo para bagagens de cotação (dados do banco)
class QuotationLuggage {
  final int id;
  final int quotationId;
  final String luggageType;
  final int quantity;
  final DateTime createdAt;
  final DateTime updatedAt;

  QuotationLuggage({
    required this.id,
    required this.quotationId,
    required this.luggageType,
    required this.quantity,
    required this.createdAt,
    required this.updatedAt,
  });

  factory QuotationLuggage.fromJson(Map<String, dynamic> json) {
    return QuotationLuggage(
      id: json['id'] as int,
      quotationId: json['quotation_id'] as int,
      luggageType: json['luggage_type'] as String,
      quantity: json['quantity'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'quotation_id': quotationId,
      'luggage_type': luggageType,
      'quantity': quantity,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get label {
    switch (luggageType) {
      case 'carry_on':
        return 'Bagagem de Mão';
      case 'checked':
        return 'Bagagem Despachada';
      case 'large_checked':
        return 'Bagagem Grande';
      case 'personal':
        return 'Item Pessoal';
      default:
        return 'Desconhecido';
    }
  }

  String get specs {
    switch (luggageType) {
      case 'carry_on':
        return 'Até 10kg - 55x40x20cm';
      case 'checked':
        return '23kg - 158cm linear';
      case 'large_checked':
        return 'Até 32kg - 203cm linear';
      case 'personal':
        return 'Até 5kg - 40x30x15cm';
      default:
        return '';
    }
  }

  String get displayText {
    return '$quantity x $label ($specs)';
  }
}
