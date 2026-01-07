import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/base_screen_layout.dart';
import '../models/agency.dart';
import '../models/account_employee.dart';
import '../models/account_employee_dto.dart';
import '../providers/account_employees_provider.dart';
import '../services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/department.dart';
import '../models/position.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
// TODO: Importar outros providers de ranking, métricas, oportunidades, etc.

class AgencyDetailsScreen extends ConsumerWidget {
  final Agency agency;
  const AgencyDetailsScreen({super.key, required this.agency});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employeesAsync = ref.watch(accountEmployeesProvider(agency.id));
    // TODO: Adicionar outros providers (ranking, métricas, etc.)

    return BaseScreenLayout(
      title: 'Detalhes da Agência',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'Atualizar página',
          onPressed: () {
            // Refresh all providers
            ref.invalidate(accountEmployeesProvider(agency.id));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Atualizando dados...'))
            );
          },
        ),
      ],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header com dados principais
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: agency.isActive ? Colors.green : Colors.red,
                      child: Text(
                        agency.name.isNotEmpty ? agency.name[0].toUpperCase() : '?',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24),
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(agency.name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 12,
                            runSpacing: 8,
                            children: [
                              Chip(
                                label: Text(agency.isActive ? 'Ativa' : 'Inativa'),
                                backgroundColor: agency.isActive ? Colors.green[100] : Colors.red[100],
                                labelStyle: TextStyle(color: agency.isActive ? Colors.green[900] : Colors.red[900]),
                              ),
                              if (agency.cityName != null && agency.cityName!.isNotEmpty)
                                Chip(label: Text(agency.cityName!)),
                              if (agency.commissionRate != null)
                                Chip(label: Text('Comissão: ${agency.commissionRate}%')),
                              if (agency.contactPerson != null && agency.contactPerson!.isNotEmpty)
                                Chip(label: Text('Contato: ${agency.contactPerson!}')),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              if (agency.email != null && agency.email!.isNotEmpty)
                                Row(children: [const Icon(Icons.email, size: 18), const SizedBox(width: 4), Text(agency.email!)]),
                              if (agency.phone != null && agency.phone!.isNotEmpty)
                                Row(children: [const SizedBox(width: 16), const Icon(Icons.phone, size: 18), const SizedBox(width: 4), Text(agency.phone!)]),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Dropdown para ações rápidas
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        // TODO: Implementar ações (editar, excluir, etc.)
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'edit', child: Text('Editar')),
                        const PopupMenuItem(value: 'delete', child: Text('Excluir')),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Funcionários/Representantes (Spreadsheet)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Funcionários/Contatos da Agência', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Atualizar lista',
                      onPressed: () {
                        ref.invalidate(accountEmployeesProvider(agency.id));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Atualizando lista de funcionários...'))
                        );
                      },
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.person_add),
                      label: const Text('Novo Funcionário'),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => _EmployeeFormDialog(accountId: agency.id),
                        ).then((_) {
                          // Refresh the list after dialog is closed
                          ref.invalidate(accountEmployeesProvider(agency.id));
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            employeesAsync.when(
              data: (employees) {
                // Debug print to check if employees are being fetched
                print('DEBUG: Fetched ${employees.length} employees for agency ${agency.id}');
                
                final supabase = Supabase.instance.client;
                return FutureBuilder(
                  future: Future.wait([
                    supabase.from('department').select('id, name').order('name'),
                    supabase.from('position').select('id, name, description').order('name'),
                  ]),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: Text('Carregando dados...'));
                    }
                    final departmentsMap = { for (var d in snapshot.data![0] as List) d['id']: d['name'] };
                    final positionsMap = { for (var p in snapshot.data![1] as List) p['id']: p };
                    
                    // Se não há funcionários, mostrar mensagem sem tentar atualizar automaticamente
                    if (employees.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('Nenhum funcionário cadastrado.'),
                            SizedBox(height: 8),
                            Text('Clique em "Novo Funcionário" para adicionar.', 
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      );
                    }
                    return Card(
                      color: const Color(0xFFE8F2FF),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(const Color(0xFF1E3A8A)),
                          headingTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          columns: const [
                            DataColumn(label: Text('Nome')),
                            DataColumn(label: Text('Cargo')),
                            DataColumn(label: Text('Depto.')),
                            DataColumn(label: Text('Email')),
                            DataColumn(label: Text('Telefone')),
                            DataColumn(label: Text('WhatsApp')),
                            DataColumn(label: Text('Principal')),
                            DataColumn(label: Text('Decisor')),
                            DataColumn(label: Text('Ativo')),
                            DataColumn(label: Text('Ações')),
                          ],
                          rows: employees.map((emp) => DataRow(
                            cells: [
                              DataCell(Text(emp.name)),
                              DataCell(Text(positionsMap[emp.positionId]!['name'] ?? '-')),
                              DataCell(Text(departmentsMap[emp.departmentId] ?? '-')),
                              DataCell(Text(emp.email ?? '-')),
                              DataCell(Text(emp.phone ?? '-')),
                              DataCell(Text(emp.whatsapp ?? '-')),
                              DataCell(emp.isPrimaryContact ? const Icon(Icons.check, color: Colors.green) : const SizedBox.shrink()),
                              DataCell(emp.isDecisionMaker ? const Icon(Icons.check, color: Colors.orange) : const SizedBox.shrink()),
                              DataCell(emp.isActive ? const Icon(Icons.check_circle, color: Colors.green) : const Icon(Icons.cancel, color: Colors.red)),
                              DataCell(Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Color(0xFF1E3A8A)),
                                    tooltip: 'Editar',
                                    onPressed: () async {
                                      await showDialog(
                                        context: context,
                                        builder: (context) => _EmployeeFormDialog(accountId: agency.id, employee: emp),
                                      );
                                      ref.invalidate(accountEmployeesProvider(agency.id));
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    tooltip: 'Excluir',
                                    onPressed: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Excluir Funcionário'),
                                          content: Text('Tem certeza que deseja excluir o funcionário "${emp.name}"?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.of(context).pop(false),
                                              child: const Text('Cancelar'),
                                            ),
                                            ElevatedButton(
                                              onPressed: () => Navigator.of(context).pop(true),
                                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                              child: const Text('Excluir'),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (confirm == true) {
                                        try {
                                          await ref.read(deleteAccountEmployeeProvider(emp.id).future);
                                          ref.invalidate(accountEmployeesProvider(agency.id));
                                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Funcionário excluído com sucesso!')));
                                        } catch (e) {
                                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao excluir funcionário: $e')));
                                        }
                                      }
                                    },
                                  ),
                                ],
                              )),
                            ],
                          )).toList(),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Erro ao carregar funcionários: $e'),
            ),
            const SizedBox(height: 32),
            // Ranking, métricas, oportunidades, tarefas, documentos, etc.
            // TODO: Integrar providers reais e exibir cards/sections para cada área
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ranking e Métricas', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    // Placeholder para ranking/métricas
                    Row(
                      children: [
                        Expanded(child: _buildMetricCard(context, 'Ranking', 'Gold', Icons.emoji_events)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildMetricCard(context, 'Receita Total', 'R\$ 120.000', Icons.attach_money)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildMetricCard(context, 'Operações', '42', Icons.work)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Oportunidades, tarefas, documentos, logs, etc. (placeholders)
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Oportunidades e Tarefas', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    // Placeholder para oportunidades/tarefas
                    Text('Nenhuma oportunidade ou tarefa cadastrada.', style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Documentos', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    // Placeholder para documentos
                    Text('Nenhum documento cadastrado.', style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(BuildContext context, String label, String value, IconData icon) {
    return Card(
      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary, size: 32),
            const SizedBox(height: 8),
            Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _EmployeeFormDialog extends ConsumerStatefulWidget {
  final int accountId;
  final AccountEmployee? employee;
  const _EmployeeFormDialog({required this.accountId, this.employee});

  @override
  ConsumerState<_EmployeeFormDialog> createState() => _EmployeeFormDialogState();
}

class _EmployeeFormDialogState extends ConsumerState<_EmployeeFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _whatsappController;
  bool _isPrimaryContact = false;
  bool _isDecisionMaker = false;
  bool _isActive = true;

  List<Department> _departments = [];
  List<Position> _positions = [];
  Department? _selectedDepartment;
  Position? _selectedPosition;
  bool _loadingDropdowns = true;

  @override
  void initState() {
    super.initState();
    final emp = widget.employee;
    _nameController = TextEditingController(text: emp?.name ?? '');
    _emailController = TextEditingController(text: emp?.email ?? '');
    _phoneController = TextEditingController(text: emp?.phone ?? '');
    _whatsappController = TextEditingController(text: emp?.whatsapp ?? '');
    _isPrimaryContact = emp?.isPrimaryContact ?? false;
    _isDecisionMaker = emp?.isDecisionMaker ?? false;
    _isActive = emp?.isActive ?? true;
    _fetchDropdownData(emp);
  }

  Future<void> _fetchDropdownData(AccountEmployee? emp) async {
    setState(() => _loadingDropdowns = true);
    final authService = AuthService();
    final supabase = Supabase.instance.client;
    try {
      final departments = await authService.getAllDepartment();
      final positionsRaw = await supabase.from('position').select('id, name, description').order('name');
      final positions = (positionsRaw as List).map((json) => Position.fromJson(json)).toList();
      print('DEBUG: Departamentos carregados: ${departments.map((d) => d.name).toList()}');
      print('DEBUG: Cargos carregados: ${positions.map((p) => p.name).toList()}');
      setState(() {
        _departments = departments;
        _positions = positions;
        if (emp != null) {
          _selectedDepartment = departments.firstWhereOrNull((d) => d.id == emp.departmentId);
          _selectedPosition = positions.firstWhereOrNull((p) => p.id == emp.positionId);
        } else {
          _selectedDepartment = departments.isNotEmpty ? departments.first : null;
          _selectedPosition = positions.isNotEmpty ? positions.first : null;
        }
        _loadingDropdowns = false;
      });
    } catch (e) {
      setState(() => _loadingDropdowns = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao carregar cargos/departamentos: $e')));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2A2D3E) : const Color(0xFFE8F2FF),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(widget.employee == null ? 'Novo Funcionário' : 'Editar Funcionário',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      content: SizedBox(
        width: 450, // Increased width to prevent overflow
        child: _loadingDropdowns
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'Nome'),
                        validator: (v) => v == null || v.isEmpty ? 'Informe o nome' : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<Position>(
                        initialValue: _positions.contains(_selectedPosition) ? _selectedPosition : null,
                        decoration: const InputDecoration(labelText: 'Cargo'),
                        isExpanded: true, // Prevent overflow
                        items: _positions.map((p) => DropdownMenuItem(
                          value: p,
                          child: Text(
                            p.description != null && p.description!.isNotEmpty
                              ? '${p.name} - ${p.description}'
                              : p.name,
                            overflow: TextOverflow.ellipsis, // Handle text overflow
                          ),
                        )).toList(),
                        onChanged: (v) => setState(() => _selectedPosition = v),
                        validator: (v) => v == null ? 'Selecione o cargo' : null,
                      ),
                      if (_positions.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 8.0),
                          child: Text('Nenhum cargo encontrado no banco.', style: TextStyle(color: Colors.red)),
                        ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<Department>(
                        initialValue: _departments.contains(_selectedDepartment) ? _selectedDepartment : null,
                        decoration: const InputDecoration(labelText: 'Departamento'),
                        isExpanded: true, // Prevent overflow
                        items: _departments.map((d) => DropdownMenuItem(
                          value: d,
                          child: Text(
                            d.description != null && d.description!.isNotEmpty
                              ? '${d.displayName} - ${d.description}'
                              : d.displayName,
                            overflow: TextOverflow.ellipsis, // Handle text overflow
                          ),
                        )).toList(),
                        onChanged: (v) => setState(() => _selectedDepartment = v),
                        validator: (v) => v == null ? 'Selecione o departamento' : null,
                      ),
                      if (_departments.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 8.0),
                          child: Text('Nenhum departamento encontrado no banco.', style: TextStyle(color: Colors.red)),
                        ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(labelText: 'Email'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(labelText: 'Telefone'),
                        keyboardType: TextInputType.phone,
                        inputFormatters: [PhoneInputFormatter()],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _whatsappController,
                        decoration: const InputDecoration(labelText: 'WhatsApp'),
                        keyboardType: TextInputType.phone,
                        inputFormatters: [PhoneInputFormatter()],
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        title: const Text('Contato Principal'),
                        value: _isPrimaryContact,
                        onChanged: (v) => setState(() => _isPrimaryContact = v),
                      ),
                      SwitchListTile(
                        title: const Text('Decisor'),
                        value: _isDecisionMaker,
                        onChanged: (v) => setState(() => _isDecisionMaker = v),
                      ),
                      SwitchListTile(
                        title: const Text('Ativo'),
                        value: _isActive,
                        onChanged: (v) => setState(() => _isActive = v),
                      ),
                    ],
                  ),
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _loadingDropdowns
              ? null
              : () async {
                  if (_formKey.currentState?.validate() ?? false) {
                    final isEdit = widget.employee != null;
                    
                    try {
                      if (isEdit) {
                        // For editing, use the existing employee with updated values
                        final employee = AccountEmployee(
                          id: widget.employee!.id,
                          accountId: widget.accountId,
                          name: _nameController.text.trim(),
                          positionId: _selectedPosition!.id,
                          departmentId: _selectedDepartment!.id,
                          email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
                          phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
                          whatsapp: _whatsappController.text.trim().isEmpty ? null : _whatsappController.text.trim(),
                          isPrimaryContact: _isPrimaryContact,
                          isDecisionMaker: _isDecisionMaker,
                          isActive: _isActive,
                          hierarchyLevel: _selectedPosition?.hierarchyLevel ?? 1,
                          preferredContactMethod: 'email',
                          notes: null,
                          createdAt: widget.employee!.createdAt,
                          updatedAt: DateTime.now(),
                        );
                        
                        await ref.read(updateAccountEmployeeProvider(employee).future);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Funcionário atualizado com sucesso!')));
                        Navigator.of(context).pop();
                      } else {
                        // For new employees, use the DTO that doesn't require an ID
                        final employeeDto = AccountEmployeeDto(
                          accountId: widget.accountId,
                          name: _nameController.text.trim(),
                          positionId: _selectedPosition!.id,
                          departmentId: _selectedDepartment!.id,
                          email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
                          phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
                          whatsapp: _whatsappController.text.trim().isEmpty ? null : _whatsappController.text.trim(),
                          isPrimaryContact: _isPrimaryContact,
                          isDecisionMaker: _isDecisionMaker,
                          isActive: _isActive,
                          hierarchyLevel: _selectedPosition?.hierarchyLevel ?? 1,
                          preferredContactMethod: 'email',
                          notes: null,
                          updatedAt: DateTime.now(),
                        );
                        
                        // Create a temporary employee with ID 0 for the provider
                        final tempEmployee = AccountEmployee(
                          id: 0, // Temporary ID
                          accountId: employeeDto.accountId,
                          name: employeeDto.name,
                          positionId: employeeDto.positionId,
                          departmentId: employeeDto.departmentId,
                          email: employeeDto.email,
                          phone: employeeDto.phone,
                          whatsapp: employeeDto.whatsapp,
                          isPrimaryContact: employeeDto.isPrimaryContact,
                          isDecisionMaker: employeeDto.isDecisionMaker,
                          isActive: employeeDto.isActive,
                          hierarchyLevel: employeeDto.hierarchyLevel,
                          preferredContactMethod: employeeDto.preferredContactMethod,
                          notes: employeeDto.notes,
                          createdAt: null,
                          updatedAt: employeeDto.updatedAt,
                        );
                        
                        try {
                          await ref.read(addAccountEmployeeProvider(tempEmployee).future);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Funcionário adicionado com sucesso!')));
                          Navigator.of(context).pop();
                        } catch (error) {
                          // Check for duplicate constraint error
                          if (error.toString().contains('duplicate') ||
                              error.toString().contains('account_contact_pk')) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Erro: Já existe um funcionário com essas informações. Verifique os dados e tente novamente.'),
                                backgroundColor: Colors.red,
                              )
                            );
                          } else {
                            // Handle other errors
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Erro ao adicionar funcionário: $error'),
                                backgroundColor: Colors.red,
                              )
                            );
                          }
                        }
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Erro ao salvar funcionário: $e'),
                          backgroundColor: Colors.red,
                        )
                      );
                    }
                  }
                },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

// Extensão para facilitar busca segura em listas
extension FirstWhereOrNullExtension<E> on List<E> {
  E? firstWhereOrNull(bool Function(E) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
