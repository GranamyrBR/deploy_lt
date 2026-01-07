import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class RotasMotoristasScreen extends ConsumerStatefulWidget {
  const RotasMotoristasScreen({super.key});

  @override
  ConsumerState<RotasMotoristasScreen> createState() => _RotasMotoristasScreenState();
}

class _RotasMotoristasScreenState extends ConsumerState<RotasMotoristasScreen> {
  String _filtroDirection = 'Todos';
  String _filtroAirline = 'Todas';
  String _searchQuery = '';

  // Mock data - em produção viria do Supabase
  final List<Map<String, dynamic>> _routes = [
    {
      'numero_voo': 'AA940',
      'nome_cia': 'American Airlines',
      'codigo_cia': 'AA',
      'origem_completa': 'GRU - São Paulo',
      'destino_completa': 'MIA - Miami',
      'terminal_origem': 'Terminal 3',
      'portao_origem': 'A15-A20',
      'terminal_destino': 'Terminal N',
      'portao_destino': 'D1-D30',
      'saida_programada': '22:30',
      'chegada_programada': '06:15',
      'balcao_checkin': 'Balcões 341-360',
      'area_checkin': 'Terminal 3, Check-in A',
      'esteira_bagagem': 'Esteira 1-3',
      'area_encontro': 'Terminal 3, Área de Desembarque Internacional - Portão Principal',
      'observacoes_motorista': 'Voo noturno. Motorista deve chegar às 19:30. Passageiros saem pela área internacional.',
      'tempo_checkin_minutos': 180,
      'tempo_espera_desembarque_minutos': 60,
      'direcao': 'Saída do Brasil',
      'voo_direto': true,
      'tipo_aeronave': 'Boeing 777-300ER'
    },
    {
      'numero_voo': 'LA533',
      'nome_cia': 'LATAM Airlines',
      'codigo_cia': 'LA',
      'origem_completa': 'GRU - São Paulo',
      'destino_completa': 'MIA - Miami',
      'terminal_origem': 'Terminal 3',
      'portao_origem': 'B10-B15',
      'terminal_destino': 'Terminal S',
      'portao_destino': 'H1-H20',
      'saida_programada': '23:30',
      'chegada_programada': '07:15',
      'balcao_checkin': 'Balcões 201-240',
      'area_checkin': 'Terminal 3, Check-in B',
      'esteira_bagagem': 'Esteira 7-9',
      'area_encontro': 'Terminal 3, Área LATAM de Desembarque',
      'observacoes_motorista': 'LATAM tem balcões dedicados. Área de desembarque diferente da American.',
      'tempo_checkin_minutos': 180,
      'tempo_espera_desembarque_minutos': 60,
      'direcao': 'Saída do Brasil',
      'voo_direto': true,
      'tipo_aeronave': 'Airbus A350-900'
    },
    {
      'numero_voo': 'AA941',
      'nome_cia': 'American Airlines',
      'codigo_cia': 'AA',
      'origem_completa': 'MIA - Miami',
      'destino_completa': 'GRU - São Paulo',
      'terminal_origem': 'Terminal N',
      'portao_origem': 'D31-D35',
      'terminal_destino': 'Terminal 3',
      'portao_destino': 'A40-A45',
      'saida_programada': '23:45',
      'chegada_programada': '14:30',
      'balcao_checkin': 'Balcões D1-D30',
      'area_checkin': 'Terminal N, Área D',
      'esteira_bagagem': 'Esteira 1-3',
      'area_encontro': 'Terminal 3, Desembarque Internacional - Saída A',
      'observacoes_motorista': 'Chegada à tarde em GRU. Horário de pico no aeroporto. Trânsito intenso para SP.',
      'tempo_checkin_minutos': 180,
      'tempo_espera_desembarque_minutos': 90,
      'direcao': 'Chegada ao Brasil',
      'voo_direto': true,
      'tipo_aeronave': 'Boeing 777-300ER'
    },
  ];

