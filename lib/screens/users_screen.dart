import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../design/design_tokens.dart';
import '../utils/responsive_utils.dart';
import '../widgets/base_components.dart';
import '../providers/auth_provider.dart';
import '../models/user.dart';
import '../models/department.dart';
import '../services/auth_service.dart';
import '../widgets/base_screen_layout.dart';
import '../widgets/standard_search_bar.dart';
import '../utils/smart_search_mixin.dart';


class UsersScreen extends ConsumerStatefulWidget {
  const UsersScreen({super.key});

  @override
  UsersScreenState createState() => UsersScreenState();
}

class UsersScreenState extends ConsumerState<UsersScreen> with SmartSearchMixin {
  final AuthService _authService = AuthService();
  List<User> _user = [];
  List<Department> _department = [];
  bool _isLoading = true;
  String? _error;
  
  // Campo de busca
  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _error = null;
        });
      }

      final user = await _authService.getAllUsers();
      final department = await _authService.getAllDepartment();

      if (mounted) {
        setState(() {
          _user = user;
          _department = department;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final u = authState.user;
    final canManage = u != null && (u.hasPermission('manage_users') || u.isAdmin);
    final isMobile = ResponsiveUtils.isMobile(context);

    if (!canManage) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            const Text(
              'Acesso Negado',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Você não tem permissão para acessar esta página',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      );
    }

    return BaseScreenLayout(
      title: 'Usuários',
      actions: [
        ModernButton(
          text: 'Novo Usuário',
          onPressed: () => _showAddUserDialog(context),
          variant: ButtonVariant.primary,
          size: ButtonSize.small,
          icon: Icons.add,
        ),
      ],
      searchBar: StandardSearchBar(
        controller: _searchController,
        hintText: 'Buscar por nome, email, departamento...',
        onChanged: (value) {
          setState(() {
            _searchTerm = value.trim().toLowerCase();
          });
        },
        onClear: () {
          setState(() {
            _searchTerm = '';
          });
        },
      ),
      child: Padding(
        padding: ResponsiveUtils.getScreenPadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Conteúdo
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isMobile) {
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.people,
                color: Theme.of(context).primaryColor,
                size: 24,
              ),
              const SizedBox(width: DesignTokens.spacing8),
              Expanded(
                child: Text(
                  'Usuários',
                  style: DesignTokens.titleLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spacing12),
          SizedBox(
            width: double.infinity,
            child: ModernButton(
              text: 'Novo Usuário',
              onPressed: () => _showAddUserDialog(context),
              variant: ButtonVariant.primary,
              size: ButtonSize.small,
              icon: Icons.add,
            ),
          ),
        ],
      );
    } else {
      return Row(
        children: [
          Icon(
            Icons.people,
            color: Theme.of(context).primaryColor,
            size: 28,
          ),
          const SizedBox(width: DesignTokens.spacing8),
          Expanded(
            child: Text(
              'Gerenciamento de Usuários',
              style: DesignTokens.headlineMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: DesignTokens.spacing8),
          ModernButton(
            text: 'Novo Usuário',
            onPressed: () => _showAddUserDialog(context),
            variant: ButtonVariant.primary,
            size: ButtonSize.small,
            icon: Icons.add,
          ),
        ],
      );
    }
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: ModernLoadingSpinner(),
      );
    }

    if (_error != null) {
      return Center(
        child: ModernEmptyState(
          icon: Icons.error_outline,
          title: 'Erro ao carregar usuários',
          description: _error!,
          actionText: 'Tentar Novamente',
          onAction: _loadData,
        ),
      );
    }

    if (_user.isEmpty) {
      return const Center(
        child: ModernEmptyState(
          icon: Icons.people_outline,
          title: 'Nenhum usuário encontrado',
          description: 'Não há usuários cadastrados no sistema.',
        ),
      );
    }

    return ModernCard(
      child: ListView.builder(
        itemCount: _getFilteredUsers().length,
        itemBuilder: (context, index) {
          final user = _getFilteredUsers()[index];
          return _buildUserTile(user);
        },
      ),
    );
  }

  List<User> _getFilteredUsers() {
    if (_searchTerm.isEmpty) {
      return _user;
    }
    
    return _user.where((user) {
      // Converter User para Map para usar o mixin
      final userMap = {
        'id': user.id,
        'name': user.name,
        'email': user.email,
        'username': user.username,
        'departmentName': user.departmentName,
        'permissions': user.permissions.join(', '),
        'isActive': user.isActive,
      };
      
      return smartSearch(
        userMap, 
        _searchTerm,
        nameField: 'name',
        emailField: 'email',
        additionalFields: 'username',
      );
    }).toList();
  }

  Widget _buildUserTile(User user) {
    final isMobile = ResponsiveUtils.isMobile(context);
    
    return ListTile(
      contentPadding: ResponsiveUtils.getScreenPadding(context),
      leading: CircleAvatar(
        backgroundColor: DesignTokens.primaryBlue,
        child: Text(
          user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        user.name,
        style: DesignTokens.titleMedium.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface,
        ),
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            user.email,
            style: DesignTokens.bodyMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: DesignTokens.spacing4),
          Wrap(
            spacing: DesignTokens.spacing8,
            runSpacing: DesignTokens.spacing4,
            children: [
              ModernBadge(
                text: user.departmentName ?? 'Sem departamento',
                variant: BadgeVariant.info,
                size: BadgeSize.small,
              ),
              ModernBadge(
                text: user.isActive ? 'Ativo' : 'Inativo',
                variant: user.isActive ? BadgeVariant.success : BadgeVariant.error,
                size: BadgeSize.small,
              ),
            ],
          ),
          if (user.permissions.isNotEmpty) ...[
            const SizedBox(height: DesignTokens.spacing8),
            Wrap(
              spacing: DesignTokens.spacing4,
              runSpacing: DesignTokens.spacing4,
              children: user.permissions.take(isMobile ? 2 : 3).map((permission) {
                return ModernBadge(
                  text: permission,
                  variant: BadgeVariant.info,
                  size: BadgeSize.small,
                );
              }).toList(),
            ),
          ],
        ],
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (value) {
          switch (value) {
            case 'edit':
              _showEditUserDialog(context, user);
              break;
            case 'delete':
              _showDeleteUserDialog(context, user);
              break;
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                Icon(Icons.edit),
                SizedBox(width: 8),
                Text('Editar'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete, color: Colors.red),
                SizedBox(width: 8),
                Text('Excluir', style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddUserDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _UserDialog(
        department: _department,
        onSave: (user) async {
          try {
            await _authService.createUser(
              username: user.username,
              email: user.email,
              password: '123456', // Senha padrão
              departmentId: user.departmentId,
              phone: user.phone,
              permissions: user.permissions,
            );
            if (mounted) {
              Navigator.of(context).pop();
              _loadData();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Usuário criado com sucesso')),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Erro: ${e.toString()}')),
              );
            }
          }
        },
      ),
    );
  }

  void _showEditUserDialog(BuildContext context, User user) {
    showDialog(
      context: context,
      builder: (context) => _UserDialog(
        department: _department,
        user: user,
        onSave: (updatedUser) async {
          try {
            final updateData = {
              'username': updatedUser.username,
              'email': updatedUser.email,
              'phone': updatedUser.phone,
              'department_id': updatedUser.departmentId,
              'permissions': updatedUser.permissions,
              'is_active': updatedUser.isActive,
            };
            
            await _authService.updateUser(user.id, updateData);
            if (mounted) {
              Navigator.of(context).pop();
              _loadData();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Usuário atualizado com sucesso')),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Erro: ${e.toString()}')),
              );
            }
          }
        },
      ),
    );
  }

  void _showDeleteUserDialog(BuildContext context, User user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text('Tem certeza que deseja excluir o usuário "${user.username}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _authService.deleteUser(user.id);
                if (mounted) {
                  Navigator.of(context).pop();
                  _loadData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Usuário excluído com sucesso')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro: ${e.toString()}')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }
}

