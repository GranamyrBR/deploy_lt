import 'package:flutter/material.dart' as flutter;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/localization_service.dart';

// Provider para o idioma atual
final currentLanguageProvider = StateNotifierProvider<LanguageNotifier, String>((ref) {
  return LanguageNotifier();
});

// Provider para as opções de idioma
final languageOptionsProvider = Provider<List<Map<String, String>>>((ref) {
  return LocalizationService.getLanguageOptions();
});

// Provider para o locale atual
final currentLocaleProvider = Provider<flutter.Locale>((ref) {
  final language = ref.watch(currentLanguageProvider);
  return LocalizationService.getLocaleFromLanguage(language);
});

// Provider para a direção do texto
final textDirectionProvider = Provider<flutter.TextDirection>((ref) {
  final language = ref.watch(currentLanguageProvider);
  return LocalizationService.getTextDirection(language);
});

// Notifier para gerenciar o idioma
class LanguageNotifier extends StateNotifier<String> {
  LanguageNotifier() : super('pt') {
    _initializeLanguage();
  }

  Future<void> _initializeLanguage() async {
    final currentLanguage = await LocalizationService.getCurrentLanguage();
    state = currentLanguage;
  }

  Future<void> setLanguage(flutter.BuildContext context, String languageCode) async {
    if (LocalizationService.isLanguageSupported(languageCode)) {
      await LocalizationService.setLanguage(context, languageCode);
      state = languageCode;
    }
  }

  String getLanguageName(String languageCode) {
    return LocalizationService.getLanguageName(languageCode);
  }

  bool isLanguageSupported(String languageCode) {
    return LocalizationService.isLanguageSupported(languageCode);
  }

  List<Map<String, String>> getLanguageOptions() {
    return LocalizationService.getLanguageOptions();
  }
}

// Provider para traduções comuns
final commonTranslationsProvider = Provider<Map<String, String>>((ref) {
  return {
    'save': 'common.save',
    'cancel': 'common.cancel',
    'delete': 'common.delete',
    'edit': 'common.edit',
    'add': 'common.add',
    'search': 'common.search',
    'filter': 'common.filter',
    'refresh': 'common.refresh',
    'loading': 'common.loading',
    'error': 'common.error',
    'success': 'common.success',
    'warning': 'common.warning',
    'info': 'common.info',
    'confirm': 'common.confirm',
    'yes': 'common.yes',
    'no': 'common.no',
    'ok': 'common.ok',
    'close': 'common.close',
    'back': 'common.back',
    'next': 'common.next',
    'previous': 'common.previous',
    'submit': 'common.submit',
    'reset': 'common.reset',
    'clear': 'common.clear',
    'select': 'common.select',
    'all': 'common.all',
    'none': 'common.none',
    'actions': 'common.actions',
    'status': 'common.status',
    'date': 'common.date',
    'time': 'common.time',
    'amount': 'common.amount',
    'total': 'common.total',
    'quantity': 'common.quantity',
    'price': 'common.price',
    'currency': 'common.currency',
    'contact': 'common.contact',
    'service': 'common.service',
    'payment': 'common.payment',
    'user': 'common.user',
    'name': 'common.name',
    'email': 'common.email',
    'phone': 'common.phone',
    'address': 'common.address',
    'city': 'common.city',
    'state': 'common.state',
    'country': 'common.country',
    'description': 'common.description',
    'notes': 'common.notes',
  };
});

// Provider para traduções de navegação
final navigationTranslationsProvider = Provider<Map<String, String>>((ref) {
  return {
    'dashboard': 'navigation.dashboard',
    'sales': 'navigation.sales',
    'contacts': 'navigation.contacts',
    'services': 'navigation.services',
    'flights': 'navigation.flights',
    'reports': 'navigation.reports',
    'settings': 'navigation.settings',
    'profile': 'navigation.profile',
    'logout': 'navigation.logout',
    'menu': 'navigation.menu',
    'home': 'navigation.home',
    'analytics': 'navigation.analytics',
    'management': 'navigation.management',
    'system': 'navigation.system',
  };
});

// Provider para traduções de autenticação
final authTranslationsProvider = Provider<Map<String, String>>((ref) {
  return {
    'login': 'auth.login',
    'logout': 'auth.logout',
    'register': 'auth.register',
    'email': 'auth.email',
    'password': 'auth.password',
    'confirm_password': 'auth.confirm_password',
    'forgot_password': 'auth.forgot_password',
    'remember_me': 'auth.remember_me',
    'sign_in': 'auth.sign_in',
    'sign_up': 'auth.sign_up',
    'welcome': 'auth.welcome',
    'login_success': 'auth.login_success',
    'login_error': 'auth.login_error',
    'invalid_credentials': 'auth.invalid_credentials',
    'password_required': 'auth.password_required',
    'email_required': 'auth.email_required',
    'email_invalid': 'auth.email_invalid',
  };
});

