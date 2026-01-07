import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/sale.dart';
import '../models/sale_item_detail.dart';
import '../models/service.dart';
import '../models/product.dart';
import '../providers/auth_provider.dart';
import '../providers/operational_routes_provider.dart';
import '../models/operational_route.dart';
import '../widgets/base_screen_layout.dart';

class CreateOperationFromSaleScreen extends ConsumerStatefulWidget {
  final Sale sale;
  
  const CreateOperationFromSaleScreen({
    required this.sale,
    super.key,
  });

  @override
  ConsumerState<CreateOperationFromSaleScreen> createState() => _CreateOperationFromSaleScreenState();
}

class _CreateOperationFromSaleScreenState extends ConsumerState<CreateOperationFromSaleScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final _scheduledDateController = TextEditingController();
  
  List<SaleItemDetail> _saleItems = [];
  List<Service> _services = [];
  List<Product> _products = [];
  bool _isLoading = true;
  bool _isCreating = false;
  DateTime? _selectedDate;
  
  // Controlador de abas
  TabController? _tabController;
  
  // Mapas para armazenar configurações individuais de cada serviço
  final Map<int, DateTime?> _serviceDates = {};
  final Map<int, String> _serviceNotes = {};
  final Map<int, TextEditingController> _serviceDateControllers = {};
  final Map<int, TextEditingController> _serviceNoteControllers = {};
  
  // Mapas para armazenar configurações individuais de cada produto
  final Map<int, String> _productNotes = {};
  final Map<int, int> _productQuantities = {};
  
  // Listas de itens selecionados para operacionalização
  final Set<int> _selectedServices = {};
  final Set<int> _selectedProducts = {};
  
  // Controladores para campos de voo
  final _flightNumberController = TextEditingController();
  final _jfkInController = TextEditingController();
  final _airlineController = TextEditingController();
  final _gateController = TextEditingController();
  final _terminalController = TextEditingController();
  final _arrivalTimeController = TextEditingController();
  
  // Controladores para campos de transporte
  final _driverNameController = TextEditingController();
  final _carModelController = TextEditingController();
  final _pickupLocationController = TextEditingController();
  final _dropoffLocationController = TextEditingController();
  final _licensePlateController = TextEditingController();
  final _driverPhoneController = TextEditingController();
  
  // IDs selecionados para driver e car
  int? _selectedDriverId;
  int? _selectedCarId;
  
  // Lista para armazenar IDs das operações criadas (para rollback)
  final List<int> _createdOperationIds = [];
  
  // Maps para controlar o status individual de cada operação
  final Map<int, bool> _serviceOperationCreated = {}; // serviceId -> bool
  final Map<int, bool> _productOperationCreated = {}; // productId -> bool
  final Map<int, bool> _serviceOperationCreating = {}; // serviceId -> bool (loading state)
  final Map<int, bool> _productOperationCreating = {}; // productId -> bool (loading state)
  
  @override
  void initState() {
    super.initState();
    print('DEBUG: initState - Inicializando nova instância da tela');
    print('DEBUG: initState - Sale ID: ${widget.sale.id}');
    print('DEBUG: initState - Sale Contact ID: ${widget.sale.contactId}');
    print('DEBUG: initState - Sale Items Count: ${widget.sale.items.length}');
    print('DEBUG: initState - _serviceDates antes: $_serviceDates');
    print('DEBUG: initState - _serviceNotes antes: $_serviceNotes');
    print('DEBUG: initState - _selectedServices antes: $_selectedServices');
    print('DEBUG: initState - _selectedProducts antes: $_selectedProducts');
    print('DEBUG: initState - _createdOperationIds antes: $_createdOperationIds');
    
    // Garantir que os Maps estão limpos na inicialização
    _serviceDates.clear();
    _serviceNotes.clear();
    _serviceDateControllers.clear();
    _serviceNoteControllers.clear();
    _productNotes.clear();
    _productQuantities.clear();
    _selectedServices.clear();
    _selectedProducts.clear();
    _createdOperationIds.clear();
    _serviceOperationCreated.clear();
    _productOperationCreated.clear();
    _serviceOperationCreating.clear();
    _productOperationCreating.clear();
    
    print('DEBUG: initState - Maps limpos');
    print('DEBUG: initState - _serviceDates depois: $_serviceDates');
    print('DEBUG: initState - _serviceNotes depois: $_serviceNotes');
    print('DEBUG: initState - _selectedServices depois: $_selectedServices');
    print('DEBUG: initState - _selectedProducts depois: $_selectedProducts');
    print('DEBUG: initState - _createdOperationIds depois: $_createdOperationIds');
    _loadSaleItems();
  }
  
  @override
  void dispose() {
    print('DEBUG: dispose - Limpando instância da tela');
    print('DEBUG: dispose - _serviceDates antes: $_serviceDates');
    print('DEBUG: dispose - _serviceNotes antes: $_serviceNotes');
    print('DEBUG: dispose - _selectedServices antes: $_selectedServices');
    print('DEBUG: dispose - _selectedProducts antes: $_selectedProducts');
    
    _notesController.dispose();
    _scheduledDateController.dispose();
    _tabController?.dispose();
    
    // Limpar controladores individuais dos serviços
    for (final controller in _serviceDateControllers.values) {
      controller.dispose();
    }
    
    // Limpar controladores de notas dos serviços
    for (final controller in _serviceNoteControllers.values) {
      controller.dispose();
    }
    
    // Limpar Maps de dados específicos de cada operação
    _serviceDates.clear();
    _serviceNotes.clear();
    _serviceDateControllers.clear();
    _serviceNoteControllers.clear();
    _productNotes.clear();
    _productQuantities.clear();
    _selectedServices.clear();
    _selectedProducts.clear();
    _createdOperationIds.clear();
    _serviceOperationCreated.clear();
    _productOperationCreated.clear();
    _serviceOperationCreating.clear();
    _productOperationCreating.clear();
    
    print('DEBUG: dispose - Maps limpos');
    
    // Limpar controladores de voo
    _flightNumberController.dispose();
    _jfkInController.dispose();
    _airlineController.dispose();
    _gateController.dispose();
    _terminalController.dispose();
    _arrivalTimeController.dispose();
    
    // Limpar controladores de transporte
    _driverNameController.dispose();
    _carModelController.dispose();
    _pickupLocationController.dispose();
    _dropoffLocationController.dispose();
    _licensePlateController.dispose();
    _driverPhoneController.dispose();
    
    super.dispose();
  }
  
  // Função para verificar operações existentes no banco de dados
  Future<void> _checkExistingOperations() async {
    try {
      final supabase = Supabase.instance.client;
      
      // Coletar todos os sale_item_ids da venda atual
      final saleItemIds = widget.sale.items.map((item) => item.saleItemId).toList();
      
      print('DEBUG: Verificando operações existentes para sale_item_ids: $saleItemIds');
      
      // Buscar operações existentes para estes sale_item_ids com todas as informações necessárias
      final existingOperations = await supabase
          .from('operation')
          .select('sale_item_id, service_id, product_id, scheduled_date, special_instructions, customer_notes, quantity, driver_id, car_id, pickup_location, dropoff_location')
          .inFilter('sale_item_id', saleItemIds);
      
      print('DEBUG: Operações existentes encontradas: $existingOperations');
      
      // Marcar serviços e produtos como já criados e carregar suas configurações
      for (final operation in existingOperations) {
        final saleItemId = operation['sale_item_id'] as int;
        final serviceId = operation['service_id'] as int?;
        final productId = operation['product_id'] as int?;
        final scheduledDate = operation['scheduled_date'] as String?;
        final specialInstructions = operation['special_instructions'] as String?;
        final customerNotes = operation['customer_notes'] as String?;
        final quantity = operation['quantity'] as int?;
        final driverId = operation['driver_id'] as int?;
        final carId = operation['car_id'] as int?;
        final pickupLocation = operation['pickup_location'] as String?;
        final dropoffLocation = operation['dropoff_location'] as String?;
        
        // Encontrar o item da venda correspondente
        final saleItem = widget.sale.items.firstWhere(
          (item) => item.saleItemId == saleItemId,
          orElse: () => widget.sale.items.first,
        );
        
        if (serviceId != null && saleItem.serviceId == serviceId) {
          _serviceOperationCreated[serviceId] = true;
          print('DEBUG: Marcando serviço $serviceId como já criado');
          
          // Carregar configurações da operação existente
          if (scheduledDate != null) {
            try {
              _serviceDates[serviceId] = DateTime.parse(scheduledDate);
              print('DEBUG: Carregando data agendada para serviço $serviceId: $scheduledDate');
            } catch (e) {
              print('DEBUG: Erro ao parsear data: $e');
            }
          }
          
          if (specialInstructions != null && specialInstructions.isNotEmpty) {
            _serviceNotes[serviceId] = specialInstructions;
            print('DEBUG: Carregando instruções especiais para serviço $serviceId: $specialInstructions');
          }
          
          if (customerNotes != null && customerNotes.isNotEmpty) {
            if (!_serviceNoteControllers.containsKey(serviceId)) {
              _serviceNoteControllers[serviceId] = TextEditingController();
            }
            _serviceNoteControllers[serviceId]!.text = customerNotes;
            print('DEBUG: Carregando notas do cliente para serviço $serviceId: $customerNotes');
          }
          
          // Carregar informações de motorista e carro se disponíveis
          if (driverId != null) {
            _selectedDriverId = driverId;
            await _loadDriverInfo(driverId);
            print('DEBUG: Carregando driver_id: $driverId');
          }
          
          if (carId != null) {
            _selectedCarId = carId;
            await _loadCarInfo(carId);
            print('DEBUG: Carregando car_id: $carId');
          }
          
          // Carregar locais de pickup e dropoff
          if (pickupLocation != null && pickupLocation.isNotEmpty) {
            _pickupLocationController.text = pickupLocation;
            print('DEBUG: Carregando pickup location: $pickupLocation');
          }
          
          if (dropoffLocation != null && dropoffLocation.isNotEmpty) {
            _dropoffLocationController.text = dropoffLocation;
            print('DEBUG: Carregando dropoff location: $dropoffLocation');
          }
        }
        
        if (productId != null && saleItem.productId == productId) {
          _productOperationCreated[productId] = true;
          print('DEBUG: Marcando produto $productId como já criado');
          
          // Carregar quantidade do produto se disponível
          if (quantity != null) {
            _productQuantities[productId] = quantity;
            print('DEBUG: Carregando quantidade para produto $productId: $quantity');
          }
          
          if (specialInstructions != null && specialInstructions.isNotEmpty) {
            _productNotes[productId] = specialInstructions;
            print('DEBUG: Carregando notas para produto $productId: $specialInstructions');
          }
        }
      }
      
    } catch (e) {
      print('DEBUG: Erro ao verificar operações existentes: $e');
    }
  }

  Future<void> _loadSaleItems() async {
    try {
      final supabase = Supabase.instance.client;
      final services = <Service>[];
      final products = <Product>[];
      final serviceIds = <int>{};
      final productIds = <int>{};
      
      print('DEBUG: Total de itens na venda: ${widget.sale.items.length}');
      
      // Coletar todos os serviceIds e productIds dos itens
      for (final item in widget.sale.items) {
        print('DEBUG: Item - serviceId: ${item.serviceId}, productId: ${item.productId}, quantity: ${item.quantity}');
        if (item.serviceId != null) {
          serviceIds.add(item.serviceId!);
        }
        if (item.productId != null) {
          productIds.add(item.productId!);
        }
      }
      
      print('DEBUG: ServiceIds coletados: $serviceIds');
      print('DEBUG: ProductIds coletados: $productIds');
      
      // Verificar operações existentes para cada sale_item_id
      await _checkExistingOperations();
      
      // Carregar os serviços do banco de dados
      if (serviceIds.isNotEmpty) {
        final servicesResponse = await supabase
            .from('service')
            .select('*')
            .inFilter('id', serviceIds.toList());
        
        print('DEBUG: Resposta do Supabase (serviços): $servicesResponse');
        
        for (final serviceData in servicesResponse) {
          services.add(Service.fromJson(serviceData));
        }
      }
      
      // Carregar os produtos do banco de dados
      if (productIds.isNotEmpty) {
        final productsResponse = await supabase
            .from('product')
            .select('*')
            .inFilter('product_id', productIds.toList());
        
        print('DEBUG: Resposta do Supabase (produtos): $productsResponse');
        
        for (final productData in productsResponse) {
          products.add(Product.fromJson(productData));
        }
      }
      
      print('DEBUG: Serviços carregados: ${services.length}');
      for (final service in services) {
        print('DEBUG: Serviço - id: ${service.id}, name: ${service.name}');
      }
      
      print('DEBUG: Produtos carregados: ${products.length}');
      for (final product in products) {
        print('DEBUG: Produto - id: ${product.productId}, name: ${product.name}');
      }
      
      setState(() {
        _saleItems = widget.sale.items;
        _services = services;
        _products = products;
        _isLoading = false;
        
        // Inicializar controladores para cada serviço
        for (final item in _saleItems) {
          if (item.serviceId != null && !_serviceDateControllers.containsKey(item.serviceId!)) {
            _serviceDateControllers[item.serviceId!] = TextEditingController();
          }
          // Inicializar quantidades para produtos
          if (item.productId != null) {
            _productQuantities[item.productId!] = item.quantity.toInt();
          }
        }
      });
    } catch (e) {
      print('DEBUG: Erro ao carregar itens da venda: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar itens da venda: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }




  
  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      
      if (time != null) {
        setState(() {
          _selectedDate = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
          _scheduledDateController.text = 
              '${date.day}/${date.month}/${date.year} ${time.format(context)}';
        });
      }
    }
  }
  
  Future<void> _selectDateForService(int serviceId) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _serviceDates[serviceId] ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: _serviceDates[serviceId] != null 
            ? TimeOfDay.fromDateTime(_serviceDates[serviceId]!)
            : TimeOfDay.now(),
      );
      
      if (time != null) {
        final selectedDateTime = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );
        
        setState(() {
          print('DEBUG: Definindo data para serviço $serviceId: $selectedDateTime');
          _serviceDates[serviceId] = selectedDateTime;
          print('DEBUG: _serviceDates agora: $_serviceDates');
          // Atualizar o controlador correspondente
          if (_serviceDateControllers.containsKey(serviceId)) {
            _serviceDateControllers[serviceId]!.text = 
                '${selectedDateTime.day.toString().padLeft(2, '0')}/${selectedDateTime.month.toString().padLeft(2, '0')}/${selectedDateTime.year} ${selectedDateTime.hour.toString().padLeft(2, '0')}:${selectedDateTime.minute.toString().padLeft(2, '0')}';
          }
        });
      }
    }
  }
  
  void _showServiceConfigDialog(dynamic saleItem, Service service) {
    final isSelected = _selectedServices.contains(saleItem.serviceId!);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                height: MediaQuery.of(context).size.height * 0.8,
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cabeçalho
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isSelected 
                                ? [Colors.green.shade400, Colors.green.shade600]
                                : [Colors.blue.shade400, Colors.blue.shade600],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isSelected ? Icons.check_circle : Icons.flight_takeoff,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                service.name ?? 'Serviço',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${saleItem.pax} PAX • US\$ ${saleItem.totalPrice.toStringAsFixed(2)}',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Switch para selecionar/desselecionar
                        Switch(
                          value: isSelected,
                          onChanged: (value) {
                            setDialogState(() {
                              setState(() {
                                if (value) {
                                  print('DEBUG: Selecionando serviço ${saleItem.serviceId} - ${service.name}');
                                  _selectedServices.add(saleItem.serviceId!);
                                  print('DEBUG: _selectedServices agora: $_selectedServices');
                                } else {
                                  print('DEBUG: Deselecionando serviço ${saleItem.serviceId} - ${service.name}');
                                  _selectedServices.remove(saleItem.serviceId!);
                                  print('DEBUG: _selectedServices agora: $_selectedServices');
                                }
                              });
                            });
                          },
                          activeThumbColor: Colors.green,
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Conteúdo do formulário
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Seção de Data e Hora
                            _buildSectionCard(
                              'Agendamento',
                              Icons.schedule,
                              Colors.blue,
                              [
                                TextFormField(
                                  decoration: const InputDecoration(
                                    labelText: 'Data e Hora da Operação',
                                    hintText: 'Selecione a data e hora',
                                    prefixIcon: Icon(Icons.calendar_today),
                                    border: OutlineInputBorder(),
                                  ),
                                  readOnly: true,
                                  onTap: () => _selectDateForService(saleItem.serviceId!),
                                  controller: _serviceDateControllers[saleItem.serviceId!],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            
                            // Seção de Detalhes do Voo
                            _buildSectionCard(
                              'Detalhes do Voo',
                              Icons.flight,
                              Colors.orange,
                              [
                                // Resumo das informações de voo
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey[300]!),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.flight, color: Colors.orange[600]),
                                          const SizedBox(width: 8),
                                          Text(
                                            _flightNumberController.text.isEmpty 
                                                ? 'Nenhum voo selecionado'
                                                : 'Voo: ${_flightNumberController.text}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (_flightNumberController.text.isNotEmpty) ...[
                                         const SizedBox(height: 8),
                                         Text('Companhia: ${_airlineController.text}'),
                                         Text('Terminal: ${_terminalController.text}'),
                                         Text('Portão: ${_gateController.text}'),
                                         Text('Chegada: ${_arrivalTimeController.text}'),
                                       ],
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // Botão para abrir modal
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: _showFlightDetailsModal,
                                    icon: const Icon(Icons.edit),
                                    label: Text(
                                      _flightNumberController.text.isEmpty 
                                          ? 'Adicionar Detalhes do Voo'
                                          : 'Editar Detalhes do Voo',
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange[600],
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            // Seção de Transporte
                            _buildSectionCard(
                              'Transporte',
                              Icons.directions_car,
                              Colors.green,
                              [
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _driverNameController,
                                        decoration: InputDecoration(
                                          labelText: 'Driver',
                                          hintText: 'Nome do motorista',
                                          border: const OutlineInputBorder(),
                                          prefixIcon: const Icon(Icons.person),
                                          suffixIcon: IconButton(
                                            icon: const Icon(Icons.search),
                                            onPressed: _showDriverSelectionModal,
                                            tooltip: 'Buscar motorista',
                                          ),
                                        ),
                                        readOnly: true,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: TextFormField(
                                        controller: _carModelController,
                                        decoration: InputDecoration(
                                          labelText: 'Car',
                                          hintText: 'Modelo do veículo',
                                          border: const OutlineInputBorder(),
                                          prefixIcon: const Icon(Icons.directions_car),
                                          suffixIcon: IconButton(
                                            icon: const Icon(Icons.search),
                                            onPressed: _showCarSelectionModal,
                                            tooltip: 'Buscar veículo',
                                          ),
                                        ),
                                        readOnly: true,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _pickupLocationController,
                                        decoration: const InputDecoration(
                                          labelText: 'Pickup Location',
                                          hintText: 'Local de coleta',
                                          border: OutlineInputBorder(),
                                          prefixIcon: Icon(Icons.location_on),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: TextFormField(
                                        controller: _dropoffLocationController,
                                        decoration: const InputDecoration(
                                          labelText: 'Dropout',
                                          hintText: 'Local de destino',
                                          border: OutlineInputBorder(),
                                          prefixIcon: Icon(Icons.place),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _licensePlateController,
                                        decoration: const InputDecoration(
                                          labelText: 'License Plate',
                                          hintText: 'Placa do veículo',
                                          border: OutlineInputBorder(),
                                          prefixIcon: Icon(Icons.confirmation_number),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: TextFormField(
                                        controller: _driverPhoneController,
                                        decoration: const InputDecoration(
                                          labelText: 'Driver Phone',
                                          hintText: 'Telefone do motorista',
                                          border: OutlineInputBorder(),
                                          prefixIcon: Icon(Icons.phone),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            // Seção de Informações Adicionais
                            _buildSectionCard(
                              'Informações Adicionais',
                              Icons.info,
                              Colors.purple,
                              [
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        decoration: const InputDecoration(
                                          labelText: 'PAX Count',
                                          hintText: 'Número de passageiros',
                                          border: OutlineInputBorder(),
                                          prefixIcon: Icon(Icons.people),
                                        ),
                                        keyboardType: TextInputType.number,
                                        initialValue: saleItem.pax.toString(),
                                        onChanged: (value) {
                                          // Salvar valor
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: TextFormField(
                                        decoration: const InputDecoration(
                                          labelText: 'Luggage Count',
                                          hintText: 'Quantidade de bagagens',
                                          border: OutlineInputBorder(),
                                          prefixIcon: Icon(Icons.luggage),
                                        ),
                                        keyboardType: TextInputType.number,
                                        onChanged: (value) {
                                          // Salvar valor
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  decoration: const InputDecoration(
                                    labelText: 'Special Instructions',
                                    hintText: 'Instruções especiais para o motorista',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.assignment),
                                  ),
                                  maxLines: 2,
                                  onChanged: (value) {
                                    // Salvar valor
                                  },
                                ),
                                const SizedBox(height: 12),
                                Builder(
                                  builder: (context) {
                                    // Garantir que temos um controlador único para este serviço
                                    if (!_serviceNoteControllers.containsKey(saleItem.serviceId!)) {
                                      _serviceNoteControllers[saleItem.serviceId!] = TextEditingController(
                                        text: _serviceNotes[saleItem.serviceId!] ?? '',
                                      );
                                    }
                                    
                                    return TextFormField(
                                      decoration: const InputDecoration(
                                        labelText: 'Customer Notes',
                                        hintText: 'Observações do cliente',
                                        border: OutlineInputBorder(),
                                        prefixIcon: Icon(Icons.note),
                                      ),
                                      maxLines: 3,
                                      controller: _serviceNoteControllers[saleItem.serviceId!],
                                      onChanged: (value) {
                                        _serviceNotes[saleItem.serviceId!] = value;
                                      },
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                  ),
                    
                    // Botões de ação
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: BorderSide(color: Colors.grey.shade400),
                            ),
                            icon: const Icon(Icons.close),
                            label: const Text('Cancelar'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              // Salvar configurações e fechar
                              setState(() {
                                if (!isSelected) {
                                  _selectedServices.add(saleItem.serviceId!);
                                }
                              });
                              Navigator.of(context).pop();
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: isSelected ? Colors.green : Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                            icon: Icon(isSelected ? Icons.save : Icons.check_circle),
                            label: Text(isSelected ? 'Salvar Configurações' : 'Selecionar e Configurar'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }
        );
      },
    );
  }

  Widget _buildModernServiceCard(dynamic saleItem, Service service, bool isSelected) {
    return GestureDetector(
      onTap: () => _showServiceConfigDialog(saleItem, service),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        height: 95, // Altura ajustada para evitar overflow
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: isSelected 
                ? Colors.green.withValues(alpha: 0.15)
                : Colors.grey.withValues(alpha: 0.05),
              blurRadius: isSelected ? 6 : 3,
              offset: const Offset(0, 2),
              spreadRadius: isSelected ? 0.5 : 0,
            ),
          ],
          border: isSelected 
            ? Border.all(color: Colors.green, width: 1)
            : Border.all(color: Colors.grey.shade200, width: 1),
        ),
        child: Stack(
          children: [
            // Conteúdo principal do card
            Padding(
              padding: const EdgeInsets.all(6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // Header com ícone e status
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isSelected 
                              ? [Colors.green.shade400, Colors.green.shade600]
                              : [Colors.blue.shade400, Colors.blue.shade600],
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Icon(
                          isSelected ? Icons.check_circle : Icons.flight_takeoff,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.green.shade50 : Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isSelected ? Colors.green.shade200 : Colors.blue.shade200,
                          ),
                        ),
                        child: Text(
                          isSelected ? 'Configurado' : 'Pendente',
                          style: TextStyle(
                            color: isSelected ? Colors.green.shade700 : Colors.blue.shade700,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 1),
                  
                  // Nome do serviço
                  Text(
                    service.name ?? 'Serviço',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  
                  // Informações do serviço
                  Row(
                    children: [
                      _buildInfoChip(Icons.people, '${saleItem.pax} PAX', Colors.orange),
                      const SizedBox(width: 4),
                      _buildInfoChip(Icons.attach_money, 'US\$ ${saleItem.totalPrice.toStringAsFixed(2)}', Colors.green),
                    ],
                  ),
                  
                  const SizedBox(height: 2),
                  
                  // Data agendada ou botão de configurar
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                  if (_serviceDates[saleItem.serviceId!] != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.schedule, color: Colors.green.shade600, size: 14),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              '${_serviceDates[saleItem.serviceId!]!.day.toString().padLeft(2, '0')}/${_serviceDates[saleItem.serviceId!]!.month.toString().padLeft(2, '0')}/${_serviceDates[saleItem.serviceId!]!.year} ${_serviceDates[saleItem.serviceId!]!.hour.toString().padLeft(2, '0')}:${_serviceDates[saleItem.serviceId!]!.minute.toString().padLeft(2, '0')}',
                              style: TextStyle(
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Botão para criar operação individual
                    if (_serviceOperationCreated[saleItem.serviceId!] == true)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.green.shade300),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle, color: Colors.green.shade700, size: 14),
                            const SizedBox(width: 2),
                            Text(
                              'Operação Criada',
                              style: TextStyle(
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      SizedBox(
                        width: double.infinity,
                        height: 18,
                        child: ElevatedButton(
                          onPressed: _serviceOperationCreating[saleItem.serviceId!] == true
                              ? null
                              : () => _createSingleServiceOperation(saleItem.serviceId!),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          child: _serviceOperationCreating[saleItem.serviceId!] == true
                              ? const SizedBox(
                                  height: 8,
                                  width: 8,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text(
                                  'Criar Operação',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                        ),
                      ),
                  ] else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.settings, color: Colors.blue.shade600, size: 14),
                          const SizedBox(width: 2),
                          Text(
                            'Montar Operação',
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Indicador de seleção
            if (isSelected)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 2),
          Text(
            text,
            style: TextStyle(
              color: Color.fromRGBO(color.red, color.green, color.blue, 0.7),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(String title, IconData icon, Color color, List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
  
  // Método para limpar dados compartilhados entre operações
  void _clearSharedOperationData() {
    print('DEBUG: Limpando dados compartilhados entre operações');
    
    // Limpar controladores de voo
    _flightNumberController.clear();
    _airlineController.clear();
    _gateController.clear();
    _terminalController.clear();
    _arrivalTimeController.clear();
    _jfkInController.clear();
    
    // Limpar controladores de transporte
    _driverNameController.clear();
    _carModelController.clear();
    _pickupLocationController.clear();
    _dropoffLocationController.clear();
    _licensePlateController.clear();
    _driverPhoneController.clear();
    
    // Limpar IDs selecionados
    _selectedDriverId = null;
    _selectedCarId = null;
    
    print('DEBUG: Dados compartilhados limpos');
  }

  Future<void> _createSingleServiceOperation(int serviceId) async {
    // Verificar se a operação já foi criada
    if (_serviceOperationCreated[serviceId] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Esta operação já foi criada anteriormente'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    // Validar se o serviço tem data selecionada
    if (_serviceDates[serviceId] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione a data e hora para esta operação'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _serviceOperationCreating[serviceId] = true);

    try {
      final supabase = Supabase.instance.client;
      final authState = ref.read(authProvider);
      final currentUser = authState.user;

      if (currentUser == null) {
        throw Exception('Usuário não autenticado');
      }

      final saleItem = _saleItems.firstWhere(
        (item) => item.serviceId == serviceId,
      );

      // Encontrar o serviço correspondente
      final service = _services.firstWhere(
        (s) => s.id == serviceId,
        orElse: () => Service(
          id: serviceId,
          name: 'Serviço não encontrado',
          isActive: true,
        ),
      );

      final operationData = {
        'sale_id': widget.sale.id,
        'sale_item_id': saleItem.saleItemId,
        'service_id': service.id,
        'customer_id': widget.sale.contactId,
        'driver_id': _selectedDriverId,
        'car_id': _selectedCarId,
        'status': 'pending',
        'priority': 'normal',
        'scheduled_date': _serviceDates[serviceId]!.toIso8601String(),
        'pickup_location': _pickupLocationController.text.isNotEmpty ? _pickupLocationController.text : null,
        'dropoff_location': _dropoffLocationController.text.isNotEmpty ? _dropoffLocationController.text : null,
        'number_of_passengers': saleItem.pax,
        'luggage_count': 0,
        'special_instructions': _serviceNotes[serviceId]?.isNotEmpty == true ? _serviceNotes[serviceId] : null,
        'customer_notes': _serviceNoteControllers[serviceId]?.text.isNotEmpty == true ? _serviceNoteControllers[serviceId]!.text : null,
        'service_value_usd': saleItem.totalPrice,
        'driver_commission_usd': saleItem.totalPrice * 0.15,
        'driver_commission_percentage': 15.0,
        'whatsapp_message_sent': false,
        'google_calendar_event_created': false,
        'created_by_user_id': currentUser.id,
        'assigned_by_user_id': currentUser.id,
      };

      print('DEBUG: Criando operação individual para serviceId $serviceId:');
      print('DEBUG: operationData: $operationData');

      // Inserir operação e capturar o ID retornado
      final response = await supabase
          .from('operation')
          .insert(operationData)
          .select('id')
          .single();

      final operationId = response['id'] as int;
      print('DEBUG: Operação criada com ID: $operationId para serviço: $serviceId');

      if (mounted) {
        setState(() {
          _serviceOperationCreated[serviceId] = true;
          _serviceOperationCreating[serviceId] = false;
        });
        
        // Forçar uma atualização adicional após um pequeno delay
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            setState(() {});
          }
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Operação criada com sucesso! ID: $operationId'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _serviceOperationCreating[serviceId] = false);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao criar operação: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _createSingleProductOperation(int productId) async {
    // Verificar se a operação já foi criada
    if (_productOperationCreated[productId] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Esta operação já foi criada anteriormente'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    // Validar se o produto tem quantidade selecionada
    if (_productQuantities[productId] == null || _productQuantities[productId]! <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Defina a quantidade para este produto'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _productOperationCreating[productId] = true);

    try {
      final supabase = Supabase.instance.client;
      final authState = ref.read(authProvider);
      final currentUser = authState.user;

      if (currentUser == null) {
        throw Exception('Usuário não autenticado');
      }

      final saleItem = _saleItems.firstWhere(
        (item) => item.productId == productId,
      );

      // Encontrar o produto correspondente
      final product = _products.firstWhere(
        (p) => p.productId == productId,
        orElse: () => Product(
          productId: productId,
          name: 'Produto não encontrado',
          pricePerUnit: 0.0,
          taxPercentage: 0.0,
          limited: false,
          activeForSale: false,
        ),
      );

      final operationData = {
        'sale_id': widget.sale.id,
        'sale_item_id': saleItem.saleItemId,
        'product_id': product.productId,
        'customer_id': widget.sale.contactId,
        'status': 'pending',
        'priority': 'normal',
        'scheduled_date': null, // Produtos não precisam de agendamento específico
        'quantity': _productQuantities[productId],
        'product_value_usd': saleItem.totalPrice,
        'service_value_usd': 0, // Para operações de produto, service_value_usd deve ser 0
        'created_by_user_id': currentUser.id,
        'assigned_by_user_id': currentUser.id,
        'special_instructions': _productNotes[productId]?.isNotEmpty == true ? _productNotes[productId] : null,
      };

      print('DEBUG: Criando operação de produto individual para productId $productId:');
      print('DEBUG: operationData: $operationData');

      // Inserir operação na tabela operation (não product_operation)
      final response = await supabase
          .from('operation')
          .insert(operationData)
          .select('id')
          .single();

      final operationId = response['id'] as int;
      print('DEBUG: Operação de produto criada com ID: $operationId para produto: $productId');

      if (mounted) {
        setState(() {
          _productOperationCreated[productId] = true;
          _productOperationCreating[productId] = false;
        });
        
        // Forçar uma atualização adicional após um pequeno delay
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            setState(() {});
          }
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Operação de produto criada com sucesso! ID: $operationId'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _productOperationCreating[productId] = false);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao criar operação de produto: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _createOperations() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedServices.isEmpty && _selectedProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione pelo menos um item para criar operações'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    // Validar se todos os serviços selecionados têm data selecionada
    final servicesWithoutDate = _selectedServices
        .where((serviceId) => _serviceDates[serviceId] == null)
        .toList();
    
    if (servicesWithoutDate.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione a data e hora para todos os serviços selecionados'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    setState(() => _isCreating = true);
    
    try {
      final supabase = Supabase.instance.client;
      final authState = ref.read(authProvider);
      final currentUser = authState.user;
      
      if (currentUser == null) {
        throw Exception('Usuário não autenticado');
      }
      
      int operationsCreated = 0;
      _createdOperationIds.clear(); // Limpar lista de IDs de operações anteriores
      
      // Criar operações para os serviços selecionados
      for (final serviceId in _selectedServices) {
        final saleItem = _saleItems.firstWhere(
          (item) => item.serviceId == serviceId,
        );
        
        // Encontrar o serviço correspondente
        final service = _services.firstWhere(
          (s) => s.id == serviceId,
          orElse: () => Service(id: serviceId, name: 'Serviço não encontrado'),
        );
        
        final operationData = {
          'sale_id': widget.sale.id,
          'sale_item_id': saleItem.saleItemId,
          'service_id': service.id,
          'customer_id': widget.sale.contactId,
          'driver_id': _selectedDriverId,
          'car_id': _selectedCarId,
          'status': 'pending',
          'priority': 'normal',
          'scheduled_date': _serviceDates[serviceId]!.toIso8601String(),
          'pickup_location': _pickupLocationController.text.isNotEmpty ? _pickupLocationController.text : null,
          'dropoff_location': _dropoffLocationController.text.isNotEmpty ? _dropoffLocationController.text : null,
          'number_of_passengers': saleItem.pax,
          'luggage_count': 0,
          'special_instructions': _serviceNotes[serviceId]?.isNotEmpty == true ? _serviceNotes[serviceId] : null,
          'customer_notes': _serviceNoteControllers[serviceId]?.text.isNotEmpty == true ? _serviceNoteControllers[serviceId]!.text : null,
          'service_value_usd': saleItem.totalPrice,
          'driver_commission_usd': saleItem.totalPrice * 0.15,
          'driver_commission_percentage': 15.0,
          'whatsapp_message_sent': false,
          'google_calendar_event_created': false,
          'created_by_user_id': currentUser.id,
          'assigned_by_user_id': currentUser.id,
        };
        
        print('DEBUG: Dados da operação para serviceId $serviceId:');
        print('DEBUG: - sale_id: ${widget.sale.id}');
        print('DEBUG: - sale_item_id: ${saleItem.saleItemId}');
        print('DEBUG: - service_id: ${service.id}');
        print('DEBUG: - customer_id: ${widget.sale.contactId}');
        print('DEBUG: - scheduled_date: ${_serviceDates[serviceId]!.toIso8601String()}');
        print('DEBUG: - number_of_passengers: ${saleItem.pax}');
        print('DEBUG: - service_value_usd: ${saleItem.totalPrice}');
        print('DEBUG: - driver_commission_usd: ${saleItem.totalPrice * 0.15}');
        print('DEBUG: - special_instructions: ${_serviceNotes[serviceId]}');
        print('DEBUG: operationData completo: $operationData');
        
        // Inserir operação e capturar o ID retornado
        final response = await supabase
            .from('operation')
            .insert(operationData)
            .select('id')
            .single();
        
        final operationId = response['id'] as int;
        _createdOperationIds.add(operationId);
        
        print('DEBUG: Operação criada com ID: $operationId para serviço: $serviceId');
        
        operationsCreated++;
      }
      
      // Criar registros para os produtos selecionados (não são operações, mas registros de controle)
      for (final productId in _selectedProducts) {
        final saleItem = _saleItems.firstWhere(
          (item) => item.productId == productId,
        );
        
        // Aqui você pode implementar a lógica para produtos
        // Por exemplo, criar um registro de controle de estoque ou entrega
        print('Produto selecionado para controle: ${saleItem.productId} - Quantidade: ${saleItem.quantity}');
        // TODO: Implementar lógica específica para produtos se necessário
      }
      
      if (mounted) {
        String message = '';
        if (operationsCreated > 0 && _selectedProducts.isNotEmpty) {
          message = '$operationsCreated operação(ões) e ${_selectedProducts.length} produto(s) processados com sucesso!';
        } else if (operationsCreated > 0) {
          message = '$operationsCreated operação(ões) criada(s) com sucesso!';
        } else if (_selectedProducts.isNotEmpty) {
          message = '${_selectedProducts.length} produto(s) processados com sucesso!';
        }
        
        // Adicionar IDs das operações criadas para referência
        if (_createdOperationIds.isNotEmpty) {
          message += '\nIDs das operações: ${_createdOperationIds.join(', ')}';
          print('DEBUG: Operações criadas com IDs: $_createdOperationIds');
        }
        
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5), // Mais tempo para ler os IDs
          ),
        );
      }
    } catch (e) {
      setState(() => _isCreating = false);
      
      // Rollback: deletar operações já criadas em caso de erro
      if (_createdOperationIds.isNotEmpty) {
        try {
          print('DEBUG: Iniciando rollback para ${_createdOperationIds.length} operações');
          final supabase = Supabase.instance.client;
          await supabase
              .from('operation')
              .delete()
              .inFilter('id', _createdOperationIds);
          print('DEBUG: Rollback concluído com sucesso');
        } catch (rollbackError) {
          print('DEBUG: Erro durante rollback: $rollbackError');
          // Log do erro de rollback, mas não interrompe o fluxo
        }
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao criar operações: $e${_createdOperationIds.isNotEmpty ? ' (Rollback executado)' : ''}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  bool _hasSelectedServicesWithoutDate() {
    for (final serviceId in _selectedServices) {
      if (!_serviceDates.containsKey(serviceId)) {
        return true;
      }
    }
    return false;
  }
  
  // Função removida - usando a versão atualizada acima
  
  Future<void> _showProductConfigDialog(int productId) async {
    final product = _products.firstWhere(
      (p) => p.productId == productId,
      orElse: () => Product(
        productId: productId,
        name: 'Produto não encontrado',
        pricePerUnit: 0.0,
        taxPercentage: 0.0,
        limited: false,
        activeForSale: false,
      ),
    );
    
    final notesController = TextEditingController(
      text: _productNotes[productId] ?? '',
    );
    final quantityController = TextEditingController(
      text: _productQuantities[productId]?.toString() ?? '1',
    );
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Configurar ${product.name}'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Campo de Quantidade
              TextFormField(
                controller: quantityController,
                decoration: const InputDecoration(
                  labelText: 'Quantidade',
                  hintText: 'Digite a quantidade',
                  prefixIcon: Icon(Icons.numbers),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              // Campo de Observações
              TextFormField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Observações (opcional)',
                  hintText: 'Informações específicas para este produto',
                  prefixIcon: Icon(Icons.note),
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
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
            onPressed: () {
              setState(() {
                _productNotes[productId] = notesController.text;
                _productQuantities[productId] = int.tryParse(quantityController.text) ?? 1;
                _selectedProducts.add(productId);
              });
              Navigator.of(context).pop();
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    
    notesController.dispose();
    quantityController.dispose();
  }
  
  // Função para determinar a cor baseada no status de pagamento
  Color _getPaymentStatusColor() {
    final totalAmount = widget.sale.totalAmountUsd ?? 0.0;
    final totalPaid = widget.sale.totalPaidUsd ?? 0.0;
    
    if (totalPaid >= totalAmount && totalAmount > 0) {
      return Colors.green; // Pago
    } else if (totalPaid > 0 && totalPaid < totalAmount) {
      return Colors.orange; // Pagamento parcial
    } else {
      return Colors.orange; // Pendente de pagamento
    }
  }

  // Função para obter o texto do status de pagamento
  String _getPaymentStatusText() {
    final totalAmount = widget.sale.totalAmountUsd ?? 0.0;
    final totalPaid = widget.sale.totalPaidUsd ?? 0.0;
    
    if (totalPaid >= totalAmount && totalAmount > 0) {
      return 'Pago';
    } else if (totalPaid > 0 && totalPaid < totalAmount) {
      return 'Pagamento Parcial';
    } else {
      return 'Pendente de Pagamento';
    }
  }

  // Função para obter o texto do tipo de conta do cliente
  String _getAccountTypeText(int? accountTypeId) {
    switch (accountTypeId) {
      case 1:
        return 'Pessoa Física';
      case 2:
        return 'Agências';
      default:
        return 'Não informado';
    }
  }

  // Função para mostrar modal de seleção de motorista
  void _showDriverSelectionModal() async {
    final searchController = TextEditingController();
    Timer? debounceTimer;
    
    List<Map<String, dynamic>> allDrivers = [];
    List<Map<String, dynamic>> filteredDrivers = [];
    bool isLoading = true;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            
            // Carregar dados apenas uma vez
            if (isLoading && allDrivers.isEmpty) {
              _fetchDrivers().then((drivers) {
                if (mounted) {
                  setState(() {
                    allDrivers = drivers;
                    filteredDrivers = drivers;
                    isLoading = false;
                  });
                }
              }).catchError((error) {
                if (mounted) {
                  setState(() {
                    isLoading = false;
                  });
                }
              });
            }
            
            void filterDrivers(String query) {
              // Cancelar timer anterior se existir
              debounceTimer?.cancel();
              
              // Criar novo timer com debounce de 300ms
              debounceTimer = Timer(const Duration(milliseconds: 300), () {
                if (mounted) {
                  setState(() {
                    if (query.isEmpty) {
                      filteredDrivers = allDrivers;
                    } else {
                      final searchLower = query.toLowerCase();
                      filteredDrivers = allDrivers.where((driver) {
                        final name = (driver['name'] ?? '').toString().toLowerCase();
                        final phone = (driver['phone'] ?? '').toString().toLowerCase();
                        final city = (driver['city_name'] ?? '').toString().toLowerCase();
                        
                        return name.contains(searchLower) ||
                               phone.contains(searchLower) ||
                               city.contains(searchLower);
                      }).toList();
                    }
                  });
                }
              });
            }
            
            return AlertDialog(
              title: const Text('Selecionar Motorista'),
              content: SizedBox(
                width: double.maxFinite,
                height: 450,
                child: Column(
                  children: [
                    // Campo de busca
                    TextField(
                      controller: searchController,
                      decoration: const InputDecoration(
                        hintText: 'Buscar motorista...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: filterDrivers,
                      autofocus: true,
                    ),
                    const SizedBox(height: 16),
                    // Lista de motoristas
                    Expanded(
                      child: isLoading
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(),
                                  SizedBox(height: 16),
                                  Text('Carregando motoristas...'),
                                ],
                              ),
                            )
                          : filteredDrivers.isEmpty
                              ? const Center(child: Text('Nenhum motorista encontrado'))
                              : ListView.builder(
                                  itemCount: filteredDrivers.length,
                                  itemBuilder: (context, index) {
                                    final driver = filteredDrivers[index];
                                    return ListTile(
                                      leading: const Icon(Icons.person),
                                      title: Text(driver['name'] ?? 'Nome não informado'),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          if (driver['phone'] != null)
                                            Text('Telefone: ${driver['phone']}'),
                                          if (driver['city_name'] != null)
                                            Text('Cidade: ${driver['city_name']}'),
                                        ],
                                      ),
                                      onTap: () {
                                        _selectDriver(driver);
                                        Navigator.of(context).pop();
                                      },
                                    );
                                  },
                                ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    searchController.dispose();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancelar'),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      // Garantir que o controller seja descartado quando o dialog for fechado
      searchController.dispose();
    });
  }

  // Função para mostrar modal de seleção de carro
  void _showCarSelectionModal() async {
    final cars = await _fetchCars();
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Selecionar Veículo'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: cars.isEmpty
                ? const Center(child: Text('Nenhum veículo encontrado'))
                : ListView.builder(
                    itemCount: cars.length,
                    itemBuilder: (context, index) {
                      final car = cars[index];
                      return ListTile(
                        leading: const Icon(Icons.directions_car),
                        title: Text('${car['make']} ${car['model']} (${car['year']})'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (car['license_plate'] != null)
                              Text('Placa: ${car['license_plate']}'),
                            if (car['capacity'] != null)
                              Text('Capacidade: ${car['capacity']} passageiros'),
                            Text('WiFi: ${car['has_wifi'] == true ? 'Sim' : 'Não'}'),
                          ],
                        ),
                        onTap: () {
                          _selectCar(car);
                          Navigator.of(context).pop();
                        },
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }

  // Função para buscar motoristas do Supabase
  Future<List<Map<String, dynamic>>> _fetchDrivers() async {
    try {
      print('DEBUG: Iniciando busca de motoristas...');
      final response = await Supabase.instance.client
          .from('driver')
          .select('id, name, phone, city_name, email')
          .order('name');
      print('DEBUG: Motoristas encontrados: ${response.length}');
      if (response.isNotEmpty) {
        print('DEBUG: Primeiro motorista: ${response.first}');
      }
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Erro ao buscar motoristas: $e');
      return [];
    }
  }

  // Função para buscar carros do Supabase
  Future<List<Map<String, dynamic>>> _fetchCars() async {
    try {
      final response = await Supabase.instance.client
          .from('car')
          .select('id, make, model, year, license_plate, capacity, has_wifi')
          .order('make, model');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Erro ao buscar carros: $e');
      return [];
    }
  }

  // Função para carregar informações do motorista
  Future<void> _loadDriverInfo(int driverId) async {
    try {
      final supabase = Supabase.instance.client;
      final driverResponse = await supabase
          .from('driver')
          .select('name, phone')
          .eq('id', driverId)
          .single();
      
      setState(() {
        _driverNameController.text = driverResponse['name'] ?? '';
        _driverPhoneController.text = driverResponse['phone'] ?? '';
      });
      
      print('DEBUG: Informações do motorista carregadas: ${driverResponse['name']}');
    } catch (e) {
      print('DEBUG: Erro ao carregar informações do motorista: $e');
    }
  }
  
  // Função para carregar informações do carro
  Future<void> _loadCarInfo(int carId) async {
    try {
      final supabase = Supabase.instance.client;
      final carResponse = await supabase
          .from('car')
          .select('make, model, year, license_plate')
          .eq('id', carId)
          .single();
      
      setState(() {
        _carModelController.text = '${carResponse['make']} ${carResponse['model']} (${carResponse['year']})';
        _licensePlateController.text = carResponse['license_plate'] ?? '';
      });
      
      print('DEBUG: Informações do carro carregadas: ${carResponse['make']} ${carResponse['model']}');
    } catch (e) {
      print('DEBUG: Erro ao carregar informações do carro: $e');
    }
  }

  // Função para selecionar motorista
  void _selectDriver(Map<String, dynamic> driver) async {
    setState(() {
      _selectedDriverId = driver['id'];
      _driverNameController.text = driver['name'] ?? '';
      _driverPhoneController.text = driver['phone'] ?? '';
    });
    
    // Buscar carro atribuído ao motorista
    await _loadDriverCar(driver['id']);
  }
  
  // Função para carregar carro atribuído ao motorista
  Future<void> _loadDriverCar(int driverId) async {
    try {
      final response = await Supabase.instance.client
          .from('driver_car')
          .select('car_id, car(id, make, model, year, license_plate, capacity, has_wifi)')
          .eq('driver_id', driverId)
          .eq('is_active', true)
          .single();
      
      if (response['car'] != null) {
        final car = response['car'];
        setState(() {
          _selectedCarId = car['id'];
          _carModelController.text = '${car['make']} ${car['model']} (${car['year']})';
          _licensePlateController.text = car['license_plate'] ?? '';
        });
      }
    } catch (e) {
      // Motorista não tem carro atribuído ou erro na consulta
      print('Motorista não tem carro atribuído: $e');
    }
  }

  // Função para selecionar carro
  void _selectCar(Map<String, dynamic> car) {
    setState(() {
      _selectedCarId = car['id'];
      _carModelController.text = '${car['make']} ${car['model']} (${car['year']})';
      _licensePlateController.text = car['license_plate'] ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final paymentStatusColor = _getPaymentStatusColor();
    
    return BaseScreenLayout(
      title: 'Criar Operação da Venda #${widget.sale.id}',
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Informações da Venda
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: paymentStatusColor,
                          width: 2,
                        ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                            colors: [
                              paymentStatusColor.withValues(alpha: 0.1),
                              Colors.white,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: paymentStatusColor.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.receipt_long,
                                      color: paymentStatusColor,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Informações da Venda',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: paymentStatusColor,
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: paymentStatusColor,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      _getPaymentStatusText(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Cliente: ${widget.sale.contactName}'),
                                        Text('Telefone: ${widget.sale.contactPhone}'),
                                        if (widget.sale.contactEmail?.isNotEmpty == true)
                                          Text('Email: ${widget.sale.contactEmail}'),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                                          ),
                                          child: Text(
                                            'Tipo de Conta: ${_getAccountTypeText(widget.sale.contactAccountTypeId)}',
                                            style: TextStyle(
                                              color: Colors.blue[700],
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.purple.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
                                          ),
                                          child: Text(
                                            'Total: US\$ ${widget.sale.totalAmountUsd.toStringAsFixed(2) ?? '0.00'}',
                                            style: TextStyle(
                                              color: Colors.purple[700],
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.green.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                                          ),
                                          child: Text(
                                            'Pago: US\$ ${widget.sale.totalPaidUsd.toStringAsFixed(2) ?? '0.00'}',
                                            style: TextStyle(
                                              color: Colors.green[700],
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                                          ),
                                          child: Text(
                                            'Pendente: US\$ ${((widget.sale.totalAmountUsd ?? 0.0) - (widget.sale.totalPaidUsd ?? 0.0)).toStringAsFixed(2)}',
                                            style: TextStyle(
                                              color: Colors.orange[700],
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text('Status: ${widget.sale.status}'),
                                        Text('Vendedor: ${widget.sale.sellerName}'),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Serviços da Venda
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Serviços para Operação',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            if (_saleItems.where((item) => item.serviceId != null).isNotEmpty)
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    final serviceItems = _saleItems.where((item) => item.serviceId != null);
                                    if (_selectedServices.length == serviceItems.length) {
                                      _selectedServices.clear();
                                    } else {
                                      _selectedServices.addAll(serviceItems.map((item) => item.serviceId!));
                                    }
                                  });
                                },
                                child: Text(_selectedServices.length == _saleItems.where((item) => item.serviceId != null).length ? 'Desmarcar Todos' : 'Selecionar Todos'),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (_services.isEmpty)
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Center(
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      size: 48,
                                      color: Colors.orange[300],
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Esta venda não possui serviços para criar operações.',
                                      style: TextStyle(color: Colors.orange, fontSize: 16),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        else
                          // Grid de Cards de Serviços - Layout Moderno
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final crossAxisCount = constraints.maxWidth > 1200 ? 4 : 
                                                   constraints.maxWidth > 800 ? 3 : 2;
                              return GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: 2.5,
                                ),
                                itemCount: _saleItems.where((item) => item.serviceId != null).length,
                                itemBuilder: (context, index) {
                                  final saleItem = _saleItems.where((item) => item.serviceId != null).elementAt(index);
                                  final service = _services.firstWhere(
                                    (s) => s.id == saleItem.serviceId,
                                    orElse: () => Service(id: saleItem.serviceId!, name: 'Serviço não encontrado'),
                                  );
                                  final isSelected = _selectedServices.contains(saleItem.serviceId!);
                                  
                                  return _buildModernServiceCard(saleItem, service, isSelected);
                                },
                              );
                            },
                          ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Produtos da Venda
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Produtos da Venda',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const Spacer(),
                                if (_saleItems.where((item) => item.productId != null).isNotEmpty)
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        final productItems = _saleItems.where((item) => item.productId != null);
                                        if (_selectedProducts.length == productItems.length) {
                                          _selectedProducts.clear();
                                        } else {
                                          _selectedProducts.addAll(productItems.map((item) => item.productId!));
                                        }
                                      });
                                    },
                                    child: Text(_selectedProducts.length == _saleItems.where((item) => item.productId != null).length ? 'Desmarcar Todos' : 'Selecionar Todos'),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (_products.isEmpty)
                              const Text(
                                'Esta venda não possui produtos.',
                                style: TextStyle(color: Colors.grey),
                              )
                            else
                              ..._saleItems.where((item) => item.productId != null).map((saleItem) {
                                // Encontrar o produto correspondente
                                final product = _products.firstWhere(
                                  (p) => p.productId == saleItem.productId,
                                  orElse: () => Product(
                                    productId: saleItem.productId!,
                                    name: 'Produto não encontrado',
                                    pricePerUnit: 0.0,
                                    taxPercentage: 0.0,
                                    limited: false,
                                    activeForSale: false,
                                  ),
                                );
                                
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Cabeçalho do Produto
                                        Row(
                                          children: [
                                            Checkbox(
                                              value: _selectedProducts.contains(saleItem.productId!),
                                              onChanged: (bool? value) {
                                                setState(() {
                                                  if (value == true) {
                                                    _selectedProducts.add(saleItem.productId!);
                                                  } else {
                                                    _selectedProducts.remove(saleItem.productId!);
                                                  }
                                                });
                                              },
                                            ),
                                            const Icon(Icons.inventory, color: Colors.purple),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                product.name,
                                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        
                                        // Informações do Produto
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[50],
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.grey[200]!),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              // Informações básicas
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          'Quantidade: ${saleItem.quantity}',
                                                          style: const TextStyle(fontWeight: FontWeight.w600),
                                                        ),
                                                        const SizedBox(height: 4),
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                          decoration: BoxDecoration(
                                                            color: Colors.purple.withValues(alpha: 0.1),
                                                            borderRadius: BorderRadius.circular(6),
                                                            border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
                                                          ),
                                                          child: Text(
                                                            'Total: US\$ ${saleItem.totalPrice.toStringAsFixed(2)}',
                                                            style: TextStyle(
                                                              color: Colors.purple[700],
                                                              fontWeight: FontWeight.bold,
                                                              fontSize: 13,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  // Categoria do produto
                                                  if (product.category != null) ...
                                                  [
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                      decoration: BoxDecoration(
                                                        color: Colors.blue.withValues(alpha: 0.1),
                                                        borderRadius: BorderRadius.circular(6),
                                                        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                                                      ),
                                                      child: Text(
                                                        product.category!,
                                                        style: TextStyle(
                                                          color: Colors.blue[700],
                                                          fontWeight: FontWeight.w600,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              
                                              // Informações de preço detalhadas
                                              Container(
                                                padding: const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: Border.all(color: Colors.grey[300]!),
                                                ),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Detalhes de Preço',
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.grey[700],
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 6),
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          child: Text(
                                                            'Preço unitário: US\$ ${product.pricePerUnit.toStringAsFixed(2)}',
                                                            style: const TextStyle(fontSize: 12),
                                                          ),
                                                        ),
                                                        if (product.taxPercentage > 0) ...
                                                        [
                                                          Container(
                                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                            decoration: BoxDecoration(
                                                              color: Colors.orange.withValues(alpha: 0.1),
                                                              borderRadius: BorderRadius.circular(4),
                                                            ),
                                                            child: Text(
                                                              'Taxa: ${product.taxPercentage.toStringAsFixed(1)}%',
                                                              style: TextStyle(
                                                                color: Colors.orange[700],
                                                                fontSize: 11,
                                                                fontWeight: FontWeight.w600,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ],
                                                    ),
                                                    
                                                    // Informações de desconto e sobretaxa se disponíveis
                                                    if (saleItem.discount > 0 || saleItem.surcharge > 0)
                                                      Column(
                                                        children: [
                                                          const SizedBox(height: 4),
                                                          Row(
                                                            children: [
                                                              if (saleItem.discount > 0)
                                                                Container(
                                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                                  decoration: BoxDecoration(
                                                                    color: Colors.green.withValues(alpha: 0.1),
                                                                    borderRadius: BorderRadius.circular(4),
                                                                  ),
                                                                  child: Text(
                                                                    'Desconto: ${saleItem.discount.toStringAsFixed(1)}%',
                                                                    style: TextStyle(
                                                                      color: Colors.green[700],
                                                                      fontSize: 11,
                                                                      fontWeight: FontWeight.w600,
                                                                    ),
                                                                  ),
                                                                ),
                                                              if (saleItem.discount > 0 && saleItem.surcharge > 0)
                                                                const SizedBox(width: 6),
                                                              if (saleItem.surcharge > 0)
                                                                Container(
                                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                                  decoration: BoxDecoration(
                                                                    color: Colors.red.withValues(alpha: 0.1),
                                                                    borderRadius: BorderRadius.circular(4),
                                                                  ),
                                                                  child: Text(
                                                                    'Sobretaxa: ${saleItem.surcharge.toStringAsFixed(1)}%',
                                                                    style: TextStyle(
                                                                      color: Colors.red[700],
                                                                      fontSize: 11,
                                                                      fontWeight: FontWeight.w600,
                                                                    ),
                                                                  ),
                                                                ),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                  ],
                                                ),
                                              ),
                                              
                                              // Descrição se disponível
                                              if (saleItem.itemDescription != null && saleItem.itemDescription!.isNotEmpty)
                                                Column(
                                                  children: [
                                                    const SizedBox(height: 8),
                                                Container(
                                                  padding: const EdgeInsets.all(8),
                                                  decoration: BoxDecoration(
                                                    color: Colors.amber.withValues(alpha: 0.05),
                                                    borderRadius: BorderRadius.circular(6),
                                                    border: Border.all(color: Colors.amber.withValues(alpha: 0.2)),
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        'Descrição',
                                                        style: TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                          color: Colors.amber[700],
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        saleItem.itemDescription!,
                                                        style: const TextStyle(fontSize: 12),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                  ],
                                                ),
                                            ],
                                          ),
                                        ),
                                        
                                        // Configurações do Produto (apenas se selecionado)
                                        if (_selectedProducts.contains(saleItem.productId!))
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.purple.withValues(alpha: 0.05),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: Colors.purple.withValues(alpha: 0.2)),
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Configurações do Produto',
                                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.purple,
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                TextFormField(
                                                  decoration: const InputDecoration(
                                                    labelText: 'Observações (opcional)',
                                                    hintText: 'Informações específicas para este produto',
                                                    prefixIcon: Icon(Icons.note),
                                                    border: OutlineInputBorder(),
                                                  ),
                                                  maxLines: 2,
                                                  onChanged: (value) {
                                                    _productNotes[saleItem.productId!] = value;
                                                  },
                                                  controller: TextEditingController(
                                                    text: _productNotes[saleItem.productId!] ?? '',
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                
                                                // Botão para criar operação individual de produto
                                                if (_productOperationCreated[saleItem.productId!] == true)
                                                  Container(
                                                    width: double.infinity,
                                                    padding: const EdgeInsets.all(6),
                                                    decoration: BoxDecoration(
                                                      color: Colors.purple.shade100,
                                                      borderRadius: BorderRadius.circular(6),
                                                      border: Border.all(color: Colors.purple.shade300),
                                                    ),
                                                    child: Row(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      children: [
                                                        Icon(Icons.check_circle, color: Colors.purple.shade700, size: 12),
                                                        const SizedBox(width: 4),
                                                        Text(
                                                          'Operação de Produto Criada',
                                                          style: TextStyle(
                                                            color: Colors.purple.shade700,
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 10,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  )
                                                else
                                                  SizedBox(
                                                    width: double.infinity,
                                                    child: ElevatedButton(
                                                      onPressed: _productOperationCreating[saleItem.productId!] == true
                                                          ? null
                                                          : () => _createSingleProductOperation(saleItem.productId!),
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor: Colors.purple,
                                                        foregroundColor: Colors.white,
                                                        padding: const EdgeInsets.symmetric(vertical: 6),
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius: BorderRadius.circular(6),
                                                        ),
                                                      ),
                                                      child: _productOperationCreating[saleItem.productId!] == true
                                                          ? const SizedBox(
                                                              height: 12,
                                                              width: 12,
                                                              child: CircularProgressIndicator(
                                                                strokeWidth: 2,
                                                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                              ),
                                                            )
                                                          : const Text(
                                                              'Criar Operação de Produto',
                                                              style: TextStyle(
                                                                fontWeight: FontWeight.bold,
                                                                fontSize: 12,
                                                              ),
                                                            ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  // Função para buscar informações de voo automaticamente
  Future<void> _searchFlightInfo(String flightNumber) async {
    if (flightNumber.isEmpty) return;
    
    try {
      // Busca simplificada - dados serão preenchidos via modal de rotas operacionais
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Use o botão "Buscar Voos Brasil-EUA" para selecionar um voo.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
      
      // Código removido - agora usa rotas operacionais catalogadas
      if (false) {
        setState(() {
          _airlineController.text = '';
          _gateController.text = '';
          _terminalController.text = '';
          _arrivalTimeController.text = '';
        });
      }
    } catch (e) {
      // Tratar erro silenciosamente ou mostrar snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao buscar informações do voo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Modal de detalhes de voo
  void _showFlightDetailsModal() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detalhes do Voo'),
        content: SizedBox(
          width: 600,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Botões para buscar voos Brasil-EUA e adicionar manualmente
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _showBrazilUsaFlightsModal,
                      icon: const Icon(Icons.flight_takeoff),
                      label: const Text('Buscar Voos Brasil-EUA'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _showManualFlightEntryModal,
                      icon: const Icon(Icons.add),
                      label: const Text('Adicionar Manualmente'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              const Divider(),
              const SizedBox(height: 8),
              
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _jfkInController,
                      decoration: const InputDecoration(
                        labelText: 'JFK IN',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.flight_land),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _flightNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Flight',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.flight),
                        hintText: 'Ex: AA123',
                      ),
                      onChanged: (value) {
                        if (value.length >= 3) {
                          _searchFlightInfo(value);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _gateController,
                      decoration: const InputDecoration(
                        labelText: 'Gate',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.door_front_door),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _terminalController,
                      decoration: const InputDecoration(
                        labelText: 'Terminal',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.business),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _airlineController,
                      decoration: const InputDecoration(
                        labelText: 'Airline',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.airplanemode_active),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _arrivalTimeController,
                      decoration: const InputDecoration(
                        labelText: 'Arrival Time',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.schedule),
                        hintText: 'HH:MM',
                      ),
                    ),
                  ),
                ],
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
            onPressed: () {
              Navigator.of(context).pop();
              // Aqui você pode adicionar lógica adicional se necessário
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  // Modal para mostrar voos Brasil-EUA
  void _showBrazilUsaFlightsModal() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Voos Brasil-EUA'),
        content: SizedBox(
          width: 800,
          height: 600,
          child: Consumer(
            builder: (context, ref, child) {
              final routesAsync = ref.watch(filteredOperationalRoutesProvider(
                OperationalRouteFilters(),
              ));
              
              return routesAsync.when(
                data: (routes) {
                  if (routes.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.flight_takeoff, color: Colors.grey, size: 48),
                          SizedBox(height: 16),
                          Text('Nenhuma rota operacional encontrada'),
                        ],
                      ),
                    );
                  }
                  
                  return ListView.builder(
                    itemCount: routes.length,
                    itemBuilder: (context, index) {
                      final route = routes[index];
                      
                      // Determinar se é voo chegando do Brasil ou saindo para o Brasil
                      final isArrivalFromBrazil = route.origem.toUpperCase().contains('BR') || 
                                                  route.origem.toUpperCase().contains('GRU') ||
                                                  route.origem.toUpperCase().contains('GIG') ||
                                                  route.origem.toUpperCase().contains('BSB') ||
                                                  route.origem.toUpperCase().contains('CGH') ||
                                                  route.origem.toUpperCase().contains('SDU');
                      
                      // Cores e ícones baseados na direção do voo
                      final cardColor = isArrivalFromBrazil ? Colors.green[50] : Colors.blue[50];
                      final borderColor = isArrivalFromBrazil ? Colors.green[300] : Colors.blue[300];
                      final iconColor = isArrivalFromBrazil ? Colors.green[700] : Colors.blue[700];
                      final flightIcon = isArrivalFromBrazil ? Icons.flight_land : Icons.flight_takeoff;
                      final directionText = isArrivalFromBrazil ? 'Chegando do Brasil' : 'Saindo para o Brasil';
                      
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        color: cardColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: borderColor!, width: 1),
                        ),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: iconColor!.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              flightIcon,
                              color: iconColor,
                              size: 24,
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${route.voo} - ${route.nomeCia}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: iconColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: iconColor.withValues(alpha: 0.3)),
                                ),
                                child: Text(
                                  directionText,
                                  style: TextStyle(
                                    color: iconColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    size: 16,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${route.origem} → ${route.destino}',
                                    style: TextStyle(color: Colors.grey[700]),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(
                                    Icons.schedule,
                                    size: 16,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Saída: ${route.saida} | Chegada: ${route.chegada}',
                                    style: TextStyle(color: Colors.grey[700]),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(
                                    Icons.business,
                                    size: 16,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Operação: ${route.operacao}',
                                    style: TextStyle(color: Colors.grey[700]),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: ElevatedButton(
                            onPressed: () {
                              _selectRouteFromList(route);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: iconColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Selecionar'),
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Carregando rotas operacionais...'),
                    ],
                  ),
                ),
                error: (error, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text('Erro ao carregar rotas: $error'),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  // Selecionar rota da lista Brasil-EUA
  void _selectRouteFromList(OperationalRoute route) {
    print('DEBUG: Selecionando voo ${route.voo}');
    setState(() {
      _flightNumberController.text = route.voo;
      _airlineController.text = route.nomeCia;
      _gateController.text = '';
      _terminalController.text = route.terminalDestino ?? '';
      _arrivalTimeController.text = route.chegada;
      _jfkInController.text = route.destino;
      print('DEBUG: Controladores atualizados - Voo: ${_flightNumberController.text}, Companhia: ${_airlineController.text}');
    });
    print('DEBUG: setState executado');
    
    // Aguardar um frame para garantir que o setState seja processado
    Future.delayed(Duration.zero, () {
      // Fechar o modal de voos Brasil-EUA
      Navigator.of(context).pop();
      
      // Fechar também o modal de detalhes do voo para exibir os dados na tela principal
      Navigator.of(context).pop();
    });
    
    // Mostrar snackbar de confirmação
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Voo ${route.voo} selecionado com sucesso!'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Modal para entrada manual de voo
  void _showManualFlightEntryModal() {
    final manualFlightNumberController = TextEditingController();
    final manualAirlineController = TextEditingController();
    final manualGateController = TextEditingController();
    final manualTerminalController = TextEditingController();
    final manualArrivalTimeController = TextEditingController();
    final manualJfkInController = TextEditingController();
    final manualDepartureAirportController = TextEditingController();
    final manualDepartureTimeController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adicionar Voo Manualmente'),
        content: SizedBox(
          width: 600,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Primeira linha: Número do voo e Companhia
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: manualFlightNumberController,
                        decoration: const InputDecoration(
                          labelText: 'Número do Voo *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.flight),
                          hintText: 'Ex: AA123',
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: manualAirlineController,
                        decoration: const InputDecoration(
                          labelText: 'Companhia Aérea',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.airplanemode_active),
                          hintText: 'Ex: American Airlines',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Segunda linha: Aeroporto de partida e JFK IN
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: manualDepartureAirportController,
                        decoration: const InputDecoration(
                          labelText: 'Aeroporto de Partida',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.flight_takeoff),
                          hintText: 'Ex: GRU, GIG',
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: manualJfkInController,
                        decoration: const InputDecoration(
                          labelText: 'JFK IN',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.flight_land),
                          hintText: 'Ex: JFK, EWR, LGA',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Terceira linha: Horário de partida e chegada
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: manualDepartureTimeController,
                        decoration: const InputDecoration(
                          labelText: 'Horário de Partida',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.schedule),
                          hintText: 'Ex: 14:30',
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: manualArrivalTimeController,
                        decoration: const InputDecoration(
                          labelText: 'Horário de Chegada',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.schedule),
                          hintText: 'Ex: 22:15',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Quarta linha: Gate e Terminal
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: manualGateController,
                        decoration: const InputDecoration(
                          labelText: 'Gate',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.door_front_door),
                          hintText: 'Ex: A12',
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: manualTerminalController,
                        decoration: const InputDecoration(
                          labelText: 'Terminal',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.business),
                          hintText: 'Ex: 1, 4, 8',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Nota informativa
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue[600], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Preencha pelo menos o número do voo. Os demais campos são opcionais.',
                          style: TextStyle(color: Colors.blue[700], fontSize: 12),
                        ),
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
            onPressed: () {
              // Limpar controladores
              manualFlightNumberController.dispose();
              manualAirlineController.dispose();
              manualGateController.dispose();
              manualTerminalController.dispose();
              manualArrivalTimeController.dispose();
              manualJfkInController.dispose();
              manualDepartureAirportController.dispose();
              manualDepartureTimeController.dispose();
              Navigator.of(context).pop();
            },
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              // Validar se pelo menos o número do voo foi preenchido
              if (manualFlightNumberController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Por favor, informe pelo menos o número do voo'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              
              // Preencher os campos principais com os dados manuais
              setState(() {
                _flightNumberController.text = manualFlightNumberController.text.trim();
                _airlineController.text = manualAirlineController.text.trim();
                _gateController.text = manualGateController.text.trim();
                _terminalController.text = manualTerminalController.text.trim();
                _arrivalTimeController.text = manualArrivalTimeController.text.trim();
                _jfkInController.text = manualJfkInController.text.trim();
              });
              
              // Limpar controladores
              manualFlightNumberController.dispose();
              manualAirlineController.dispose();
              manualGateController.dispose();
              manualTerminalController.dispose();
              manualArrivalTimeController.dispose();
              manualJfkInController.dispose();
              manualDepartureAirportController.dispose();
              manualDepartureTimeController.dispose();
              
              Navigator.of(context).pop(); // Fechar modal de entrada manual
              Navigator.of(context).pop(); // Fechar modal de detalhes do voo
              
              // Mostrar confirmação
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Voo ${_flightNumberController.text} adicionado manualmente!'),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
            ),
            child: const Text('Adicionar Voo'),
          ),
        ],
      ),
    );
  }
}
