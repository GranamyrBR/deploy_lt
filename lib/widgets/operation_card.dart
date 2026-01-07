import 'package:flutter/material.dart';
import '../providers/operations_provider.dart';
import '../utils/timezone_utils.dart';
import 'agency_details_modal.dart';

class OperationCard extends StatelessWidget {
  final Operation operation;
  final VoidCallback? onTap;
  final Function(String)? onStatusChanged;

  const OperationCard({
    Key? key,
    required this.operation,
    this.onTap,
    this.onStatusChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header com status e prioridade
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _getStatusColor(operation.status),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Operação #${operation.id}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getPriorityColor(operation.priority),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      operation.priorityText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              
              // Hora atual do Brasil para referência da atendente
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.access_time, size: 14, color: Colors.blue[700]),
                    const SizedBox(width: 4),
                    Text(
                      'Agora: ${_getCurrentTimeBrazil()}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Informações principais
              Row(
                children: [
                  Expanded(
                    child: _buildInfoRow(
                      context,
                      Icons.person,
                      'Cliente',
                      operation.customerName ?? 'Cliente não especificado',
                    ),
                  ),
                  if (operation.isVipCustomer)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star,
                            size: 10,
                            color: Colors.amber[700],
                          ),
                          const SizedBox(width: 2),
                          Text(
                            'VIP',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              if (operation.hasAgency)
                InkWell(
                  onTap: () => _showAgencyDetails(context, operation),
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildInfoRow(
                            context,
                            Icons.business,
                            'Agência',
                            operation.agencyDisplayName,
                          ),
                        ),
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
                        ),
                      ],
                    ),
                  ),
                ),
              // Informações de Serviço ou Produto
              if (operation.serviceName != null) ...[
                _buildInfoRow(
                  context,
                  Icons.room_service,
                  'Serviço',
                  operation.serviceName!,
                ),
                if (operation.serviceValueUsd != null && operation.serviceValueUsd! > 0)
                  _buildInfoRow(
                    context,
                    Icons.attach_money,
                    'Valor Serviço',
                    '\$${operation.serviceValueUsd!.toStringAsFixed(2)}',
                  ),
              ] else if (operation.productName != null) ...[
                _buildInfoRow(
                  context,
                  Icons.inventory,
                  'Produto',
                  operation.productName!,
                ),
                if (operation.productValueUsd != null && operation.productValueUsd! > 0)
                  _buildInfoRow(
                    context,
                    Icons.attach_money,
                    'Valor Produto',
                    '\$${operation.productValueUsd!.toStringAsFixed(2)}',
                  ),
              ] else ...[
                _buildInfoRow(
                  context,
                  Icons.work,
                  'Tipo',
                  'Operação Geral',
                ),
              ],
              _buildInfoRow(
                context,
                Icons.schedule,
                'Agendado',
                _formatDateTime(operation.scheduledDate),
              ),
              
              // Driver e carro (se designados)
              if (operation.hasDriver) ...[
                _buildInfoRow(
                  context,
                  Icons.drive_eta,
                  'Driver',
                  operation.driverName ?? 'Driver não especificado',
                ),
              ],
              if (operation.hasCar) ...[
                _buildInfoRow(
                  context,
                  Icons.directions_car,
                  'Carro',
                  operation.carName ?? 'Carro não especificado',
                ),
              ],
              
              // Dados de voo (se aplicável)
              if (operation.hasFlightData) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.flight, size: 16, color: Colors.blue[600]),
                          const SizedBox(width: 4),
                          Text(
                            'Voo ${operation.flightNumber ?? 'N/A'}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[600],
                            ),
                          ),
                        ],
                      ),
                      if (operation.departureAirportCode != null && 
                          operation.arrivalAirportCode != null)
                        Text(
                          '${operation.departureAirportCode} → ${operation.arrivalAirportCode}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[700],
                          ),
                        ),
                      if (operation.scheduledDepartureTime != null)
                        Text(
                          'Partida: ${_formatTime(operation.scheduledDepartureTime!)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 12),
              
              // Footer com status e ações
              Row(
                children: [
                  // Comissão do motorista (se houver)
                  if (operation.driverCommissionUsd > 0)
                    Expanded(
                      child: Text(
                        'Comissão: \$${operation.driverCommissionUsd.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  
                  // Status atual
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(operation.status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _getStatusColor(operation.status)),
                    ),
                    child: Text(
                      operation.statusText,
                      style: TextStyle(
                        color: _getStatusColor(operation.status),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              
              // Botões de ação rápida
              if (onStatusChanged != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (operation.isPending || operation.isAssigned)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => onStatusChanged!('in_progress'),
                          icon: const Icon(Icons.play_arrow, size: 16),
                          label: const Text('Iniciar'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.green,
                            side: const BorderSide(color: Colors.green),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                    if (operation.isInProgress) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => onStatusChanged!('completed'),
                          icon: const Icon(Icons.check, size: 16),
                          label: const Text('Concluir'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.blue,
                            side: const BorderSide(color: Colors.blue),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _showAgencyDetails(BuildContext context, Operation operation) {
    AgencyDetailsModal.show(
      context,
      agencyName: operation.customerAgencyName ?? 'Agência não especificada',
      agencyEmail: operation.customerAgencyEmail,
      agencyPhone: operation.customerAgencyPhone,
      agencyCity: operation.customerAgencyCity,
      commissionRate: operation.customerAgencyCommissionRate,
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'assigned':
        return Colors.blue;
      case 'in_progress':
        return Colors.green;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'low':
        return Colors.grey;
      case 'normal':
        return Colors.blue;
      case 'high':
        return Colors.orange;
      case 'urgent':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    // Horário da operação em NYC (horário oficial da operação)
    final nycTime = TimezoneUtils.convertToNewYork(dateTime);
    
    return '${nycTime.day.toString().padLeft(2, '0')}/'
           '${nycTime.month.toString().padLeft(2, '0')}/'
           '${nycTime.year} '
           '${nycTime.hour.toString().padLeft(2, '0')}:'
           '${nycTime.minute.toString().padLeft(2, '0')} (NYC)';
  }

  String _formatTime(DateTime dateTime) {
    // Horário da operação em NYC (horário oficial da operação)
    final nycTime = TimezoneUtils.convertToNewYork(dateTime);
    
    return '${nycTime.hour.toString().padLeft(2, '0')}:'
           '${nycTime.minute.toString().padLeft(2, '0')} (NYC)';
  }

  String _getCurrentTimeBrazil() {
    // Hora atual no Brasil para referência da atendente
    final brazilTime = TimezoneUtils.getCurrentTimeSaoPaulo();
    
    return '${brazilTime.hour.toString().padLeft(2, '0')}:'
           '${brazilTime.minute.toString().padLeft(2, '0')} (BR)';
  }
}
