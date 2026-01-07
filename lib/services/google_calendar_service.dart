import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/google_calendar_event.dart';
import '../models/api_configuration.dart';

class GoogleCalendarService {
  static const String _baseUrl = 'https://www.googleapis.com/calendar/v3';
  String? _accessToken;
  String? _calendarId;
  
  // Configuração da API
  ApiConfiguration? _apiConfig;
  
  // Construtor
  GoogleCalendarService();
  
  // Configurar o serviço
  void configure(ApiConfiguration apiConfig, {String? accessToken, String? calendarId}) {
    _apiConfig = apiConfig;
    _accessToken = accessToken;
    _calendarId = calendarId ?? 'primary';
  }

  // Definir token de acesso
  void setAccessToken(String token) {
    _accessToken = token;
  }
  
  // Verificar se está configurado
  bool get isConfigured => _accessToken != null;
  
  // Headers padrão para requisições
  Map<String, String> get _headers {
    if (!isConfigured) {
      throw Exception('Google Calendar não está configurado');
    }
    
    return {
      'Authorization': 'Bearer $_accessToken',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }
  
  // URL base da API
  String get _apiUrl => '$_baseUrl/calendars/$_calendarId';
  
  // =====================================================
  // MÉTODOS PRINCIPAIS
  // =====================================================
  
  /// Listar eventos do calendário
  Future<List<GoogleCalendarEvent>> listEvents({
    DateTime? timeMin,
    DateTime? timeMax,
    int maxResults = 2500,
    String? query,
    bool singleEvents = true,
    String orderBy = 'startTime',
    String? calendarId,
  }) async {
    try {
      final params = <String, String>{
        'maxResults': maxResults.toString(),
        'singleEvents': singleEvents.toString(),
        'orderBy': orderBy,
      };
      
      if (timeMin != null) {
        params['timeMin'] = timeMin.toUtc().toIso8601String();
      }
      
      if (timeMax != null) {
        params['timeMax'] = timeMax.toUtc().toIso8601String();
      }
      
      if (query != null && query.isNotEmpty) {
        params['q'] = query;
      }
      
      final targetCalendarId = calendarId ?? _calendarId ?? 'primary';
      final uri = Uri.parse('$_baseUrl/calendars/$targetCalendarId/events').replace(queryParameters: params);
      
      print('=== GOOGLE CALENDAR: Listando eventos ===');
      print('Calendário: $targetCalendarId');
      print('URL: $uri');
      
      final response = await http.get(uri, headers: _headers);
      
      print('Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Resposta completa: ${response.body}');
        print('Total de eventos na resposta: ${data['items']?.length ?? 0}');
        
        final events = data['items'] as List? ?? [];
        print('Eventos encontrados: ${events.length}');
        
        if (events.isNotEmpty) {
          print('Primeiro evento: ${events.first}');
        }
        
        return events
            .map((event) => GoogleCalendarEvent.fromJson(event))
            .toList();
      } else {
        print('Erro ao listar eventos: ${response.statusCode}');
        print('Resposta: ${response.body}');
        throw Exception('Erro ao listar eventos: ${response.statusCode}');
      }
    } catch (e) {
      print('Erro ao listar eventos do Google Calendar: $e');
      rethrow;
    }
  }
  
  /// Buscar evento específico
  Future<GoogleCalendarEvent?> getEvent(String eventId) async {
    try {
      final uri = Uri.parse('$_apiUrl/events/$eventId');
      
      print('=== GOOGLE CALENDAR: Buscando evento ===');
      print('Event ID: $eventId');
      print('URL: $uri');
      
      final response = await http.get(uri, headers: _headers);
      
      print('Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return GoogleCalendarEvent.fromJson(data);
      } else if (response.statusCode == 404) {
        print('Evento não encontrado');
        return null;
      } else {
        print('Erro ao buscar evento: ${response.statusCode}');
        print('Resposta: ${response.body}');
        throw Exception('Erro ao buscar evento: ${response.statusCode}');
      }
    } catch (e) {
      print('Erro ao buscar evento do Google Calendar: $e');
      rethrow;
    }
  }
  
