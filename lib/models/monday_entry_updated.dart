import 'package:json_annotation/json_annotation.dart';

part 'monday_entry_updated.g.dart';

@JsonSerializable()
class MondayEntryUpdated {
  final int contactId;
  final String? name;
  final String? email;
  final String? phone;
  final String? city;
  final String? gender;
  
  // Campos específicos do Monday
  @JsonKey(name: 'previsao_Start')
  final String? previsaoStart;
  @JsonKey(name: 'previsao_End')
  final String? previsaoEnd;
  final String? servicos;
  final String? observacao;
  @JsonKey(name: 'contact_date')
  final String? contactDate;
  @JsonKey(name: 'closing_date')
  final String? closingDate;
  final String? log;
  final String? logAtual;
  final String? diasViagem;
  @JsonKey(name: 'closing_day')
  final String? closingDay;
  @JsonKey(name: 'monday_id')
  final String? mondayId;
  final String? vendedor;
  
  // Chaves estrangeiras (IDs)
  final int? sourceId;
  final int? accountId;
  final int? customerTypeId;
  final int? contactCategoryId;
  
  // Campos de auditoria
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  MondayEntryUpdated({
    required this.contactId,
    this.name,
    this.email,
    this.phone,
    this.city,
    this.gender,
    this.previsaoStart,
    this.previsaoEnd,
    this.servicos,
    this.observacao,
    this.contactDate,
    this.closingDate,
    this.log,
    this.logAtual,
    this.diasViagem,
    this.closingDay,
    this.mondayId,
    this.vendedor,
    this.sourceId,
    this.accountId,
    this.customerTypeId,
    this.contactCategoryId,
    this.createdAt,
    this.updatedAt,
  });

  factory MondayEntryUpdated.fromJson(Map<String, dynamic> json) => _$MondayEntryUpdatedFromJson(json);
  Map<String, dynamic> toJson() => _$MondayEntryUpdatedToJson(this);
} 
