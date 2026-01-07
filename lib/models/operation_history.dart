import 'package:json_annotation/json_annotation.dart';

part 'operation_history.g.dart';

@JsonSerializable()
class OperationHistory {
  final int id;
  final int operationId;
  final String actionType; // created, status_changed, driver_assigned, driver_unassigned, car_assigned, car_unassigned, scheduled, started, completed, cancelled, note_added, location_updated
  final String? oldValue;
  final String? newValue;
  final Map<String, dynamic>? actionData;
  final String? performedByUserId;
  final String? performedByUserName;
  final DateTime performedAt;

  OperationHistory({
    required this.id,
    required this.operationId,
    required this.actionType,
    this.oldValue,
    this.newValue,
    this.actionData,
    this.performedByUserId,
    this.performedByUserName,
    required this.performedAt,
  });

  factory OperationHistory.fromJson(Map<String, dynamic> json) => _$OperationHistoryFromJson(json);
  Map<String, dynamic> toJson() => _$OperationHistoryToJson(this);

  OperationHistory copyWith({
    int? id,
    int? operationId,
    String? actionType,
    String? oldValue,
    String? newValue,
    Map<String, dynamic>? actionData,
    String? performedByUserId,
    String? performedByUserName,
    DateTime? performedAt,
  }) {
    return OperationHistory(
      id: id ?? this.id,
      operationId: operationId ?? this.operationId,
      actionType: actionType ?? this.actionType,
      oldValue: oldValue ?? this.oldValue,
      newValue: newValue ?? this.newValue,
      actionData: actionData ?? this.actionData,
      performedByUserId: performedByUserId ?? this.performedByUserId,
      performedByUserName: performedByUserName ?? this.performedByUserName,
      performedAt: performedAt ?? this.performedAt,
    );
  }
} 
