import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:state_notifier/state_notifier.dart';

import '../services/google_calendar_service.dart';
import '../models/google_calendar_event.dart';
import '../models/api_configuration.dart';

// Estado do Google Calendar
class GoogleCalendarState {
  final List<GoogleCalendarEvent> events;
  final List<GoogleCalendar> calendars;
  final GoogleCalendar? selectedCalendar;
  final Set<String> selectedCalendarIds;
  final bool isLoading;
  final String? error;
  final bool isConfigured;
  final bool isAuthenticated;
  final String? accessToken;
  final String? selectedPeriod; // today, week, month

  GoogleCalendarState({
    required this.events,
    required this.calendars,
    this.selectedCalendar,
    Set<String>? selectedCalendarIds,
    required this.isLoading,
    this.error,
    required this.isConfigured,
    required this.isAuthenticated,
    this.accessToken,
    this.selectedPeriod,
  }) : selectedCalendarIds = selectedCalendarIds ?? {};

  GoogleCalendarState copyWith({
    List<GoogleCalendarEvent>? events,
    List<GoogleCalendar>? calendars,
    GoogleCalendar? selectedCalendar,
    Set<String>? selectedCalendarIds,
    bool? isLoading,
    String? error,
    bool? isConfigured,
    bool? isAuthenticated,
    String? accessToken,
    String? selectedPeriod,
  }) {
    return GoogleCalendarState(
      events: events ?? this.events,
      calendars: calendars ?? this.calendars,
      selectedCalendar: selectedCalendar ?? this.selectedCalendar,
      selectedCalendarIds: selectedCalendarIds ?? this.selectedCalendarIds,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isConfigured: isConfigured ?? this.isConfigured,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      accessToken: accessToken ?? this.accessToken,
      selectedPeriod: selectedPeriod ?? this.selectedPeriod,
    );
  }

  // Obter eventos de hoje
  List<GoogleCalendarEvent> get todayEvents {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    return events.where((event) {
      final eventDate = event.start?.dateTime ?? event.start?.date;
      if (eventDate == null) return false;

      DateTime eventDateTime;
      if (event.start?.dateTime != null) {
        eventDateTime = event.start!.dateTime!;
      } else {
        eventDateTime = DateTime.parse(event.start!.date!);
      }

      return eventDateTime.isAfter(today) && eventDateTime.isBefore(tomorrow);
    }).toList();
  }

  // Obter eventos da semana
  List<GoogleCalendarEvent> get weekEvents {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 7));

    return events.where((event) {
      final eventDate = event.start?.dateTime ?? event.start?.date;
      if (eventDate == null) return false;

      DateTime eventDateTime;
      if (event.start?.dateTime != null) {
        eventDateTime = event.start!.dateTime!;
      } else {
        eventDateTime = DateTime.parse(event.start!.date!);
      }

      return eventDateTime.isAfter(startOfWeek) && eventDateTime.isBefore(endOfWeek);
    }).toList();
  }

  // Obter eventos do mês
  List<GoogleCalendarEvent> get monthEvents {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 1);

    return events.where((event) {
      final eventDate = event.start?.dateTime ?? event.start?.date;
      if (eventDate == null) return false;

      DateTime eventDateTime;
      if (event.start?.dateTime != null) {
        eventDateTime = event.start!.dateTime!;
      } else {
        eventDateTime = DateTime.parse(event.start!.date!);
      }

      return eventDateTime.isAfter(startOfMonth) && eventDateTime.isBefore(endOfMonth);
    }).toList();
  }

  // Obter eventos próximos (próximas 24 horas)
  List<GoogleCalendarEvent> get upcomingEvents {
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));

    return events.where((event) {
      final eventDate = event.start?.dateTime ?? event.start?.date;
      if (eventDate == null) return false;

      DateTime eventDateTime;
      if (event.start?.dateTime != null) {
        eventDateTime = event.start!.dateTime!;
      } else {
        eventDateTime = DateTime.parse(event.start!.date!);
      }

      return eventDateTime.isAfter(now) && eventDateTime.isBefore(tomorrow);
    }).toList();
  }

  // Obter calendários selecionados
  List<GoogleCalendar> get selectedCalendars {
    return calendars.where((calendar) => 
      selectedCalendarIds.contains(calendar.id)
    ).toList();
  }

  // Verificar se um calendário está selecionado
  bool isCalendarSelected(String calendarId) {
    return selectedCalendarIds.contains(calendarId);
  }

  // Verificar se todos os calendários estão selecionados
  bool get areAllCalendarsSelected {
    return calendars.isNotEmpty && selectedCalendarIds.length == calendars.length;
  }

  // Verificar se pelo menos um calendário está selecionado
  bool get hasSelectedCalendars {
    return selectedCalendarIds.isNotEmpty;
  }
}

