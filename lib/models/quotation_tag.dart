import 'package:json_annotation/json_annotation.dart';

part 'quotation_tag.g.dart';

/// Model para tags de cotações
@JsonSerializable()
class QuotationTag {
  final int id;
  final String name;
  final String color; // Hex color (ex: #FF5733)
  final String? description;
  final String? icon; // Nome do ícone Material
  
  @JsonKey(name: 'display_order')
  final int displayOrder;
  
  @JsonKey(name: 'is_active')
  final bool isActive;
  
  @JsonKey(name: 'is_system')
  final bool isSystem;
  
  @JsonKey(name: 'usage_count')
  final int? usageCount;
  
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  
  @JsonKey(name: 'assigned_at')
  final DateTime? assignedAt;

  QuotationTag({
    required this.id,
    required this.name,
    required this.color,
    this.description,
    this.icon,
    this.displayOrder = 0,
    this.isActive = true,
    this.isSystem = false,
    this.usageCount,
    this.createdAt,
    this.assignedAt,
  });

  factory QuotationTag.fromJson(Map<String, dynamic> json) => _$QuotationTagFromJson(json);
  Map<String, dynamic> toJson() => _$QuotationTagToJson(this);

  QuotationTag copyWith({
    int? id,
    String? name,
    String? color,
    String? description,
    String? icon,
    int? displayOrder,
    bool? isActive,
    bool? isSystem,
    int? usageCount,
    DateTime? createdAt,
    DateTime? assignedAt,
  }) {
    return QuotationTag(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      displayOrder: displayOrder ?? this.displayOrder,
      isActive: isActive ?? this.isActive,
      isSystem: isSystem ?? this.isSystem,
      usageCount: usageCount ?? this.usageCount,
      createdAt: createdAt ?? this.createdAt,
      assignedAt: assignedAt ?? this.assignedAt,
    );
  }
}

/// Request para criar nova tag
class CreateTagRequest {
  final String name;
  final String color;
  final String? description;
  final String? icon;
  final String createdBy;

  CreateTagRequest({
    required this.name,
    required this.color,
    this.description,
    this.icon,
    required this.createdBy,
  });

  Map<String, dynamic> toJson() => {
    'p_name': name,
    'p_color': color,
    'p_description': description,
    'p_icon': icon,
    'p_created_by': createdBy,
  };
}

/// Response de operações
class TagOperationResult {
  final bool success;
  final String message;
  final QuotationTag? tag;

  TagOperationResult({
    required this.success,
    required this.message,
    this.tag,
  });

  factory TagOperationResult.fromJson(Map<String, dynamic> json) {
    return TagOperationResult(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      tag: json['id'] != null ? QuotationTag.fromJson(json) : null,
    );
  }
}
