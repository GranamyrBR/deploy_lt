import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/agency_model.dart';
import '../providers/agency_provider.dart';

class AgencySelectionDialog extends ConsumerStatefulWidget {
  final Agency? selectedAgency;
  final Function(Agency) onAgencySelected;

  const AgencySelectionDialog({
    Key? key,
    this.selectedAgency,
    required this.onAgencySelected,
  }) : super(key: key);

  @override
  ConsumerState<AgencySelectionDialog> createState() => _AgencySelectionDialogState();
}

class _AgencySelectionDialogState extends ConsumerState<AgencySelectionDialog> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(agencyProvider);
    final agencies = state.agencies
        .where((agency) =>
            _searchQuery.isEmpty ||
            agency.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (agency.contactPerson != null && agency.contactPerson!.toLowerCase().contains(_searchQuery.toLowerCase())) ||
            (agency.cityName != null && agency.cityName!.toLowerCase().contains(_searchQuery.toLowerCase())))
        .toList();

    return AlertDialog(
      title: const Text('Selecionar Agência'),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: 600,
        ),
        child: SizedBox(
          width: double.maxFinite,
          child: Column(
          children: [
            // Search field
            TextField(
              decoration: InputDecoration(
                hintText: 'Pesquisar agência...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
            const SizedBox(height: 16),
            
            // Agency list
            Expanded(
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : agencies.isEmpty
                      ? const Center(child: Text('Nenhuma agência encontrada'))
                      : ListView.builder(
                          itemCount: agencies.length,
                          itemBuilder: (context, index) {
                            final agency = agencies[index];
                            final isSelected = widget.selectedAgency?.id == agency.id.toString();
                            return Card(
                              elevation: isSelected ? 4 : 1,
                              color: isSelected ? Theme.of(context).colorScheme.primaryContainer : null,
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Theme.of(context).colorScheme.secondary,
                                  child: Text(
                                    agency.name.substring(0, 1).toUpperCase(),
                                    style: TextStyle(color: Theme.of(context).colorScheme.onSecondary),
                                  ),
                                ),
                                title: Text(agency.displayName),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (agency.contactPerson != null) Text('Contato: ${agency.contactPerson}'),
                                    if (agency.email != null) Text(agency.email!),
                                    if (agency.phone != null) Text(agency.phone!),
                                    if (agency.cityName != null && agency.stateCode != null) Text('${agency.cityName}, ${agency.stateCode}'),
                                    if (agency.commissionRate != null) Text('Comissão: ${agency.commissionRate}%'),
                                  ],
                                ),
                                trailing: isSelected ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary) : null,
                                onTap: () {
                                  final selected = Agency(
                                    id: agency.id.toString(),
                                    name: agency.name,
                                    cnpj: agency.cnpj,
                                    email: agency.email,
                                    phone: agency.phone,
                                    address: agency.address,
                                    city: agency.cityName ?? agency.city,
                                    state: agency.stateCode ?? agency.state,
                                    cep: agency.postalCode ?? agency.zipCode,
                                    contactPerson: agency.contactPerson,
                                    commissionRate: agency.commissionRate,
                                    paymentTerms: null,
                                    isActive: agency.isActive,
                                    createdAt: agency.createdAt,
                                    updatedAt: agency.updatedAt,
                                  );
                                  widget.onAgencySelected(selected);
                                  Navigator.of(context).pop();
                                },
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton.icon(
          onPressed: () async => _showAddAgencyDialog(),
          icon: const Icon(Icons.add),
          label: const Text('Nova Agência'),
        ),
      ],
    );
  }

  void _showAddAgencyDialog() {
    final nameController = TextEditingController();
    final cnpjController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final contactPersonController = TextEditingController();
    final cityController = TextEditingController();
    final stateController = TextEditingController();
    final commissionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adicionar Nova Agência'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome da Agência *',
                  hintText: 'Nome completo da agência',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: cnpjController,
                decoration: const InputDecoration(
                  labelText: 'CNPJ',
                  hintText: '12.345.678/0001-90',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'email@exemplo.com',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Telefone',
                  hintText: '+55 11 1234-5678',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: contactPersonController,
                decoration: const InputDecoration(
                  labelText: 'Pessoa de Contato',
                  hintText: 'Nome do responsável',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: cityController,
                decoration: const InputDecoration(
                  labelText: 'Cidade',
                  hintText: 'São Paulo',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: stateController,
                decoration: const InputDecoration(
                  labelText: 'Estado',
                  hintText: 'SP',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: commissionController,
                decoration: const InputDecoration(
                  labelText: 'Taxa de Comissão (%)',
                  hintText: '15',
                ),
                keyboardType: TextInputType.number,
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
            onPressed: () async {
              if (nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Por favor, insira o nome da agência')),
                );
                return;
              }

              final commissionRate = double.tryParse(commissionController.text) ?? 0.0;

              final ok = await ref.read(agencyProvider.notifier).addAgency(
                name: nameController.text.trim(),
                email: emailController.text.trim(),
                phone: phoneController.text.trim(),
                address: null,
                cityName: cityController.text.trim(),
                stateCode: stateController.text.trim(),
                countryCode: null,
                zipCode: null,
                website: null,
                contactPerson: contactPersonController.text.trim(),
                commissionRate: commissionRate > 0 ? commissionRate : null,
              );
              if (ok) {
                final stateNow = ref.read(agencyProvider);
                final added = stateNow.agencies.last;
                final selected = Agency(
                  id: added.id.toString(),
                  name: added.name,
                  cnpj: added.cnpj,
                  email: added.email,
                  phone: added.phone,
                  address: added.address,
                  city: added.cityName ?? added.city,
                  state: added.stateCode ?? added.state,
                  cep: added.postalCode ?? added.zipCode,
                  contactPerson: added.contactPerson,
                  commissionRate: added.commissionRate,
                  paymentTerms: null,
                  isActive: added.isActive,
                  createdAt: added.createdAt,
                  updatedAt: added.updatedAt,
                );
                widget.onAgencySelected(selected);
              }
              Navigator.of(context).pop(); // Fecha dialog de adicionar
              
              // Aguarda um pouco antes de fechar o dialog de seleção
              Future.delayed(const Duration(milliseconds: 100), () {
                if (mounted) {
                  Navigator.of(context).pop(); // Fecha dialog de seleção
                }
              });
            },
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
  }
}
