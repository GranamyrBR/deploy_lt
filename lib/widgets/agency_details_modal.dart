import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AgencyDetailsModal extends StatelessWidget {
  final String agencyName;
  final String? agencyEmail;
  final String? agencyPhone;
  final String? agencyCity;
  final double? commissionRate;

  const AgencyDetailsModal({
    Key? key,
    required this.agencyName,
    this.agencyEmail,
    this.agencyPhone,
    this.agencyCity,
    this.commissionRate,
  }) : super(key: key);

  static void show(
    BuildContext context, {
    required String agencyName,
    String? agencyEmail,
    String? agencyPhone,
    String? agencyCity,
    double? commissionRate,
  }) {
    showDialog(
      context: context,
      builder: (context) => AgencyDetailsModal(
        agencyName: agencyName,
        agencyEmail: agencyEmail,
        agencyPhone: agencyPhone,
        agencyCity: agencyCity,
        commissionRate: commissionRate,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.business,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Detalhes da Agência',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Informações da agência parceira',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Informações da agência
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nome da agência
                  _buildInfoItem(
                    context,
                    icon: Icons.business,
                    label: 'Nome da Agência',
                    value: agencyName,
                    copyable: true,
                  ),
                  
                  if (agencyEmail != null && agencyEmail!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildInfoItem(
                      context,
                      icon: Icons.email,
                      label: 'E-mail',
                      value: agencyEmail!,
                      copyable: true,
                    ),
                  ],
                  
                  if (agencyPhone != null && agencyPhone!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildInfoItem(
                      context,
                      icon: Icons.phone,
                      label: 'Telefone',
                      value: agencyPhone!,
                      copyable: true,
                    ),
                  ],
                  
                  if (agencyCity != null && agencyCity!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildInfoItem(
                      context,
                      icon: Icons.location_city,
                      label: 'Cidade',
                      value: agencyCity!,
                      copyable: false,
                    ),
                  ],
                  
                  if (commissionRate != null) ...[
                    const SizedBox(height: 16),
                    _buildInfoItem(
                      context,
                      icon: Icons.percent,
                      label: 'Taxa de Comissão',
                      value: '${(commissionRate! * 100).toStringAsFixed(1)}%',
                      copyable: false,
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Botões de ação
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Fechar'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    // Implementar ação para entrar em contato
                    _showContactOptions(context);
                  },
                  icon: const Icon(Icons.contact_phone),
                  label: const Text('Entrar em Contato'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required bool copyable,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (copyable)
          IconButton(
            onPressed: () => _copyToClipboard(context, value),
            icon: Icon(
              Icons.copy,
              size: 16,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            tooltip: 'Copiar',
          ),
      ],
    );
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copiado: $text'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showContactOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Opções de Contato',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            if (agencyEmail != null && agencyEmail!.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.email),
                title: const Text('Enviar E-mail'),
                subtitle: Text(agencyEmail!),
                onTap: () {
                  Navigator.pop(context);
                  _copyToClipboard(context, agencyEmail!);
                },
              ),
            
            if (agencyPhone != null && agencyPhone!.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.phone),
                title: const Text('Ligar'),
                subtitle: Text(agencyPhone!),
                onTap: () {
                  Navigator.pop(context);
                  _copyToClipboard(context, agencyPhone!);
                },
              ),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}