import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/sale.dart';
import '../models/sale_payment.dart';
import '../models/contact.dart';
import '../models/service.dart';
import '../models/product.dart';
import '../models/currency.dart';
import '../models/sale_item_detail.dart';
import '../providers/contacts_provider.dart';
import '../providers/currencies_provider.dart';
import '../providers/filtered_services_provider.dart';
import '../providers/filtered_products_provider.dart';

class SaleRegulationModal extends ConsumerStatefulWidget {
  final Sale? sale; // Se null, é uma nova venda
  final Contact? preSelectedContact;
  
  const SaleRegulationModal({
    super.key,
    this.sale,
    this.preSelectedContact,
  });

  @override
  ConsumerState<SaleRegulationModal> createState() => _SaleRegulationModalState();
}

class _SaleRegulationModalState extends ConsumerState<SaleRegulationModal> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  
  Contact? _selectedContact;
  Currency? _selectedCurrency;
  List<SaleItemDetail> _saleItems = [];
  List<SalePayment> _salePayments = [];
  
  // Campos do item atual
  Service? _selectedService;
  Product? _selectedProduct;
  double _itemQuantity = 1;
  int _itemPax = 1;
  double _itemUnitPrice = 0;
  double _itemDiscount = 0;
  double _itemSurcharge = 0;
  double _itemTax = 0;
  
  // Validações
  final List<String> _validationErrors = [];
  final List<String> _validationWarnings = [];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    // Carregar moedas
    try {
      final currencyAsync = await ref.read(currenciesProvider.future);
      if (currencyAsync.isNotEmpty) {
        _selectedCurrency = currencyAsync.firstWhere(
          (currency) => currency.currencyCode == 'USD',
          orElse: () => currencyAsync.first,
        );
      }
    } catch (e) {
      print('Erro ao carregar moedas: $e');
    }

    // Se é uma venda existente, carregar dados
    if (widget.sale != null) {
      print('DEBUG: Iniciando carregamento da venda #${widget.sale!.id}');
      print('DEBUG: Dados da venda:');
      print('DEBUG: - Contact ID: ${widget.sale!.contactId}');
      print('DEBUG: - Contact Name: ${widget.sale!.contactName}');
      print('DEBUG: - Total Items: ${widget.sale!.items.length}');
      print('DEBUG: - Total Payments: ${widget.sale!.payments.length}');
      print('DEBUG: - Currency Code: ${widget.sale!.currencyCode}');
      print('DEBUG: - Notes: ${widget.sale!.notes}');
      
      _selectedContact = await _getContactById(widget.sale!.contactId);
      _notesController.text = widget.sale!.notes ?? '';
      
      // Carregar itens da venda
      print('DEBUG: Carregando itens da venda #${widget.sale!.id}');
      _saleItems = List.from(widget.sale!.items);
      print('DEBUG: ${_saleItems.length} itens carregados');
      
      // Debug dos itens
      for (int i = 0; i < _saleItems.length; i++) {
        final item = _saleItems[i];
        print('DEBUG: Item $i:');
        print('DEBUG:   - Service: ${item.service?.name}');
        print('DEBUG:   - Product: ${item.product?.name}');
        print('DEBUG:   - Quantity: ${item.quantity}');
        print('DEBUG:   - Unit Price: ${item.unitPrice}');
        print('DEBUG:   - Total Price: ${item.totalPrice}');
      }
      
      // Carregar pagamentos da venda
      _salePayments = List.from(widget.sale!.payments);
      print('DEBUG: ${_salePayments.length} pagamentos carregados');
      
      // Definir moeda da venda
      try {
        final currencyAsync = await ref.read(currenciesProvider.future);
        _selectedCurrency = currencyAsync.firstWhere(
          (currency) => currency.currencyCode == widget.sale!.currencyCode,
          orElse: () => currencyAsync.first,
        );
      } catch (e) {
        print('Erro ao definir moeda da venda: $e');
      }
        } else if (widget.preSelectedContact != null) {
      _selectedContact = widget.preSelectedContact;
    }
  }

  Future<Contact?> _getContactById(int contactId) async {
    try {
      final contacts = await ref.read(contactsProvider(true).future);
      return contacts.firstWhere((contact) => contact.id == contactId);
    } catch (e) {
      return null;
    }
  }

  void _addItem() {
    if (_selectedService == null && _selectedProduct == null) {
      _showErrorSnackBar('Selecione um serviço ou produto');
      return;
    }

    if (_itemUnitPrice <= 0) {
      _showErrorSnackBar('Preço unitário deve ser maior que zero');
      return;
    }

    if (_itemQuantity <= 0) {
      _showErrorSnackBar('Quantidade deve ser maior que zero');
      return;
    }

    if (_itemPax <= 0) {
      _showErrorSnackBar('PAX deve ser maior que zero');
      return;
    }

    final item = SaleItemDetail(
      service: _selectedService,
      product: _selectedProduct,
      quantity: _itemQuantity,
      pax: _itemPax,
      unitPrice: _itemUnitPrice,
      discount: _itemDiscount,
      surcharge: _itemSurcharge,
      tax: _itemTax,
    );

    setState(() {
      _saleItems.add(item);
      _clearItemFields();
    });

    _validateSale();
  }

  void _clearItemFields() {
    _selectedService = null;
    _selectedProduct = null;
    _itemQuantity = 1;
    _itemPax = 1;
    _itemUnitPrice = 0;
    _itemDiscount = 0;
    _itemSurcharge = 0;
    _itemTax = 0;
  }

  void _removeItem(int index) {
    setState(() {
      _saleItems.removeAt(index);
    });
    _validateSale();
  }

  void _editItem(int index) {
    final item = _saleItems[index];
    
    // Preencher campos com dados do item
    _selectedService = item.service;
    _selectedProduct = item.product;
    _itemQuantity = item.quantity;
    _itemPax = item.pax;
    _itemUnitPrice = item.unitPrice;
    _itemDiscount = item.discount;
    _itemSurcharge = item.surcharge;
    _itemTax = item.tax;
    
    // Remover item antigo
    setState(() {
      _saleItems.removeAt(index);
    });
    
    _validateSale();
  }

  void _duplicateItem(int index) {
    final item = _saleItems[index];
    
    final newItem = SaleItemDetail(
      service: item.service,
      product: item.product,
      quantity: item.quantity,
      pax: item.pax,
      unitPrice: item.unitPrice,
      discount: item.discount,
      surcharge: item.surcharge,
      tax: item.tax,
    );
    
    setState(() {
      _saleItems.add(newItem);
    });
    
    _validateSale();
  }

  void _validateSale() {
    _validationErrors.clear();
    _validationWarnings.clear();

    // Validações obrigatórias
    if (_selectedContact == null) {
      _validationErrors.add('Cliente é obrigatório');
    }

    if (_saleItems.isEmpty) {
      _validationErrors.add('Pelo menos um item é obrigatório');
    }

    // Validações de negócio
    for (int i = 0; i < _saleItems.length; i++) {
      final item = _saleItems[i];
      
      if (item.unitPrice <= 0) {
        _validationErrors.add('Item ${i + 1}: Preço unitário deve ser maior que zero');
      }
      
      if (item.quantity <= 0) {
        _validationErrors.add('Item ${i + 1}: Quantidade deve ser maior que zero');
      }
      
      if (item.pax <= 0) {
        _validationErrors.add('Item ${i + 1}: PAX deve ser maior que zero');
      }
      
      if (item.discount < 0 || item.discount > 100) {
        _validationErrors.add('Item ${i + 1}: Desconto deve estar entre 0% e 100%');
      }
      
      if (item.surcharge < 0) {
        _validationErrors.add('Item ${i + 1}: Adicional não pode ser negativo');
      }
      
      if (item.tax < 0 || item.tax > 100) {
        _validationErrors.add('Item ${i + 1}: Taxa deve estar entre 0% e 100%');
      }
    }

    // Warnings
    if (_saleItems.length > 10) {
      _validationWarnings.add('Venda com muitos itens (${_saleItems.length})');
    }

    final totalAmount = _saleItems.fold<double>(0, (sum, item) => sum + item.totalPrice);
    if (totalAmount > 10000) {
      _validationWarnings.add('Venda de alto valor (\$${totalAmount.toStringAsFixed(2)})');
    }

    for (final item in _saleItems) {
      if (item.discount > 50) {
        _validationWarnings.add('Desconto muito alto (${item.discount}%)');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.9,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildContactSelection(),
                      _buildCurrencySelection(),
                      _buildItemsSection(),
                      _buildValidationSection(),
                      _buildSummarySection(),
                      _buildNotesSection(),
                    ],
                  ),
                ),
              ),
            ),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(
          Icons.shopping_cart,
          color: Theme.of(context).primaryColor,
          size: 24,
        ),
        const SizedBox(width: 8),
        Text(
          widget.sale != null ? 'Editar Venda' : 'Nova Venda',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }

  Widget _buildContactSelection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cliente',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            FutureBuilder<List<Contact>>(
              future: ref.read(contactsProvider(true).future),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }
                
                if (snapshot.hasError) {
                  return Text('Erro: ${snapshot.error}');
                }
                
                final contacts = snapshot.data ?? [];
                
                return DropdownButtonFormField<Contact>(
                  initialValue: _selectedContact,
                  decoration: const InputDecoration(
                    labelText: 'Selecione o cliente',
                    border: OutlineInputBorder(),
                  ),
                  items: contacts.map((contact) {
                    return DropdownMenuItem(
                      value: contact,
                      child: Text(contact.name ?? ''),
                    );
                  }).toList(),
                  onChanged: (contact) {
                    setState(() {
                      _selectedContact = contact;
                    });
                    _validateSale();
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Cliente é obrigatório';
                    }
                    return null;
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencySelection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Moeda',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            FutureBuilder<List<Currency>>(
              future: ref.read(currenciesProvider.future),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }
                
                if (snapshot.hasError) {
                  return Text('Erro: ${snapshot.error}');
                }
                
                final currencies = snapshot.data ?? [];
                
                return DropdownButtonFormField<Currency>(
                  initialValue: _selectedCurrency,
                  decoration: const InputDecoration(
                    labelText: 'Selecione a moeda',
                    border: OutlineInputBorder(),
                  ),
                  items: currencies.map((currency) {
                    return DropdownMenuItem(
                      value: currency,
                      child: Text('${currency.currencyCode} (${currency.currencyCode})'),
                    );
                  }).toList(),
                  onChanged: (currency) {
                    setState(() {
                      _selectedCurrency = currency;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Moeda é obrigatória';
                    }
                    return null;
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Itens da Venda',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _addItem,
                  icon: const Icon(Icons.add),
                  label: const Text('Adicionar Item'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildItemForm(),
            const SizedBox(height: 16),
            _buildItemsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildItemForm() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildServiceSelection(),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildProductSelection(),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Quantidade',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                initialValue: _itemQuantity.toString(),
                onChanged: (value) {
                  _itemQuantity = double.tryParse(value) ?? 1;
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                decoration: const InputDecoration(
                  labelText: 'PAX',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                initialValue: _itemPax.toString(),
                onChanged: (value) {
                  _itemPax = int.tryParse(value) ?? 1;
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Preço Unitário',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                initialValue: _itemUnitPrice.toString(),
                onChanged: (value) {
                  _itemUnitPrice = double.tryParse(value) ?? 0;
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
                decoration: const InputDecoration(
                  labelText: 'Desconto (%)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                initialValue: _itemDiscount.toString(),
                onChanged: (value) {
                  _itemDiscount = double.tryParse(value) ?? 0;
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Adicional (%)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                initialValue: _itemSurcharge.toString(),
                onChanged: (value) {
                  _itemSurcharge = double.tryParse(value) ?? 0;
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Taxa (%)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                initialValue: _itemTax.toString(),
                onChanged: (value) {
                  _itemTax = double.tryParse(value) ?? 0;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildServiceSelection() {
    return FutureBuilder<List<Service>>(
      future: ref.read(filteredServicesProvider(null).future),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }
        
        final services = snapshot.data ?? [];
        
        return DropdownButtonFormField<Service>(
          initialValue: _selectedService,
          decoration: const InputDecoration(
            labelText: 'Serviço',
            border: OutlineInputBorder(),
          ),
          items: services.map((service) {
            return DropdownMenuItem(
              value: service,
              child: Text(service.name ?? ''),
            );
          }).toList(),
          onChanged: (service) {
            setState(() {
              _selectedService = service;
              _selectedProduct = null;
              if (service != null) {
                _itemUnitPrice = service.price ?? 0;
              }
            });
          },
        );
      },
    );
  }

  Widget _buildProductSelection() {
    return FutureBuilder<List<Product>>(
      future: ref.read(filteredProductsProvider(null).future),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }
        
        final products = snapshot.data ?? [];
        
        return DropdownButtonFormField<Product>(
          initialValue: _selectedProduct,
          decoration: const InputDecoration(
            labelText: 'Produto',
            border: OutlineInputBorder(),
          ),
          items: products.map((product) {
            return DropdownMenuItem(
              value: product,
              child: Text(product.name),
            );
          }).toList(),
          onChanged: (product) {
            setState(() {
              _selectedProduct = product;
              _selectedService = null;
              if (product != null) {
                _itemUnitPrice = product.price ?? 0;
              }
            });
          },
        );
      },
    );
  }

  Widget _buildItemsList() {
    if (_saleItems.isEmpty) {
      return const Center(
        child: Text('Nenhum item adicionado'),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _saleItems.length,
      itemBuilder: (context, index) {
        final item = _saleItems[index];
        return Card(
          child: ListTile(
            title: Text(
              item.service?.name ?? item.product?.name ?? 'Item ${index + 1}',
            ),
            subtitle: Text(
              'Qtd: ${item.quantity} | PAX: ${item.pax} | Preço: \$${item.unitPrice.toStringAsFixed(2)}',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '\$${item.totalPrice.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () => _editItem(index),
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  tooltip: 'Editar item',
                ),
                IconButton(
                  onPressed: () => _duplicateItem(index),
                  icon: const Icon(Icons.copy, color: Colors.green),
                  tooltip: 'Duplicar item',
                ),
                IconButton(
                  onPressed: () => _removeItem(index),
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: 'Remover item',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildValidationSection() {
    if (_validationErrors.isEmpty && _validationWarnings.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      color: _validationErrors.isNotEmpty ? Colors.red.shade50 : Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _validationErrors.isNotEmpty ? Icons.error : Icons.warning,
                  color: _validationErrors.isNotEmpty ? Colors.red : Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(
                  _validationErrors.isNotEmpty ? 'Erros de Validação' : 'Avisos',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _validationErrors.isNotEmpty ? Colors.red : Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._validationErrors.map((error) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('• $error', style: const TextStyle(color: Colors.red)),
            )),
            ..._validationWarnings.map((warning) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('• $warning', style: const TextStyle(color: Colors.orange)),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySection() {
    final totalAmount = _saleItems.fold<double>(0, (sum, item) => sum + item.totalPrice);
    final totalItems = _saleItems.length;
    final totalQuantity = _saleItems.fold<int>(0, (sum, item) => sum + item.quantity.toInt());
    final totalPax = _saleItems.fold<int>(0, (sum, item) => sum + item.pax);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumo da Venda',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem('Total de Itens', totalItems.toString()),
                ),
                Expanded(
                  child: _buildSummaryItem('Quantidade Total', totalQuantity.toString()),
                ),
                Expanded(
                  child: _buildSummaryItem('PAX Total', totalPax.toString()),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Text(
                    'Valor Total:',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '\$${totalAmount.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildNotesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Observações',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Observações da venda',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _validationErrors.isEmpty ? _saveSale : null,
            child: const Text('Salvar Venda'),
          ),
        ),
      ],
    );
  }

  void _saveSale() {
    if (!_formKey.currentState!.validate()) return;
    
    if (_validationErrors.isNotEmpty) {
      _showErrorSnackBar('Corrija os erros antes de salvar');
      return;
    }

    // TODO: Implementar salvamento da venda
    Navigator.of(context).pop(true);
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }
}
