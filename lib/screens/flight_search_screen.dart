import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/flight_info.dart';
import 'package:lecotour_dashboard/providers/api_providers.dart';
import 'package:lecotour_dashboard/screens/brazil_usa_flights_screen.dart';
import '../widgets/base_screen_layout.dart';

class FlightSearchScreen extends ConsumerStatefulWidget {
  const FlightSearchScreen({super.key});

  @override
  FlightSearchScreenState createState() => FlightSearchScreenState();
}

class FlightSearchScreenState extends ConsumerState<FlightSearchScreen> {
  final TextEditingController _flightNumberController = TextEditingController();
  DateTime? _selectedDate;
  bool _isSearching = false;
  String _currentSearch = ''; // Para controlar quando buscar
  String? _errorMessage;

  @override
  void dispose() {
    _flightNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreenLayout(
      title: 'Buscar Voo por Número',
      actions: [
        // Botão para voos Brasil-EUA
        ElevatedButton.icon(
          icon: const Icon(Icons.flight_takeoff),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const BrazilUsaFlightsScreen(),
              ),
            );
          },
          label: const Text('Brasil-EUA'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            // Campo de número do voo
            Center(
              child: SizedBox(
                width: 400,
                child: TextField(
                  controller: _flightNumberController,
                  decoration: InputDecoration(
                    hintText: 'Buscar voo...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(32),
                      borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(32),
                      borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    fillColor: Theme.of(context).cardColor,
                    filled: true,
                  ),
                  onChanged: (v) {
                    // Limpar busca atual quando o texto mudar
                    setState(() {
                      _currentSearch = '';
                      _errorMessage = null;
                    });
                  },
                  onSubmitted: (_) => _searchFlight(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Botão de data (opcional)
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.calendar_today),
                onPressed: () async {
                  final now = DateTime.now();
                  final lastDate = DateTime(now.year + 2, 12, 31);
                  final safeInitialDate = _selectedDate ?? now;
                  final finalInitialDate = safeInitialDate.isAfter(lastDate) ? lastDate : safeInitialDate;
                  
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: finalInitialDate,
                    firstDate: DateTime(2020),
                    lastDate: lastDate,
                  );
                  
                  if (pickedDate != null) {
                    setState(() {
                      _selectedDate = pickedDate;
                    });
                    // Buscar automaticamente quando a data mudar
                    if (_currentSearch.isNotEmpty) {
                      _searchFlight();
                    }
                  }
                },
                label: Text(_selectedDate == null
                    ? 'Data do Voo (Opcional)'
                    : 'Data: ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'),
              ),
            ),
            const SizedBox(height: 16),
            
            // Botão de busca
            Center(
              child: SizedBox(
                width: 400,
                child: ElevatedButton.icon(
                  icon: _isSearching 
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.search),
                  onPressed: _isSearching ? null : _searchFlight,
                  label: Text(_isSearching ? 'Buscando...' : 'Buscar Voo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            
            // Botão de teste
            Center(
              child: SizedBox(
                width: 400,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.bug_report),
                  onPressed: _testSearch,
                  label: const Text('Testar Busca (AA940)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ),
            
            // Mensagem de erro
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Center(
                child: Container(
                  width: 400,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red[600], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red[700]),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 24),
            
            // Resultado da busca
            Expanded(
              child: _buildSearchResult(),
            ),
          ],
        ),
      ),
    );
  }

  void _searchFlight() {
    final flightNumber = _flightNumberController.text.trim();
    if (flightNumber.isEmpty) {
      setState(() {
        _errorMessage = 'Digite um número de voo';
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _currentSearch = flightNumber;
      _errorMessage = null;
    });

    // Converter data para string se existir
    String? dateString;
    if (_selectedDate != null) {
      dateString = "${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}";
    }

    // Invalidar o provider para forçar uma nova busca
    ref.invalidate(flightByNumberProvider((
      flightNumber: flightNumber,
      date: dateString,
    )));
    
    // Aguardar um pouco e parar o loading
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    });
  }

  void _testSearch() {
    _flightNumberController.text = 'AA940';
    _searchFlight();
  }

  Widget _buildSearchResult() {
    final flightNumber = _flightNumberController.text.trim();
    
    if (flightNumber.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.flight_takeoff,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Digite um número de voo para buscar',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Exemplos: AA940, TAM8126, UA149, DL60, JJ8080',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    // Só mostrar resultado se houver uma busca ativa
    if (_currentSearch.isEmpty || _currentSearch != flightNumber) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: Colors.blue,
            ),
            SizedBox(height: 16),
            Text(
              'Clique em "Buscar Voo" para ver os resultados',
              style: TextStyle(
                fontSize: 16,
                color: Colors.blue,
              ),
            ),
          ],
        ),
      );
    }

    // Usar o provider para buscar o voo com data
    return Consumer(
      builder: (context, ref, child) {
        // Converter data para string se existir
        String? dateString;
        if (_selectedDate != null) {
          dateString = "${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}";
        }
        
        final flightAsync = ref.watch(flightByNumberProvider((
          flightNumber: flightNumber,
          date: dateString,
        )));
        
        return flightAsync.when(
          data: (flight) {
            if (flight == null) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.flight_land,
                      size: 64,
                      color: Colors.orange,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Voo não encontrado',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Verifique o número do voo e tente novamente',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              );
            }
            
            return _buildFlightCard(flight);
          },
          loading: () => const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Buscando informações do voo...'),
              ],
            ),
          ),
          error: (error, stack) {
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
                    'Erro ao buscar voo',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tente novamente ou verifique sua conexão',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _searchFlight,
                    child: const Text('Tentar Novamente'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFlightCard(FlightInfo flight) {
    return Center(
      child: Container(
        width: 600,
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho
            Row(
              children: [
                Icon(
                  Icons.flight,
                  color: Theme.of(context).primaryColor,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Voo ${flight.flight?.number ?? 'N/A'}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        flight.airline?.name ?? 'Companhia não informada',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(flight.flightStatus).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _getStatusColor(flight.flightStatus)),
                  ),
                  child: Text(
                    _getStatusText(flight.flightStatus),
                    style: TextStyle(
                      color: _getStatusColor(flight.flightStatus),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
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
                          fontSize: 18,
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
                        flight.departure?.scheduled ?? 'Horário não informado',
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
                      color: Theme.of(context).primaryColor,
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
                          fontSize: 18,
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
                        flight.arrival?.scheduled ?? 'Horário não informado',
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