  List<Map<String, dynamic>> get _filteredRoutes {
    return _routes.where((route) {
      final matchesDirection = _filtroDirection == 'Todos' || route['direcao'] == _filtroDirection;
      final matchesAirline = _filtroAirline == 'Todas' || route['codigo_cia'] == _filtroAirline;
      final matchesSearch = _searchQuery.isEmpty ||
          route['numero_voo'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
          route['nome_cia'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
          route['origem_completa'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
          route['destino_completa'].toLowerCase().contains(_searchQuery.toLowerCase());
      
      return matchesDirection && matchesAirline && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rotas Aéreas - Informações para Motoristas'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(context),
            tooltip: 'Informações importantes',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFiltersCard(),
          Expanded(
            child: _buildRoutesList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.filter_list, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Filtros',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Buscar voo ou destino',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _filtroDirection,
                    decoration: const InputDecoration(
                      labelText: 'Direção',
                      border: OutlineInputBorder(),
                    ),
                    items: ['Todos', 'Saída do Brasil', 'Chegada ao Brasil']
                        .map((value) => DropdownMenuItem(
                              value: value,
                              child: Text(value),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _filtroDirection = value!;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _filtroAirline,
                    decoration: const InputDecoration(
                      labelText: 'Companhia',
                      border: OutlineInputBorder(),
                    ),
                    items: ['Todas', 'AA', 'LA', 'UA', 'DL', 'CM']
                        .map((value) => DropdownMenuItem(
                              value: value,
                              child: Text(value),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _filtroAirline = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoutesList() {
    final routes = _filteredRoutes;

    if (routes.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.flight_takeoff, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Nenhuma rota encontrada',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: routes.length,
      itemBuilder: (context, index) {
        final route = routes[index];
        return _buildRouteCard(route);
      },
    );
  }

  Widget _buildRouteCard(Map<String, dynamic> route) {
    final isArrival = route['direcao'] == 'Chegada ao Brasil';
    final cardColor = isArrival ? Colors.green.shade50 : Colors.blue.shade50;
    final iconColor = isArrival ? Colors.green : Colors.blue;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: cardColor,
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: iconColor,
          child: Icon(
            isArrival ? Icons.flight_land : Icons.flight_takeoff,
            color: Colors.white,
          ),
        ),
        title: Row(
          children: [
            Text(
              route['numero_voo'],
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(width: 8),
            Chip(
              label: Text(route['codigo_cia']),
              backgroundColor: iconColor.withValues(alpha: 0.2),
            ),
            const Spacer(),
            if (route['voo_direto'] == true)
              const Chip(
                label: Text('DIRETO'),
                backgroundColor: Colors.orange,
                labelStyle: TextStyle(color: Colors.white, fontSize: 10),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              route['nome_cia'],
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    route['origem_completa'],
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                const Icon(Icons.arrow_forward, size: 16),
                Expanded(
                  child: Text(
                    route['destino_completa'],
                    textAlign: TextAlign.end,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Saída: ${route['saida_programada']} | Chegada: ${route['chegada_programada']}',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailSection('🏢 Informações do Terminal', [
                  'Terminal Origem: ${route['terminal_origem']}',
                  'Portão Origem: ${route['portao_origem']}',
                  'Terminal Destino: ${route['terminal_destino']}',
                  'Portão Destino: ${route['portao_destino']}',
                ]),
                const SizedBox(height: 16),
                _buildDetailSection('✈️ Check-in e Bagagem', [
                  'Check-in: ${route['balcao_checkin']}',
                  'Área Check-in: ${route['area_checkin']}',
                  'Esteira Bagagem: ${route['esteira_bagagem']}',
                ]),
                const SizedBox(height: 16),
                _buildDetailSection('📍 Local de Encontro', [
                  route['area_encontro'],
                ]),
                const SizedBox(height: 16),
                _buildDetailSection('⏰ Tempos Importantes', [
                  'Chegar ${route['tempo_checkin_minutos']} min antes da decolagem',
                  'Aguardar ${route['tempo_espera_desembarque_minutos']} min após chegada',
                ]),
                const SizedBox(height: 16),
                _buildDetailSection('ℹ️ Observações para Motorista', [
                  route['observacoes_motorista'],
                ]),
                const SizedBox(height: 16),
                _buildDetailSection('🛩️ Detalhes da Aeronave', [
                  'Tipo: ${route['tipo_aeronave']}',
                  'Status: ${route['voo_direto'] ? 'Voo Direto' : 'Com Conexão'}',
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(String title, List<String> items) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '• $item',
                  style: const TextStyle(fontSize: 14),
                ),
              )),
        ],
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info, color: Colors.blue),
            SizedBox(width: 8),
            Text('Informações Importantes'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'HORÁRIOS:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('• STD/STA: Horários programados oficiais'),
              Text('• ETD/ETA: Horários estimados (podem mudar)'),
              SizedBox(height: 12),
              Text(
                'CÓDIGOS IMPORTANTES:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('• GRU: Guarulhos (São Paulo)'),
              Text('• GIG: Galeão (Rio de Janeiro)'),
              Text('• MIA: Miami Internacional'),
              Text('• JFK: John F. Kennedy (NY)'),
              Text('• IAH: Houston Bush'),
              Text('• ATL: Atlanta Hartsfield'),
              SizedBox(height: 12),
              Text(
                'DICAS PARA MOTORISTAS:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('• Sempre chegue 15min antes do horário indicado'),
              Text('• Para chegadas, monitore possíveis atrasos'),
              Text('• Áreas de encontro podem mudar - confirme sempre'),
              Text('• Voos noturnos: trânsito mais tranquilo'),
              Text('• Voos diurnos: considere trânsito de SP'),
            ],
          ),
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
} 
