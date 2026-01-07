import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/flight_info.dart';
import '../models/operational_route.dart';
import '../providers/api_providers.dart';
import '../providers/operational_routes_provider.dart';
import '../utils/date_time_utils.dart';
import '../widgets/base_components.dart';
import '../widgets/base_screen_layout.dart';

import '../services/favicon_service.dart';

class FlightsScreen extends ConsumerStatefulWidget {
  const FlightsScreen({super.key});

  @override
  ConsumerState<FlightsScreen> createState() => _FlightsScreenState();
}

class _FlightsScreenState extends ConsumerState<FlightsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _flightController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  
  // Filtros para rotas operacionais
  String? _selectedOperacao;
  String? _selectedCompanhia;
  String? _selectedAeroporto;
  String _searchQuery = '';
  bool _isSearching = false;
  final FaviconService _faviconService = FaviconService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _flightController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _searchFlight() {
    final flightNumber = _flightController.text.trim();
    if (flightNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Digite o número do voo'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSearching = true;
    });

    ref.invalidate(flightSearchProvider(flightNumber));
    
    setState(() {
      _isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreenLayout(
      title: 'Gestão de Voos',
      backgroundColor: const Color(0xFFF8FAFC),
      actions: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.circle, color: Color(0xFF10B981), size: 8),
              SizedBox(width: 6),
              Text(
                'Sistema Ativo',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF10B981),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.refresh, color: Color(0xFF1E293B)),
          onPressed: () {
            ref.invalidate(operationalRoutesProvider);
            ref.invalidate(availableAirportsProvider);
            ref.invalidate(availableAirlinesProvider);
            ref.invalidate(availableOperationsProvider);
          },
          tooltip: 'Atualizar dados',
        ),
      ],
      child: Column(
        children: [
          // Tabs
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF3B82F6),
              unselectedLabelColor: const Color(0xFF64748B),
              indicatorColor: const Color(0xFF3B82F6),
              tabs: const [
                Tab(
                  icon: Icon(Icons.route),
                  text: 'Rotas Operacionais',
                ),
                Tab(
                  icon: Icon(Icons.flight),
                  text: 'Status em Tempo Real',
                ),
              ],
            ),
          ),
          
          // Conteúdo das tabs
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOperationalRoutesTab(),
                _buildRealTimeFlightsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOperationalRoutesTab() {
    return Column(
      children: [
        // Filtros e busca
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Busca
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar por voo, companhia, aeroporto...',
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B)),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
              
              const SizedBox(height: 16),
              
              // Filtros em linha
              Row(
                children: [
                  Expanded(
                    child: _buildDynamicFilterDropdown(
                      'Operação',
                      _selectedOperacao,
                      availableOperationsProvider,
                      (value) => setState(() => _selectedOperacao = value),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDynamicFilterDropdown(
                      'Companhia',
                      _selectedCompanhia,
                      availableAirlinesProvider,
                      (value) => setState(() => _selectedCompanhia = value),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDynamicFilterDropdown(
                      'Aeroporto',
                      _selectedAeroporto,
                      availableAirportsProvider,
                      (value) => setState(() => _selectedAeroporto = value),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Lista de rotas
        Expanded(
          child: _buildOperationalRoutesList(),
        ),
      ],
    );
  }

  Widget _buildDynamicFilterDropdown(
    String label,
    String? value,
    FutureProvider<List<String>> provider,
    Function(String?) onChanged,
  ) {
    return Consumer(
      builder: (context, ref, child) {
        final asyncOptions = ref.watch(provider);
        
        return asyncOptions.when(
          data: (options) => DropdownButtonFormField<String>(
            value: value,
            decoration: InputDecoration(
              labelText: label,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: [
              DropdownMenuItem<String>(
                value: null,
                child: Text('Todos os ${label.toLowerCase()}s', style: TextStyle(color: Colors.grey[600])),
              ),
              ...options.map((option) => DropdownMenuItem<String>(
                value: option,
                child: Text(option),
              )),
            ],
            onChanged: onChanged,
          ),
          loading: () => DropdownButtonFormField<String>(
            value: null,
            decoration: InputDecoration(
              labelText: label,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: const [
              DropdownMenuItem<String>(
                value: null,
                child: Text('Carregando...'),
              ),
            ],
            onChanged: null,
          ),
          error: (error, stack) => DropdownButtonFormField<String>(
            value: null,
            decoration: InputDecoration(
              labelText: label,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.red[300]!),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: const [
              DropdownMenuItem<String>(
                value: null,
                child: Text('Erro ao carregar'),
              ),
            ],
            onChanged: null,
          ),
        );
      },
    );
  }

  Widget _buildFilterDropdown(String label, String? value, List<String> options, Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: [
        DropdownMenuItem<String>(
          value: null,
          child: Text('Todos os ${label.toLowerCase()}s', style: TextStyle(color: Colors.grey[600])),
        ),
        ...options.map((option) => DropdownMenuItem<String>(
          value: option,
          child: Text(option),
        )),
      ],
      onChanged: onChanged,
    );
  }

  Widget _buildOperationalRoutesList() {
    return Consumer(
      builder: (context, ref, child) {
        final filters = OperationalRouteFilters(
          operacao: _selectedOperacao,
          companhia: _selectedCompanhia,
          aeroportoOrigem: _selectedAeroporto, // Filtra por origem
          aeroportoDestino: null,
          searchQuery: _searchController.text.isNotEmpty ? _searchController.text : null,
        );

        final routesAsync = ref.watch(filteredOperationalRoutesProvider(filters));

        return routesAsync.when(
          data: (routes) {
            if (routes.isEmpty) {
              return _buildEmptyState();
            }

            return ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: routes.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: _buildOperationalRouteCard(routes[index]),
                );
              },
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
          ),
          error: (error, stack) => _buildErrorState(error.toString()),
        );
      },
    );
  }

  Widget _buildStatsHeader(Map<String, dynamic> stats) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Estatísticas das Rotas',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total de Rotas',
                  '${stats['total_routes'] ?? 0}',
                  Icons.route,
                  const Color(0xFF3B82F6),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Saída do Brasil',
                  '${stats['saida_brasil'] ?? 0}',
                  Icons.flight_takeoff,
                  const Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Chegada ao Brasil',
                  '${stats['chegada_brasil'] ?? 0}',
                  Icons.flight_land,
                  const Color(0xFFF59E0B),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Companhias',
                  '${stats['total_companies'] ?? 0}',
                  Icons.airline_seat_flat,
                  const Color(0xFF8B5CF6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.flight,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhuma rota encontrada',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tente ajustar os filtros ou verificar a conexão',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
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
            'Erro ao carregar rotas',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.red[600],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error,
              style: TextStyle(
                fontSize: 14,
                color: Colors.red[500],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              // Recarregar dados
              ref.invalidate(operationalRoutesProvider);
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Tentar Novamente'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOperationalRouteCard(OperationalRoute route) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF3B82F6)),
                  ),
                  child: Text(
                    route.voo,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3B82F6),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Favicon da companhia
                _faviconService.buildAirlineFavicon(route.cia, size: route.cia == 'DL' || route.cia == 'LA' ? 40 : 32),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    route.nomeCia,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: route.operacao == 'SAÍDA DO BRASIL' 
                        ? const Color(0xFF10B981).withValues(alpha: 0.1)
                        : const Color(0xFFF59E0B).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: route.operacao == 'SAÍDA DO BRASIL' 
                          ? const Color(0xFF10B981)
                          : const Color(0xFFF59E0B),
                    ),
                  ),
                  child: Text(
                    route.operacao,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: route.operacao == 'SAÍDA DO BRASIL' 
                          ? const Color(0xFF10B981)
                          : const Color(0xFFF59E0B),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Rota
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Origem',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${route.origem} - ${route.aeroportoOrigem}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (route.terminalOrigem != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Terminal: ${route.terminalOrigem}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Seta
                Column(
                  children: [
                    Icon(
                      Icons.arrow_forward,
                      color: Colors.grey[400],
                      size: 20,
                    ),
                    Text(
                      route.saida,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Destino',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${route.destino} - ${route.aeroportoDestino}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.end,
                      ),
                      if (route.terminalDestino != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Terminal: ${route.terminalDestino}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.end,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Informações adicionais
            if (route.observacoes != null && route.observacoes!.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3CD),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFFEAA7)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: const Color(0xFF856404),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        route.observacoes!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF856404),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRealTimeFlightsTab() {
    return Column(
      children: [
        // Busca específica de voo
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Buscar Status de Voo Específico',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _flightController,
                      decoration: InputDecoration(
                        hintText: 'Número do voo (ex: TAM8126, AA940)',
                        prefixIcon: const Icon(Icons.flight, color: Color(0xFF64748B)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      onSubmitted: (_) => _searchFlight(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isSearching ? null : _searchFlight,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSearching
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Buscar'),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Resultados da busca de voo em tempo real
        Expanded(
          child: _buildRealTimeFlightResults(),
        ),
      ],
    );
  }

  Widget _buildRealTimeFlightResults() {
    if (_flightController.text.trim().isEmpty) {
      return Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.flight_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Digite o número do voo para consultar',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Use o campo acima para buscar informações em tempo real',
                style: TextStyle(
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Consumer(
      builder: (context, ref, child) {
        final flightAsync = ref.watch(
          flightSearchProvider(_flightController.text.trim())
        );
        
        return flightAsync.when(
          data: (flight) {
            if (flight == null) {
              return _buildFlightNotFound();
            }
            return Container(
              margin: const EdgeInsets.all(20),
              child: _buildRealTimeFlightCard(flight),
            );
          },
          loading: () => Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF3B82F6)),
                  SizedBox(height: 16),
                  Text(
                    'Buscando informações do voo...',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
          error: (error, stack) => _buildErrorState('Erro ao buscar voo: $error'),
        );
      },
    );
  }

  Widget _buildFlightNotFound() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.flight_land,
              size: 64,
              color: Colors.orange[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Voo não encontrado',
              style: TextStyle(
                fontSize: 18,
                color: Colors.orange[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Verifique o número do voo e tente novamente',
              style: TextStyle(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRealTimeFlightCard(FlightInfo flight) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF3B82F6)),
                  ),
                  child: Text(
                    flight.flight?.number ?? 'N/A',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3B82F6),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    flight.airline?.name ?? 'Companhia não informada',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(flight.flightStatus).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _getStatusColor(flight.flightStatus)),
                  ),
                  child: Text(
                    _getStatusText(flight.flightStatus),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(flight.flightStatus),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Informações de partida e chegada
            Row(
              children: [
                // Partida
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PARTIDA',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        flight.departure?.airport ?? 'Aeroporto não informado',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        flight.departure?.iata ?? '',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        flight.departure?.scheduled?.substring(11, 16) ?? 'Horário não informado',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (flight.departure?.terminal != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Terminal: ${flight.departure!.terminal}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                      if (flight.departure?.gate != null) ...[
                        Text(
                          'Portão: ${flight.departure!.gate}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Seta
                Column(
                  children: [
                    Icon(
                      Icons.arrow_forward,
                      color: const Color(0xFF3B82F6),
                      size: 32,
                    ),
                    Text(
                      flight.flightDate ?? '',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                
                // Chegada
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'CHEGADA',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        flight.arrival?.airport ?? 'Aeroporto não informado',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.end,
                      ),
                      Text(
                        flight.arrival?.iata ?? '',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.end,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        flight.arrival?.scheduled?.substring(11, 16) ?? 'Horário não informado',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.end,
                      ),
                      if (flight.arrival?.terminal != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Terminal: ${flight.arrival!.terminal}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.end,
                        ),
                      ],
                      if (flight.arrival?.gate != null) ...[
                        Text(
                          'Portão: ${flight.arrival!.gate}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.end,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'active':
      case 'en route':
        return Colors.green;
      case 'landed':
      case 'arrived':
        return Colors.blue;
      case 'delayed':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      case 'diverted':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String? status) {
    switch (status?.toLowerCase()) {
      case 'active':
      case 'en route':
        return 'EM VOO';
      case 'landed':
      case 'arrived':
        return 'POUSOU';
      case 'delayed':
        return 'ATRASADO';
      case 'cancelled':
        return 'CANCELADO';
      case 'diverted':
        return 'DESVIADO';
      case 'scheduled':
        return 'PROGRAMADO';
      default:
        return 'DESCONHECIDO';
    }
  }
}