  /// Criar novo evento
  Future<GoogleCalendarEvent> createEvent(GoogleCalendarEvent event) async {
    try {
      final uri = Uri.parse('$_apiUrl/events');
      
      print('=== GOOGLE CALENDAR: Criando evento ===');
      print('Título: ${event.summary}');
      print('Data: ${event.start?.dateTime}');
      print('URL: $uri');
      
      final response = await http.post(
        uri,
        headers: _headers,
        body: json.encode(event.toJson()),
      );
      
      print('Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final createdEvent = GoogleCalendarEvent.fromJson(data);
        
        print('Evento criado com sucesso!');
        print('ID: ${createdEvent.id}');
        
        return createdEvent;
      } else {
        print('Erro ao criar evento: ${response.statusCode}');
        print('Resposta: ${response.body}');
        throw Exception('Erro ao criar evento: ${response.statusCode}');
      }
    } catch (e) {
      print('Erro ao criar evento no Google Calendar: $e');
      rethrow;
    }
  }
  
  /// Atualizar evento existente
  Future<GoogleCalendarEvent> updateEvent(String eventId, GoogleCalendarEvent event) async {
    try {
      final uri = Uri.parse('$_apiUrl/events/$eventId');
      
      print('=== GOOGLE CALENDAR: Atualizando evento ===');
      print('Event ID: $eventId');
      print('Título: ${event.summary}');
      print('URL: $uri');
      
      final response = await http.put(
        uri,
        headers: _headers,
        body: json.encode(event.toJson()),
      );
      
      print('Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final updatedEvent = GoogleCalendarEvent.fromJson(data);
        
        print('Evento atualizado com sucesso!');
        
        return updatedEvent;
      } else {
        print('Erro ao atualizar evento: ${response.statusCode}');
        print('Resposta: ${response.body}');
        throw Exception('Erro ao atualizar evento: ${response.statusCode}');
      }
    } catch (e) {
      print('Erro ao atualizar evento no Google Calendar: $e');
      rethrow;
    }
  }
  
  /// Excluir evento
  Future<bool> deleteEvent(String eventId) async {
    try {
      final uri = Uri.parse('$_apiUrl/events/$eventId');
      
      print('=== GOOGLE CALENDAR: Excluindo evento ===');
      print('Event ID: $eventId');
      print('URL: $uri');
      
      final response = await http.delete(uri, headers: _headers);
      
      print('Status: ${response.statusCode}');
      
      if (response.statusCode == 204) {
        print('Evento excluído com sucesso!');
        return true;
      } else {
        print('Erro ao excluir evento: ${response.statusCode}');
        print('Resposta: ${response.body}');
        throw Exception('Erro ao excluir evento: ${response.statusCode}');
      }
    } catch (e) {
      print('Erro ao excluir evento do Google Calendar: $e');
      rethrow;
    }
  }
  
  /// Listar calendários disponíveis
  Future<List<GoogleCalendar>> listCalendars() async {
    try {
      final uri = Uri.parse('$_baseUrl/users/me/calendarList');
      
      print('=== GOOGLE CALENDAR: Listando calendários ===');
      print('URL: $uri');
      
      final response = await http.get(uri, headers: _headers);
      
      print('Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final calendars = data['items'] as List;
        
        return calendars
            .map((calendar) => GoogleCalendar.fromJson(calendar))
            .toList();
      } else {
        print('Erro ao listar calendários: ${response.statusCode}');
        print('Resposta: ${response.body}');
        throw Exception('Erro ao listar calendários: ${response.statusCode}');
      }
    } catch (e) {
      print('Erro ao listar calendários do Google Calendar: $e');
      rethrow;
    }
  }
  
