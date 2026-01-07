import 'package:flutter/material.dart';
import '../models/enhanced_quotation_model.dart';

/// Widget visual e intuitivo para gerenciar o status da cotação
/// com timeline e botões claros para cada transição
class QuotationStatusManager extends StatelessWidget {
  final QuotationStatus currentStatus;
  final void Function(QuotationStatus) onStatusChanged;
  final bool enabled;

  const QuotationStatusManager({
    Key? key,
    required this.currentStatus,
    required this.onStatusChanged,
    this.enabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getStatusColor(currentStatus).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getStatusIcon(currentStatus),
                    color: _getStatusColor(currentStatus),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Status da Cotação',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _getStatusName(currentStatus),
                      style: TextStyle(
                        fontSize: 14,
                        color: _getStatusColor(currentStatus),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Explicação do status atual
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getStatusExplanation(currentStatus),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // Timeline visual
            _buildTimeline(),
            const SizedBox(height: 20),
            
            // Ações disponíveis
            const Text(
              'Ações Disponíveis:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline() {
    final statuses = [
      QuotationStatus.draft,
      QuotationStatus.sent,
      QuotationStatus.viewed,
      QuotationStatus.accepted,
    ];

    return Column(
      children: List.generate(statuses.length, (index) {
        final status = statuses[index];
        final isPassed = _getStatusOrder(currentStatus) >= _getStatusOrder(status);
        final isCurrent = currentStatus == status;

        return Row(
          children: [
            // Icon
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isPassed
                    ? _getStatusColor(status)
                    : Colors.grey.shade300,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCurrent
                      ? _getStatusColor(status)
                      : Colors.transparent,
                  width: 3,
                ),
              ),
              child: Icon(
                isPassed ? Icons.check : _getStatusIcon(status),
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getStatusName(status),
                    style: TextStyle(
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                      fontSize: 14,
                      color: isPassed ? Colors.black87 : Colors.grey,
                    ),
                  ),
                  if (isCurrent)
                    Text(
                      'Status Atual',
                      style: TextStyle(
                        fontSize: 11,
                        color: _getStatusColor(status),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
            
            // Line to next
            if (index < statuses.length - 1)
              Container(
                width: 2,
                height: 30,
                margin: const EdgeInsets.only(left: 15, top: 8),
                color: isPassed ? _getStatusColor(status) : Colors.grey.shade300,
              ),
          ],
        );
      }).expand((widget) => [widget, const SizedBox(height: 8)]).toList()
        ..removeLast(),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // RASCUNHO → ENVIADO
        if (currentStatus == QuotationStatus.draft)
          _buildActionButton(
            context,
            'Marcar como Enviado',
            Icons.send,
            Colors.blue,
            QuotationStatus.sent,
            'Cliente recebeu a cotação por email/WhatsApp',
          ),
        
        // ENVIADO → VISUALIZADO
        if (currentStatus == QuotationStatus.sent)
          _buildActionButton(
            context,
            'Marcar como Visualizado',
            Icons.visibility,
            Colors.orange,
            QuotationStatus.viewed,
            'Cliente abriu e leu a cotação',
          ),
        
        // VISUALIZADO → ACEITO ou REJEITADO
        if (currentStatus == QuotationStatus.viewed) ...[
          _buildActionButton(
            context,
            'Marcar como Aceito ✅',
            Icons.check_circle,
            Colors.green,
            QuotationStatus.accepted,
            'Cliente aceitou a proposta! 🎉',
          ),
          _buildActionButton(
            context,
            'Marcar como Rejeitado',
            Icons.cancel,
            Colors.red,
            QuotationStatus.rejected,
            'Cliente recusou a proposta',
          ),
        ],
        
        // De ENVIADO → ACEITO (atalho)
        if (currentStatus == QuotationStatus.sent)
          _buildActionButton(
            context,
            'Aceitar Diretamente ✅',
            Icons.check_circle,
            Colors.green,
            QuotationStatus.accepted,
            'Cliente aceitou sem visualizar',
          ),
        
        // De QUALQUER → REJEITADO
        if (currentStatus != QuotationStatus.rejected &&
            currentStatus != QuotationStatus.accepted)
          _buildActionButton(
            context,
            'Rejeitar',
            Icons.cancel,
            Colors.red,
            QuotationStatus.rejected,
            'Cliente recusou',
          ),
        
        // Voltar para RASCUNHO (se aceito ou rejeitado)
        if (currentStatus == QuotationStatus.accepted ||
            currentStatus == QuotationStatus.rejected)
          _buildActionButton(
            context,
            'Voltar para Rascunho',
            Icons.edit,
            Colors.grey,
            QuotationStatus.draft,
            'Editar novamente',
          ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    QuotationStatus newStatus,
    String explanation,
  ) {
    return ElevatedButton.icon(
      onPressed: enabled
          ? () {
              showDialog<void>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Confirmar Mudança de Status'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _getStatusColor(currentStatus).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              _getStatusIcon(currentStatus),
                              color: _getStatusColor(currentStatus),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.arrow_forward, size: 20),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(icon, color: color, size: 20),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'De: ${_getStatusName(currentStatus)}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        'Para: ${_getStatusName(newStatus)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(explanation),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        onStatusChanged(newStatus);
                        Navigator.of(context).pop();
                      },
                      icon: Icon(icon, size: 18),
                      label: const Text('Confirmar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              );
            }
          : null,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Color _getStatusColor(QuotationStatus status) {
    switch (status) {
      case QuotationStatus.draft:
        return Colors.grey;
      case QuotationStatus.sent:
        return Colors.blue;
      case QuotationStatus.viewed:
        return Colors.orange;
      case QuotationStatus.accepted:
        return Colors.green;
      case QuotationStatus.rejected:
        return Colors.red;
      case QuotationStatus.expired:
        return Colors.purple;
      case QuotationStatus.cancelled:
        return Colors.blueGrey;
    }
  }

  IconData _getStatusIcon(QuotationStatus status) {
    switch (status) {
      case QuotationStatus.draft:
        return Icons.edit;
      case QuotationStatus.sent:
        return Icons.send;
      case QuotationStatus.viewed:
        return Icons.visibility;
      case QuotationStatus.accepted:
        return Icons.check_circle;
      case QuotationStatus.rejected:
        return Icons.cancel;
      case QuotationStatus.expired:
        return Icons.schedule;
      case QuotationStatus.cancelled:
        return Icons.block;
    }
  }

  String _getStatusName(QuotationStatus status) {
    switch (status) {
      case QuotationStatus.draft:
        return '📝 Rascunho';
      case QuotationStatus.sent:
        return '📤 Enviado';
      case QuotationStatus.viewed:
        return '👀 Visualizado';
      case QuotationStatus.accepted:
        return '✅ Aceito';
      case QuotationStatus.rejected:
        return '❌ Rejeitado';
      case QuotationStatus.expired:
        return '⏰ Expirado';
      case QuotationStatus.cancelled:
        return '🚫 Cancelado';
    }
  }

  String _getStatusExplanation(QuotationStatus status) {
    switch (status) {
      case QuotationStatus.draft:
        return 'Cotação em edição. Quando terminar de editar, envie para o cliente.';
      case QuotationStatus.sent:
        return 'Cotação enviada ao cliente. Aguardando ele abrir e visualizar.';
      case QuotationStatus.viewed:
        return 'Cliente visualizou a cotação! Aguardando resposta dele.';
      case QuotationStatus.accepted:
        return '🎉 Parabéns! Cliente aceitou a cotação. Venda fechada!';
      case QuotationStatus.rejected:
        return 'Cliente rejeitou. Considere fazer follow-up ou ajustar valores.';
      case QuotationStatus.expired:
        return 'Cotação expirou. Considere renovar com nova data de validade.';
      case QuotationStatus.cancelled:
        return 'Cotação cancelada. Não será mais processada.';
    }
  }

  int _getStatusOrder(QuotationStatus status) {
    switch (status) {
      case QuotationStatus.draft:
        return 0;
      case QuotationStatus.sent:
        return 1;
      case QuotationStatus.viewed:
        return 2;
      case QuotationStatus.accepted:
      case QuotationStatus.rejected:
      case QuotationStatus.expired:
      case QuotationStatus.cancelled:
        return 3;
    }
  }
}

