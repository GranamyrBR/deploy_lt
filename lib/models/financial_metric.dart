
class FinancialMetric {
  final String id;
  final String name;
  final String description;
  final double currentValue;
  final double previousValue;
  final String unit;
  final String category;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final String? targetValue;
  final String? alertThreshold;

  FinancialMetric({
    required this.id,
    required this.name,
    required this.description,
    required this.currentValue,
    required this.previousValue,
    required this.unit,
    required this.category,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.targetValue,
    this.alertThreshold,
  });

  double get variationPercentage {
    if (previousValue == 0) return 0;
    return ((currentValue - previousValue) / previousValue) * 100;
  }

  bool get isPositiveVariation => variationPercentage > 0;

  bool get hasAlert {
    if (alertThreshold == null) return false;
    
    final threshold = double.tryParse(alertThreshold!);
    if (threshold == null) return false;
    
    return currentValue < threshold;
  }

  factory FinancialMetric.fromJson(Map<String, dynamic> json) {
    return FinancialMetric(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      currentValue: (json['current_value'] ?? 0).toDouble(),
      previousValue: (json['previous_value'] ?? 0).toDouble(),
      unit: json['unit'] ?? '',
      category: json['category'] ?? 'general',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toUtc().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toUtc().toIso8601String()),
      isActive: json['is_active'] ?? true,
      targetValue: json['target_value'],
      alertThreshold: json['alert_threshold'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'current_value': currentValue,
      'previous_value': previousValue,
      'unit': unit,
      'category': category,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_active': isActive,
      'target_value': targetValue,
      'alert_threshold': alertThreshold,
    };
  }

  FinancialMetric copyWith({
    String? id,
    String? name,
    String? description,
    double? currentValue,
    double? previousValue,
    String? unit,
    String? category,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    String? targetValue,
    String? alertThreshold,
  }) {
    return FinancialMetric(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      currentValue: currentValue ?? this.currentValue,
      previousValue: previousValue ?? this.previousValue,
      unit: unit ?? this.unit,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      targetValue: targetValue ?? this.targetValue,
      alertThreshold: alertThreshold ?? this.alertThreshold,
    );
  }

  @override
  String toString() {
    return 'FinancialMetric(id: $id, name: $name, currentValue: $currentValue$unit, category: $category)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is FinancialMetric &&
      other.id == id &&
      other.name == name &&
      other.currentValue == currentValue &&
      other.category == category;
  }

  @override
  int get hashCode {
    return id.hashCode ^ name.hashCode ^ currentValue.hashCode ^ category.hashCode;
  }
}