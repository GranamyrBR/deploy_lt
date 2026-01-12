import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/enhanced_quotation_model.dart';
import '../models/lead_tintim.dart';
import '../models/contact.dart';
import '../models/agency_model.dart';
import '../models/service.dart' as db;
import '../models/product.dart' as dbp;
import '../widgets/nominatim_address_field.dart';
import '../widgets/quotation_management_dialog.dart';
import '../widgets/service_product_selection_with_whatsapp_dialog.dart';
import '../widgets/luggage_selector_widget.dart';
import '../widgets/vehicle_selector_widget.dart';
import '../services/quotation_service.dart';
import '../providers/accessibility_provider.dart';

/// Modal PROFISSIONAL de criação de cotação com mensagens WhatsApp integradas
/// Split-screen: Esquerda = WhatsApp com IA | Direita = Formulário completo
class CreateQuotationWithWhatsAppDialog extends ConsumerStatefulWidget {
  final Contact? initialContact;
  final List<LeadTintim> whatsappMessages;
  final String? leadId;
  final String? leadTitle;

  const CreateQuotationWithWhatsAppDialog({
    super.key,
    this.initialContact,
    required this.whatsappMessages,
    this.leadId,
    this.leadTitle,
  });

  @override
  ConsumerState<CreateQuotationWithWhatsAppDialog> createState() =>
      _CreateQuotationWithWhatsAppDialogState();
}

