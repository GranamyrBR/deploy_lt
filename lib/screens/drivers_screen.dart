import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lecotour_dashboard/models/driver.dart';
import 'package:lecotour_dashboard/models/car.dart';
import 'package:lecotour_dashboard/providers/driver_provider.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import '../widgets/base_screen_layout.dart';
import '../widgets/standard_search_bar.dart';
import '../utils/smart_search_mixin.dart';
import '../utils/flag_utils.dart';
import 'package:flutter/foundation.dart';

class DriversScreen extends ConsumerStatefulWidget {
  const DriversScreen({super.key});

  @override
  ConsumerState<DriversScreen> createState() => _DriversScreenState();
}

class _DriversScreenState extends ConsumerState<DriversScreen> with SmartSearchMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  final _photoUrlController = TextEditingController();
  List<int> _selectedCarIds = [];
  bool _isSubmitting = false;
  
  // Campo de busca
  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = '';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _photoUrlController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Adicionar debug para verificar se a tela está sendo carregada
    print('DriversScreen: initState called');
    
    // A busca inicial é feita quando o provider é inicializado.
    // Se precisar de um refresh explícito ao entrar na tela, pode ser feito aqui:
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('DriversScreen: Post frame callback - fetching data');
      ref.read(driverProvider.notifier).fetchInitialData();
    });
  }

  void _showAddDriverDialog() {
    final driversAsync = ref.read(driverProvider);
    final isLoadingCars = driversAsync.isLoading;

    if (isLoadingCars) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Carregando lista de carros... Por favor, aguarde.')),
      );
      return;
    }

    // Reset form
    _formKey.currentState?.reset();
    _nameController.clear();
    _emailController.clear();
    _phoneController.clear();
    _cityController.clear();
    _photoUrlController.clear();
    _selectedCarIds.clear();
    _isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF2A2D3E)
              : const Color(0xFFE8F2FF),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Adicionar Novo Motorista',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
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
                      decoration: _buildModernInputDecoration('Nome *'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Nome é obrigatório';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: _buildModernInputDecoration('Email', hintText: 'exemplo@email.com'),
                      keyboardType: TextInputType.emailAddress,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9@._-]')),
                      ],
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                            return 'Email inválido';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      decoration: _buildModernInputDecoration('Telefone', hintText: '+1 (555) 123-4567'),
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        PhoneInputFormatter(
                          allowEndlessPhone: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _cityController,
                      decoration: _buildModernInputDecoration('Cidade'),
                    ),
                    const SizedBox(height: 16),
                    _buildCarSelectionWidget(ref.read(driverProvider).availableCars, setDialogState),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _photoUrlController,
                      decoration: _buildModernInputDecoration('URL da Foto', hintText: 'https://exemplo.com/foto.jpg'),
                      keyboardType: TextInputType.url,
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: _isSubmitting ? null : () async {
                if (_formKey.currentState!.validate()) {
                  setDialogState(() {
                    _isSubmitting = true;
                  });

                  final success = await ref.read(driverProvider.notifier).addDriver(
                    name: _nameController.text,
                    email: _emailController.text,
                    phone: _phoneController.text,
                    cityName: _cityController.text,
                    carIds: _selectedCarIds.isNotEmpty ? _selectedCarIds : null,
                    photoUrl: _photoUrlController.text,
                  );

                  if (success) {
                    Navigator.of(context).pop();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Motorista adicionado com sucesso!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } else {
                    setDialogState(() {
                      _isSubmitting = false;
                    });
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(ref.read(driverProvider).errorMessage ?? 'Erro ao adicionar motorista'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isSubmitting 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCarSelectionWidget(List<Car> availableCars, StateSetter setDialogState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Carros Disponíveis para Atribuir',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Container(
          height: 200,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(4),
          ),
          child: availableCars.isEmpty
              ? const Center(
                  child: Text(
                    'Nenhum carro disponível para atribuir',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  itemCount: availableCars.length,
                  itemBuilder: (context, index) {
                    final car = availableCars[index];
                    final isSelected = _selectedCarIds.contains(car.id);
                    
                    return CheckboxListTile(
                      title: Text(car.displayName),
                      subtitle: Text('${car.year} • ${car.capacity ?? 'N/A'} passageiros • WiFi: ${car.hasWifi ? "Sim" : "Não"}'),
                      value: isSelected,
                      onChanged: (bool? value) {
                        setDialogState(() {
                          if (value == true) {
                            _selectedCarIds.add(car.id);
                          } else {
                            _selectedCarIds.remove(car.id);
                          }
                        });
                      },
                    );
                  },
                ),
        ),
        if (_selectedCarIds.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            '${_selectedCarIds.length} carro(s) selecionado(s)',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ],
    );
  }

  void _showEditDriverDialog(Driver driver) {
    final car = ref.read(driverProvider).car;
    final driverCars = ref.read(driverProvider).getCarsForDriver(driver.id);
    
    // Preencher formulário com dados do driver
    _nameController.text = driver.name;
    _emailController.text = driver.email ?? '';
    _phoneController.text = driver.phone ?? '';
    _cityController.text = driver.cityName ?? '';
    _photoUrlController.text = driver.photoUrl ?? '';
    _selectedCarIds = driverCars.map((car) => car.id).toList();
    _isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF2A2D3E)
              : const Color(0xFFE8F2FF),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Editar Motorista',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
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
                      decoration: _buildModernInputDecoration('Nome *'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Nome é obrigatório';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: _buildModernInputDecoration('Email', hintText: 'exemplo@email.com'),
                      keyboardType: TextInputType.emailAddress,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9@._-]')),
                      ],
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                            return 'Email inválido';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      decoration: _buildModernInputDecoration('Telefone', hintText: '+1 (555) 123-4567'),
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        PhoneInputFormatter(
                          allowEndlessPhone: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _cityController,
                      decoration: _buildModernInputDecoration('Cidade'),
                    ),
                    const SizedBox(height: 16),
                    _buildCarSelectionWidget(ref.read(driverProvider).availableCars, setDialogState),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _photoUrlController,
                      decoration: _buildModernInputDecoration('URL da Foto', hintText: 'https://exemplo.com/foto.jpg'),
                      keyboardType: TextInputType.url,
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: _isSubmitting ? null : () async {
                if (_formKey.currentState!.validate()) {
                  setDialogState(() {
                    _isSubmitting = true;
                  });

                  final success = await ref.read(driverProvider.notifier).updateDriver(
                    driverId: driver.id,
                    name: _nameController.text,
                    email: _emailController.text,
                    phone: _phoneController.text,
                    cityName: _cityController.text,
                    carIds: _selectedCarIds,
                    photoUrl: _photoUrlController.text,
                  );

                  if (success) {
                    Navigator.of(context).pop();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Motorista atualizado com sucesso!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } else {
                    setDialogState(() {
                      _isSubmitting = false;
                    });
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(ref.read(driverProvider).errorMessage ?? 'Erro ao atualizar motorista'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isSubmitting 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Atualizar'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(Driver driver) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text('Tem certeza que deseja excluir o motorista "${driver.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              
              final success = await ref.read(driverProvider.notifier).deleteDriver(driver.id);
              
              if (success) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Motorista excluído com sucesso!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(ref.read(driverProvider).errorMessage ?? 'Erro ao excluir motorista'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final driverState = ref.watch(driverProvider);
    final drivers = driverState.drivers;

    return BaseScreenLayout(
      title: 'Motoristas',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () =>
              ref.read(driverProvider.notifier).fetchInitialData(),
          tooltip: 'Atualizar Dados',
        ),
        IconButton(
          icon: const Icon(Icons.add_circle_outline),
          onPressed: _showAddDriverDialog,
          tooltip: 'Adicionar Motorista',
        ),
      ],
      searchBar: StandardSearchBar(
        controller: _searchController,
        hintText: 'Buscar por nome, telefone, cidade...',
        onChanged: (v) {
          setState(() => _searchTerm = v.trim().toLowerCase());
        },
      ),
      child: driverState.isLoading && drivers.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : driverState.errorMessage != null && drivers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Erro: ${driverState.errorMessage}'),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () => ref
                            .read(driverProvider.notifier)
                            .fetchInitialData(),
                        child: const Text('Tentar Novamente'),
                      )
                    ],
                  ),
                )
              : drivers.isEmpty
                  ? const Center(child: Text('Nenhum motorista encontrado.'))
                  : _buildDriversList(_getFilteredDrivers(drivers), driverState.cars),
    );
  }

  Widget _buildDriversList(List<Driver> driver, List<Car> allCars) {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: driver.length,
      itemBuilder: (context, index) {
        final selectedDriver = driver[index];
        final driverCars = ref.read(driverProvider).getCarsForDriver(selectedDriver.id);

        return Card(
          key: ValueKey(selectedDriver.id),
          margin: const EdgeInsets.only(bottom: 16.0),
          elevation: 2,
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF2A2D3E) // Azul escuro para dark mode
              : const Color(0xFFE8F2FF), // Azul claro para light mode
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: CircleAvatar(
              child: selectedDriver.photoUrl == null || selectedDriver.photoUrl!.isEmpty
                  ? Text(selectedDriver.name.isNotEmpty
                      ? selectedDriver.name[0].toUpperCase()
                      : '?')
                  : null,
            ),
            title: Text(selectedDriver.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  fontFamily: 'Inter',
                )),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (selectedDriver.email != null && selectedDriver.email!.isNotEmpty)
                    Text('Email: ${_formatEmail(selectedDriver.email!)}', 
                        style: TextStyle(color: Colors.orange[700], fontSize: 14, fontFamily: 'Inter')),
                                      if (selectedDriver.phone != null && selectedDriver.phone!.isNotEmpty)
                      Row(
                        children: [
                          if (_getCountryCodeFromPhone(selectedDriver.phone!) != null)
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: Image.network(
                                FlagUtils.getFlagUrl(_getCountryCodeFromPhone(selectedDriver.phone!)!, width: 24, height: 18),
                                width: 24,
                                height: 18,
                                errorBuilder: (context, error, stackTrace) => const SizedBox(width: 24, height: 18),
                              ),
                            ),
                          Text('Telefone: ${_formatPhone(selectedDriver.phone!)}', 
                            style: TextStyle(color: Colors.orange[700], fontSize: 16, fontFamily: 'Inter')),
                        ],
                      ),
                  const SizedBox(height: 6),
                  if (driverCars.isNotEmpty) ...[
                    ...driverCars.map((car) => Padding(
                      padding: const EdgeInsets.only(left: 8.0, top: 2.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text('• ${car.make} ${car.model} (${car.year}) - ${car.licensePlate}',
                                style: TextStyle(fontSize: 14, fontFamily: 'Inter', color: Colors.orange[700])),
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove_circle, color: Colors.red, size: 16),
                            onPressed: () => _removeCarFromDriver(selectedDriver, car),
                            tooltip: 'Remover carro',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    )),
                  ] else ...[
                    const Padding(
                      padding: EdgeInsets.only(left: 8.0),
                      child: Text(
                        'Nenhum carro atribuído',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Colors.orange,
                          fontSize: 14,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    _showEditDriverDialog(selectedDriver);
                  },
                  tooltip: 'Editar motorista',
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    _showDeleteConfirmation(selectedDriver);
                  },
                  tooltip: 'Excluir motorista',
                ),
              ],
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }

  // Função auxiliar para criar decoração moderna dos campos de formulário
  InputDecoration _buildModernInputDecoration(String labelText, {String? hintText, String? suffixText}) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      suffixText: suffixText,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
      ),
      filled: true,
      fillColor: Theme.of(context).colorScheme.surface,
      labelStyle: TextStyle(color: Theme.of(context).colorScheme.primary),
      hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7)),
    );
  }

  // Função para formatar telefone
  String _formatPhone(String phone) {
    print('Formatando telefone: $phone'); // Debug
    final digits = phone.replaceAll(RegExp(r'[^\d+]'), '');
    print('Dígitos extraídos: $digits'); // Debug
    
    if (digits.startsWith('+55')) {
      // Brasil com +: +55 (11) 99999-9999 ou +55 (11) 9999-9999
      if (digits.length == 13) {
        final formatted = '+55 (${digits.substring(3, 5)}) ${digits.substring(5, 10)}-${digits.substring(10)}';
        print('Brasil +55 13 dígitos: $formatted'); // Debug
        return formatted;
      } else if (digits.length == 12) {
        final formatted = '+55 (${digits.substring(3, 5)}) ${digits.substring(5, 9)}-${digits.substring(9)}';
        print('Brasil +55 12 dígitos: $formatted'); // Debug
        return formatted;
      }
    } else if (digits.startsWith('55') && digits.length == 13) {
      // Brasil sem +: 55 (11) 99999-9999
      final formatted = '+55 (${digits.substring(2, 4)}) ${digits.substring(4, 9)}-${digits.substring(9)}';
      print('Brasil 55 13 dígitos: $formatted'); // Debug
      return formatted;
    } else if (digits.startsWith('55') && digits.length == 12) {
      // Brasil sem +: 55 (11) 9999-9999
      final formatted = '+55 (${digits.substring(2, 4)}) ${digits.substring(4, 8)}-${digits.substring(8)}';
      print('Brasil 55 12 dígitos: $formatted'); // Debug
      return formatted;
    } else if (digits.startsWith('+1') && digits.length == 12) {
      // EUA: +1 (555) 123-4567 (10 dígitos após o +1)
      final formatted = '+1 (${digits.substring(2, 5)}) ${digits.substring(5, 8)}-${digits.substring(8)}';
      print('EUA: $formatted'); // Debug
      return formatted;
         } else if (digits.startsWith('1') && digits.length == 11) {
       // EUA sem o +: 1 (555) 123-4567 (10 dígitos após o 1)
       final formatted = '1 (${digits.substring(1, 4)}) ${digits.substring(4, 7)}-${digits.substring(7)}';
       print('EUA sem +: $formatted'); // Debug
       return formatted;
     } else if (digits.length == 11) {
      // Brasil sem DDI: (11) 99999-9999
      final formatted = '(${digits.substring(0, 2)}) ${digits.substring(2, 7)}-${digits.substring(7)}';
      print('Brasil 11 dígitos sem DDI: $formatted'); // Debug
      return formatted;
    } else if (digits.length == 10) {
      // Brasil sem DDI: (11) 9999-9999
      final formatted = '(${digits.substring(0, 2)}) ${digits.substring(2, 6)}-${digits.substring(6)}';
      print('Brasil 10 dígitos sem DDI: $formatted'); // Debug
      return formatted;
    }
    // Para outros casos, retorna o número original
    print('Formato não reconhecido, retornando original: $phone'); // Debug
    return phone;
  }

  // Função para extrair o código ISO do país a partir do DDI do telefone
  String? _getCountryCodeFromPhone(String phone) {
    return FlagUtils.getCountryIsoCodeFromPhone(phone);
  }

  // Função para formatar email
  String _formatEmail(String email) {
    return email.toLowerCase();
  }

  List<Driver> _getFilteredDrivers(List<Driver> drivers) {
    if (_searchTerm.isEmpty) {
      return drivers;
    }

    return drivers.where((driver) {
      // Converter Driver para Map para usar o mixin
      final driverMap = {
        'id': driver.id,
        'name': driver.name,
        'email': driver.email,
        'phone': driver.phone,
        'cityName': driver.cityName,
      };
      
      return smartSearch(
        driverMap, 
        _searchTerm,
        nameField: 'name',
        phoneField: 'phone',
        emailField: 'email',
        cityField: 'cityName',
      );
    }).toList();
  }

  void _removeCarFromDriver(Driver driver, Car car) async {
    // Mostrar confirmação antes de remover
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover Carro'),
        content: Text('Tem certeza que deseja remover o carro ${car.make} ${car.model} (${car.licensePlate}) do motorista ${driver.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remover', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final success = await ref.read(driverProvider.notifier).removeCarFromDriver(driver.id, car.id);

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Carro ${car.make} ${car.model} removido do motorista ${driver.name}!'),
            backgroundColor: Colors.green,
          ),
        );
      }
      // Refresh the list to reflect the change
      ref.read(driverProvider.notifier).fetchInitialData();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ref.read(driverProvider).errorMessage ?? 'Erro ao remover carro do motorista'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
