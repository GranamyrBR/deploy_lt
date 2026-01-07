import 'package:json_annotation/json_annotation.dart';

part 'driver_commission.g.dart';

@JsonSerializable()
class DriverCommission {
  final int id;
  final int operationId;
  final int driverId;
  final double baseCommissionUsd;
  final double bonusUsd;
  final double penaltyUsd;
  final double totalCommissionUsd;
  final double exchangeRateToUsd;
  final double? totalCommissionBrl;
  final String paymentStatus; // pending, approved, paid, cancelled
  final String? paymentMethod;
  final DateTime? paymentDate;
  final String? paymentReference;
  final String? bonusReason;
  final String? penaltyReason;
  final String? approvedByUserId;
  final DateTime? approvedAt;
  final String? paidByUserId;
  final DateTime? paidAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  DriverCommission({
    required this.id,
    required this.operationId,
    required this.driverId,
    required this.baseCommissionUsd,
    this.bonusUsd = 0,
    this.penaltyUsd = 0,
    required this.totalCommissionUsd,
    this.exchangeRateToUsd = 0.0, // Sem valor padrão - cotação deve ser definida manualmente
    this.totalCommissionBrl,
    required this.paymentStatus,
    this.paymentMethod,
    this.paymentDate,
    this.paymentReference,
    this.bonusReason,
    this.penaltyReason,
    this.approvedByUserId,
    this.approvedAt,
    this.paidByUserId,
    this.paidAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DriverCommission.fromJson(Map<String, dynamic> json) => _$DriverCommissionFromJson(json);
  Map<String, dynamic> toJson() => _$DriverCommissionToJson(this);

  DriverCommission copyWith({
    int? id,
    int? operationId,
    int? driverId,
    double? baseCommissionUsd,
    double? bonusUsd,
    double? penaltyUsd,
    double? totalCommissionUsd,
    double? exchangeRateToUsd,
    double? totalCommissionBrl,
    String? paymentStatus,
    String? paymentMethod,
    DateTime? paymentDate,
    String? paymentReference,
    String? bonusReason,
    String? penaltyReason,
    String? approvedByUserId,
    DateTime? approvedAt,
    String? paidByUserId,
    DateTime? paidAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DriverCommission(
      id: id ?? this.id,
      operationId: operationId ?? this.operationId,
      driverId: driverId ?? this.driverId,
      baseCommissionUsd: baseCommissionUsd ?? this.baseCommissionUsd,
      bonusUsd: bonusUsd ?? this.bonusUsd,
      penaltyUsd: penaltyUsd ?? this.penaltyUsd,
      totalCommissionUsd: totalCommissionUsd ?? this.totalCommissionUsd,
      exchangeRateToUsd: exchangeRateToUsd ?? this.exchangeRateToUsd,
      totalCommissionBrl: totalCommissionBrl ?? this.totalCommissionBrl,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentDate: paymentDate ?? this.paymentDate,
      paymentReference: paymentReference ?? this.paymentReference,
      bonusReason: bonusReason ?? this.bonusReason,
      penaltyReason: penaltyReason ?? this.penaltyReason,
      approvedByUserId: approvedByUserId ?? this.approvedByUserId,
      approvedAt: approvedAt ?? this.approvedAt,
      paidByUserId: paidByUserId ?? this.paidByUserId,
      paidAt: paidAt ?? this.paidAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
