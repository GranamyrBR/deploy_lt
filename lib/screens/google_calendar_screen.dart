import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/google_calendar_provider.dart';
import '../providers/api_configuration_provider.dart';
import '../models/google_calendar_event.dart';
import '../services/google_oauth_service.dart';
import '../widgets/base_screen_layout.dart';
import '../widgets/standard_search_bar.dart'; // Added import for StandardSearchBar
import '../utils/smart_search_mixin.dart';
import '../providers/auth_provider.dart';
import '../utils/timezone_utils.dart';

class GoogleCalendarScreen extends ConsumerStatefulWidget {
  const GoogleCalendarScreen({super.key});


  @override
  ConsumerState<GoogleCalendarScreen> createState() => _GoogleCalendarScreenState();
}

class _GoogleCalendarScreenState extends ConsumerState<GoogleCalendarScreen> 
    with SmartSearchMixin, TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = '';
  
  // Estados de filtro
  String _selectedPeriod = 'week';
  GoogleCalendar? _selectedCalendar;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeCalendar();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeCalendar() async {
    try {
      // Carregar configuração da API
      await ref.read(apiConfigurationProvider.notifier).loadApiConfigurations();
      final apiConfigs = ref.read(apiConfigurationProvider).apiConfigurations;
      final googleCalendarConfig = apiConfigs.firstWhere(
        (config) => config.apiName == 'google_calendar',
        orElse: () => throw Exception('Configuração do Google Calendar não encontrada'),
      );

      // Configurar o provider
      ref.read(googleCalendarProvider.notifier).configure(
        googleCalendarConfig,
        accessToken: null, // Será obtido via OAuth2
      );

      // Carregar dados
      await ref.read(googleCalendarProvider.notifier).loadCalendars();
      
      // Selecionar automaticamente o calendário principal se nenhum estiver selecionado
      final calendarState = ref.read(googleCalendarProvider);
      if (calendarState.calendars.isNotEmpty && calendarState.selectedCalendarIds.isEmpty) {
        // Selecionar automaticamente o calendário principal (primary)
        final primaryCalendar = calendarState.calendars.firstWhere(
          (calendar) => calendar.primary == true,
          orElse: () => calendarState.calendars.first,
        );
        
        if (primaryCalendar.id != null) {
          await ref.read(googleCalendarProvider.notifier)
              .selectCalendarById(primaryCalendar.id!);
        }
      } else {
        // Carregar eventos dos calendários já selecionados
        await ref.read(googleCalendarProvider.notifier).loadEventsFromSelectedCalendars();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao inicializar Google Calendar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final calendarState = ref.watch(googleCalendarProvider);
    final authState = ref.watch(authProvider);
    final userName = authState.user?.name ?? 'Usuário';

    return BaseScreenLayout(
      title: 'Google Calendar',
      actions: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            children: [
              const Icon(Icons.person, size: 18),
              const SizedBox(width: 6),
              Text(
                userName,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () {
            ref.read(googleCalendarProvider.notifier).loadEventsByPeriod(_selectedPeriod);
          },
          tooltip: 'Atualizar',
        ),
        IconButton(
          icon: const Icon(Icons.filter_list),
          onPressed: _showFilterDialog,
          tooltip: 'Filtros',
        ),
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: _showSettingsDialog,
          tooltip: 'Configurações',
        ),
        IconButton(
          icon: const Icon(Icons.bug_report),
          onPressed: _testAllEvents,
          tooltip: 'Testar Todos os Eventos',
        ),
        IconButton(
          icon: const Icon(Icons.list),
          onPressed: _testManyEvents,
          tooltip: 'Buscar Muitos Eventos',
        ),
        IconButton(
          icon: const Icon(Icons.calendar_view_month),
          onPressed: _showAllCalendars,
          tooltip: 'Todas as Agendas',
        ),
      ],
      searchBar: StandardSearchBar(
        controller: _searchController,
        hintText: 'Buscar eventos...',
        onChanged: (value) {
          setState(() {
            _searchTerm = value.trim().toLowerCase();
          });
        },
        onClear: () {
          setState(() {
            _searchTerm = '';
          });
        },
      ),
      child: Column(
        children: [
          // Tabs para diferentes visualizações
          Container(
            color: Theme.of(context).colorScheme.surface,
            child: TabBar(
              controller: _tabController,
              indicatorColor: Theme.of(context).colorScheme.primary,
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              tabs: const [
                Tab(text: 'Visão Geral'),
                Tab(text: 'Hoje'),
                Tab(text: 'Semana'),
                Tab(text: 'Mês'),
              ],
            ),
          ),
          // Status do Google Calendar
          Consumer(
            builder: (context, ref, child) {
              final calendarState = ref.watch(googleCalendarProvider);
              
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // Status principal
                        Row(
                          children: [
                            Icon(
                              calendarState.isAuthenticated 
                                ? Icons.check_circle 
                                : calendarState.isConfigured 
                                  ? Icons.warning 
                                  : Icons.error,
                              color: calendarState.isAuthenticated 
                                ? Colors.green 
                                : calendarState.isConfigured 
                                  ? Colors.orange 
                                  : Colors.red,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Google Calendar',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    calendarState.isAuthenticated 
                                      ? '✅ Conectado (${calendarState.events.length} eventos)'
                                      : calendarState.isConfigured 
                                        ? '⚠️ Configurado mas não autenticado'
                                        : '❌ Não configurado',
                                    style: TextStyle(
                                      color: calendarState.isAuthenticated 
                                        ? Colors.green[700] 
                                        : calendarState.isConfigured 
                                          ? Colors.orange[700] 
                                          : Colors.red[700],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!calendarState.isAuthenticated)
                              ElevatedButton.icon(
                                onPressed: _loginWithGoogle,
                                icon: const Icon(Icons.login, size: 16),
                                label: const Text('Conectar'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green[600],
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                              ),
                          ],
                        ),
                        
                        // Seletor de calendários (apenas se autenticado)
                        if (calendarState.isAuthenticated && calendarState.calendars.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today, size: 16),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Agendas Selecionadas:',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${calendarState.selectedCalendarIds.length}/${calendarState.calendars.length}',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              
                              // Mostrar calendários selecionados
                              if (calendarState.selectedCalendarIds.isNotEmpty) ...[
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: calendarState.selectedCalendars.map((calendar) {
                                    return Chip(
                                      avatar: Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: _parseColor(calendar.backgroundColor),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      label: Text(
                                        calendar.summary ?? 'Sem nome',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      deleteIcon: const Icon(Icons.close, size: 16),
                                      onDeleted: () {
                                        ref.read(googleCalendarProvider.notifier)
                                            .deselectCalendarById(calendar.id!);
                                      },
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 8),
                              ],
                              
                              // Botões de ação
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: _showAllCalendars,
                                      icon: const Icon(Icons.list, size: 16),
                                      label: const Text('Gerenciar Agendas'),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (calendarState.selectedCalendarIds.isNotEmpty)
                                    OutlinedButton.icon(
                                      onPressed: () {
                                        ref.read(googleCalendarProvider.notifier)
                                            .deselectAllCalendars();
                                      },
                                      icon: const Icon(Icons.clear_all, size: 16),
                                      label: const Text('Limpar'),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                      ),
                                    ),
                                  if (calendarState.selectedCalendarIds.isEmpty)
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        ref.read(googleCalendarProvider.notifier)
                                            .selectAllCalendars();
                                      },
                                      icon: const Icon(Icons.select_all, size: 16),
                                      label: const Text('Selecionar Todas'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue[600],
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          

          
          // Conteúdo principal
          Expanded(
            child: _buildContent(calendarState),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(GoogleCalendarState state) {
    if (!state.isConfigured) {
      return _buildNotConfiguredWidget();
    }

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return _buildErrorWidget(state.error!);
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildOverviewTab(state),
        _buildTodayTab(state),
        _buildWeekTab(state),
        _buildMonthTab(state),
      ],
    );
  }

  Widget _buildNotConfiguredWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Google Calendar não configurado',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Configure a integração com Google Calendar para começar',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showSettingsDialog,
            icon: const Icon(Icons.settings),
            label: const Text('Configurar'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Erro ao carregar eventos',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.red[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              ref.read(googleCalendarProvider.notifier).clearError();
              ref.read(googleCalendarProvider.notifier).loadEventsByPeriod(_selectedPeriod);
            },
            child: const Text('Tentar Novamente'),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(GoogleCalendarState state) {
    final todayEvents = state.todayEvents;
    final upcomingEvents = state.upcomingEvents;
    final weekEvents = state.weekEvents;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Estatísticas
          _buildStatsCards(state),
          
          const SizedBox(height: 24),
          
          // Eventos de hoje
          if (todayEvents.isNotEmpty) ...[
            _buildSectionHeader('Eventos de Hoje', Icons.today),
            const SizedBox(height: 12),
            _buildEventsList(todayEvents),
            const SizedBox(height: 24),
          ],
          
          // Próximos eventos
          if (upcomingEvents.isNotEmpty) ...[
            _buildSectionHeader('Próximos Eventos', Icons.schedule),
            const SizedBox(height: 12),
            _buildEventsList(upcomingEvents),
            const SizedBox(height: 24),
          ],
          
          // Eventos da semana
          if (weekEvents.isNotEmpty) ...[
            _buildSectionHeader('Eventos da Semana', Icons.view_week),
            const SizedBox(height: 12),
            _buildEventsList(weekEvents),
          ],
        ],
      ),
    );
  }

  Widget _buildTodayTab(GoogleCalendarState state) {
    return _buildEventsList(state.todayEvents);
  }

  Widget _buildWeekTab(GoogleCalendarState state) {
    return _buildEventsList(state.weekEvents);
  }

  Widget _buildMonthTab(GoogleCalendarState state) {
    return _buildEventsList(state.monthEvents);
  }

  Widget _buildStatsCards(GoogleCalendarState state) {
    final todayCount = state.todayEvents.length;
    final weekCount = state.weekEvents.length;
    final monthCount = state.monthEvents.length;
    final upcomingCount = state.upcomingEvents.length;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard('Hoje', todayCount.toString(), Icons.today, Colors.blue),
        _buildStatCard('Próximos', upcomingCount.toString(), Icons.schedule, Colors.orange),
        _buildStatCard('Semana', weekCount.toString(), Icons.view_week, Colors.green),
        _buildStatCard('Mês', monthCount.toString(), Icons.calendar_month, Colors.purple),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return InkWell(
      onTap: () {
        // Navegar para a aba correspondente
        switch (title.toLowerCase()) {
          case 'hoje':
            _tabController.animateTo(1); // Aba Hoje
            break;
          case 'próximos':
            _tabController.animateTo(1); // Aba Hoje (próximos eventos)
            break;
          case 'semana':
            _tabController.animateTo(2); // Aba Semana
            break;
          case 'mês':
            _tabController.animateTo(3); // Aba Mês
            break;
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Card(
        elevation: 4,
        shadowColor: color.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: 0.1),
                color.withValues(alpha: 0.05),
              ],
            ),
            border: Border.all(
              color: color.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 28, color: color),
                ),
                const SizedBox(height: 12),
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: color.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Clique para ver',
                    style: TextStyle(
                      fontSize: 10,
                      color: color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.blue[600], size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.blue[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsList(List<GoogleCalendarEvent> events) {
    if (events.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey.withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.event_busy,
                size: 48,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhum evento encontrado',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Não há eventos para o período selecionado',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return _buildEventCard(event);
      },
    );
  }

  Widget _buildEventCard(GoogleCalendarEvent event) {
    final startTime = event.start?.dateTime ?? event.start?.date;
    final endTime = event.end?.dateTime ?? event.end?.date;
    
    String timeText = '';
    if (startTime != null) {
      if (event.start?.dateTime != null) {
        timeText = DateFormat('HH:mm').format(TimezoneUtils.convertToNewYork(startTime as DateTime));
        if (endTime != null && event.end?.dateTime != null) {
          timeText += ' - ${DateFormat('HH:mm').format(TimezoneUtils.convertToNewYork(endTime as DateTime))}';
        }
        timeText += ' (NYC)';
      } else {
        timeText = 'Dia inteiro';
      }
    }

    // Determinar cor baseada no conteúdo do evento
    Color eventColor = Colors.blue;
    final summary = event.summary?.toLowerCase() ?? '';
    final description = event.description?.toLowerCase() ?? '';
    
    if (summary.contains('aniversário') || summary.contains('birthday') || 
        description.contains('aniversário') || description.contains('birthday')) {
      eventColor = Colors.pink;
    } else if (summary.contains('reunião') || summary.contains('meeting') || 
               summary.contains('encontro') || description.contains('reunião')) {
      eventColor = Colors.green;
    } else if (summary.contains('lembrete') || summary.contains('reminder') || 
               summary.contains('alerta') || description.contains('lembrete')) {
      eventColor = Colors.orange;
    } else if (event.location != null && event.location!.isNotEmpty) {
      eventColor = Colors.purple;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shadowColor: eventColor.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showEventDetails(event),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                eventColor.withValues(alpha: 0.05),
                eventColor.withValues(alpha: 0.02),
              ],
            ),
            border: Border.all(
              color: eventColor.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Ícone do evento
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: eventColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getEventIcon(event),
                    color: eventColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                
                // Conteúdo do evento
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.summary ?? 'Sem título',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (timeText.isNotEmpty)
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: eventColor.withValues(alpha: 0.7),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              timeText,
                              style: TextStyle(
                                color: eventColor.withValues(alpha: 0.8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      if (event.location != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 14,
                              color: eventColor.withValues(alpha: 0.7),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                event.location!,
                                style: TextStyle(
                                  color: eventColor.withValues(alpha: 0.8),
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (event.description != null && event.description!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: eventColor.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            event.description!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                              fontSize: 12,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Botões de ação
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    color: eventColor.withValues(alpha: 0.7),
                  ),
                  onSelected: (value) => _handleEventAction(value, event),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit),
                          SizedBox(width: 8),
                          Text('Editar'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Excluir', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                    if (event.htmlLink != null)
                      const PopupMenuItem(
                        value: 'open',
                        child: Row(
                          children: [
                            Icon(Icons.open_in_new),
                            SizedBox(width: 8),
                            Text('Abrir no Google'),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getEventIcon(GoogleCalendarEvent event) {
    final summary = event.summary?.toLowerCase() ?? '';
    final description = event.description?.toLowerCase() ?? '';
    
    if (summary.contains('aniversário') || summary.contains('birthday') || 
        description.contains('aniversário') || description.contains('birthday')) {
      return Icons.cake;
    } else if (summary.contains('reunião') || summary.contains('meeting') || 
               summary.contains('encontro') || description.contains('reunião')) {
      return Icons.meeting_room;
    } else if (summary.contains('lembrete') || summary.contains('reminder') || 
               summary.contains('alerta') || description.contains('lembrete')) {
      return Icons.alarm;
    } else if (event.location != null && event.location!.isNotEmpty) {
      return Icons.location_on;
    } else {
      return Icons.event;
    }
  }

  void _handleEventAction(String action, GoogleCalendarEvent event) {
    switch (action) {
      case 'edit':
        _showEditEventDialog(event);
        break;
      case 'delete':
        _showDeleteEventDialog(event);
        break;
      case 'open':
        // TODO: Implementar abertura no Google Calendar
        break;
    }
  }

  void _showEventDetails(GoogleCalendarEvent event) {
    // Determinar cor baseada no conteúdo do evento
    Color eventColor = Colors.blue;
    final summary = event.summary?.toLowerCase() ?? '';
    final description = event.description?.toLowerCase() ?? '';
    
    if (summary.contains('aniversário') || summary.contains('birthday') || 
        description.contains('aniversário') || description.contains('birthday')) {
      eventColor = Colors.pink;
    } else if (summary.contains('reunião') || summary.contains('meeting') || 
               summary.contains('encontro') || description.contains('reunião')) {
      eventColor = Colors.green;
    } else if (summary.contains('lembrete') || summary.contains('reminder') || 
               summary.contains('alerta') || description.contains('lembrete')) {
      eventColor = Colors.orange;
    } else if (event.location != null && event.location!.isNotEmpty) {
      eventColor = Colors.purple;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                eventColor.withValues(alpha: 0.05),
                eventColor.withValues(alpha: 0.02),
              ],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header do modal
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: eventColor.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: eventColor.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getEventIcon(event),
                        color: eventColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.summary ?? 'Detalhes do Evento',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: eventColor,
                            ),
                          ),
                          Text(
                            _getEventTypeText(event),
                            style: TextStyle(
                              color: eventColor.withValues(alpha: 0.8),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close, color: eventColor),
                    ),
                  ],
                ),
              ),
              
              // Conteúdo do modal
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (event.description != null && event.description!.isNotEmpty) ...[
                        _buildDetailSection(
                          'Descrição',
                          Icons.description,
                          event.description!,
                          eventColor,
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (event.location != null && event.location!.isNotEmpty) ...[
                        _buildDetailSection(
                          'Local',
                          Icons.location_on,
                          event.location!,
                          eventColor,
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (event.start != null) ...[
                        _buildDetailSection(
                          'Início',
                          Icons.access_time,
                          _formatDateTime(event.start!),
                          eventColor,
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (event.end != null) ...[
                        _buildDetailSection(
                          'Fim',
                          Icons.access_time,
                          _formatDateTime(event.end!),
                          eventColor,
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (event.attendees != null && event.attendees!.isNotEmpty) ...[
                        _buildDetailSection(
                          'Participantes',
                          Icons.people,
                          event.attendees!.map((attendee) => 
                            '• ${attendee.displayName ?? attendee.email}'
                          ).join('\n'),
                          eventColor,
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (event.htmlLink != null) ...[
                        _buildDetailSection(
                          'Link',
                          Icons.link,
                          'Abrir no Google Calendar',
                          eventColor,
                          isLink: true,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              
              // Botões de ação
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: eventColor.withValues(alpha: 0.05),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                        label: const Text('Fechar'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: eventColor,
                          side: BorderSide(color: eventColor),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _showEditEventDialog(event);
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('Editar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: eventColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getEventTypeText(GoogleCalendarEvent event) {
    final summary = event.summary?.toLowerCase() ?? '';
    final description = event.description?.toLowerCase() ?? '';
    
    if (summary.contains('aniversário') || summary.contains('birthday') || 
        description.contains('aniversário') || description.contains('birthday')) {
      return 'Tipo: Aniversário';
    } else if (summary.contains('reunião') || summary.contains('meeting') || 
               summary.contains('encontro') || description.contains('reunião')) {
      return 'Tipo: Reunião';
    } else if (summary.contains('lembrete') || summary.contains('reminder') || 
               summary.contains('alerta') || description.contains('lembrete')) {
      return 'Tipo: Lembrete';
    } else if (event.location != null && event.location!.isNotEmpty) {
      return 'Tipo: Evento com local';
    } else {
      return 'Tipo: Evento';
    }
  }

  Widget _buildDetailSection(String title, IconData icon, String content, Color color, {bool isLink = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (isLink)
            InkWell(
              onTap: () {
                // TODO: Implementar abertura do link
              },
              child: Text(
                content,
                style: TextStyle(
                  color: color,
                  decoration: TextDecoration.underline,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          else
            Text(
              content,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDateTime(GoogleCalendarDateTime dateTime) {
    if (dateTime.dateTime != null) {
      return '${DateFormat('dd/MM/yyyy HH:mm').format(TimezoneUtils.convertToNewYork(dateTime.dateTime!))} (NYC)';
    } else if (dateTime.date != null) {
      return DateFormat('dd/MM/yyyy').format(DateTime.parse(dateTime.date!));
    }
    return 'Data não especificada';
  }

  void _showCreateEventDialog() {
    // TODO: Implementar diálogo de criação de evento
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Novo Evento'),
        content: const Text('Funcionalidade em desenvolvimento...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  void _showEditEventDialog(GoogleCalendarEvent event) {
    // TODO: Implementar diálogo de edição de evento
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Evento'),
        content: const Text('Funcionalidade em desenvolvimento...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  void _showDeleteEventDialog(GoogleCalendarEvent event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Evento'),
        content: Text('Tem certeza que deseja excluir o evento "${event.summary}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              if (event.id != null) {
                final success = await ref.read(googleCalendarProvider.notifier).deleteEvent(event.id!);
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Evento excluído com sucesso'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtros'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Período:'),
            DropdownButton<String>(
              value: _selectedPeriod,
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedPeriod = value);
                  ref.read(googleCalendarProvider.notifier).loadEventsByPeriod(value);
                }
              },
              items: const [
                DropdownMenuItem(value: 'today', child: Text('Hoje')),
                DropdownMenuItem(value: 'week', child: Text('Semana')),
                DropdownMenuItem(value: 'month', child: Text('Mês')),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configurações do Google Calendar'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Para configurar o Google Calendar:'),
            SizedBox(height: 8),
            Text('1. Acesse a tela de Configuração de APIs'),
            Text('2. Configure a API do Google Calendar'),
            Text('3. Adicione suas credenciais OAuth2'),
            Text('4. Teste a conexão'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Navegar para tela de configuração de APIs
            },
            child: const Text('Configurar'),
          ),
        ],
      ),
    );
  }

  void _loginWithGoogle() async {
    try {
      // Mostrar loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Conectando com Google...'),
            ],
          ),
        ),
      );

      // Buscar configuração do Google Calendar
      final apiConfigState = ref.read(apiConfigurationProvider);
      final googleConfig = apiConfigState.apiConfigurations.firstWhere(
        (config) => config.apiName == 'google_calendar',
        orElse: () => throw Exception('Configuração do Google Calendar não encontrada'),
      );

      // Configurar o provider com a configuração real
      ref.read(googleCalendarProvider.notifier).configureWithRealConfig(googleConfig);

      // Iniciar OAuth2 real
      final accessToken = await GoogleOAuthService.authenticate(googleConfig);
      
      // Fechar loading
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (accessToken != null) {
        // Configurar token de acesso real
        ref.read(googleCalendarProvider.notifier).setAccessToken(accessToken);

        // Carregar dados reais do Google Calendar
        await ref.read(googleCalendarProvider.notifier).loadCalendars();
        
        // Selecionar automaticamente o calendário principal se nenhum estiver selecionado
        final calendarState = ref.read(googleCalendarProvider);
        if (calendarState.calendars.isNotEmpty && calendarState.selectedCalendarIds.isEmpty) {
          // Selecionar automaticamente o calendário principal (primary)
          final primaryCalendar = calendarState.calendars.firstWhere(
            (calendar) => calendar.primary == true,
            orElse: () => calendarState.calendars.first,
          );
          
          if (primaryCalendar.id != null) {
            await ref.read(googleCalendarProvider.notifier)
                .selectCalendarById(primaryCalendar.id!);
          }
        } else {
          // Carregar eventos dos calendários já selecionados
          await ref.read(googleCalendarProvider.notifier).loadEventsFromSelectedCalendars();
        }

        // Mostrar mensagem de sucesso
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Conectado com Google Calendar com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Mostrar erro de autenticação
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Falha na autenticação com Google'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }

    } catch (e) {
      // Fechar loading
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Mostrar erro
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao conectar com Google: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _testAllEvents() async {
    try {
      // Mostrar loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Buscando todos os eventos...'),
            ],
          ),
        ),
      );

      // Buscar todos os eventos (últimos 6 meses)
      await ref.read(googleCalendarProvider.notifier).loadAllEvents();
      
      // Fechar loading
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Mostrar resultado
      final state = ref.read(googleCalendarProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Encontrados ${state.events.length} eventos!'),
            backgroundColor: Colors.green,
          ),
        );
      }

    } catch (e) {
      // Fechar loading
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Mostrar erro
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao buscar eventos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAllCalendars() {
    final calendarState = ref.read(googleCalendarProvider);
    
    if (calendarState.calendars.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nenhuma agenda encontrada'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Estado local para seleção múltipla - inicializar com os já selecionados
    final selectedCalendars = <String>{};
    selectedCalendars.addAll(calendarState.selectedCalendarIds);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final allSelected = selectedCalendars.length == calendarState.calendars.length;
          final someSelected = selectedCalendars.isNotEmpty && !allSelected;

          return AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.calendar_today),
                const SizedBox(width: 8),
                const Text('Suas Agendas'),
                const Spacer(),
                // Checkbox para selecionar todos
                Checkbox(
                  value: allSelected,
                  tristate: true,
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        selectedCalendars.addAll(
                          calendarState.calendars.map((c) => c.id!).where((id) => id.isNotEmpty)
                        );
                      } else {
                        selectedCalendars.clear();
                      }
                    });
                  },
                ),
              ],
            ),
            content: SizedBox(
              width: 300,
              height: 400,
              child: Column(
                children: [
                  // Contador de selecionados
                  if (selectedCalendars.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        '${selectedCalendars.length} de ${calendarState.calendars.length} selecionadas',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  
                  // Lista de agendas
                  Expanded(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: calendarState.calendars.length,
                      itemBuilder: (context, index) {
                        final calendar = calendarState.calendars[index];
                        final isSelected = selectedCalendars.contains(calendar.id);
                        
                        return ListTile(
                          dense: true,
                          leading: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: _parseColor(calendar.backgroundColor),
                              shape: BoxShape.circle,
                            ),
                          ),
                          title: Text(
                            calendar.summary ?? 'Sem nome',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                          subtitle: calendar.description?.isNotEmpty == true
                            ? Text(
                                calendar.description!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12),
                              )
                            : null,
                          trailing: Checkbox(
                            value: isSelected,
                            onChanged: (value) {
                              setState(() {
                                if (value == true) {
                                  selectedCalendars.add(calendar.id!);
                                } else {
                                  selectedCalendars.remove(calendar.id);
                                }
                              });
                            },
                          ),
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                selectedCalendars.remove(calendar.id);
                              } else {
                                selectedCalendars.add(calendar.id!);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: selectedCalendars.isEmpty ? null : () {
                  Navigator.of(context).pop();
                  
                  // Aplicar seleção múltipla usando o novo método
                  ref.read(googleCalendarProvider.notifier)
                      .selectMultipleCalendars(selectedCalendars.toList());
                  
                  // Mostrar feedback
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        selectedCalendars.length == 1
                          ? '1 agenda selecionada'
                          : '${selectedCalendars.length} agendas selecionadas',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                child: Text(selectedCalendars.length == 1 ? 'Selecionar' : 'Aplicar'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _testManyEvents() async {
    try {
      // Mostrar loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Buscando muitos eventos...'),
            ],
          ),
        ),
      );

      // Buscar eventos com limite maior
      await ref.read(googleCalendarProvider.notifier).loadManyEvents();
      
      // Fechar loading
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Mostrar resultado
      final state = ref.read(googleCalendarProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Encontrados ${state.events.length} eventos!'),
            backgroundColor: Colors.green,
          ),
        );
      }

    } catch (e) {
      // Fechar loading
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Mostrar erro
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao buscar eventos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Método para converter string de cor para Color
  Color _parseColor(String? colorString) {
    if (colorString == null || colorString.isEmpty) {
      return const Color(0xFF4285F4); // Azul padrão do Google
    }
    
    // Se a cor já é um hex válido (começa com #)
    if (colorString.startsWith('#')) {
      try {
        return Color(int.parse(colorString.substring(1), radix: 16) + 0xFF000000);
      } catch (e) {
        return const Color(0xFF4285F4);
      }
    }
    
    // Mapeamento de cores do Google Calendar
    switch (colorString.toLowerCase()) {
      case 'lavender':
        return const Color(0xFF7986CB);
      case 'sage':
        return const Color(0xFF33B679);
      case 'grape':
        return const Color(0xFF8E63CE);
      case 'flamingo':
        return const Color(0xFFE67C73);
      case 'banana':
        return const Color(0xFFF6C026);
      case 'tangerine':
        return const Color(0xFFF4511E);
      case 'peacock':
        return const Color(0xFF039BE5);
      case 'graphite':
        return const Color(0xFF616161);
      case 'blueberry':
        return const Color(0xFF3F51B5);
      case 'basil':
        return const Color(0xFF0B8043);
      case 'tomato':
        return const Color(0xFFD60000);
      default:
        return const Color(0xFF4285F4); // Azul padrão
    }
  }

}