// Provider para traduções de vendas
final salesTranslationsProvider = Provider<Map<String, String>>((ref) {
  return {
    'title': 'sales.title',
    'new_sale': 'sales.new_sale',
    'edit_sale': 'sales.edit_sale',
    'delete_sale': 'sales.delete_sale',
    'sale_details': 'sales.sale_details',
    'sale_id': 'sales.sale_id',
    'sale_date': 'sales.sale_date',
    'sale_status': 'sales.sale_status',
    'sale_amount': 'sales.sale_amount',
    'sale_total': 'sales.sale_total',
    'sale_contact': 'sales.sale_contact',
    'sale_agent': 'sales.sale_agent',
    'sale_notes': 'sales.sale_notes',
    'sale_currency': 'sales.sale_currency',
    'sale_cancellation': 'sales.sale_cancellation',
    'sale_refund': 'sales.sale_refund',
    'sale_delete_confirm': 'sales.sale_delete_confirm',
    'sale_delete_success': 'sales.sale_delete_success',
    'sale_delete_error': 'sales.sale_delete_error',
    'sale_save_success': 'sales.sale_save_success',
    'sale_save_error': 'sales.sale_save_error',
    'sale_update_success': 'sales.sale_update_success',
    'sale_update_error': 'sales.sale_update_error',
    'sale_create_success': 'sales.sale_create_success',
    'sale_create_error': 'sales.sale_create_error',
    'sale_cancel_success': 'sales.sale_cancel_success',
    'sale_cancel_error': 'sales.sale_cancel_error',
    'sale_refund_success': 'sales.sale_refund_success',
    'sale_refund_error': 'sales.sale_refund_error',
  };
});

// Provider para traduções de cancelamento de vendas
final salesCancellationTranslationsProvider = Provider<Map<String, String>>((ref) {
  return {
    'title': 'sales_cancellation.title',
    'cancellation_logs': 'sales_cancellation.cancellation_logs',
    'cancellation_details': 'sales_cancellation.cancellation_details',
    'cancellation_reason': 'sales_cancellation.cancellation_reason',
    'cancellation_type': 'sales_cancellation.cancellation_type',
    'cancellation_date': 'sales_cancellation.cancellation_date',
    'cancelled_by': 'sales_cancellation.cancelled_by',
    'cancellation_notes': 'sales_cancellation.cancellation_notes',
    'refund_required': 'sales_cancellation.refund_required',
    'refund_amount': 'sales_cancellation.refund_amount',
    'refund_status': 'sales_cancellation.refund_status',
    'refund_date': 'sales_cancellation.refund_date',
    'refund_method': 'sales_cancellation.refund_method',
    'refund_transaction_id': 'sales_cancellation.refund_transaction_id',
    'cancel_sale': 'sales_cancellation.cancel_sale',
    'cancel_sale_confirm': 'sales_cancellation.cancel_sale_confirm',
    'cancel_sale_success': 'sales_cancellation.cancel_sale_success',
    'cancel_sale_error': 'sales_cancellation.cancel_sale_error',
    'update_refund_success': 'sales_cancellation.update_refund_success',
    'update_refund_error': 'sales_cancellation.update_refund_error',
    'total_cancellations': 'sales_cancellation.total_cancellations',
    'total_amount_cancelled': 'sales_cancellation.total_amount_cancelled',
    'total_refund_amount': 'sales_cancellation.total_refund_amount',
    'avg_amount_cancelled': 'sales_cancellation.avg_amount_cancelled',
    'cancellations_by_type': 'sales_cancellation.cancellations_by_type',
    'refunds_by_status': 'sales_cancellation.refunds_by_status',
    'pending_refunds': 'sales_cancellation.pending_refunds',
    'cancellation_statistics': 'sales_cancellation.cancellation_statistics',
    'cancellation_reports': 'sales_cancellation.cancellation_reports',
    'cancellation_analytics': 'sales_cancellation.cancellation_analytics',
  };
});

// Provider para traduções de tipos de cancelamento
final cancellationTypesTranslationsProvider = Provider<Map<String, String>>((ref) {
  return {
    'client_request': 'sales_cancellation.cancellation_types.client_request',
    'payment_issue': 'sales_cancellation.cancellation_types.payment_issue',
    'service_unavailable': 'sales_cancellation.cancellation_types.service_unavailable',
    'error': 'sales_cancellation.cancellation_types.error',
    'other': 'sales_cancellation.cancellation_types.other',
  };
});