class _CreateQuotationWithWhatsAppDialogState
    extends ConsumerState<CreateQuotationWithWhatsAppDialog> {
  // Form controllers
  final _formKey = GlobalKey<FormState>();
  bool _isCreating = false; // Lock para evitar double-submit
  final _clientNameController = TextEditingController();
  final _clientEmailController = TextEditingController();
  final _passengerCountController = TextEditingController(text: '1');
  final _travelDateController = TextEditingController();
  final _returnDateController = TextEditingController();
  final _hotelController = TextEditingController();
  final _notesController = TextEditingController();
  final _specialRequestsController = TextEditingController();
  final _destinationController = TextEditingController();
  final _originController = TextEditingController();

  // Selected entities
  Contact? _selectedClient;
  Agency? _selectedAgency;
  DateTime? _travelDate;
  DateTime? _returnDate;
  final QuotationType _quotationType = QuotationType.tourism;
  final double _taxRate = 0.0;
  final List<db.Service> _selectedServices = [];
  final List<dbp.Product> _selectedProducts = [];
  List<LuggageItem> _luggageItems = [];
  List<VehicleSelection> _vehicleSelections = [];

  // WhatsApp IA
  List<LeadTintim> _selectedMessages = [];
  String _extractedInfo = '';

  @override
  void initState() {
    super.initState();
    
    // Pre-fill from initial contact
    if (widget.initialContact != null) {
      _selectedClient = widget.initialContact;
      _clientNameController.text = widget.initialContact!.name ?? '';
      _clientEmailController.text = widget.initialContact!.email ?? '';
    } else if (widget.leadTitle != null) {
      _clientNameController.text = widget.leadTitle!;
    }

    // Set default destination to New York
    _destinationController.text = 'New York';

    // Auto-select recent messages
    if (widget.whatsappMessages.isNotEmpty) {
      _selectedMessages = widget.whatsappMessages.take(3).toList();
      _extractAndFillData();
    }
  }

  @override
  void dispose() {
    _clientNameController.dispose();
    _clientEmailController.dispose();
    _passengerCountController.dispose();
    _travelDateController.dispose();
    _returnDateController.dispose();
    _hotelController.dispose();
    _notesController.dispose();
    _specialRequestsController.dispose();
    _destinationController.dispose();
    _originController.dispose();
    super.dispose();
  }

  /// Abre dialog de seleção de serviços/produtos COM mensagens WhatsApp
  Future<void> _selectServicesProducts() async {
    await showDialog<void>(
      context: context,
      builder: (context) => ServiceProductSelectionWithWhatsAppDialog(
        selectedServices: _selectedServices,
        selectedProducts: _selectedProducts,
        whatsappMessages: widget.whatsappMessages,
        onSelectionChanged: (services, products) {
          setState(() {
            _selectedServices.clear();
            _selectedServices.addAll(services);
            _selectedProducts.clear();
            _selectedProducts.addAll(products);
          });
        },
      ),
    );
  }

  /// Extrai dados das mensagens e PREENCHE automaticamente os campos
  void _extractAndFillData() {
    if (_selectedMessages.isEmpty) {
      setState(() {
        _extractedInfo = '⚠️ Nenhuma mensagem selecionada';
      });
      return;
    }

    final allText = _selectedMessages
        .where((m) => m.message != null && m.message!.isNotEmpty)
        .map((m) => m.message!)
        .join('\n');

    final info = StringBuffer();
    info.writeln('🤖 IA ANALISOU E PREENCHEU:\n');

    // 1. Destinos
    final destinations = _extractDestinations(allText);
    if (destinations.isNotEmpty) {
      _destinationController.text = destinations.first;
      info.writeln('📍 Destino: ${destinations.first}');
    }

    // 2. Hotéis
    final hotels = _extractHotels(allText);
    if (hotels.isNotEmpty) {
      _hotelController.text = hotels.first;
      info.writeln('🏨 Hotel: ${hotels.first}');
    }

    // 3. Passageiros
    final passengers = _extractPassengers(allText);
    if (passengers != null) {
      _passengerCountController.text = passengers.toString();
      info.writeln('👥 Passageiros: $passengers');
    }

    // 4. Datas
    final dates = _extractDates(allText);
    if (dates.isNotEmpty) {
      info.writeln('📅 Datas mencionadas: ${dates.join(', ')}');
    }

    // 5. Valores
    final values = _extractValues(allText);
    if (values.isNotEmpty) {
      info.writeln('💰 Valores: ${values.join(', ')}');
    }

    // 6. Adiciona texto original para contexto
    info.writeln('\n📝 Contexto das mensagens:');
    info.writeln(_selectedMessages.take(2).map((m) => '"${m.message}"').join('\n'));

    if (destinations.isEmpty && hotels.isEmpty && passengers == null) {
      info.writeln('\nℹ️ Poucos dados detectados.');
      info.writeln('💡 Preencha manualmente os campos.');
    }

    setState(() {
      _extractedInfo = info.toString();
    });
  }

  List<String> _extractDestinations(String text) {
    final cities = [
      'Miami', 'Orlando', 'New York', 'Nova York', 'Los Angeles', 'Las Vegas',
      'Paris', 'Londres', 'London', 'Dubai', 'Tokyo', 'Tóquio', 'Barcelona',
      'Rio de Janeiro', 'Rio', 'São Paulo', 'Salvador', 'Cancun', 'Lisboa',
    ];
    return cities
        .where((city) => text.toLowerCase().contains(city.toLowerCase()))
        .toSet()
        .toList();
  }

  List<String> _extractHotels(String text) {
    final patterns = [
      RegExp(r'(?:hotel|resort|inn|pousada)\s+[\w\s]{3,30}', caseSensitive: false),
      RegExp(r'[\w\s]{3,30}\s+(?:hotel|resort)', caseSensitive: false),
      RegExp(r'Hilton|Marriott|Riu|Ibis|Holiday|Sheraton', caseSensitive: false),
    ];

    final hotels = <String>{};
    for (final pattern in patterns) {
      final matches = pattern.allMatches(text);
      for (final match in matches) {
        final hotel = match.group(0)?.trim();
        if (hotel != null && hotel.length > 5) {
          hotels.add(hotel);
        }
      }
    }
    return hotels.take(3).toList();
  }

  int? _extractPassengers(String text) {
    final patterns = [
      RegExp(r'(\d+)\s+(?:pessoas?|passageiros?|adultos?|pax)', caseSensitive: false),
      RegExp(r'família\s+de\s+(\d+)', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return int.tryParse(match.group(1) ?? '');
      }
    }
    return null;
  }

  List<String> _extractDates(String text) {
    final patterns = [
      RegExp(r'\d{1,2}[/-]\d{1,2}[/-]\d{2,4}'),
      RegExp(r'\d{1,2}\s+de\s+\w+', caseSensitive: false),
    ];

    final dates = <String>{};
    for (final pattern in patterns) {
      final matches = pattern.allMatches(text);
      for (final match in matches) {
        final date = match.group(0);
        if (date != null) dates.add(date);
      }
    }
    return dates.toList();
  }

  List<String> _extractValues(String text) {
    final patterns = [
      RegExp(r'R\$\s*[\d.,]+'),
      RegExp(r'USD?\s*[\d.,]+', caseSensitive: false),
    ];

    final values = <String>{};
    for (final pattern in patterns) {
      final matches = pattern.allMatches(text);
      for (final match in matches) {
        final value = match.group(0);
        if (value != null) values.add(value);
      }
    }
    return values.toList();
  }

  Future<void> _createQuotation() async {
    // Prevenir double-submit
    if (_isCreating) {
      print('⚠️ Tentativa de criar cotação duplicada bloqueada');
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Converter serviços e produtos selecionados para QuotationItem
    final List<QuotationItem> quotationItems = [];
    
    // Adicionar serviços
    for (final service in _selectedServices) {
      quotationItems.add(QuotationItem.fromDbService(
        service,
        date: _travelDate ?? DateTime.now(),
        quantity: 1,
      ));
    }
    
    // Adicionar produtos
    for (final product in _selectedProducts) {
      quotationItems.add(QuotationItem.fromDbProduct(
        product,
        date: _travelDate ?? DateTime.now(),
        quantity: 1,
      ));
    }
    
    // Calcular valores totais
    final subtotal = quotationItems.fold<double>(0, (sum, item) => sum + item.value);
    final taxAmount = subtotal * _taxRate;
    final total = subtotal + taxAmount;

    // Preparar bagagens para envio (formato normalizado)
    final luggageList = _luggageItems
        .where((item) => item.quantity > 0)
        .map((item) => {
              'type': item.type.name,
              'quantity': item.quantity,
            })
        .toList();

    // Preparar veículos para envio
    final vehiclesList = _vehicleSelections
        .where((v) => v.quantity > 0)
        .map((v) => {
              'type': v.type.name,
              'label': v.type.label,
              'quantity': v.quantity,
              'max_passengers': v.type.maxPassengers, // snake_case para o banco
            })
        .toList();
    
    // Criar string resumida de veículos para o campo 'vehicle'
    final vehicleSummary = vehiclesList.isNotEmpty
        ? vehiclesList.map((v) => '${v['quantity']}x ${v['label']}').join(', ')
        : null;

    // Create quotation with all filled data INCLUDING ITEMS
    final quotation = Quotation(
      id: '0',
      quotationNumber: 'QT-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(9999).toString().padLeft(4, '0')}',
      type: _quotationType,
      status: QuotationStatus.draft,
      clientName: _clientNameController.text,
      clientEmail: _clientEmailController.text,
      clientPhone: _selectedClient?.phone,
      passengerCount: int.tryParse(_passengerCountController.text) ?? 1,
      travelDate: _travelDate ?? DateTime.now(),
      returnDate: _returnDate,
      origin: _originController.text.isNotEmpty ? _originController.text : null,
      destination: _destinationController.text.isNotEmpty ? _destinationController.text : null,
      hotel: _hotelController.text.isNotEmpty ? _hotelController.text : null,
      roomType: null, // Campo removido
      vehicle: vehicleSummary, // Usa o resumo dos veículos selecionados
      quotationDate: DateTime.now(),
      expirationDate: DateTime.now().add(const Duration(days: 7)),
      subtotal: subtotal,
      discountAmount: 0.0,
      taxRate: _taxRate,
      taxAmount: taxAmount,
      total: total,
      currency: 'USD',
      notes: _notesController.text,
      specialRequests: _specialRequestsController.text,
      createdBy: 'system',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      items: quotationItems, // ✅ AGORA PASSA OS ITENS!
      agency: _selectedAgency,
    );

    setState(() {
      _isCreating = true;
    });

    try {
      final service = QuotationService();
      final result = await service.saveQuotation(
        quotation, 
        luggage: luggageList,
        vehicles: vehiclesList,
      );

      if (!result.success) {
        throw Exception(result.errorMessage ?? 'Erro desconhecido ao salvar cotação');
      }

      if (mounted) {
        // Close this dialog
        Navigator.of(context).pop();
        
        // Show success and open management dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Cotação criada! Abrindo gerenciamento...'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Atualizar quotation com o ID real do banco
        final savedQuotation = quotation.copyWith(id: result.id.toString());

        // Open management dialog com cotação já salva (não vai salvar novamente)
        await showDialog<void>(
          context: context,
          builder: (context) => QuotationManagementDialog(
            quotation: savedQuotation,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao criar cotação: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isHighContrast = ref.watch(accessibilityProvider);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: size.width * 0.95,
        height: size.height * 0.95,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: Row(
                children: [
                  // Painel WhatsApp (aumentado para 600px para melhor leitura)
                  SizedBox(
                    width: 600,
                    child: _buildWhatsAppPanel(context),
                  ),
                  
                  // Divisor com espaçamento
                  const SizedBox(width: 8),
                  Container(width: 2, color: Theme.of(context).dividerColor),
                  const SizedBox(width: 8),
                  
                  // Formulário de cotação
                  Expanded(
                    child: _buildQuotationForm(context, isHighContrast),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF25D366).withValues(alpha: 0.8),
            Theme.of(context).colorScheme.primary,
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.chat_bubble, color: Color(0xFF25D366), size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Criar Cotação com WhatsApp IA',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '${widget.initialContact?.name ?? "Cliente"} • ${widget.whatsappMessages.length} mensagens',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded, color: Colors.white),
            tooltip: 'Fechar',
          ),
        ],
      ),
    );
  }

  Widget _buildWhatsAppPanel(BuildContext context) {
    return Container(
      color: Colors.grey.shade50,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                const Icon(Icons.chat, color: Color(0xFF25D366), size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Mensagens',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _extractAndFillData,
                  icon: const Icon(Icons.auto_fix_high, size: 16),
                  label: const Text('Extrair'),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.blue.shade50,
                    foregroundColor: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
          ),
          
          // Card "IA Analisou" removido - era apenas mock
          
          // Messages list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widget.whatsappMessages.length,
              itemBuilder: (context, index) {
                final message = widget.whatsappMessages[index];
                final isSelected = _selectedMessages.contains(message);
                
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedMessages.remove(message);
                      } else {
                        _selectedMessages.add(message);
                      }
                      _extractAndFillData();
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue.shade50 : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? Colors.blue : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.blue : Colors.transparent,
                                border: Border.all(color: isSelected ? Colors.blue : Colors.grey),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                                  : null,
                            ),
                            const SizedBox(width: 8),
                            // Ícone indicando quem enviou
                            Icon(
                              message.fromMe == true ? Icons.person : Icons.support_agent,
                              size: 16,
                              color: message.fromMe == true ? Colors.green : Colors.blue,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                message.fromMe == true ? 'Atendente' : (message.name ?? 'Cliente'),
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: message.fromMe == true ? Colors.green.shade700 : Colors.blue.shade700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        if (message.message != null && message.message!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              message.message!,
                              style: const TextStyle(fontSize: 11, height: 1.4),
                              // Removido maxLines e overflow para mostrar conteúdo completo
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuotationForm(BuildContext context, bool isHighContrast) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Row(
              children: [
                Icon(Icons.article, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                const Text(
                  'Nova Cotação',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Cliente
            _buildSectionTitle('👤 Cliente'),
            TextFormField(
              controller: _clientNameController,
              decoration: const InputDecoration(
                labelText: 'Nome',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              validator: (v) => v?.isEmpty == true ? 'Obrigatório' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _clientEmailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
            ),
            const SizedBox(height: 24),

            // Viagem
            _buildSectionTitle('✈️ Detalhes da Viagem'),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _originController,
                    decoration: const InputDecoration(
                      labelText: 'Origem',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.flight_takeoff),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _destinationController,
                    decoration: const InputDecoration(
                      labelText: 'Destino',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.flight_land),
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
                    controller: _travelDateController,
                    decoration: const InputDecoration(
                      labelText: 'Data de Ida',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    readOnly: true,
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        setState(() {
                          _travelDate = date;
                          _travelDateController.text =
                              '${date.day}/${date.month}/${date.year}';
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _returnDateController,
                    decoration: const InputDecoration(
                      labelText: 'Data de Volta',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    readOnly: true,
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _travelDate ?? DateTime.now(),
                        firstDate: _travelDate ?? DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        setState(() {
                          _returnDate = date;
                          _returnDateController.text =
                              '${date.day}/${date.month}/${date.year}';
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _passengerCountController,
              decoration: const InputDecoration(
                labelText: 'Número de Passageiros',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.people),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),

            // Hotel
            _buildSectionTitle('🏨 Hospedagem'),
            NominatimAddressField(
              controller: _hotelController,
              labelText: 'Hotel',
              hintText: 'Digite para buscar hotéis nos EUA',
              prefixIcon: Icons.hotel,
            ),
            const SizedBox(height: 24),

            // Veículos
            _buildSectionTitle('🚗 Transporte'),
            VehicleSelectorWidget(
              initialVehicles: _vehicleSelections.isEmpty ? null : _vehicleSelections,
              passengerCount: int.tryParse(_passengerCountController.text),
              onChanged: (vehicles) {
                setState(() {
                  _vehicleSelections = vehicles;
                });
              },
            ),
            const SizedBox(height: 24),

            // Bagagens
            _buildSectionTitle('🧳 Bagagens e Itens Especiais'),
            LuggageSelectorWidget(
              initialLuggage: _luggageItems.isEmpty ? null : _luggageItems,
              onChanged: (luggage) {
                setState(() {
                  _luggageItems = luggage;
                });
              },
            ),
            const SizedBox(height: 24),

            // Serviços e Produtos
            _buildSectionTitle('🛒 Serviços e Produtos'),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.purple.shade200),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.shopping_bag, color: Colors.purple.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${_selectedServices.length} serviços, ${_selectedProducts.length} produtos',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _selectServicesProducts,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Adicionar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_selectedServices.isNotEmpty || _selectedProducts.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 8),
                    if (_selectedServices.isNotEmpty) ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Serviços:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      ...List.generate(
                        _selectedServices.length,
                        (index) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle, size: 16, color: Colors.green.shade600),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _selectedServices[index].name ?? '',
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                              Text(
                                'R\$ ${_selectedServices[index].price?.toStringAsFixed(2) ?? "0.00"}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (_selectedProducts.isNotEmpty) ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Produtos:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      ...List.generate(
                        _selectedProducts.length,
                        (index) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle, size: 16, color: Colors.orange.shade600),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _selectedProducts[index].name ?? '',
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                              Text(
                                'R\$ ${_selectedProducts[index].price?.toStringAsFixed(2) ?? "0.00"}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Observações
            _buildSectionTitle('📝 Observações'),
            
            // Notas Internas (PRIVADO - apenas equipe)
            TextFormField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: 'Notas Internas',
                hintText: 'Visível apenas para atendentes e gestão',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: Tooltip(
                  message: 'Estas notas são PRIVADAS e não aparecerão no PDF da cotação',
                  child: Icon(Icons.info_outline, size: 20, color: Colors.orange.shade600),
                ),
                helperText: '🔒 Privado - Não aparece no PDF',
                helperStyle: TextStyle(
                  color: Colors.orange.shade700,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            
            // Solicitações Especiais (PÚBLICO - vai para PDF)
            TextFormField(
              controller: _specialRequestsController,
              decoration: InputDecoration(
                labelText: 'Solicitações Especiais',
                hintText: 'Ex: Cadeira de rodas, dieta especial, aniversário...',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.star_outline),
                suffixIcon: Tooltip(
                  message: 'Estas solicitações APARECERÃO no PDF enviado ao cliente',
                  child: Icon(Icons.picture_as_pdf, size: 20, color: Colors.blue.shade600),
                ),
                helperText: '📄 Aparece no PDF da cotação',
                helperStyle: TextStyle(
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 32),

            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _isCreating ? null : _createQuotation,
                  icon: _isCreating 
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check_circle),
                  label: Text(_isCreating ? 'Criando...' : 'Criar Cotação'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }
}