// Provider do serviço Google Calendar
final googleCalendarServiceProvider = Provider<GoogleCalendarService>((ref) {
  return GoogleCalendarService();
});

// Provider do estado do Google Calendar
class GoogleCalendarNotifier extends StateNotifier<GoogleCalendarState> {
  final GoogleCalendarService _service;

  GoogleCalendarNotifier(this._service) : super(GoogleCalendarState(
    events: [],
    calendars: [],
    isLoading: false,
    isConfigured: false,
    isAuthenticated: false,
  ));

  // Configurar o serviço
  void configure(ApiConfiguration apiConfig, {String? accessToken, String? calendarId}) {
    _service.configure(apiConfig, accessToken: accessToken, calendarId: calendarId);
    state = state.copyWith(isConfigured: true);
  }

  // Definir token de acesso
  void setAccessToken(String token) {
    // Configurar o serviço com o token de acesso
    _service.setAccessToken(token);
    
    state = state.copyWith(
      isConfigured: true,
      isAuthenticated: token.isNotEmpty,
      accessToken: token,
    );
  }

  // Obter configuração do Google Calendar
  ApiConfiguration? _getGoogleCalendarConfig() {
    // Usar a configuração real do Supabase
    // Esta configuração já foi carregada pelo ApiConfigurationProvider
    // Vamos buscar ela do provider
    return null; // Será configurado via configure()
  }

  // Configurar com configuração real
  void configureWithRealConfig(ApiConfiguration apiConfig) {
    _service.configure(apiConfig);
    state = state.copyWith(isConfigured: true);
  }

  // Definir eventos mock para teste
  void setMockEvents(List<GoogleCalendarEvent> events) {
    state = state.copyWith(
      events: events,
      isLoading: false,
      error: null,
    );
  }

  // Carregar calendários
  Future<void> loadCalendars() async {
    if (!state.isConfigured) {
      state = state.copyWith(error: 'Google Calendar não está configurado');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final calendars = await _service.listCalendars();
      final primaryCalendar = calendars.firstWhere(
        (cal) => cal.primary == true,
        orElse: () => calendars.first,
      );

      state = state.copyWith(
        calendars: calendars,
        selectedCalendar: primaryCalendar,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao carregar calendários: $e',
      );
    }
  }

  // Carregar eventos
  Future<void> loadEvents({String? period}) async {
    if (!state.isConfigured) {
      state = state.copyWith(error: 'Google Calendar não está configurado');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      List<GoogleCalendarEvent> events;
      
      if (period != null) {
        events = await _service.getEventsByPeriod(period);
        state = state.copyWith(selectedPeriod: period);
      } else {
        events = await _service.listEvents();
      }

      state = state.copyWith(
        events: events,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao carregar eventos: $e',
      );
    }
  }

  // Carregar eventos por período
  Future<void> loadEventsByPeriod(String period) async {
    if (!state.isConfigured) {
      state = state.copyWith(error: 'Google Calendar não está configurado');
      return;
    }

    // Se não há calendários selecionados, usar o método antigo
    if (state.selectedCalendarIds.isEmpty) {
      await loadEvents(period: period);
      return;
    }

    // Usar os calendários selecionados
    await loadEventsFromSelectedCalendars(period: period);
  }

  // Carregar todos os eventos (últimos 6 meses)
  Future<void> loadAllEvents() async {
    if (!state.isConfigured) {
      state = state.copyWith(error: 'Google Calendar não está configurado');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final events = await _service.getAllEvents();
      
      state = state.copyWith(
        events: events,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao carregar todos os eventos: $e',
      );
    }
  }

