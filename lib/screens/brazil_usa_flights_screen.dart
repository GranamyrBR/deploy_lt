import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/flight_info.dart';
import 'package:lecotour_dashboard/providers/api_providers.dart';
import '../widgets/base_screen_layout.dart';

class BrazilUsaFlightsScreen extends ConsumerWidget {
  const BrazilUsaFlightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flightsAsync = ref.watch(brazilUsaFlightsProvider);

    return BaseScreenLayout(
      title: 'Voos Brasil ↔ EUA',
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rotas internacionais entre Brasil e Estados Unidos',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            
            Expanded(
              child: flightsAsync.when(
                data: (flights) => flights.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.flight_land,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Nenhum voo encontrado',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: flights.length,
                        itemBuilder: (context, index) {
                          final flight = flights[index];
                          return _buildFlightCard(context, flight);
                        },
                      ),
                loading: () => const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Carregando voos Brasil-EUA...'),
                    ],
                  ),
                ),
                error: (error, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Erro ao carregar voos',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        error.toString(),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => ref.refresh(brazilUsaFlightsProvider),
                        child: const Text('Tentar Novamente'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlightCard(BuildContext context, FlightInfo flight) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho com número do voo e companhia
            Row(
              children: [
                Icon(
                  Icons.flight,
                  color: Theme.of(context).primaryColor,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        flight.flight?.number ?? 'N/A',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        flight.airline?.name ?? 'Companhia não informada',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(flight.flightStatus ?? 'Unknown'),
              ],
            ),
            const SizedBox(height: 16),
            
            // Informações de partida
            _buildFlightLeg(
              'Partida',
              flight.departure?.airport ?? 'N/A',
              flight.departure?.scheduled ?? 'N/A',
              flight.departure?.gate ?? 'N/A',
              flight.departure?.terminal ?? 'N/A',
              Icons.flight_takeoff,
              Colors.blue,
            ),
            
            const SizedBox(height: 12),
            
            // Linha de conexão
            Center(
              child: Container(
                width: 2,
                height: 20,
                color: Colors.grey[300],
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Informações de chegada
            _buildFlightLeg(
              'Chegada',
              flight.arrival?.airport ?? 'N/A',
              flight.arrival?.scheduled ?? 'N/A',
              flight.arrival?.gate ?? 'N/A',
              flight.arrival?.terminal ?? 'N/A',
              Icons.flight_land,
              Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlightLeg(
    String title,
    String airport,
    String time,
    String gate,
    String terminal,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                airport,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(
                    time,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  if (gate.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    Text(
                      'Gate: $gate',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                  if (terminal.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    Text(
                      'Terminal: $terminal',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String status) {
    Color backgroundColor;
    Color textColor;
    
    switch (status.toLowerCase()) {
      case 'on time':
      case 'scheduled':
        backgroundColor = Colors.green.withValues(alpha: 0.2);
        textColor = Colors.green;
        break;
      case 'delayed':
        backgroundColor = Colors.orange.withValues(alpha: 0.2);
        textColor = Colors.orange;
        break;
      case 'cancelled':
        backgroundColor = Colors.red.withValues(alpha: 0.2);
        textColor = Colors.red;
        break;
      default:
        backgroundColor = Colors.grey.withValues(alpha: 0.2);
        textColor = Colors.grey;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }
} 
