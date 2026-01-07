import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/contact.dart' as db;
import '../services/contacts_service.dart';
import '../models/contact.dart';

class ClientSelectionDialog extends ConsumerStatefulWidget {
  final Contact? selectedClient;
  final Function(Contact) onClientSelected;

  const ClientSelectionDialog({
    Key? key,
    this.selectedClient,
    required this.onClientSelected,
  }) : super(key: key);

  @override
  ConsumerState<ClientSelectionDialog> createState() => _ClientSelectionDialogState();
}

class _ClientSelectionDialogState extends ConsumerState<ClientSelectionDialog> {
  String _searchQuery = '';
  final ContactsService _service = ContactsService();
  bool _isLoading = false;
  List<db.Contact> _results = [];
  int _pageSize = 100;
  int _offset = 0;
  bool _hasMore = true;
  bool _loadingMore = false;

  Future<void> _fetch({bool reset = false}) async {
    setState(() {
      _isLoading = true;
      if (reset) {
        _results = [];
        _offset = 0;
        _hasMore = true;
      }
    });
    final maps = await _service.getContactsPage(limit: _pageSize, offset: _offset, search: _searchQuery.isEmpty ? null : _searchQuery);
    final page = maps.map((m) => db.Contact.fromJson(m)).toList();
    setState(() {
      _results = [..._results, ...page];
      _offset += page.length;
      _hasMore = page.length == _pageSize;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final clients = _results;

    return AlertDialog(
      title: const Text('Selecionar Cliente'),
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
                hintText: 'Pesquisar cliente...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
                if (value.trim().length >= 2) {
                  _fetch(reset: true);
                } else {
                  setState(() {
                    _results = [];
                    _offset = 0;
                    _hasMore = true;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            
            // Client list
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : clients.isEmpty
                      ? const Center(child: Text('Nenhum cliente encontrado'))
                      : Column(
                          children: [
                            Expanded(
                              child: ListView.builder(
                                itemCount: clients.length,
                                itemBuilder: (context, index) {
                                  final client = clients[index];
                                  final isSelected = widget.selectedClient?.id == client.id.toString();
                                  return Card(
                                    elevation: isSelected ? 4 : 1,
                                    color: isSelected ? Theme.of(context).colorScheme.primaryContainer : null,
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: Theme.of(context).colorScheme.primary,
                                        child: Text(
                                          (client.name ?? 'C').substring(0, 1).toUpperCase(),
                                          style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
                                        ),
                                      ),
                                      title: Text(client.name ?? 'Cliente'),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          if (client.email != null) Text(client.email!),
                                          if (client.phone != null) Text(client.phone!),
                                          if (client.city != null && client.state != null) Text('${client.city}, ${client.state}'),
                                        ],
                                      ),
                                      trailing: isSelected ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary) : null,
                                      onTap: () {
                                        widget.onClientSelected(client);
                                        Navigator.of(context).pop();
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: (!_hasMore || _loadingMore) ? null : () async {
                                    setState(() => _loadingMore = true);
                                    await _fetch();
                                    setState(() => _loadingMore = false);
                                  },
                                  icon: const Icon(Icons.more_horiz),
                                  label: Text(_hasMore ? 'Carregar mais' : 'Fim'),
                                ),
                              ],
                            ),
                          ],
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
          onPressed: () => _showAddClientDialog(),
          icon: const Icon(Icons.add),
          label: const Text('Novo Cliente'),
        ),
      ],
    );
  }

  void _showAddClientDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final cityController = TextEditingController();
    final stateController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adicionar Novo Cliente'),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
            maxWidth: 500,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome *',
                  hintText: 'Nome completo do cliente',
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
                  labelText: 'Telefone/WhatsApp',
                  hintText: '+55 11 91234-5678',
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
            ],
          ),
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
                  const SnackBar(content: Text('Por favor, insira o nome do cliente')),
                );
                return;
              }

              final created = await _service.createContact(
                name: nameController.text.trim(),
                email: emailController.text.trim(),
                phone: phoneController.text.trim(),
                city: cityController.text.trim(),
                state: stateController.text.trim(),
                country: null,
              );
              widget.onClientSelected(created);
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