  // Carregar muitos eventos (até 10.000)
  Future<void> loadManyEvents() async {
    if (!state.isConfigured) {
      state = state.copyWith(error: 'Google Calendar não está configurado');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final events = await _service.getManyEvents();
      
      state = state.copyWith(
        events: events,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao carregar muitos eventos: $e',
      );
    }
  }

  // Buscar evento específico
  Future<GoogleCalendarEvent?> getEvent(String eventId) async {
    if (!state.isConfigured) {
      state = state.copyWith(error: 'Google Calendar não está configurado');
      return null;
    }

    try {
      return await _service.getEvent(eventId);
    } catch (e) {
      state = state.copyWith(error: 'Erro ao buscar evento: $e');
      return null;
    }
  }

  // Criar evento
  Future<GoogleCalendarEvent?> createEvent(GoogleCalendarEvent event) async {
    if (!state.isConfigured) {
      state = state.copyWith(error: 'Google Calendar não está configurado');
      return null;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final createdEvent = await _service.createEvent(event);
      
      // Adicionar à lista de eventos
      final updatedEvents = [...state.events, createdEvent];
      
      state = state.copyWith(
        events: updatedEvents,
        isLoading: false,
      );

      return createdEvent;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao criar evento: $e',
      );
      return null;
    }
  }

  // Atualizar evento
  Future<GoogleCalendarEvent?> updateEvent(String eventId, GoogleCalendarEvent event) async {
    if (!state.isConfigured) {
      state = state.copyWith(error: 'Google Calendar não está configurado');
      return null;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final updatedEvent = await _service.updateEvent(eventId, event);
      
      // Atualizar na lista de eventos
      final updatedEvents = state.events.map((e) {
        return e.id == eventId ? updatedEvent : e;
      }).toList();
      
      state = state.copyWith(
        events: updatedEvents,
        isLoading: false,
      );

      return updatedEvent;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao atualizar evento: $e',
      );
      return null;
    }
  }

  // Excluir evento
  Future<bool> deleteEvent(String eventId) async {
    if (!state.isConfigured) {
      state = state.copyWith(error: 'Google Calendar não está configurado');
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final success = await _service.deleteEvent(eventId);
      
      if (success) {
        // Remover da lista de eventos
        final updatedEvents = state.events.where((e) => e.id != eventId).toList();
        
        state = state.copyWith(
          events: updatedEvents,
          isLoading: false,
        );
      }

      return success;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao excluir evento: $e',
      );
      return false;
    }
  }

  // Criar evento a partir de uma operação
  Future<GoogleCalendarEvent?> createEventFromOperation(Map<String, dynamic> operation) async {
    if (!state.isConfigured) {
      state = state.copyWith(error: 'Google Calendar não está configurado');
      return null;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final createdEvent = await _service.createEventFromOperation(operation);
      
      if (createdEvent != null) {
        // Adicionar à lista de eventos
        final updatedEvents = [...state.events, createdEvent];
        
        state = state.copyWith(
          events: updatedEvents,
          isLoading: false,
        );
      }

      return createdEvent;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao criar evento a partir da operação: $e',
      );
      return null;
    }
  }

  // Selecionar calendário (método antigo - mantido para compatibilidade)
  Future<void> selectCalendar(GoogleCalendar calendar) async {
    state = state.copyWith(selectedCalendar: calendar);
    
    // Recarregar eventos do calendário selecionado
    if (state.isConfigured) {
      await loadEvents();
    }
  }

  // NOVOS MÉTODOS PARA SELEÇÃO MÚLTIPLA
  
  // Selecionar um calendário específico
  Future<void> selectCalendarById(String calendarId) async {
    final newSelectedIds = Set<String>.from(state.selectedCalendarIds);
    newSelectedIds.add(calendarId);
    
    state = state.copyWith(selectedCalendarIds: newSelectedIds);
    
    // Recarregar eventos dos calendários selecionados
    if (state.isConfigured) {
      await loadEventsFromSelectedCalendars();
    }
  }

  // Deselecionar um calendário específico
  Future<void> deselectCalendarById(String calendarId) async {
    final newSelectedIds = Set<String>.from(state.selectedCalendarIds);
    newSelectedIds.remove(calendarId);
    
    state = state.copyWith(selectedCalendarIds: newSelectedIds);
    
    // Recarregar eventos dos calendários selecionados
    if (state.isConfigured) {
      await loadEventsFromSelectedCalendars();
    }
  }

  // Selecionar todos os calendários
  Future<void> selectAllCalendars() async {
    final allCalendarIds = state.calendars
        .where((calendar) => calendar.id != null)
        .map((calendar) => calendar.id!)
        .toSet();
    
    state = state.copyWith(selectedCalendarIds: allCalendarIds);
    
    // Recarregar eventos dos calendários selecionados
    if (state.isConfigured) {
      await loadEventsFromSelectedCalendars();
    }
  }

  // Deselecionar todos os calendários
  Future<void> deselectAllCalendars() async {
    state = state.copyWith(selectedCalendarIds: {});
    
    // Limpar eventos
    state = state.copyWith(events: []);
  }

  // Alternar seleção de um calendário
  Future<void> toggleCalendarSelection(String calendarId) async {
    if (state.selectedCalendarIds.contains(calendarId)) {
      await deselectCalendarById(calendarId);
    } else {
      await selectCalendarById(calendarId);
    }
  }

  // Selecionar múltiplos calendários por IDs
  Future<void> selectMultipleCalendars(List<String> calendarIds) async {
    final newSelectedIds = Set<String>.from(state.selectedCalendarIds);
    newSelectedIds.addAll(calendarIds);
    
    state = state.copyWith(selectedCalendarIds: newSelectedIds);
    
    // Recarregar eventos dos calendários selecionados
    if (state.isConfigured) {
      await loadEventsFromSelectedCalendars();
    }
  }

  // Carregar eventos dos calendários selecionados
  Future<void> loadEventsFromSelectedCalendars({String? period}) async {
    if (!state.isConfigured || state.selectedCalendarIds.isEmpty) {
      state = state.copyWith(events: []);
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      List<GoogleCalendarEvent> allEvents = [];
      
      // Carregar eventos de cada calendário selecionado
      for (String calendarId in state.selectedCalendarIds) {
        try {
          List<GoogleCalendarEvent> events;
          
          if (period != null) {
            // Usar o período especificado
            events = await _service.getEventsByPeriod(period, calendarId: calendarId);
          } else {
            // Usar período padrão
            events = await _service.listEvents(calendarId: calendarId);
          }
          
          allEvents.addAll(events);
        } catch (e) {
          print('Erro ao carregar eventos do calendário $calendarId: $e');
          // Continuar com outros calendários mesmo se um falhar
        }
      }
      
      // Ordenar eventos por data
      allEvents.sort((a, b) {
        final aDate = a.start?.dateTime ?? DateTime.parse(a.start?.date ?? '');
        final bDate = b.start?.dateTime ?? DateTime.parse(b.start?.date ?? '');
        return aDate.compareTo(bDate);
      });
      
      state = state.copyWith(
        events: allEvents,
        isLoading: false,
        selectedPeriod: period,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao carregar eventos dos calendários selecionados: $e',
      );
    }
  }

  // Limpar erro
  void clearError() {
    state = state.copyWith(error: null);
  }

  // Testar conexão
  Future<bool> testConnection() async {
    if (!state.isConfigured) {
      return false;
    }

    try {
      return await _service.testConnection();
    } catch (e) {
      return false;
    }
  }

  // Buscar eventos por texto
  Future<void> searchEvents(String query) async {
    if (!state.isConfigured) {
      state = state.copyWith(error: 'Google Calendar não está configurado');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final events = await _service.listEvents(query: query);
      
      state = state.copyWith(
        events: events,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao buscar eventos: $e',
      );
    }
  }
}

// Provider principal do Google Calendar
final googleCalendarProvider = StateNotifierProvider<GoogleCalendarNotifier, GoogleCalendarState>((ref) {
  final service = ref.watch(googleCalendarServiceProvider);
  return GoogleCalendarNotifier(service);
}); 