  /// Buscar eventos por período (hoje, semana, mês)
  Future<List<GoogleCalendarEvent>> getEventsByPeriod(String period, {String? calendarId}) async {
    final now = DateTime.now();
    DateTime timeMin;
    DateTime timeMax;
    
    switch (period.toLowerCase()) {
      case 'today':
        timeMin = DateTime(now.year, now.month, now.day);
        timeMax = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case 'week':
        // Buscar eventos da semana atual + próxima semana
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        timeMin = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
        timeMax = timeMin.add(const Duration(days: 14)); // 2 semanas
        break;
      case 'month':
        // Buscar eventos do mês atual + próximo mês
        timeMin = DateTime(now.year, now.month, 1);
        timeMax = DateTime(now.year, now.month + 2, 1);
        break;
      default:
        // Buscar eventos dos próximos 30 dias
        timeMin = now;
        timeMax = now.add(const Duration(days: 30));
    }
    
    print('=== GOOGLE CALENDAR: Buscando eventos por período ===');
    print('Período: $period');
    print('Calendário: ${calendarId ?? 'padrão'}');
    print('De: $timeMin');
    print('Até: $timeMax');
    
    if (calendarId != null) {
      return _listEventsForCalendar(calendarId, timeMin: timeMin, timeMax: timeMax);
    } else {
      return listEvents(timeMin: timeMin, timeMax: timeMax);
    }
  }
  
  /// Listar eventos de um calendário específico
  Future<List<GoogleCalendarEvent>> _listEventsForCalendar(
    String calendarId, {
    DateTime? timeMin,
    DateTime? timeMax,
    int maxResults = 2500,
    String? query,
    bool singleEvents = true,
    String orderBy = 'startTime',
  }) async {
    try {
      final params = <String, String>{
        'maxResults': maxResults.toString(),
        'singleEvents': singleEvents.toString(),
        'orderBy': orderBy,
      };
      
      if (timeMin != null) {
        params['timeMin'] = timeMin.toUtc().toIso8601String();
      }
      
      if (timeMax != null) {
        params['timeMax'] = timeMax.toUtc().toIso8601String();
      }
      
      if (query != null && query.isNotEmpty) {
        params['q'] = query;
      }
      
      final uri = Uri.parse('$_baseUrl/calendars/$calendarId/events').replace(queryParameters: params);
      
      print('=== GOOGLE CALENDAR: Listando eventos do calendário específico ===');
      print('Calendário: $calendarId');
      print('URL: $uri');
      
      final response = await http.get(uri, headers: _headers);
      
      print('Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final events = data['items'] as List? ?? [];
        
        print('Eventos encontrados no calendário $calendarId: ${events.length}');
        
        return events
            .map((event) => GoogleCalendarEvent.fromJson(event))
            .toList();
      } else {
        print('Erro ao listar eventos do calendário $calendarId: ${response.statusCode}');
        print('Resposta: ${response.body}');
        throw Exception('Erro ao listar eventos do calendário $calendarId: ${response.statusCode}');
      }
    } catch (e) {
      print('Erro ao listar eventos do calendário $calendarId: $e');
      rethrow;
    }
  }
  
  /// Criar evento a partir de uma operação
  Future<GoogleCalendarEvent?> createEventFromOperation(Map<String, dynamic> operation) async {
    try {
      final event = GoogleCalendarEvent(
        summary: '${operation['service_name']} - ${operation['customer_name']}',
        description: _buildEventDescription(operation),
        start: GoogleCalendarDateTime(
          dateTime: DateTime.parse(operation['scheduled_date']),
          timeZone: 'America/Sao_Paulo',
        ),
        end: GoogleCalendarDateTime(
          dateTime: DateTime.parse(operation['scheduled_date']).add(
            Duration(minutes: operation['estimated_duration_minutes'] ?? 60),
          ),
          timeZone: 'America/Sao_Paulo',
        ),
        location: operation['pickup_location'] ?? 'Local não especificado',
        attendees: _buildAttendees(operation),
        reminders: GoogleCalendarReminders(
          useDefault: false,
          overrides: [
            GoogleCalendarReminderOverride(
              method: 'popup',
              minutes: 30,
            ),
            GoogleCalendarReminderOverride(
              method: 'email',
              minutes: 60,
            ),
          ],
        ),
      );
      
      return await createEvent(event);
    } catch (e) {
      print('Erro ao criar evento a partir da operação: $e');
      return null;
    }
  }
  