class _UserDialog extends StatefulWidget {
  final List<Department> department;
  final User? user;
  final Function(User) onSave;

  const _UserDialog({
    required this.department,
    this.user,
    required this.onSave,
  });

  @override
  _UserDialogState createState() => _UserDialogState();
}

class _UserDialogState extends State<_UserDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late String _selectedDepartmentId;
  late bool _isActive;
  late List<String> _selectedPermissions;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.user?.firstName ?? '');
    _lastNameController = TextEditingController(text: widget.user?.lastName ?? '');
    _emailController = TextEditingController(text: widget.user?.email ?? '');
    _phoneController = TextEditingController(text: widget.user?.phone ?? '');
    _selectedDepartmentId = widget.user?.departmentId ?? '1';
    _isActive = widget.user?.isActive ?? true;
    _selectedPermissions = List.from(widget.user?.permissions ?? []);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.user == null ? 'Novo Usuário' : 'Editar Usuário'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Nome é obrigatório';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(
                    labelText: 'Sobrenome',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Sobrenome é obrigatório';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Email é obrigatório';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'Email inválido';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Telefone (opcional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _selectedDepartmentId,
                  decoration: const InputDecoration(
                    labelText: 'Departamento',
                    border: OutlineInputBorder(),
                  ),
                  items: widget.department.map((dept) {
                    return DropdownMenuItem(
                      value: dept.id.toString(),
                      child: Text(dept.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedDepartmentId = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Checkbox(
                      value: _isActive,
                      onChanged: (value) {
                        setState(() {
                          _isActive = value ?? true;
                        });
                      },
                    ),
                    const Text('Usuário Ativo'),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Permissões:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _buildPermissionsCheckboxes(),
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
          onPressed: _saveUser,
          child: Text(widget.user == null ? 'Criar' : 'Salvar'),
        ),
      ],
    );
  }

  Widget _buildPermissionsCheckboxes() {
    final Map<String, List<Map<String, String>>> groups = {
      'Dashboards': [
        {'title': 'Gestão', 'perm': 'view_dashboard'},
        {'title': 'Vendedor', 'perm': 'view_own_sales'},
      ],
      'B2B': [
        {'title': 'Agências', 'perm': 'view_dashboard'},
        {'title': 'Dashboard B2B', 'perm': 'view_dashboard'},
        {'title': 'Infotravel', 'perm': 'view_dashboard'},
        {'title': 'Documentos', 'perm': 'view_dashboard'},
        {'title': 'Faturas', 'perm': 'view_invoice'},
      ],
      'CRM': [
        {'title': 'Contatos', 'perm': 'view_contact'},
        {'title': 'WhatsApp Leads', 'perm': 'view_leads'},
      ],
      'Configurações': [
        {'title': 'Contas Firebase', 'perm': 'view_dashboard'},
        {'title': 'Gerenciar Produtos', 'perm': 'view_dashboard'},
        {'title': 'Gerenciar Serviços', 'perm': 'view_dashboard'},
        {'title': 'Usuários', 'perm': 'manage_users'},
      ],
      'Financeiro': [
        {'title': 'Centro de Custos', 'perm': 'view_dashboard'},
        {'title': 'Dashboard Financeiro', 'perm': 'view_dashboard'},
      ],
      'Operações': [
        {'title': 'Carros', 'perm': 'view_driver'},
        {'title': 'Google Calendar', 'perm': 'view_calendar'},
        {'title': 'Motoristas', 'perm': 'view_driver'},
        {'title': 'Operações', 'perm': 'view_operations'},
        {'title': 'Voos', 'perm': 'view_flights'},
      ],
      'Vendas': [
        {'title': 'Nova Venda', 'perm': 'create_sale'},
        {'title': 'Vendas Realizadas', 'perm': 'view_own_sales'},
      ],
    };

    bool has(String p) => _selectedPermissions.contains(p);
    void toggle(String p, bool v) {
      if (v) {
        if (!has(p)) _selectedPermissions.add(p);
        if (p.startsWith('manage_')) {
          final base = p.substring('manage_'.length);
          final vp = 'view_$base';
          if (!has(vp)) _selectedPermissions.add(vp);
        }
      } else {
        _selectedPermissions.remove(p);
        if (p.startsWith('view_')) {
          final base = p.substring('view_'.length);
          _selectedPermissions.remove('manage_$base');
        }
      }
    }

    final roleItems = [
      {'title': 'Admin', 'perm': 'admin'},
      {'title': 'Seller', 'perm': 'seller'},
      {'title': 'Vendor', 'perm': 'vendor'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...roleItems.map((ri) => CheckboxListTile(
              title: Text(ri['title']!),
              value: has(ri['perm']!),
              onChanged: (v) {
                setState(() {
                  toggle(ri['perm']!, v ?? false);
                });
              },
              contentPadding: EdgeInsets.zero,
            )),
        const SizedBox(height: 8),
        ...groups.entries.map((entry) {
          final perms = entry.value.map((e) => e['perm']!).toSet().toList();
          final allEnabled = perms.every(has);
          return ExpansionTile(
            title: Row(
              children: [
                Checkbox(
                  value: allEnabled,
                  onChanged: (v) {
                    setState(() {
                      for (final p in perms) {
                        toggle(p, v ?? false);
                      }
                    });
                  },
                ),
                Text(entry.key),
              ],
            ),
            children: entry.value.map((item) {
              final perm = item['perm']!;
              final enabled = has(perm);
              final manage = perm.startsWith('view_');
              final managePerm = manage ? 'manage_${perm.substring(5)}' : null;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  children: [
                    CheckboxListTile(
                      title: Text(item['title']!),
                      value: enabled,
                      onChanged: (v) {
                        setState(() {
                          toggle(perm, v ?? false);
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                    if (managePerm != null)
                      CheckboxListTile(
                        title: Text('Gerenciar ${item['title']}'),
                        value: has(managePerm),
                        onChanged: (v) {
                          setState(() {
                            toggle(managePerm, v ?? false);
                          });
                        },
                        contentPadding: EdgeInsets.zero,
                      ),
                  ],
                ),
              );
            }).toList(),
          );
        }),
      ],
    );
  }

  void _saveUser() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final username = '$firstName $lastName'.trim();

    final user = User(
      id: widget.user?.id ?? '',
      username: username,
      firstName: firstName,
      lastName: lastName,
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      avatar: widget.user?.avatar,
      departmentId: _selectedDepartmentId,
      departmentName: widget.department
          .firstWhere((d) => d.id.toString() == _selectedDepartmentId)
          .name,
      permissions: _selectedPermissions,
      isActive: _isActive,
      createdAt: widget.user?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      lastLoginAt: widget.user?.lastLoginAt,
    );

    widget.onSave(user);
  }
}
