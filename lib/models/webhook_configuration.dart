class WebhookConfiguration {
  final String id;
  final String name;
  final String webhookUrl;
  final bool isEnabled;
  final DateTime createdAt;
  final DateTime? updatedAt;

  WebhookConfiguration({
    required this.id,
    required this.name,
    required this.webhookUrl,
    this.isEnabled = true,
    required this.createdAt,
    this.updatedAt,
  });

  factory WebhookConfiguration.fromJson(Map<String, dynamic> json) {
    return WebhookConfiguration(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      webhookUrl: json['webhookUrl'] ?? json['webhook_url'] ?? '',
      isEnabled: json['isEnabled'] ?? json['is_enabled'] ?? true,
      createdAt: DateTime.parse(json['createdAt'] ?? json['created_at'] ?? DateTime.now().toUtc().toIso8601String()),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : (json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'webhookUrl': webhookUrl,
      'isEnabled': isEnabled,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