  // =====================================================
  // MÉTODOS AUXILIARES
  // =====================================================
  
  String _buildEventDescription(Map<String, dynamic> operation) {
    final buffer = StringBuffer();
    
    buffer.writeln('Cliente: ${operation['customer_name']}');
    buffer.writeln('Telefone: ${operation['customer_phone'] ?? 'Não informado'}');
    
    // Verificar se é operação de serviço ou produto
    if (operation['service_name'] != null) {
      buffer.writeln('Serviço: ${operation['service_name']}');
      buffer.writeln('Valor: \$${operation['service_value_usd'] ?? 0.0}');
    } else if (operation['product_name'] != null) {
      buffer.writeln('Produto: ${operation['product_name']}');
      buffer.writeln('Quantidade: ${operation['quantity'] ?? 1}');
      buffer.writeln('Valor: \$${operation['product_value_usd'] ?? 0.0}');
    }
    
    if (operation['pickup_location'] != null) {
      buffer.writeln('Coleta: ${operation['pickup_location']}');
    }
    
    if (operation['dropoff_location'] != null) {
      buffer.writeln('Entrega: ${operation['dropoff_location']}');
    }
    
    if (operation['driver_name'] != null) {
      buffer.writeln('Motorista: ${operation['driver_name']}');
    }
    
    if (operation['special_instructions'] != null) {
      buffer.writeln('Instruções: ${operation['special_instructions']}');
    }
    
    return buffer.toString();
  }
  
  List<GoogleCalendarAttendee> _buildAttendees(Map<String, dynamic> operation) {
    final attendees = <GoogleCalendarAttendee>[];
    
    // Adicionar cliente se tiver email
    if (operation['customer_email'] != null) {
      attendees.add(GoogleCalendarAttendee(
        email: operation['customer_email'],
        displayName: operation['customer_name'],
        responseStatus: 'needsAction',
      ));
    }
    
    // Adicionar motorista se tiver email
    if (operation['driver_email'] != null) {
      attendees.add(GoogleCalendarAttendee(
        email: operation['driver_email'],
        displayName: operation['driver_name'],
        responseStatus: 'needsAction',
      ));
    }
    
    return attendees;
  }
  
  /// Buscar todos os eventos (últimos 6 meses)
  Future<List<GoogleCalendarEvent>> getAllEvents() async {
    final now = DateTime.now();
    final sixMonthsAgo = DateTime(now.year, now.month - 6, now.day);
    final sixMonthsFromNow = DateTime(now.year, now.month + 6, now.day);
    
    print('=== GOOGLE CALENDAR: Buscando todos os eventos ===');
    print('De: $sixMonthsAgo');
    print('Até: $sixMonthsFromNow');
    
    return listEvents(timeMin: sixMonthsAgo, timeMax: sixMonthsFromNow);
  }

  /// Buscar muitos eventos (até 10.000 eventos)
  Future<List<GoogleCalendarEvent>> getManyEvents({
    DateTime? timeMin,
    DateTime? timeMax,
    String? query,
  }) async {
    print('=== GOOGLE CALENDAR: Buscando muitos eventos ===');
    print('Limite: 10.000 eventos');
    
    return listEvents(
      timeMin: timeMin,
      timeMax: timeMax,
      maxResults: 10000,
      query: query,
    );
  }

  /// Testar conexão com Google Calendar
  Future<bool> testConnection() async {
    try {
      final calendars = await listCalendars();
      return calendars.isNotEmpty;
    } catch (e) {
      print('Erro ao testar conexão com Google Calendar: $e');
      return false;
    }
  }
}
