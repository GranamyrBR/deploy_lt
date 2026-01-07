import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/firebase_account.dart';
import '../services/firebase_account_service.dart';
import '../widgets/base_app_bar.dart';

class FirebaseAccountsScreen extends ConsumerStatefulWidget {
  const FirebaseAccountsScreen({super.key});

  @override
  ConsumerState<FirebaseAccountsScreen> createState() => _FirebaseAccountsScreenState();
}

class _FirebaseAccountsScreenState extends ConsumerState<FirebaseAccountsScreen> {
  final FirebaseAccountService _accountService = FirebaseAccountService.instance;
  bool _isLoading = true;
  List<FirebaseAccount> _accounts = [];
  FirebaseAccount? _activeAccount;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    setState(() => _isLoading = true);
    
    try {
      await _accountService.initialize();
      setState(() {
        _accounts = _accountService.accounts;
        _activeAccount = _accountService.activeAccount;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar contas: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _setActiveAccount(String accountId) async {
    final success = await _accountService.setActiveAccount(accountId);
    
    if (success) {
      setState(() {
        _activeAccount = _accountService.activeAccount;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Conta ativa alterada com sucesso'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao alterar conta ativa'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _removeAccount(String accountId) async {
    final success = await _accountService.removeAccount(accountId);
    
    if (success) {
      await _loadAccounts();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Conta removida com sucesso'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao remover conta (conta padrão não pode ser removida)'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAddAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddAccountDialog(
        onAccountAdded: () async {
          await _loadAccounts();
        },
      ),
    );
  }

  void _showEditAccountDialog(FirebaseAccount account) {
    showDialog(
      context: context,
      builder: (context) => _EditAccountDialog(
        account: account,
        onAccountUpdated: () async {
          await _loadAccounts();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BaseAppBar(title: 'Contas Firebase'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header com informações
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.cloud,
                                color: Colors.orange[600],
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Gerenciar Contas Firebase',
                                style: Theme.of(context).textTheme.headlineSmall,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Configure múltiplas contas Firebase para alternar entre diferentes projetos.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (_activeAccount != null)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green[50],
                                border: Border.all(color: Colors.green[200]!),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: Colors.green[600],
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Conta Ativa: ${_activeAccount!.displayName}',
                                    style: TextStyle(
                                      color: Colors.green[800],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Botão para adicionar nova conta
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _showAddAccountDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('Adicionar Nova Conta'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Lista de contas
                  Expanded(
                    child: _accounts.isEmpty
                        ? const Center(
                            child: Text(
                              'Nenhuma conta configurada',
                              style: TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _accounts.length,
                            itemBuilder: (context, index) {
                              final account = _accounts[index];
                              final isActive = _activeAccount?.id == account.id;
                              
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: isActive 
                                        ? Colors.green[100] 
                                        : Colors.grey[200],
                                    child: Icon(
                                      isActive ? Icons.check : Icons.cloud,
                                      color: isActive 
                                          ? Colors.green[600] 
                                          : Colors.grey[600],
                                    ),
                                  ),
                                  title: Text(
                                    account.displayName,
                                    style: TextStyle(
                                      fontWeight: isActive 
                                          ? FontWeight.bold 
                                          : FontWeight.normal,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Projeto: ${account.projectId}'),
                                      if (account.description != null)
                                        Text(
                                          account.description!,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Botão de teste de conexão
                                      IconButton(
                                        icon: const Icon(Icons.wifi_tethering),
                                        tooltip: 'Testar Conexão',
                                        onPressed: () => _testConnection(account),
                                      ),
                                      PopupMenuButton<String>(
                                        onSelected: (value) {
                                          switch (value) {
                                            case 'activate':
                                              _setActiveAccount(account.id);
                                              break;
                                            case 'edit':
                                              _showEditAccountDialog(account);
                                              break;
                                            case 'delete':
                                              _showDeleteConfirmation(account);
                                              break;
                                          }
                                        },
                                        itemBuilder: (context) => [
                                          if (!isActive)
                                            const PopupMenuItem(
                                              value: 'activate',
                                              child: ListTile(
                                                leading: Icon(Icons.check_circle),
                                                title: Text('Ativar'),
                                                dense: true,
                                              ),
                                            ),
                                          const PopupMenuItem(
                                            value: 'edit',
                                            child: ListTile(
                                              leading: Icon(Icons.edit),
                                              title: Text('Editar'),
                                              dense: true,
                                            ),
                                          ),
                                          if (account.id != 'default')
                                            const PopupMenuItem(
                                              value: 'delete',
                                              child: ListTile(
                                                leading: Icon(Icons.delete, color: Colors.red),
                                                title: Text('Remover', style: TextStyle(color: Colors.red)),
                                                dense: true,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _testConnection(FirebaseAccount account) async {
    // Mostrar dialog de loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Testando conexão...'),
          ],
        ),
      ),
    );

    try {
       // Testar conexão com a conta Firebase
       final success = await _accountService.testAccountConnection(account);
      
      if (mounted) {
        Navigator.of(context).pop(); // Fechar dialog de loading
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success 
                  ? 'Conexão com ${account.displayName} bem-sucedida!' 
                  : 'Falha na conexão com ${account.displayName}',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Fechar dialog de loading
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao testar conexão: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDeleteConfirmation(FirebaseAccount account) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Remoção'),
        content: Text(
          'Tem certeza que deseja remover a conta "${account.displayName}"?\n\nEsta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _removeAccount(account.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
  }
}

// Dialog para adicionar nova conta
class _AddAccountDialog extends StatefulWidget {
  final VoidCallback onAccountAdded;

  const _AddAccountDialog({required this.onAccountAdded});

  @override
  State<_AddAccountDialog> createState() => _AddAccountDialogState();
}

class _AddAccountDialogState extends State<_AddAccountDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _projectIdController = TextEditingController();
  final _apiKeyController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _testConnectionUrlController = TextEditingController();
  final _searchFlightUrlController = TextEditingController();
  final _getAirportFlightsUrlController = TextEditingController();
  final _getBrazilUsaFlightsUrlController = TextEditingController();
  
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _displayNameController.dispose();
    _projectIdController.dispose();
    _apiKeyController.dispose();
    _descriptionController.dispose();
    _testConnectionUrlController.dispose();
    _searchFlightUrlController.dispose();
    _getAirportFlightsUrlController.dispose();
    _getBrazilUsaFlightsUrlController.dispose();
    super.dispose();
  }

  Future<void> _saveAccount() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final account = FirebaseAccount(
        id: _nameController.text.toLowerCase().replaceAll(' ', '_'),
        name: _nameController.text,
        displayName: _displayNameController.text,
        projectId: _projectIdController.text,
        apiKey: _apiKeyController.text,
        description: _descriptionController.text.isEmpty 
            ? null 
            : _descriptionController.text,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        testConnectionUrl: _testConnectionUrlController.text.isEmpty 
            ? null 
            : _testConnectionUrlController.text,
        searchFlightUrl: _searchFlightUrlController.text.isEmpty 
            ? null 
            : _searchFlightUrlController.text,
        getAirportFlightsUrl: _getAirportFlightsUrlController.text.isEmpty 
            ? null 
            : _getAirportFlightsUrlController.text,
        getBrazilUsaFlightsUrl: _getBrazilUsaFlightsUrlController.text.isEmpty 
            ? null 
            : _getBrazilUsaFlightsUrlController.text,
      );

      // Validar a conta antes de adicionar
      if (!FirebaseAccountService.instance.validateAccount(account)) {
        throw Exception('Configuração da conta inválida. Verifique os dados informados.');
      }

      await FirebaseAccountService.instance.addAccount(account);
      
      if (mounted) {
        Navigator.of(context).pop();
        widget.onAccountAdded();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Conta adicionada com sucesso'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao adicionar conta: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Adicionar Nova Conta Firebase'),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome da Conta *',
                    hintText: 'ex: minha-conta-firebase',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Nome é obrigatório';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _displayNameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome de Exibição *',
                    hintText: 'ex: Minha Conta Firebase',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Nome de exibição é obrigatório';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _projectIdController,
                  decoration: const InputDecoration(
                    labelText: 'Project ID *',
                    hintText: 'ex: meu-projeto-firebase',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Project ID é obrigatório';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _apiKeyController,
                  decoration: const InputDecoration(
                    labelText: 'API Key *',
                    hintText: 'Chave da API do Firebase',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'API Key é obrigatória';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Descrição',
                    hintText: 'Descrição opcional da conta',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                ExpansionTile(
                  title: const Text('URLs das Cloud Functions (Opcional)'),
                  children: [
                    TextFormField(
                      controller: _testConnectionUrlController,
                      decoration: const InputDecoration(
                        labelText: 'Test Connection URL',
                        hintText: 'URL da função de teste de conexão',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _searchFlightUrlController,
                      decoration: const InputDecoration(
                        labelText: 'Search Flight URL',
                        hintText: 'URL da função de busca de voo',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _getAirportFlightsUrlController,
                      decoration: const InputDecoration(
                        labelText: 'Get Airport Flights URL',
                        hintText: 'URL da função de voos do aeroporto',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _getBrazilUsaFlightsUrlController,
                      decoration: const InputDecoration(
                        labelText: 'Get Brazil USA Flights URL',
                        hintText: 'URL da função de voos Brasil-EUA',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveAccount,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Adicionar'),
        ),
      ],
    );
  }
}

// Dialog para editar conta existente
class _EditAccountDialog extends StatefulWidget {
  final FirebaseAccount account;
  final VoidCallback onAccountUpdated;

  const _EditAccountDialog({
    required this.account,
    required this.onAccountUpdated,
  });

  @override
  State<_EditAccountDialog> createState() => _EditAccountDialogState();
}

class _EditAccountDialogState extends State<_EditAccountDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _displayNameController;
  late final TextEditingController _projectIdController;
  late final TextEditingController _apiKeyController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _testConnectionUrlController;
  late final TextEditingController _searchFlightUrlController;
  late final TextEditingController _getAirportFlightsUrlController;
  late final TextEditingController _getBrazilUsaFlightsUrlController;
  
  bool _isLoading = false;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.account.name);
    _displayNameController = TextEditingController(text: widget.account.displayName);
    _projectIdController = TextEditingController(text: widget.account.projectId);
    _apiKeyController = TextEditingController(text: widget.account.apiKey);
    _descriptionController = TextEditingController(text: widget.account.description ?? '');
    _testConnectionUrlController = TextEditingController(text: widget.account.testConnectionUrl ?? '');
    _searchFlightUrlController = TextEditingController(text: widget.account.searchFlightUrl ?? '');
    _getAirportFlightsUrlController = TextEditingController(text: widget.account.getAirportFlightsUrl ?? '');
    _getBrazilUsaFlightsUrlController = TextEditingController(text: widget.account.getBrazilUsaFlightsUrl ?? '');
    _isActive = widget.account.isActive;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _displayNameController.dispose();
    _projectIdController.dispose();
    _apiKeyController.dispose();
    _descriptionController.dispose();
    _testConnectionUrlController.dispose();
    _searchFlightUrlController.dispose();
    _getAirportFlightsUrlController.dispose();
    _getBrazilUsaFlightsUrlController.dispose();
    super.dispose();
  }

  Future<void> _updateAccount() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final updatedAccount = widget.account.copyWith(
        name: _nameController.text,
        displayName: _displayNameController.text,
        projectId: _projectIdController.text,
        apiKey: _apiKeyController.text,
        description: _descriptionController.text.isEmpty 
            ? null 
            : _descriptionController.text,
        isActive: _isActive,
        testConnectionUrl: _testConnectionUrlController.text.isEmpty 
            ? null 
            : _testConnectionUrlController.text,
        searchFlightUrl: _searchFlightUrlController.text.isEmpty 
            ? null 
            : _searchFlightUrlController.text,
        getAirportFlightsUrl: _getAirportFlightsUrlController.text.isEmpty 
            ? null 
            : _getAirportFlightsUrlController.text,
        getBrazilUsaFlightsUrl: _getBrazilUsaFlightsUrlController.text.isEmpty 
            ? null 
            : _getBrazilUsaFlightsUrlController.text,
      );

      await FirebaseAccountService.instance.updateAccount(updatedAccount);
      
      if (mounted) {
        Navigator.of(context).pop();
        widget.onAccountUpdated();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Conta atualizada com sucesso'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar conta: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Editar ${widget.account.displayName}'),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome da Conta *',
                  ),
                  enabled: widget.account.id != 'default', // Não permitir editar nome da conta padrão
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Nome é obrigatório';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _displayNameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome de Exibição *',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Nome de exibição é obrigatório';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _projectIdController,
                  decoration: const InputDecoration(
                    labelText: 'Project ID *',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Project ID é obrigatório';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _apiKeyController,
                  decoration: const InputDecoration(
                    labelText: 'API Key *',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'API Key é obrigatória';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Descrição',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Conta Ativa'),
                  subtitle: const Text('Permitir uso desta conta'),
                  value: _isActive,
                  onChanged: (value) {
                    setState(() => _isActive = value);
                  },
                ),
                const SizedBox(height: 16),
                ExpansionTile(
                  title: const Text('URLs das Cloud Functions'),
                  children: [
                    TextFormField(
                      controller: _testConnectionUrlController,
                      decoration: const InputDecoration(
                        labelText: 'Test Connection URL',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _searchFlightUrlController,
                      decoration: const InputDecoration(
                        labelText: 'Search Flight URL',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _getAirportFlightsUrlController,
                      decoration: const InputDecoration(
                        labelText: 'Get Airport Flights URL',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _getBrazilUsaFlightsUrlController,
                      decoration: const InputDecoration(
                        labelText: 'Get Brazil USA Flights URL',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _updateAccount,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Salvar'),
        ),
      ],
    );
  }
}