// Provider para traduções de status de reembolso
final refundStatusesTranslationsProvider = Provider<Map<String, String>>((ref) {
  return {
    'pending': 'sales_cancellation.refund_statuses.pending',
    'processed': 'sales_cancellation.refund_statuses.processed',
    'completed': 'sales_cancellation.refund_statuses.completed',
    'failed': 'sales_cancellation.refund_statuses.failed',
  };
});

// Provider para traduções de mensagens
final messagesTranslationsProvider = Provider<Map<String, String>>((ref) {
  return {
    'welcome': 'messages.welcome',
    'goodbye': 'messages.goodbye',
    'loading_data': 'messages.loading_data',
    'saving_data': 'messages.saving_data',
    'deleting_data': 'messages.deleting_data',
    'updating_data': 'messages.updating_data',
    'creating_data': 'messages.creating_data',
    'data_loaded': 'messages.data_loaded',
    'data_saved': 'messages.data_saved',
    'data_deleted': 'messages.data_deleted',
    'data_updated': 'messages.data_updated',
    'data_created': 'messages.data_created',
    'no_data': 'messages.no_data',
    'no_results': 'messages.no_results',
    'try_again': 'messages.try_again',
    'contact_support': 'messages.contact_support',
    'operation_successful': 'messages.operation_successful',
    'operation_failed': 'messages.operation_failed',
    'please_wait': 'messages.please_wait',
    'processing': 'messages.processing',
    'completed': 'messages.completed',
    'failed': 'messages.failed',
    'cancelled': 'messages.cancelled',
    'pending': 'messages.pending',
    'in_progress': 'messages.in_progress',
    'scheduled': 'messages.scheduled',
    'overdue': 'messages.overdue',
    'on_time': 'messages.on_time',
    'delayed': 'messages.delayed',
    'completed_early': 'messages.completed_early',
    'completed_late': 'messages.completed_late',
  };
});

// Provider para traduções de erros
final errorsTranslationsProvider = Provider<Map<String, String>>((ref) {
  return {
    'network_error': 'errors.network_error',
    'server_error': 'errors.server_error',
    'timeout_error': 'errors.timeout_error',
    'unauthorized_error': 'errors.unauthorized_error',
    'forbidden_error': 'errors.forbidden_error',
    'not_found_error': 'errors.not_found_error',
    'validation_error': 'errors.validation_error',
    'unknown_error': 'errors.unknown_error',
    'connection_error': 'errors.connection_error',
    'database_error': 'errors.database_error',
    'file_error': 'errors.file_error',
    'permission_error': 'errors.permission_error',
    'quota_error': 'errors.quota_error',
    'maintenance_error': 'errors.maintenance_error',
    'version_error': 'errors.version_error',
  };
});

// Provider para traduções de validação
final validationTranslationsProvider = Provider<Map<String, String>>((ref) {
  return {
    'required': 'validation.required',
    'email': 'validation.email',
    'phone': 'validation.phone',
    'min_length': 'validation.min_length',
    'max_length': 'validation.max_length',
    'min_value': 'validation.min_value',
    'max_value': 'validation.max_value',
    'numeric': 'validation.numeric',
    'integer': 'validation.integer',
    'decimal': 'validation.decimal',
    'positive': 'validation.positive',
    'negative': 'validation.negative',
    'zero': 'validation.zero',
    'date': 'validation.date',
    'time': 'validation.time',
    'datetime': 'validation.datetime',
    'past_date': 'validation.past_date',
    'future_date': 'validation.future_date',
    'today': 'validation.today',
    'yesterday': 'validation.yesterday',
    'tomorrow': 'validation.tomorrow',
    'week': 'validation.week',
    'month': 'validation.month',
    'year': 'validation.year',
    'password_match': 'validation.password_match',
    'password_weak': 'validation.password_weak',
    'password_strong': 'validation.password_strong',
    'username_taken': 'validation.username_taken',
    'email_taken': 'validation.email_taken',
    'phone_taken': 'validation.phone_taken',
    'invalid_format': 'validation.invalid_format',
    'invalid_characters': 'validation.invalid_characters',
    'invalid_size': 'validation.invalid_size',
    'invalid_type': 'validation.invalid_type',
    'file_too_large': 'validation.file_too_large',
    'file_too_small': 'validation.file_too_small',
    'file_required': 'validation.file_required',
    'file_optional': 'validation.file_optional',
  };
}); 
