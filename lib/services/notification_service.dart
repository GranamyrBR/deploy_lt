import 'package:flutter/material.dart';
import '../models/webhook_configuration.dart';

/// Tipos de notificação disponíveis
enum NotificationType {
  success,
  error,
  warning,
  info,
}

/// Modelo para notificações
class AppNotification {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime timestamp;
  final bool isRead;
  final Map<String, dynamic>? metadata;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.metadata,
  });

  AppNotification copyWith({
    String? id,
    String? title,
    String? message,
    NotificationType? type,
    DateTime? timestamp,
    bool? isRead,
    Map<String, dynamic>? metadata,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type.name,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'metadata': metadata,
    };
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'],
      title: json['title'],
      message: json['message'],
      type: NotificationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => NotificationType.info,
      ),
      timestamp: DateTime.parse(json['timestamp']),
      isRead: json['isRead'] ?? false,
      metadata: json['metadata'],
    );
  }
}

/// Serviço para gerenciar notificações da aplicação
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final List<AppNotification> _notifications = [];
  final List<Function(AppNotification)> _listeners = [];

  /// Lista de notificações
  List<AppNotification> get notifications => List.unmodifiable(_notifications);

  /// Notificações não lidas
  List<AppNotification> get unreadNotifications => 
      _notifications.where((n) => !n.isRead).toList();

  /// Contador de notificações não lidas
  int get unreadCount => unreadNotifications.length;

  /// Adiciona um listener para mudanças nas notificações
  void addListener(Function(AppNotification) listener) {
    _listeners.add(listener);
  }

  /// Remove um listener
  void removeListener(Function(AppNotification) listener) {
    _listeners.remove(listener);
  }

  /// Notifica todos os listeners
  void _notifyListeners(AppNotification notification) {
    for (final listener in _listeners) {
      try {
        listener(notification);
      } catch (e) {
        debugPrint('Erro ao notificar listener: $e');
      }
    }
  }

  /// Adiciona uma nova notificação
  void addNotification(AppNotification notification) {
    _notifications.insert(0, notification);
    _notifyListeners(notification);
    
    // Limita o número de notificações armazenadas
    if (_notifications.length > 100) {
      _notifications.removeRange(100, _notifications.length);
    }
  }

  /// Marca uma notificação como lida
  void markAsRead(String notificationId) {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
    }
  }

  /// Marca todas as notificações como lidas
  void markAllAsRead() {
    for (int i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(isRead: true);
    }
  }

  /// Remove uma notificação
  void removeNotification(String notificationId) {
    _notifications.removeWhere((n) => n.id == notificationId);
  }

  /// Limpa todas as notificações
  void clearAll() {
    _notifications.clear();
  }

  /// Limpa notificações antigas (mais de 7 dias)
  void clearOldNotifications() {
    final cutoffDate = DateTime.now().subtract(const Duration(days: 7));
    _notifications.removeWhere((n) => n.timestamp.isBefore(cutoffDate));
  }

  // Métodos de conveniência para diferentes tipos de notificação

  /// Notificação de sucesso
  void showSuccess(String title, String message, {Map<String, dynamic>? metadata}) {
    addNotification(AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      type: NotificationType.success,
      timestamp: DateTime.now(),
      metadata: metadata,
    ));
  }

  /// Notificação de erro
  void showError(String title, String message, {Map<String, dynamic>? metadata}) {
    addNotification(AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      type: NotificationType.error,
      timestamp: DateTime.now(),
      metadata: metadata,
    ));
  }

  /// Notificação de aviso
  void showWarning(String title, String message, {Map<String, dynamic>? metadata}) {
    addNotification(AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      type: NotificationType.warning,
      timestamp: DateTime.now(),
      metadata: metadata,
    ));
  }

  /// Notificação informativa
  void showInfo(String title, String message, {Map<String, dynamic>? metadata}) {
    addNotification(AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      type: NotificationType.info,
      timestamp: DateTime.now(),
      metadata: metadata,
    ));
  }

  // Notificações específicas para webhooks

  /// Notificação de webhook enviado com sucesso
  void notifyWebhookSuccess(WebhookConfiguration config, String message) {
    showSuccess(
      'Webhook Enviado',
      'Webhook "${config.name}" enviado com sucesso: $message',
      metadata: {
        'webhookId': config.id,
        'webhookName': config.name,
        'webhookUrl': config.webhookUrl,
      },
    );
  }

  /// Notificação de erro no webhook
  void notifyWebhookError(WebhookConfiguration config, String error) {
    showError(
      'Erro no Webhook',
      'Falha ao enviar webhook "${config.name}": $error',
      metadata: {
        'webhookId': config.id,
        'webhookName': config.name,
        'webhookUrl': config.webhookUrl,
        'error': error,
      },
    );
  }

  /// Notificação de webhook desabilitado por muitos erros
  void notifyWebhookDisabled(WebhookConfiguration config) {
    showWarning(
      'Webhook Desabilitado',
      'Webhook "${config.name}" foi desabilitado devido a muitos erros consecutivos',
      metadata: {
        'webhookId': config.id,
        'webhookName': config.name,
        'webhookUrl': config.webhookUrl,
      },
    );
  }

  /// Notificação de nova configuração de webhook
  void notifyWebhookConfigured(WebhookConfiguration config) {
    showInfo(
      'Webhook Configurado',
      'Novo webhook "${config.name}" foi configurado com sucesso',
      metadata: {
        'webhookId': config.id,
        'webhookName': config.name,
        'webhookUrl': config.webhookUrl,
      },
    );
  }

  /// Notificação de integração WhatsApp
  void notifyWhatsAppSent(String phoneNumber, String message) {
    showSuccess(
      'WhatsApp Enviado',
      'Mensagem enviada para $phoneNumber: ${message.length > 50 ? '${message.substring(0, 50)}...' : message}',
      metadata: {
        'phoneNumber': phoneNumber,
        'messageLength': message.length,
      },
    );
  }

  /// Notificação de erro no WhatsApp
  void notifyWhatsAppError(String phoneNumber, String error) {
    showError(
      'Erro no WhatsApp',
      'Falha ao enviar mensagem para $phoneNumber: $error',
      metadata: {
        'phoneNumber': phoneNumber,
        'error': error,
      },
    );
  }

  /// Exibe uma notificação como SnackBar no contexto fornecido
  void showSnackBar(BuildContext context, AppNotification notification) {
    Color backgroundColor;
    IconData icon;
    
    switch (notification.type) {
      case NotificationType.success:
        backgroundColor = Colors.green;
        icon = Icons.check_circle;
        break;
      case NotificationType.error:
        backgroundColor = Colors.red;
        icon = Icons.error;
        break;
      case NotificationType.warning:
        backgroundColor = Colors.orange;
        icon = Icons.warning;
        break;
      case NotificationType.info:
        backgroundColor = Colors.blue;
        icon = Icons.info;
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    notification.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    notification.message,
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: Duration(
          seconds: notification.type == NotificationType.error ? 5 : 3,
        ),
        action: SnackBarAction(
          label: 'Fechar',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
}
