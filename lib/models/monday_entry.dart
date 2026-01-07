import 'package:json_annotation/json_annotation.dart';

part 'monday_entry.g.dart';

@JsonSerializable()
class MondayEntry {
  final int id;
  final String? name;
  final String? email;
  final String? telefone;
  final String? cidade;
  final String? state;
  final String? country;
  final String? postalCode;
  final String? address;
  final String? sexo;
  final String? font;
  final String? contas;
  final String? tipo;
  final String? status;
  final String? vendedor;
  
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
  
  // Campos de auditoria
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  // Novos campos vindos de JOINs
  final int? contactCategoryId;
  final String? contactCategoryName;
  final int? sourceId;
  final String? sourceName;
  final int? accountId;
  final String? accountName;
  final String? customerTypeName;

  MondayEntry({
    required this.id,
    this.name,
    this.email,
    this.telefone,
    this.cidade,
    this.state,
    this.country,
    this.postalCode,
    this.address,
    this.sexo,
    this.font,
    this.contas,
    this.tipo,
    this.status,
    this.vendedor,
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
    this.createdAt,
    this.updatedAt,
    this.contactCategoryId,
    this.contactCategoryName,
    this.sourceId,
    this.sourceName,
    this.accountId,
    this.accountName,
    this.customerTypeName,
  });

  // Getters para compatibilidade com a UI existente
  String? get dataContato => contactDate;
  String? get dataFechamento => closingDate;
  String? get diaFechamento => closingDay;
  String? get idMonday => mondayId;

  factory MondayEntry.fromJson(Map<String, dynamic> json) => _$MondayEntryFromJson(json);
  Map<String, dynamic> toJson() => _$MondayEntryToJson(this);
} 
