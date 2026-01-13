import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/enhanced_quotation_model.dart';
import '../models/contact.dart';
import '../models/agency_model.dart';
import '../models/service.dart' as db;
import '../models/product.dart' as dbp;
import '../widgets/client_selection_dialog.dart';
import '../widgets/agency_selection_dialog.dart';
import '../widgets/service_product_selection_dialog.dart';
import '../widgets/nominatim_address_field.dart';
import '../services/notification_service.dart';
import '../services/quotation_service.dart';
import '../providers/accessibility_provider.dart';
import '../widgets/quotation_tag_selector.dart';
import '../screens/quotation_tags_management_screen.dart';

class EnhancedQuotationDialog extends ConsumerStatefulWidget {
  final String? leadId;
  final String? leadTitle;

  const EnhancedQuotationDialog({
    super.key,
    this.leadId,
    this.leadTitle,
  });

  @override
  ConsumerState<EnhancedQuotationDialog> createState() =>
      _EnhancedQuotationDialogState();
}

class _EnhancedQuotationDialogState
    extends ConsumerState<EnhancedQuotationDialog> {
  bool get isHighContrast => ref.watch(accessibilityProvider);
  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _clientNameController = TextEditingController();
  final _clientEmailController = TextEditingController();
  final _passengerCountController = TextEditingController(text: '1');
  final _travelDateController = TextEditingController();
  final _returnDateController = TextEditingController();
  final _hotelController = TextEditingController();
  final _roomTypeController = TextEditingController();
  final _vehicleController = TextEditingController();
  final _notesController = TextEditingController();
  final _specialRequestsController = TextEditingController();

  // Selected entities
  Contact? _selectedClient;
  Agency? _selectedAgency;
  final List<db.Service> _selectedServices = [];
  final List<dbp.Product> _selectedProducts = [];
  DateTime? _travelDate;
  DateTime? _returnDate;
  QuotationType _quotationType = QuotationType.tourism;
  double _taxRate = 0.0;
  
  // Selected tags
  List<int> _selectedTagIds = [];

  @override
  void initState() {
    super.initState();
    if (widget.leadTitle != null) {
      _clientNameController.text = widget.leadTitle!;
    }
    // Carregar tags
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(quotationTagProvider).loadTags();
    });
  }

  @override
  void dispose() {
    _clientNameController.dispose();
    _clientEmailController.dispose();
    _passengerCountController.dispose();
    _travelDateController.dispose();
    _returnDateController.dispose();
    _hotelController.dispose();
    _roomTypeController.dispose();
    _vehicleController.dispose();
    _notesController.dispose();
    _specialRequestsController.dispose();
    super.dispose();
  }

  /// Atualiza a categoria do contato após criar uma cotação
  /// Lead → Prospect (ao criar cotação)
  /// IMPORTANTE: Só atualiza contatos que VIERAM DO LEADSTINTIM (contatos novos)
  Future<void> _atualizarCategoriaAposCotacao(int contactId, String? currentCategoryName) async {
    try {
      print('🔄 [DIALOG] Tentando atualizar categoria...');
      print('   Contato ID: $contactId');
      print('   Categoria atual: $currentCategoryName');
      
      if (currentCategoryName == null) {
        print('⚠️ [DIALOG] Categoria atual é null, não atualizando');
        return;
      }
      
      final client = Supabase.instance.client;
      
      // ✅ VERIFICAR SE É CONTATO NOVO (do leadstintim) ou LEGADO (do monday)
      final contato = await client
          .from('contact')
          .select('phone')
          .eq('id', contactId)
          .maybeSingle();
      
      if (contato == null || contato['phone'] == null) {
        print('⚠️ [DIALOG] Contato não encontrado ou sem telefone');
        return;
      }
      
      final contactPhone = contato['phone'].toString().replaceAll(RegExp(r'[^\d+]'), '');
      
      // Verificar se telefone existe no leadstintim
      final leadExists = await client
          .from('leadstintim')
          .select('phone')
          .eq('phone', contactPhone)
          .maybeSingle();
      
      if (leadExists == null) {
        print('❌ [DIALOG][LEGADO] Contato $contactId é do Monday (não tem no leadstintim), NÃO atualizando categoria');
        return;
      }
      
      print('   ✅ [DIALOG] Contato é NOVO (existe no leadstintim)');
      
      final lowerCategory = currentCategoryName.toLowerCase();
      print('   Categoria lowercase: $lowerCategory');
      
      // Verificar se é Lead (deve virar Prospect)
      if (lowerCategory.contains('lead') && !lowerCategory.contains('perdido')) {
        print('   ✓ [DIALOG] É Lead (não perdido), buscando categoria Prospect...');
        
        // Buscar o ID da categoria Prospect
        final prospectCategory = await client
            .from('contact_category')
            .select('id, name')
            .ilike('name', '%prospect%')
            .maybeSingle();
        
        print('   Prospect encontrado: ${prospectCategory != null ? prospectCategory['name'] : "NÃO ENCONTRADO"}');
        
        if (prospectCategory != null) {
          await client
              .from('contact')
              .update({'contact_category_id': prospectCategory['id']})
              .eq('id', contactId);
          
          print('✅ [DIALOG][NOVO] Categoria atualizada: Lead → Prospect (ID: ${prospectCategory['id']})');
        } else {
          print('⚠️ [DIALOG] Categoria Prospect não encontrada no banco!');
        }
      } else {
        print('   ✗ [DIALOG] Não é Lead ou é Lead Perdido, não atualizando');
      }
    } catch (e) {
      print('⚠️ [DIALOG] Erro ao atualizar categoria após cotação: $e');
      // Não bloquear o fluxo se houver erro na atualização de categoria
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final isHighContrast = ref.watch(accessibilityProvider);
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.description,
              color: isHighContrast ? Colors.black : theme.colorScheme.primary),
          const SizedBox(width: 8),
          const Text('Criar Cotação Profissional'),
        ],
      ),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight:
              MediaQuery.of(context).size.height * 0.85, // 85% of screen height
          maxWidth: 700, // Slightly wider for forms
        ),
        child: SingleChildScrollView(
          child: SizedBox(
            width: double.maxFinite,
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Text('Alto Contraste'),
                      Switch(
                        value: isHighContrast,
                        onChanged: (_) =>
                            ref.read(accessibilityProvider.notifier).toggle(),
                      ),
                    ],
                  ),
                  // Client Section
                  _buildSectionHeader(
                    context,
                    'Cliente',
                    Icons.person,
                  ),
                  const SizedBox(height: 8),
                  _buildClientSection(),
                  const SizedBox(height: 16),

                  // Agency Section
                  _buildSectionHeader(
                    context,
                    'Agência (Opcional)',
                    Icons.business,
                  ),
                  const SizedBox(height: 8),
                  _buildAgencySection(),
                  const SizedBox(height: 16),

                  // Trip Details Section
                  _buildSectionHeader(
                      context, 'Detalhes da Viagem', Icons.flight),
                  const SizedBox(height: 8),
                  _buildTripDetailsSection(),
                  const SizedBox(height: 16),

                  // Services and Products Section
                  _buildSectionHeader(
                    context,
                    'Serviços e Produtos',
                    Icons.shopping_cart,
                    trailing: TextButton.icon(
                      onPressed: _selectServicesProducts,
                      icon: const Icon(Icons.add_shopping_cart),
                      label: Text(
                          'Adicionar (${_selectedServices.length + _selectedProducts.length})'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildServicesProductsSection(),
                  const SizedBox(height: 16),

                  // Additional Information Section
                  _buildSectionHeader(
                      context, 'Informações Adicionais', Icons.info),
                  const SizedBox(height: 8),
                  _buildAdditionalInfoSection(),
                  const SizedBox(height: 16),

                  // Tags Section
                  _buildSectionHeader(
                      context, 'Tags (Opcional)', Icons.label),
                  const SizedBox(height: 8),
                  _buildTagsSection(),
                  const SizedBox(height: 16),

                  // Summary Section
                  _buildSectionHeader(context, 'Resumo', Icons.summarize),
                  const SizedBox(height: 8),
                  _buildSummarySection(),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton.icon(
          onPressed: _createQuotation,
          icon: const Icon(Icons.send),
          label: const Text('Criar Cotação'),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon,
      {Widget? trailing}) {
    return Row(
      children: [
        Icon(icon,
            color: isHighContrast
                ? Colors.black
                : Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isHighContrast ? Colors.black : null,
              ),
        ),
        if (trailing != null) ...[
          const Spacer(),
          trailing,
        ],
      ],
    );
  }

  Widget _buildClientSection() {
    if (_selectedClient != null) {
      return Card(
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: isHighContrast
                ? Colors.black
                : Theme.of(context).colorScheme.primary,
            child: Text(
                (_selectedClient!.name ?? 'C').substring(0, 1).toUpperCase()),
          ),
          title: Text(_selectedClient!.name ?? 'Cliente',
              style: TextStyle(color: isHighContrast ? Colors.black : null)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_selectedClient!.email != null) Text(_selectedClient!.email!),
              if (_selectedClient!.phone != null) Text(_selectedClient!.phone!),
            ],
          ),
          trailing: IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              setState(() {
                _selectedClient = null;
                _clientNameController.clear();
                _clientEmailController.clear();
              });
            },
          ),
        ),
      );
    }

    return Column(
      children: [
        TextFormField(
          controller: _clientNameController,
          decoration: const InputDecoration(
            labelText: 'Nome do Cliente *',
            hintText: 'Nome completo do cliente',
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Por favor, insira o nome do cliente';
            }
            return null;
          },
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _clientEmailController,
          decoration: const InputDecoration(
            labelText: 'Email do Cliente',
            hintText: 'email@exemplo.com',
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 8),
        const SizedBox.shrink(),
      ],
    );
  }

  Widget _buildAgencySection() {
    if (_selectedAgency != null) {
      return Card(
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: isHighContrast
                ? Colors.black
                : Theme.of(context).colorScheme.secondary,
            child: Text(_selectedAgency!.name.substring(0, 1).toUpperCase()),
          ),
          title: Text(_selectedAgency!.name),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_selectedAgency!.contactPerson != null)
                Text('Contato: ${_selectedAgency!.contactPerson}'),
              if (_selectedAgency!.email != null) Text(_selectedAgency!.email!),
              if (_selectedAgency!.commissionRate != null)
                Text('Comissão: ${_selectedAgency!.commissionRate}%'),
            ],
          ),
          trailing: IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              setState(() {
                _selectedAgency = null;
              });
            },
          ),
        ),
      );
    }

    return InkWell(
      onTap: _selectAgency,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'Nenhuma agência selecionada',
          style: TextStyle(
            color: isHighContrast
                ? Colors.black
                : Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }

  Widget _buildTripDetailsSection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<QuotationType>(
                initialValue: _quotationType,
                decoration: const InputDecoration(
                  labelText: 'Tipo de Cotação',
                ),
                items: QuotationType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(_getQuotationTypeDisplayName(type)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _quotationType = value;
                    });
                  }
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _passengerCountController,
                decoration: const InputDecoration(
                  labelText: 'Nº de Passageiros *',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Obrigatório';
                  }
                  final count = int.tryParse(value);
                  if (count == null || count <= 0) {
                    return 'Inválido';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _travelDateController,
                decoration: const InputDecoration(
                  labelText: 'Data de Viagem',
                  hintText: 'Selecione a data',
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: _selectTravelDate,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _returnDateController,
                decoration: const InputDecoration(
                  labelText: 'Data de Retorno',
                  hintText: 'Opcional',
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: _selectReturnDate,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        NominatimAddressField(
          controller: _hotelController,
          labelText: 'Hotel / Local de Hospedagem',
          hintText: 'Digite o nome do hotel ou endereço',
          prefixIcon: Icons.hotel,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _vehicleController,
                decoration: const InputDecoration(
                  labelText: 'Veículo',
                  hintText: 'Ex: SUV, Van, Sedan',
                  prefixIcon: Icon(Icons.directions_car),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _roomTypeController,
                decoration: const InputDecoration(
                  labelText: 'Tipo de Quarto',
                  hintText: 'Ex: Standard, Suite, Duplo',
                  prefixIcon: Icon(Icons.bed),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildServicesProductsSection() {
    if (_selectedServices.isEmpty && _selectedProducts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
              color:
                  Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'Nenhum serviço ou produto selecionado',
          style: TextStyle(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.6)),
        ),
      );
    }

    return Column(
      children: [
        if (_selectedServices.isNotEmpty) ...[
          _buildSectionHeader(context, 'Serviços', Icons.construction),
          const SizedBox(height: 8),
          ..._selectedServices
              .map((service) => _buildServiceProductCard(service)),
          const SizedBox(height: 16),
        ],
        if (_selectedProducts.isNotEmpty) ...[
          _buildSectionHeader(context, 'Produtos', Icons.inventory),
          const SizedBox(height: 8),
          ..._selectedProducts
              .map((product) => _buildServiceProductCard(product)),
        ],
      ],
    );
  }

  Widget _buildServiceProductCard(dynamic item) {
    final isService = item is db.Service;
    final name = isService
        ? (item).name ?? 'Serviço'
        : (item as dbp.Product).name;
    final description = isService
        ? (item).description ?? ''
        : (item as dbp.Product).description ?? '';
    final price = isService
        ? ((item).price ?? 0.0)
        : (item as dbp.Product).pricePerUnit;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isHighContrast
              ? Colors.black
              : Theme.of(context).colorScheme.tertiary,
          child: Icon(
            isService ? Icons.construction : Icons.inventory,
            color: isHighContrast
                ? Colors.white
                : Theme.of(context).colorScheme.onTertiary,
          ),
        ),
        title: Text(name,
            style: TextStyle(color: isHighContrast ? Colors.black : null)),
        subtitle: Text(description,
            style: TextStyle(color: isHighContrast ? Colors.black : null)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '\$${price.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.remove_circle, color: Colors.red),
              onPressed: () {
                setState(() {
                  if (isService) {
                    _selectedServices.remove(item);
                  } else {
                    _selectedProducts.remove(item as dbp.Product);
                  }
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagsSection() {
    final tagProvider = ref.watch(quotationTagProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (tagProvider.isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          )
        else if (tagProvider.activeTags.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.grey.shade600),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Nenhuma tag disponível. Crie tags em "Gerenciar Tags".',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
              ],
            ),
          )
        else
          QuotationTagSelector(
            availableTags: tagProvider.activeTags,
            selectedTagIds: _selectedTagIds,
            onTagsChanged: (tagIds) {
              setState(() {
                _selectedTagIds = tagIds;
              });
            },
            allowCreateNew: false,
          ),
        
        if (_selectedTagIds.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            '${_selectedTagIds.length} tag${_selectedTagIds.length != 1 ? 's' : ''} selecionada${_selectedTagIds.length != 1 ? 's' : ''}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAdditionalInfoSection() {
    return Column(
      children: [
        TextFormField(
          controller: _notesController,
          decoration: const InputDecoration(
            labelText: 'Observações',
            hintText: 'Informações adicionais sobre a cotação',
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _specialRequestsController,
          decoration: const InputDecoration(
            labelText: 'Solicitações Especiais',
            hintText: 'Requisitos especiais do cliente',
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: _taxRate.toString(),
          decoration: const InputDecoration(
            labelText: 'Taxa de Imposto (%)',
            hintText: '0.0',
          ),
          keyboardType: TextInputType.number,
          onChanged: (value) {
            setState(() {
              _taxRate = double.tryParse(value) ?? 0.0;
            });
          },
        ),
      ],
    );
  }

  Widget _buildSummarySection() {
    final subtotal = _calculateSubtotal();
    final taxAmount = subtotal * (_taxRate / 100);
    final total = subtotal + taxAmount;

    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Subtotal:',
                    style: TextStyle(
                        color:
                            Theme.of(context).colorScheme.onPrimaryContainer)),
                Text('\$${subtotal.toStringAsFixed(2)}',
                    style: TextStyle(
                        color:
                            Theme.of(context).colorScheme.onPrimaryContainer)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Taxa ($_taxRate%):',
                    style: TextStyle(
                        color:
                            Theme.of(context).colorScheme.onPrimaryContainer)),
                Text('\$${taxAmount.toStringAsFixed(2)}',
                    style: TextStyle(
                        color:
                            Theme.of(context).colorScheme.onPrimaryContainer)),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total:',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color:
                            Theme.of(context).colorScheme.onPrimaryContainer)),
                Text('\$${total.toStringAsFixed(2)}',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color:
                            Theme.of(context).colorScheme.onPrimaryContainer)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _selectClient() async {
    showDialog(
      context: context,
      builder: (context) => ClientSelectionDialog(
        selectedClient: _selectedClient,
        onClientSelected: (client) {
          setState(() {
            _selectedClient = client;
            _clientNameController.text = client.name ?? '';
            _clientEmailController.text = client.email ?? '';
          });
        },
      ),
    );
  }

  void _selectAgency() async {
    showDialog(
      context: context,
      builder: (context) => AgencySelectionDialog(
        selectedAgency: _selectedAgency,
        onAgencySelected: (agency) {
          setState(() {
            _selectedAgency = agency;
          });
        },
      ),
    );
  }

  void _selectServicesProducts() async {
    showDialog(
      context: context,
      builder: (context) => ServiceProductSelectionDialog(
        selectedServices: _selectedServices,
        selectedProducts: _selectedProducts,
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

  Future<void> _selectTravelDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _travelDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() {
        _travelDate = date;
        _travelDateController.text = '${date.day}/${date.month}/${date.year}';
      });
    }
  }

  Future<void> _selectReturnDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _returnDate ??
          _travelDate?.add(const Duration(days: 7)) ??
          DateTime.now().add(const Duration(days: 37)),
      firstDate: _travelDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() {
        _returnDate = date;
        _returnDateController.text = '${date.day}/${date.month}/${date.year}';
      });
    }
  }

  double _calculateSubtotal() {
    double subtotal = 0;
    for (final service in _selectedServices) {
      subtotal += service.price ?? 0.0;
    }
    for (final product in _selectedProducts) {
      subtotal += product.pricePerUnit;
    }
    return subtotal;
  }

  String _getQuotationTypeDisplayName(QuotationType type) {
    switch (type) {
      case QuotationType.tourism:
        return 'Turismo';
      case QuotationType.corporate:
        return 'Corporativo';
      case QuotationType.event:
        return 'Evento';
      case QuotationType.transfer:
        return 'Transfer';
      case QuotationType.other:
        return 'Outro';
    }
  }

  void _createQuotation() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final clientName =
        _selectedClient?.name ?? _clientNameController.text.trim();
    final clientEmail =
        _selectedClient?.email ?? _clientEmailController.text.trim();
    final clientPhone = _selectedClient?.phone;
    final passengerCount = int.parse(_passengerCountController.text.trim());

    if (clientName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, insira o nome do cliente')),
      );
      return;
    }

    if (_selectedServices.isEmpty && _selectedProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Por favor, selecione pelo menos um serviço ou produto')),
      );
      return;
    }

    // Criar items da cotação
    final quotationItems = <QuotationItem>[];

    for (final service in _selectedServices) {
      if (service.isActive == false) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Serviço inativo selecionado')),
        );
        return;
      }
      quotationItems.add(QuotationItem.fromDbService(service,
          date: _travelDate ?? DateTime.now()));
    }

    for (final product in _selectedProducts) {
      if (!product.activeForSale) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Produto indisponível para venda: ${product.name}')),
        );
        return;
      }
      quotationItems.add(QuotationItem.fromDbProduct(product,
          date: _travelDate ?? DateTime.now()));
    }

    // Criar cotação
    final quotation = Quotation.fromKanbanData(
      id: 'quotation_${DateTime.now().millisecondsSinceEpoch}',
      quotationNumber:
          'QT-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
      clientName: clientName,
      clientEmail: clientEmail,
      clientPhone: clientPhone?.isNotEmpty == true ? clientPhone : null,
      clientContact: _selectedClient,
      agency: _selectedAgency,
      agencyCommissionRate: _selectedAgency?.commissionRate,
      travelDate: _travelDate ?? DateTime.now(),
      returnDate: _returnDate,
      passengerCount: passengerCount,
      hotel: _hotelController.text.trim().isNotEmpty
          ? _hotelController.text.trim()
          : null,
      roomType: _roomTypeController.text.trim().isNotEmpty
          ? _roomTypeController.text.trim()
          : null,
      vehicle: _vehicleController.text.trim().isNotEmpty
          ? _vehicleController.text.trim()
          : null,
      items: quotationItems,
      taxRate: _taxRate,
      createdBy: 'seller_user', // This should come from the logged in user
      notes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
      specialRequests: _specialRequestsController.text.trim().isNotEmpty
          ? _specialRequestsController.text.trim()
          : null,
    );

    QuotationService().saveQuotation(quotation).then((result) async {
      // Atribuir tags se houver
      if (_selectedTagIds.isNotEmpty && result.success) {
        try {
          await ref.read(quotationTagProvider).updateQuotationTags(
            quotationId: result.id,
            tagIds: _selectedTagIds,
            assignedBy: 'user', // TODO: pegar do auth
          );
        } catch (e) {
          print('Erro ao atribuir tags: $e');
          // Não bloqueia a criação da cotação se falhar
        }
      }
      
      // REGRA DE NEGÓCIO: Atualizar categoria do contato após criar cotação
      if (_selectedClient != null && result.success) {
        try {
          await _atualizarCategoriaAposCotacao(
            _selectedClient!.id,
            _selectedClient!.contactCategory,
          );
        } catch (e) {
          print('Erro ao atualizar categoria: $e');
          // Não bloqueia o fluxo
        }
      }
      
      NotificationService().showSuccess(
        'Cotação salva',
        'Nº ${quotation.quotationNumber} • Total: ${quotation.formattedTotal}',
        metadata: {
          'id': result.id,
          'quotationNumber': quotation.quotationNumber,
          'subtotal': quotation.subtotal,
          'tax': quotation.taxAmount,
          'total': quotation.total,
          'itemsCount': quotation.items.length,
        },
      );
      if (mounted) Navigator.of(context).pop(quotation);
    }).catchError((e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar cotação: $e')),
      );
    });
  }
}
