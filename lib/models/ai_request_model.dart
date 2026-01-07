import 'package:json_annotation/json_annotation.dart';

part 'ai_request_model.g.dart';

@JsonSerializable()
class AIRequest {
  final String message;
  final String userId;
  final String conversationId;
  final DateTime timestamp;
  final Map<String, dynamic>? context;
  final String? requestType;

  AIRequest({
    required this.message,
    required this.userId,
    required this.conversationId,
    this.context,
    this.requestType,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory AIRequest.fromJson(Map<String, dynamic> json) =>
      _$AIRequestFromJson(json);

  Map<String, dynamic> toJson() => _$AIRequestToJson(this);

  AIRequest copyWith({
    String? message,
    String? userId,
    String? conversationId,
    Map<String, dynamic>? context,
    String? requestType,
    DateTime? timestamp,
  }) {
    return AIRequest(
      message: message ?? this.message,
      userId: userId ?? this.userId,
      conversationId: conversationId ?? this.conversationId,
      context: context ?? this.context,
      requestType: requestType ?? this.requestType,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}