import 'package:json_annotation/json_annotation.dart';

part 'contact_category.g.dart';

@JsonSerializable()
class ContactCategory {
  final int id;
  final String? name;
  final String? description;
  final bool? isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ContactCategory({
    required this.id,
    this.name,
    this.description,
    this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory ContactCategory.fromJson(Map<String, dynamic> json) => _$ContactCategoryFromJson(json);
  Map<String, dynamic> toJson() => _$ContactCategoryToJson(this);
} 
