import 'package:json_annotation/json_annotation.dart';

part 'api_configuration.g.dart';

@JsonSerializable()
class ApiConfiguration {
  final int id;
  final String apiName;
  final String apiDisplayName;
  final String? apiDescription;
  final String baseUrl;
  final String? apiKeyEncrypted;
  final String? apiSecretEncrypted;
  final String authType; // api_key, oauth2, bearer, basic
  final int requestsPerMinute;
  final int requestsPerHour;
  final int requestsPerDay;
  final int maxRetries;
  final int retryDelaySeconds;
  final bool exponentialBackoff;
  final bool isActive;
  final bool isTestMode;
  final Map<String, dynamic>? configData;
  final DateTime createdAt;
  final DateTime updatedAt;

  ApiConfiguration({
    required this.id,
    required this.apiName,
    required this.apiDisplayName,
    this.apiDescription,
    required this.baseUrl,
    this.apiKeyEncrypted,
    this.apiSecretEncrypted,
    required this.authType,
    this.requestsPerMinute = 60,
    this.requestsPerHour = 1000,
    this.requestsPerDay = 10000,
    this.maxRetries = 3,
    this.retryDelaySeconds = 5,
    this.exponentialBackoff = true,
    this.isActive = true,
    this.isTestMode = false,
    this.configData,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ApiConfiguration.fromJson(Map<String, dynamic> json) {
    try {
      return ApiConfiguration(
        id: json['id'] ?? 0,
        apiName: json['api_name'] ?? '',
        apiDisplayName: json['api_display_name'] ?? '',
        apiDescription: json['api_description'],
        baseUrl: json['base_url'] ?? '',
        apiKeyEncrypted: json['api_key_encrypted'],
        apiSecretEncrypted: json['api_secret_encrypted'],
        authType: json['auth_type'] ?? 'api_key',
        requestsPerMinute: json['requests_per_minute'] ?? 60,
        requestsPerHour: json['requests_per_hour'] ?? 1000,
        requestsPerDay: json['requests_per_day'] ?? 10000,
        maxRetries: json['max_retries'] ?? 3,
        retryDelaySeconds: json['retry_delay_seconds'] ?? 5,
        exponentialBackoff: json['exponential_backoff'] ?? true,
        isActive: json['is_active'] ?? true,
        isTestMode: json['is_test_mode'] ?? false,
        configData: json['config_data'],
        createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
        updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : DateTime.now(),
      );
    } catch (e) {
      print('Erro ao fazer parse do ApiConfiguration: $e');
      print('JSON recebido: $json');
      rethrow;
    }
  }
  Map<String, dynamic> toJson() => _$ApiConfigurationToJson(this);

  ApiConfiguration copyWith({
    int? id,
    String? apiName,
    String? apiDisplayName,
    String? apiDescription,
    String? baseUrl,
    String? apiKeyEncrypted,
    String? apiSecretEncrypted,
    String? authType,
    int? requestsPerMinute,
    int? requestsPerHour,
    int? requestsPerDay,
    int? maxRetries,
    int? retryDelaySeconds,
    bool? exponentialBackoff,
    bool? isActive,
    bool? isTestMode,
    Map<String, dynamic>? configData,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ApiConfiguration(
      id: id ?? this.id,
      apiName: apiName ?? this.apiName,
      apiDisplayName: apiDisplayName ?? this.apiDisplayName,
      apiDescription: apiDescription ?? this.apiDescription,
      baseUrl: baseUrl ?? this.baseUrl,
      apiKeyEncrypted: apiKeyEncrypted ?? this.apiKeyEncrypted,
      apiSecretEncrypted: apiSecretEncrypted ?? this.apiSecretEncrypted,
      authType: authType ?? this.authType,
      requestsPerMinute: requestsPerMinute ?? this.requestsPerMinute,
      requestsPerHour: requestsPerHour ?? this.requestsPerHour,
      requestsPerDay: requestsPerDay ?? this.requestsPerDay,
      maxRetries: maxRetries ?? this.maxRetries,
      retryDelaySeconds: retryDelaySeconds ?? this.retryDelaySeconds,
      exponentialBackoff: exponentialBackoff ?? this.exponentialBackoff,
      isActive: isActive ?? this.isActive,
      isTestMode: isTestMode ?? this.isTestMode,
      configData: configData ?? this.configData,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isConfigured => apiKeyEncrypted != null && apiKeyEncrypted!.isNotEmpty;
} 
