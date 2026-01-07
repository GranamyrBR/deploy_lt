import 'package:flutter/foundation.dart';
import '../services/notification_service.dart';

/// Provider para gerenciar notificações na aplicação
class NotificationProvider extends ChangeNotifier {
  final NotificationService _notificationService = NotificationService();

  /// Lista de notificações
  List<AppNotification> get notifications => _notificationService.notifications;

  /// Notificações não lidas
  List<AppNotification> get unreadNotifications => _notificationService.unreadNotifications;

  /// Contador de notificações não lidas
  int get unreadCount => _notificationService.unreadCount;

  /// Inicializa o provider
  NotificationProvider() {
    _notificationService.addListener(_onNotificationAdded);
  }

  @override
  void dispose() {
    _notificationService.removeListener(_onNotificationAdded);
    super.dispose();
  }

  /// Callback chamado quando uma nova notificação é adicionada
  void _onNotificationAdded(AppNotification notification) {
    notifyListeners();
  }

  /// Adiciona uma nova notificação
  void addNotification(AppNotification notification) {
    _notificationService.addNotification(notification);
  }

  /// Marca uma notificação como lida
  void markAsRead(String notificationId) {
    _notificationService.markAsRead(notificationId);
    notifyListeners();
  }

  /// Marca todas as notificações como lidas
  void markAllAsRead() {
    _notificationService.markAllAsRead();
    notifyListeners();
  }

  /// Remove uma notificação
  void removeNotification(String notificationId) {
    _notificationService.removeNotification(notificationId);
    notifyListeners();
  }

  /// Limpa todas as notificações
  void clearAll() {
    _notificationService.clearAll();
    notifyListeners();
  }

  /// Limpa notificações antigas
  void clearOldNotifications() {
    _notificationService.clearOldNotifications();
    notifyListeners();
  }

  // Métodos de conveniência para diferentes tipos de notificação

  /// Notificação de sucesso
  void showSuccess(String title, String message, {Map<String, dynamic>? metadata}) {
    _notificationService.showSuccess(title, message, metadata: metadata);
  }

  /// Notificação de erro
  void showError(String title, String message, {Map<String, dynamic>? metadata}) {
    _notificationService.showError(title, message, metadata: metadata);
  }

  /// Notificação de aviso
  void showWarning(String title, String message, {Map<String, dynamic>? metadata}) {
    _notificationService.showWarning(title, message, metadata: metadata);
  }

  /// Notificação informativa
  void showInfo(String title, String message, {Map<String, dynamic>? metadata}) {
    _notificationService.showInfo(title, message, metadata: metadata);
  }

  // Métodos específicos para webhooks

  /// Notificação de webhook enviado com sucesso
  void notifyWebhookSuccess(dynamic config, String message) {
    _notificationService.notifyWebhookSuccess(config, message);
  }

  /// Notificação de erro no webhook
  void notifyWebhookError(dynamic config, String error) {
    _notificationService.notifyWebhookError(config, error);
  }

  /// Notificação de webhook desabilitado
  void notifyWebhookDisabled(dynamic config) {
    _notificationService.notifyWebhookDisabled(config);
  }

  /// Notificação de nova configuração de webhook
  void notifyWebhookConfigured(dynamic config) {
    _notificationService.notifyWebhookConfigured(config);
  }

  /// Notificação de integração WhatsApp
  void notifyWhatsAppSent(String phoneNumber, String message) {
    _notificationService.notifyWhatsAppSent(phoneNumber, message);
  }

  /// Notificação de erro no WhatsApp
  void notifyWhatsAppError(String phoneNumber, String error) {
    _notificationService.notifyWhatsAppError(phoneNumber, error);
  }

  /// Filtra notificações por tipo
  List<AppNotification> getNotificationsByType(NotificationType type) {
    return notifications.where((n) => n.type == type).toList();
  }

  /// Filtra notificações por período
  List<AppNotification> getNotificationsByPeriod(DateTime start, DateTime end) {
    return notifications.where((n) => 
        n.timestamp.isAfter(start) && n.timestamp.isBefore(end)
    ).toList();
  }

  /// Obtém notificações relacionadas a um webhook específico
  List<AppNotification> getWebhookNotifications(String webhookId) {
    return notifications.where((n) => 
        n.metadata?['webhookId'] == webhookId
    ).toList();
  }

  /// Obtém estatísticas das notificações
  Map<String, int> getNotificationStats() {
    final stats = <String, int>{
      'total': notifications.length,
      'unread': unreadCount,
      'success': 0,
      'error': 0,
      'warning': 0,
      'info': 0,
    };

    for (final notification in notifications) {
      switch (notification.type) {
        case NotificationType.success:
          stats['success'] = (stats['success'] ?? 0) + 1;
          break;
        case NotificationType.error:
          stats['error'] = (stats['error'] ?? 0) + 1;
          break;
        case NotificationType.warning:
          stats['warning'] = (stats['warning'] ?? 0) + 1;
          break;
        case NotificationType.info:
          stats['info'] = (stats['info'] ?? 0) + 1;
          break;
      }
    }

    return stats;
  }
}