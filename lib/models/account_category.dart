import 'package:json_annotation/json_annotation.dart';

part 'account_category.g.dart';

@JsonSerializable()
class AccountCategory {
  final int accountId;
  final DateTime createdAt;
  final String? accountType;

  AccountCategory({
    required this.accountId,
    required this.createdAt,
    this.accountType,
  });

  factory AccountCategory.fromJson(Map<String, dynamic> json) => _$AccountCategoryFromJson(json);
  Map<String, dynamic> toJson() => _$AccountCategoryToJson(this);

  AccountCategory copyWith({
    int? accountId,
    DateTime? createdAt,
    String? accountType,
  }) {
    return AccountCategory(
      accountId: accountId ?? this.accountId,
      createdAt: createdAt ?? this.createdAt,
      accountType: accountType ?? this.accountType,
    );
  }
} 
