import 'package:json_annotation/json_annotation.dart';

part 'ai_response_model.g.dart';

@JsonSerializable()
class AIResponse {
  final String message;
  final String conversationId;
  final DateTime timestamp;
  final int tokensUsed;
  final String model;
  final Map<String, dynamic>? metadata;
  final String? error;

  AIResponse({
    required this.message,
    required this.conversationId,
    required this.timestamp,
    required this.tokensUsed,
    required this.model,
    this.metadata,
    this.error,
  });

  factory AIResponse.fromJson(Map<String, dynamic> json) =>
      _$AIResponseFromJson(json);

  Map<String, dynamic> toJson() => _$AIResponseToJson(this);

  bool get hasError => error != null && error!.isNotEmpty;
  bool get isSuccess => !hasError;

  AIResponse copyWith({
    String? message,
    String? conversationId,
    DateTime? timestamp,
    int? tokensUsed,
    String? model,
    Map<String, dynamic>? metadata,
    String? error,
  }) {
    return AIResponse(
      message: message ?? this.message,
      conversationId: conversationId ?? this.conversationId,
      timestamp: timestamp ?? this.timestamp,
      tokensUsed: tokensUsed ?? this.tokensUsed,
      model: model ?? this.model,
      metadata: metadata ?? this.metadata,
      error: error ?? this.error,
    );
  }

  @override
  String toString() {
    return 'AIResponse(message: $message, conversationId: $conversationId, '
           'tokensUsed: $tokensUsed, model: $model, error: $error)';
  }
}