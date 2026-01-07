import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/contact.dart';
import '../models/service.dart';
import '../models/currency.dart';
import '../models/product.dart';
import '../models/sale.dart';
import '../providers/sales_provider.dart';
import '../providers/contacts_provider.dart';
import '../providers/product_categories_provider.dart';
import '../providers/filtered_services_provider.dart';
import '../providers/filtered_products_provider.dart';
import '../providers/service_types_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/exchange_rate_provider.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/exchange_rate_display.dart';
import '../widgets/base_screen_layout.dart';
import '../widgets/sales_timeline_widget.dart';
import '../widgets/add_payment_modal.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Classe auxiliar para gerenciar itens da venda
class SaleItemData {
  final Service? service;
  final Product? product;
  final int quantity;
  final int pax;
  final double unitPrice;
  final double discount;
  final double surcharge;
  final double tax;

  SaleItemData({
    this.service,
    this.product,
    required this.quantity,
    required this.pax,
    required this.unitPrice,
    this.discount = 0.0,
    this.surcharge = 0.0,
    this.tax = 0.0,
  });

  String get itemName =>
      service?.name ?? product?.name ?? 'Item não identificado';
  double get subtotal => unitPrice * quantity;
  double get discountAmount => subtotal * (discount / 100);
  double get surchargeAmount => subtotal * (surcharge / 100);
  double get taxAmount => subtotal * (tax / 100);
  double get totalPrice =>
      subtotal - discountAmount + surchargeAmount + taxAmount;
}

// Classe SalePaymentData agora é importada de ../widgets/add_payment_modal.dart

class CreateSaleScreenV2 extends ConsumerStatefulWidget {
  final Sale? sale; // Se null, é uma nova venda; se não null, é edição
  final Contact? contact; // Contato pré-selecionado

  const CreateSaleScreenV2({
    super.key,
    this.sale,
    this.contact,
  });

  @override
  ConsumerState<CreateSaleScreenV2> createState() => _CreateSaleScreenV2State();
}

class _CreateSaleScreenV2State extends ConsumerState<CreateSaleScreenV2>
    with TickerProviderStateMixin {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Controladores de animação
  late AnimationController _cardAnimationController;
  late AnimationController _stepAnimationController;
  late Animation<double> _cardAnimation;
  late Animation<double> _stepAnimation;

  // Cores do tema B2B
  static const Color _primaryBlue = Color(0xFF1565C0);
  static const Color _secondaryBlue = Color(0xFF42A5F5);
  static const Color _accentPurple = Color(0xFF7E57C2);
  static const Color _successGreen = Color(0xFF43A047);
  static const Color _warningOrange = Color(0xFFFF9800);
  static const Color _errorRed = Color(0xFFE53935);
  static const Color _neutralGray = Color(0xFF757575);

  // Passo atual do formulário
  int _currentStep = 0;
  final List<String> _stepTitles = [
    'Cliente, Serviços & Produtos',
    'Pagamentos',
    'Revisão Final'
  ];

  // Dados do formulário
  Contact? _selectedContact;
  Currency? _selectedCurrency;
  final List<SaleItemData> _saleItems = [];
  final List<SalePaymentData> _salePayments = [];
  final List<Currency> _currencies = [];

  // Estados de carregamento
  bool _isLoading = false;
  bool _showContractedItems =
      true; // Controla se a lista de itens está expandida

  // Filtros
  String? _selectedServiceCategory;
  int? _selectedProductCategoryId;
  String _serviceSearchQuery = '';
  String _productSearchQuery = '';
  bool _isSaving = false;

  // Estado para o item em configuração
  String _itemType = 'Serviço'; // 'Produto' ou 'Serviço'
  Product? _selectedProduct;
  Service? _selectedService;

  // Timeline steps
  final List<TimelineStep> _timelineSteps = const [
    TimelineStep(
      title: 'Itens',
      description: 'Cliente, serviços e produtos',
      icon: Icons.inventory_2,
    ),
    TimelineStep(
      title: 'Pagamento',
      description: 'Formas de pagamento',
      icon: Icons.payment,
    ),
    TimelineStep(
      title: 'Finalizar',
      description: 'Revisão e conclusão',
      icon: Icons.check_circle,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadCurrencies();

    // Se há um contato pré-selecionado, definir
    if (widget.contact != null) {
      _selectedContact = widget.contact;
    }

    // Se é uma edição, carregar dados da venda
    if (widget.sale != null) {
      _loadSaleData();
    }
  }

  void _loadSaleData() {
    print('DEBUG: Carregando dados da venda #${widget.sale!.id} para edição');

    // Carregar cliente
    _loadContactById(widget.sale!.contactId);
  
    // Carregar itens da venda
    _loadSaleItems();

    // Carregar pagamentos da venda
    _loadSalePayments();

    // Definir moeda
    _setCurrencyByCode(widget.sale!.currencyCode);
    }

  Future<void> _loadContactById(int contactId) async {
    try {
      final contacts = await ref.read(contactsProvider(true).future);
      final contact = contacts.firstWhere((c) => c.id == contactId);
      setState(() {
        _selectedContact = contact;
      });
      print('DEBUG: Cliente carregado: ${contact.name}');
    } catch (e) {
      print('DEBUG: Erro ao carregar cliente: $e');
    }
  }

  Future<void> _loadSaleItems() async {
    print('DEBUG: Carregando ${widget.sale!.items.length} itens da venda');

    // Carregar todos os serviços e produtos disponíveis
    final allServices = await ref.read(filteredServicesProvider(null).future);
    final allProducts = await ref.read(filteredProductsProvider(null).future);

    setState(() {
      _saleItems.clear();

      for (final itemDetail in widget.sale!.items) {
        Service? service;
        Product? product;

        if (itemDetail.serviceId != null) {
          try {
            service =
                allServices.firstWhere((s) => s.id == itemDetail.serviceId);
          } catch (e) {
            service = null;
          }
        }

        if (itemDetail.productId != null) {
          try {
            product = allProducts
                .firstWhere((p) => p.productId == itemDetail.productId);
          } catch (e) {
            product = null;
          }
        }

        _saleItems.add(SaleItemData(
          service: service,
          product: product,
          quantity: itemDetail.quantity.toInt(),
          pax: itemDetail.pax,
          unitPrice: itemDetail.unitPrice,
          discount: itemDetail.discount,
          surcharge: itemDetail.surcharge,
          tax: itemDetail.tax,
        ));
      }
    });

    print('DEBUG: ${_saleItems.length} itens carregados para edição');
  }

  void _loadSalePayments() {
    print(
        'DEBUG: Carregando ${widget.sale!.payments.length} pagamentos da venda');

    setState(() {
      _salePayments.clear();

      for (final payment in widget.sale!.payments) {
        // CORREÇÃO CRÍTICA: Usar valores já convertidos que foram travados no momento do pagamento
        // Não recalcular com cotação atual, pois isso causa inversão dos valores

        _salePayments.add(SalePaymentData(
          paymentMethodName: payment.paymentMethodName,
          amount: payment.amount,
          currencyCode: payment.currencyCode,
          paymentDate: payment.paymentDate,
          isAdvancePayment: payment.isAdvancePayment,
          exchangeRateToUsd: payment.exchangeRateToUsd ?? 1.0,
          amountInBrl: payment.amountInBrl ?? 0.0,
          amountInUsd: payment.amountInUsd ?? 0.0,
        ));
      }
    });

    print('DEBUG: ${_salePayments.length} pagamentos carregados para edição');
    print('DEBUG: Valores dos pagamentos:');
    for (int i = 0; i < _salePayments.length; i++) {
      final payment = _salePayments[i];
      print(
          '  Pagamento ${i + 1}: ${payment.currencyCode} ${payment.amount} (USD: ${payment.amountInUsd}, BRL: ${payment.amountInBrl})');
    }
  }

  void _setCurrencyByCode(String currencyCode) {
    try {
      if (_currencies.isEmpty) {
        print('DEBUG: Lista de moedas vazia');
        return;
      }

      Currency? foundCurrency;
      try {
        foundCurrency = _currencies.firstWhere(
          (c) => c.currencyCode == currencyCode,
        );
        setState(() {
          _selectedCurrency = foundCurrency;
        });
        print('DEBUG: Moeda definida: ${foundCurrency.currencyCode}');
      } catch (e) {
        print(
            'DEBUG: Moeda não encontrada: $currencyCode, usando primeira disponível');
        if (_currencies.isNotEmpty) {
          setState(() {
            _selectedCurrency = _currencies.first;
          });
        }
      }
    } catch (e) {
      print('DEBUG: Erro ao definir moeda: $e');
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Widget _buildHistoryFinancialCard(String title, double amount,
      String currency, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 12),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            '${currency == 'USD' ? '\$' : 'R\$'} ${amount.toStringAsFixed(2)}',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItemsList() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shopping_cart, color: Colors.blue[600], size: 16),
              const SizedBox(width: 6),
              Text(
                'Itens Comprados (${_saleItems.length})',
                style: TextStyle(
                  color: Colors.blue[600],
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_saleItems.isEmpty)
            Text(
              'Nenhum item adicionado',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            )
          else
            ...(_saleItems.take(3).map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.blue[400],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${item.itemName} (${item.quantity}x)',
                          style: const TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '\$${item.totalPrice.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[600],
                        ),
                      ),
                    ],
                  ),
                ))),
          if (_saleItems.length > 3)
            Text(
              '... e mais ${_saleItems.length - 3} itens',
              style: TextStyle(color: Colors.grey[600], fontSize: 11),
            ),
        ],
      ),
    );
  }

  Widget _buildHistoryPaymentsList() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.payment, color: Colors.green[600], size: 16),
              const SizedBox(width: 6),
              Text(
                'Pagamentos (${_salePayments.length})',
                style: TextStyle(
                  color: Colors.green[600],
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_salePayments.isEmpty)
            Text(
              'Nenhum pagamento realizado',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            )
          else
            ...(_salePayments.take(3).map((payment) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: payment.isAdvancePayment
                              ? Colors.orange[400]
                              : Colors.green[400],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${payment.paymentMethodName}${payment.isAdvancePayment ? ' (Adiantamento)' : ''}',
                          style: const TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${payment.currencyCode == 'USD' ? '\$' : 'R\$'}${payment.amount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[600],
                        ),
                      ),
                    ],
                  ),
                ))),
          if (_salePayments.length > 3)
            Text(
              '... e mais ${_salePayments.length - 3} pagamentos',
              style: TextStyle(color: Colors.grey[600], fontSize: 11),
            ),
        ],
      ),
    );
  }

  void _initAnimations() {
    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _stepAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _cardAnimation = CurvedAnimation(
      parent: _cardAnimationController,
      curve: Curves.easeOutCubic,
    );
    _stepAnimation = CurvedAnimation(
      parent: _stepAnimationController,
      curve: Curves.easeInOut,
    );

    _cardAnimationController.forward();
  }

  Future<void> _loadCurrencies() async {
    setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client
          .from('currency')
          .select()
          .order('currency_code');

      _currencies.clear();
      for (final item in response) {
        _currencies.add(Currency.fromJson(item));
      }
    } catch (e) {
      print('Erro ao carregar moedas: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _cardAnimationController.dispose();
    _stepAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Observar a cotação para reconstruir a tela quando ela mudar
    ref.watch(tourismDollarRateProvider);

    return BaseScreenLayout(
      title: widget.sale != null
          ? 'âœï¸ Editando Venda #${widget.sale!.id} - ${widget.sale!.contactName}'
          : '🆕 Nova Venda (V2)',
      backgroundColor: Colors.grey[50],
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FadeTransition(
              opacity: _cardAnimation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.1),
                  end: Offset.zero,
                ).animate(_cardAnimation),
                child: _buildBody(),
              ),
            ),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Seção de histórico da venda (apenas para edição)
          if (widget.sale != null) _buildSaleHistorySection(),

          // Timeline de progresso
          _buildTimelineSection(),

          // Conteúdo principal
          SizedBox(
            height: MediaQuery.of(context).size.height -
                200, // Altura fixa para evitar overflow
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Formulário principal
                  Expanded(
                    flex: 2,
                    child: _buildMainForm(),
                  ),

                  const SizedBox(width: 16),

                  // Sidebar com resumo
                  SizedBox(
                    width: 320,
                    child: _buildSidebar(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaleHistorySection() {
    print(
        'DEBUG: _buildSaleHistorySection chamado - widget.sale: ${widget.sale?.id}');
    if (widget.sale == null) {
      print('DEBUG: widget.sale é null, retornando SizedBox.shrink()');
      return const SizedBox.shrink();
    }

    print(
        'DEBUG: Construindo seção de histórico para venda #${widget.sale!.id}');
    final sale = widget.sale!;

    // Calcular totais pagos nas moedas originais
    final totalPaidUsd = _salePayments.fold(
        0.0,
        (sum, payment) =>
            sum + (payment.currencyCode == 'USD' ? payment.amount : 0));
    final totalPaidBrl = _salePayments.fold(
        0.0,
        (sum, payment) =>
            sum + (payment.currencyCode == 'BRL' ? payment.amount : 0));

    // Converter BRL para USD usando a cotação da venda para calcular o saldo
    final exchangeRate = sale.exchangeRateToUsd ??
        0.0; // Sem fallback - cotação deve ser definida manualmente
    final totalPaidBrlInUsd =
        (exchangeRate > 0) ? totalPaidBrl / exchangeRate : 0.0;
    final totalPaidEquivalentUsd = totalPaidUsd + totalPaidBrlInUsd;
    final remainingUsd = sale.totalAmountUsd - totalPaidEquivalentUsd;

    return Container(
      width: double.infinity,
      height: 30, // Altura mínima absoluta
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[50]!, Colors.indigo[50]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!, width: 2),
      ),
      child: Row(
        children: [
          Icon(Icons.history, color: Colors.blue[600], size: 16),
          const SizedBox(width: 6),
          Text(
            'Venda #${sale.id}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.indigo,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Total: \$${sale.totalAmountUsd.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 11,
              color: Colors.blue[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          if (totalPaidUsd > 0)
            Text(
              'Pago: \$${totalPaidUsd.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 11,
                color: Colors.green[600],
                fontWeight: FontWeight.bold,
              ),
            ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: remainingUsd <= 0 ? Colors.green[100] : Colors.orange[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              remainingUsd <= 0 ? 'Pago' : 'Pendente',
              style: TextStyle(
                color:
                    remainingUsd <= 0 ? Colors.green[800] : Colors.orange[800],
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineSection() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: _primaryBlue.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: _primaryBlue.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título da seção
          Row(
            children: [
              const Icon(
                Icons.timeline,
                color: _primaryBlue,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Progresso da Venda',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: _primaryBlue,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStepColor().withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getStepColor().withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  'Etapa ${_currentStep + 1} de ${_timelineSteps.length}',
                  style: TextStyle(
                    color: _getStepColor(),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Timeline Widget - Centralizada
          Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600),
              child: SalesTimelineWidget(
                steps: _timelineSteps,
                currentStep: _currentStep,
              ),
            ),
          ),

          const SizedBox(height: 6),

          // Status text
          Center(
            child: Text(
              _getTimelineStatusText(),
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Lista de Itens Contratados (expandível)
          if (_saleItems.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildContractedItemsSection(),
          ],
        ],
      ),
    );
  }

  String _getTimelineStatusText() {
    switch (_currentStep) {
      case 0:
        if (_selectedContact == null) {
          return 'Selecione um cliente para continuar';
        } else if (_saleItems.isEmpty) {
          return 'Adicione serviços ou produtos à venda';
        } else {
          return '${_saleItems.length} ${_saleItems.length == 1 ? 'item adicionado' : 'itens adicionados'}';
        }
      case 1:
        return _salePayments.isNotEmpty
            ? '${_salePayments.length} ${_salePayments.length == 1 ? 'pagamento configurado' : 'pagamentos configurados'}'
            : 'Configure as formas de pagamento';
      case 2:
        return 'Revise os dados e finalize a venda';
      default:
        return '';
    }
  }

  Widget _buildMainForm() {
    return Card(
      elevation: 8,
      shadowColor: _primaryBlue.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Conteúdo do step atual
              Expanded(
                child: _buildCurrentStepContent(),
              ),

              // Botões de navegação
              _buildNavigationButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStepColor() {
    switch (_currentStep) {
      case 0:
        return _primaryBlue;
      case 1:
        return _warningOrange;
      case 2:
        return _successGreen;
      default:
        return _primaryBlue;
    }
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildClientAndServicesStep();
      case 1:
        return _buildPaymentsStep();
      case 2:
        return _buildReviewStep();
      default:
        return const SizedBox();
    }
  }

  Widget _buildClientAndServicesStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Seleção de cliente
          _buildSectionCard(
            title: 'Selecione o Cliente',
            icon: Icons.person,
            color: _primaryBlue,
            child: _buildContactSelector(),
          ),

          const SizedBox(height: 24),

          // Serviços e Produtos lado a lado
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Serviços (metade da largura)
              Expanded(
                flex: 1,
                child: _buildSectionCard(
                  title: 'Serviços da Venda',
                  icon: Icons.room_service,
                  color: _secondaryBlue,
                  child: _buildServicesSection(),
                ),
              ),

              const SizedBox(width: 16),

              // Produtos (metade da largura)
              Expanded(
                flex: 1,
                child: _buildSectionCard(
                  title: 'Produtos',
                  icon: Icons.inventory,
                  color: _accentPurple,
                  child: _buildProductsSection(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductsAndPricesStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionCard(
            title: 'Adicionar Produtos',
            icon: Icons.inventory,
            color: _accentPurple,
            child: _buildProductsSection(),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentsStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionCard(
            title: 'Formas de Pagamento',
            icon: Icons.credit_card,
            color: _warningOrange,
            child: _buildPaymentsSection(),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionCard(
            title: 'Revisão da Venda',
            icon: Icons.fact_check,
            color: _successGreen,
            child: _buildReviewSection(),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header da seção
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),

          // Conteúdo da seção
          Padding(
            padding: const EdgeInsets.all(12),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildContactSelector() {
    return Column(
      children: [
        if (_selectedContact == null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.person_add,
                  size: 32,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 8),
                Text(
                  'Nenhum cliente selecionado',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Clique no botão abaixo para selecionar um cliente',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _showContactSelector,
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.search),
            label: const Text('Buscar Cliente'),
          ),
        ] else ...[
          _buildSelectedContactCard(),
        ],
      ],
    );
  }

  Widget _buildSelectedContactCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _successGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _successGreen.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: const BoxDecoration(
              color: _successGreen,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person,
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
                  _selectedContact?.name ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (_selectedContact?.email != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _selectedContact!.email!,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
                if (_selectedContact?.phone != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    _selectedContact!.phone!,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _selectedContact = null;
              });
            },
            icon: Icon(
              Icons.close,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  void _showContactSelector() {
    showDialog(
      context: context,
      builder: (context) => _ContactSelectorDialog(
        onContactSelected: (contact) {
          setState(() {
            _selectedContact = contact;
          });
        },
      ),
    );
  }

  Widget _buildServicesSection() {
    return Column(
      children: [
        // Search and Filter Bar
        Row(
          children: [
            Expanded(
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Buscar serviços...',
                    prefixIcon:
                        Icon(Icons.search, size: 20, color: Colors.grey[600]),
                    border: InputBorder.none,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  style: const TextStyle(fontSize: 14),
                  onChanged: (value) {
                    setState(() {
                      _serviceSearchQuery = value;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: _primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _primaryBlue.withValues(alpha: 0.3)),
              ),
              child: DropdownButtonHideUnderline(
                child: Consumer(
                  builder: (context, ref, child) {
                    final serviceTypesAsync = ref.watch(serviceTypesProvider);

                    return serviceTypesAsync.when(
                      loading: () => const Text(
                        'Carregando...',
                        style: TextStyle(
                          color: _primaryBlue,
                          fontSize: 14,
                        ),
                      ),
                      error: (error, stack) => const Text(
                        'Erro',
                        style: TextStyle(
                          color: _errorRed,
                          fontSize: 14,
                        ),
                      ),
                      data: (serviceTypes) {
                        final items = [
                          const DropdownMenuItem<String?>(
                              value: null, child: Text('Todas as Categorias')),
                          ...serviceTypes.map((serviceType) =>
                              DropdownMenuItem<String?>(
                                value: serviceType.name ?? '',
                                child: Text(
                                    serviceType.name ?? 'Categoria sem nome'),
                              )),
                        ];

                        return DropdownButton<String?>(
                          value: _selectedServiceCategory,
                          hint: const Text(
                            'Categoria',
                            style: TextStyle(
                              color: _primaryBlue,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          items: items,
                          onChanged: (value) {
                            setState(() {
                              _selectedServiceCategory = value;
                            });
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Services List
        Container(
          height: 300,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Consumer(
            builder: (context, ref, child) {
              final servicesAsync = ref.watch(filteredServicesProvider(null));

              return servicesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, color: _errorRed, size: 32),
                      SizedBox(height: 8),
                      Text('Erro ao carregar serviços',
                          style: TextStyle(color: _errorRed)),
                    ],
                  ),
                ),
                data: (services) {
                  if (services.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.room_service_outlined,
                              color: Colors.grey[400], size: 32),
                          const SizedBox(height: 8),
                          Text('Nenhum serviço encontrado',
                              style: TextStyle(color: Colors.grey[600])),
                        ],
                      ),
                    );
                  }

                  // Filtrar serviços por categoria e busca de texto
                  final filteredServices = services.where((service) {
                    // Filtro por categoria
                    if (_selectedServiceCategory != null &&
                        _selectedServiceCategory!.isNotEmpty) {
                      if (service.category != _selectedServiceCategory) {
                        return false;
                      }
                    }

                    // Filtro por texto
                    if (_serviceSearchQuery.isNotEmpty) {
                      final query = _serviceSearchQuery.toLowerCase();
                      final serviceName = service.name?.toLowerCase() ?? '';
                      final serviceDescription =
                          service.description?.toLowerCase() ?? '';

                      return serviceName.contains(query) ||
                          serviceDescription.contains(query);
                    }

                    return true;
                  }).toList();

                  if (filteredServices.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off,
                              size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 8),
                          Text(
                              'Nenhum serviço encontrado para "$_serviceSearchQuery"',
                              style: TextStyle(color: Colors.grey[600])),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(8),
                    itemCount: filteredServices.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final service = filteredServices[index];
                      return _buildServiceListItem(service);
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProductListItem(Product product) {
    return InkWell(
      onTap: () {
        setState(() {
          _itemType = 'Produto';
          _selectedProduct = product;
          _selectedService = null;
        });
        _showItemConfigurationModal();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            // Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _accentPurple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getProductIcon(product.name),
                color: _accentPurple,
                size: 20,
              ),
            ),

            const SizedBox(width: 12),

            // Product Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Taxa: ${product.taxPercentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  if (product.category != null &&
                      product.category!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _accentPurple.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        product.category!,
                        style: const TextStyle(
                          color: _accentPurple,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Price and Action
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'US\$ ${product.pricePerUnit.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: _successGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _accentPurple,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Adicionar',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceListItem(Service service) {
    return InkWell(
      onTap: () {
        setState(() {
          _itemType = 'Serviço';
          _selectedService = service;
          _selectedProduct = null;
        });
        _showItemConfigurationModal();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            // Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getServiceIcon(service.category),
                color: _primaryBlue,
                size: 20,
              ),
            ),

            const SizedBox(width: 12),

            // Service Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.name ?? 'Serviço sem nome',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (service.description != null &&
                      service.description!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      service.description!,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (service.category != null) ...[
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _secondaryBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        service.category!,
                        style: const TextStyle(
                          color: _secondaryBlue,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Price and Action
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (service.price != null) ...[
                  Text(
                    'US\$ ${service.price!.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: _successGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _primaryBlue,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Adicionar',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Métodos auxiliares para serviços
  IconData _getServiceIcon(String? category) {
    switch (category?.toLowerCase()) {
      case 'transporte':
      case 'transfer':
        return Icons.directions_car;
      case 'hotel':
      case 'hospedagem':
        return Icons.hotel;
      case 'tour':
      case 'passeio':
        return Icons.tour;
      case 'voo':
      case 'flight':
        return Icons.flight;
      case 'restaurante':
      case 'alimentacao':
        return Icons.restaurant;
      default:
        return Icons.room_service;
    }
  }

  Color _getServiceColor(int index) {
    final colors = [
      _primaryBlue,
      _secondaryBlue,
      _accentPurple,
      _warningOrange,
      _successGreen
    ];
    return colors[index % colors.length];
  }

  void _resetItemFields() {
    // Não reseta a quantidade e pax para manter a última configuração
  }

  void _addItemWithConfiguration(
      int quantity, int pax, double discount, double surcharge, double tax) {
    if (_itemType == 'Produto' && _selectedProduct != null) {
      final item = SaleItemData(
        service: null,
        product: _selectedProduct,
        quantity: quantity,
        pax: pax,
        unitPrice: _selectedProduct!.pricePerUnit,
        discount: discount,
        surcharge: surcharge,
        tax: tax,
      );

      setState(() {
        _saleItems.add(item);
        _selectedProduct = null;
        _resetItemFields();
      });
    } else if (_itemType == 'Serviço' && _selectedService != null) {
      final item = SaleItemData(
        service: _selectedService,
        product: null,
        quantity: quantity,
        pax: pax,
        unitPrice: _selectedService!.price ?? 0.0,
        discount: discount,
        surcharge: surcharge,
        tax: tax,
      );

      setState(() {
        _saleItems.add(item);
        _selectedService = null;
        _resetItemFields();
      });
    }
  }

  InputDecoration _inputDecoration(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      filled: true,
      fillColor: Theme.of(context).colorScheme.surface,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 2.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.error,
          width: 1.5,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.error,
          width: 2.5,
        ),
      ),
      prefixIcon: icon != null
          ? Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            )
          : null,
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
    );
  }

  void _showItemConfigurationModal() {
    if (_selectedProduct == null && _selectedService == null) return;

    final formKey = GlobalKey<FormState>();
    int quantity = 1;
    int pax = 1;
    double discount = 0.0;
    double surcharge = 0.0;
    double tax = 0.0;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Configurar $_itemType',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          content: SingleChildScrollView(
            child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Detalhes do item selecionado compacto
                      if (_selectedProduct != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green[200]!),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(
                                  Icons.inventory,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _selectedProduct!.name,
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      'USD ${_selectedProduct!.pricePerUnit.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      if (_selectedService != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green[200]!),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(
                                  Icons.room_service,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _selectedService!.name ?? 'Sem nome',
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      'USD ${_selectedService!.price?.toStringAsFixed(2) ?? '0.00'}',
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),

                      // Campos de configuração compactos
                      Column(
                        children: [
                          // Primeira linha: Quantidade e PAX
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  initialValue: '1',
                                  style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                      fontSize: 14),
                                  decoration: _inputDecoration('Quantidade',
                                          icon: Icons.confirmation_number)
                                      .copyWith(
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 10),
                                  ),
                                  keyboardType: TextInputType.number,
                                  onChanged: (value) {
                                    quantity = int.tryParse(value) ?? 1;
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  initialValue: '1',
                                  style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                      fontSize: 14),
                                  decoration: _inputDecoration('PAX',
                                          icon: Icons.people)
                                      .copyWith(
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 10),
                                  ),
                                  keyboardType: TextInputType.number,
                                  onChanged: (value) {
                                    pax = int.tryParse(value) ?? 1;
                                  },
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Segunda linha: Desconto, Acréscimo e Taxa
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  initialValue: '0',
                                  style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                      fontSize: 14),
                                  decoration: _inputDecoration('Desconto (%)',
                                          icon: Icons.remove_circle_outline)
                                      .copyWith(
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 10),
                                  ),
                                  keyboardType: TextInputType.number,
                                  onChanged: (value) {
                                    discount = double.tryParse(value) ?? 0.0;
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  initialValue: '0',
                                  style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                      fontSize: 14),
                                  decoration: _inputDecoration('Acréscimo (%)',
                                          icon: Icons.add_circle_outline)
                                      .copyWith(
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 10),
                                  ),
                                  keyboardType: TextInputType.number,
                                  onChanged: (value) {
                                    surcharge = double.tryParse(value) ?? 0.0;
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  initialValue: '0',
                                  style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                      fontSize: 14),
                                  decoration: _inputDecoration('Taxa (%)',
                                          icon: Icons.receipt)
                                      .copyWith(
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 10),
                                  ),
                                  keyboardType: TextInputType.number,
                                  onChanged: (value) {
                                    tax = double.tryParse(value) ?? 0.0;
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Botão adicionar
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            foregroundColor:
                                Theme.of(context).colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () {
                            _addItemWithConfiguration(
                                quantity, pax, discount, surcharge, tax);
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.add_shopping_cart, size: 18),
                          label: const Text('Adicionar ao Carrinho'),
                        ),
                      ),
                    ],
                  ),
                )),
          ),
        );
      },
    );
  }

  Widget _buildProductsSection() {
    return Column(
      children: [
        // Search and Filter Bar
        Row(
          children: [
            Expanded(
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Buscar produtos...',
                    prefixIcon:
                        Icon(Icons.search, size: 20, color: Colors.grey[600]),
                    border: InputBorder.none,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  style: const TextStyle(fontSize: 14),
                  onChanged: (value) {
                    setState(() {
                      _productSearchQuery = value;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: _accentPurple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _accentPurple.withValues(alpha: 0.3)),
              ),
              child: DropdownButtonHideUnderline(
                child: Consumer(
                  builder: (context, ref, child) {
                    final productCategoriesAsync =
                        ref.watch(productCategoriesProvider);

                    return productCategoriesAsync.when(
                      loading: () => const Text(
                        'Carregando...',
                        style: TextStyle(
                          color: _accentPurple,
                          fontSize: 14,
                        ),
                      ),
                      error: (error, stack) => const Text(
                        'Erro',
                        style: TextStyle(
                          color: _errorRed,
                          fontSize: 14,
                        ),
                      ),
                      data: (productCategories) {
                        final items = [
                          const DropdownMenuItem<int?>(
                              value: null, child: Text('Todas as Categorias')),
                          ...productCategories.map((category) =>
                              DropdownMenuItem<int?>(
                                value: category.categoryId,
                                child:
                                    Text(category.name ?? 'Categoria sem nome'),
                              )),
                        ];

                        return DropdownButton<int?>(
                          value: _selectedProductCategoryId,
                          hint: const Text(
                            'Categoria',
                            style: TextStyle(
                              color: _accentPurple,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          items: items,
                          onChanged: (value) {
                            setState(() {
                              _selectedProductCategoryId = value;
                            });
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Products List
        Container(
          height: 300,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Consumer(
            builder: (context, ref, child) {
              final productsAsync = ref
                  .watch(filteredProductsProvider(_selectedProductCategoryId));

              return productsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, color: _errorRed, size: 32),
                      SizedBox(height: 8),
                      Text('Erro ao carregar produtos',
                          style: TextStyle(color: _errorRed)),
                    ],
                  ),
                ),
                data: (products) {
                  if (products.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory_outlined,
                              color: Colors.grey[400], size: 32),
                          const SizedBox(height: 8),
                          Text('Nenhum produto encontrado',
                              style: TextStyle(color: Colors.grey[600])),
                        ],
                      ),
                    );
                  }

                  // Filtrar produtos por busca de texto (categoria já filtrada pelo provider)
                  final filteredProducts = products.where((product) {
                    // Filtro por texto
                    if (_productSearchQuery.isNotEmpty) {
                      final query = _productSearchQuery.toLowerCase();
                      final productName = product.name.toLowerCase();
                      return productName.contains(query);
                    }

                    return true;
                  }).toList();

                  if (filteredProducts.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off,
                              size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 8),
                          Text(
                            _productSearchQuery.isNotEmpty
                                ? 'Nenhum produto encontrado para "$_productSearchQuery"'
                                : 'Nenhum produto encontrado para a categoria selecionada',
                            style: TextStyle(color: Colors.grey[600]),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(8),
                    itemCount: filteredProducts.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];
                      return _buildProductListItem(product);
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProductCard(String title, IconData icon, Color color,
      {Product? product}) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: InkWell(
        onTap: () {
          if (product != null) {
            _addProductToSale(product);
          }
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (product != null) ...[
                const SizedBox(height: 4),
                Text(
                  'US\$ ${product.pricePerUnit.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: color.withValues(alpha: 0.8),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _getProductIcon(String? name) {
    final productName = name?.toLowerCase() ?? '';

    if (productName.contains('seguro')) return Icons.security;
    if (productName.contains('chip') || productName.contains('sim')) {
      return Icons.sim_card;
    }
    if (productName.contains('bagagem')) return Icons.luggage;
    if (productName.contains('camera') || productName.contains('foto')) {
      return Icons.camera_alt;
    }
    if (productName.contains('guia') || productName.contains('book')) {
      return Icons.book;
    }
    if (productName.contains('mapa')) return Icons.map;
    if (productName.contains('souvenir')) return Icons.card_giftcard;

    return Icons.inventory;
  }

  void _addProductToSale(Product product) {
    setState(() {
      final newItem = SaleItemData(
        product: product,
        quantity: 1,
        pax: 1,
        unitPrice: product.pricePerUnit,
      );
      _saleItems.add(newItem);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} adicionado Ã  venda'),
        backgroundColor: _successGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildPaymentsSection() {
    return Column(
      children: [
        // Alerta sobre sistema de cotação
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _warningOrange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _warningOrange.withValues(alpha: 0.3)),
          ),
          child: const Row(
            children: [
              Icon(Icons.currency_exchange, color: _warningOrange, size: 20),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '💰 Sistema de Pagamentos Multi-Moeda',
                      style: TextStyle(
                        color: _warningOrange,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'A empresa vende em dólares. Adiantamentos em reais travam a cotação. Flutuações cambiais são do cliente.',
                      style: TextStyle(
                        color: _warningOrange,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Resumo financeiro da venda
        _buildFinancialSummary(),

        const SizedBox(height: 20),

        // Lista de pagamentos existentes
        if (_salePayments.isNotEmpty) ...[
          _buildPaymentsList(),
          const SizedBox(height: 20),
        ],

        // Botão para adicionar pagamento
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _showAddPaymentModal(),
            style: ElevatedButton.styleFrom(
              backgroundColor: _warningOrange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 4,
            ),
            icon: const Icon(Icons.add, size: 20),
            label: Text(
              _salePayments.isEmpty
                  ? 'Adicionar Primeiro Pagamento'
                  : 'Adicionar Outro Pagamento',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFinancialSummary() {
    final totalSaleUsd =
        _saleItems.fold<double>(0, (sum, item) => sum + item.totalPrice);
    final totalPaidUsd = _salePayments.fold<double>(0, (sum, payment) {
      if (payment.currencyCode == 'USD') {
        return sum + payment.amount;
      } else if (payment.currencyCode == 'BRL') {
        return sum + payment.amountInUsd;
      }
      return sum;
    });
    final remainingUsd = totalSaleUsd - totalPaidUsd;

    // Calcular valores em BRL usando cotação atual (para estimativa)
    final exchangeRate = ref.watch(tourismDollarRateProvider);
    final totalSaleBrl = totalSaleUsd * exchangeRate;
    final remainingBrl = remainingUsd * exchangeRate;
    final brlFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _warningOrange.withValues(alpha: 0.1),
            _warningOrange.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _warningOrange.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.account_balance_wallet,
                  color: _warningOrange, size: 20),
              SizedBox(width: 8),
              Text(
                'Resumo Financeiro',
                style: TextStyle(
                  color: _warningOrange,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Total da venda
          _buildFinancialRow(
            'Total da Venda:',
            'US\$ ${totalSaleUsd.toStringAsFixed(2)}',
            brlFormat.format(totalSaleBrl),
            _primaryBlue,
          ),

          const SizedBox(height: 12),

          // Total pago
          _buildFinancialRow(
            'Total Pago:',
            'US\$ ${totalPaidUsd.toStringAsFixed(2)}',
            brlFormat.format(_calculateTotalPaidBrl()),
            _successGreen,
          ),

          const SizedBox(height: 12),

          // Saldo pendente
          _buildFinancialRow(
            'Saldo Pendente:',
            'US\$ ${remainingUsd.toStringAsFixed(2)}',
            '${brlFormat.format(remainingBrl)} (estimativa)',
            remainingUsd > 0 ? _errorRed : _successGreen,
          ),

          if (_salePayments.isNotEmpty) ...[
            const SizedBox(height: 16),
            Divider(color: _warningOrange.withValues(alpha: 0.3)),
            const SizedBox(height: 8),
            const Text(
              '💡 Valores em reais mostram a cotação travada no momento do adiantamento',
              style: TextStyle(
                color: _warningOrange,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFinancialRow(
      String label, String usdValue, String brlValue, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              usdValue,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              brlValue,
              style: TextStyle(
                color: color.withValues(alpha: 0.8),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }

  double _calculateTotalPaidBrl() {
    return _salePayments.fold<double>(0, (sum, payment) {
      if (payment.currencyCode == 'BRL') {
        return sum + payment.amount;
      } else if (payment.currencyCode == 'USD') {
        return sum + payment.amountInBrl;
      }
      return sum;
    });
  }

  Widget _buildPaymentsList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _successGreen.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.payment, color: _successGreen, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Pagamentos Registrados (${_salePayments.length})',
                  style: const TextStyle(
                    color: _successGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),

          // Lista de pagamentos
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _salePayments.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              color: Colors.grey[200],
            ),
            itemBuilder: (context, index) {
              final payment = _salePayments[index];
              return _buildPaymentListItem(payment, index);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentListItem(SalePaymentData payment, int index) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Ícone do método de pagamento
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _getPaymentMethodColor(payment.paymentMethodName)
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _getPaymentMethodColor(payment.paymentMethodName)
                    .withValues(alpha: 0.3),
              ),
            ),
            child: Icon(
              _getPaymentMethodIcon(payment.paymentMethodName),
              color: _getPaymentMethodColor(payment.paymentMethodName),
              size: 24,
            ),
          ),

          const SizedBox(width: 16),

          // Informações do pagamento
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      payment.paymentMethodName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: payment.isAdvancePayment
                            ? _warningOrange
                            : _successGreen,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        payment.isAdvancePayment ? 'ADIANTAMENTO' : 'PAGAMENTO',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: payment.currencyCode == 'USD'
                            ? _primaryBlue
                            : Colors.orange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        payment.currencyCode,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  payment.paymentDateFormatted,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                if (payment.transactionId != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'ID: ${payment.transactionId}',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Valores
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                payment.amountFormatted,
                style: TextStyle(
                  color: _getPaymentMethodColor(payment.paymentMethodName),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              if (payment.dualCurrencyDisplay != payment.amountFormatted) ...[
                const SizedBox(height: 2),
                Text(
                  payment.currencyCode == 'BRL'
                      ? 'US\$ ${payment.amountInUsd.toStringAsFixed(2)}'
                      : payment.currencyCode == 'USD'
                          ? 'R\$ ${payment.amountInBrl.toStringAsFixed(2)}'
                          : '',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(width: 12),

          // Botão remover
          IconButton(
            onPressed: () => _removePayment(index),
            icon: const Icon(Icons.delete, color: Colors.red, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  void _removePayment(int index) {
    setState(() {
      _salePayments.removeAt(index);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Pagamento removido'),
        backgroundColor: _warningOrange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Color _getPaymentMethodColor(String method) {
    switch (method.toLowerCase()) {
      case 'pix':
        return Colors.green;
      case 'cartão de crédito':
      case 'cartao de credito':
        return Colors.blue;
      case 'transferÃªncia':
      case 'transferencia':
        return Colors.purple;
      case 'dinheiro':
        return Colors.orange;
      default:
        return _primaryBlue;
    }
  }

  IconData _getPaymentMethodIcon(String method) {
    switch (method.toLowerCase()) {
      case 'pix':
        return Icons.pix;
      case 'cartão de crédito':
      case 'cartao de credito':
        return Icons.credit_card;
      case 'transferÃªncia':
      case 'transferencia':
        return Icons.account_balance;
      case 'dinheiro':
        return Icons.money;
      default:
        return Icons.payment;
    }
  }

  Widget _buildReviewSection() {
    final totalSaleUsd =
        _saleItems.fold<double>(0, (sum, item) => sum + item.totalPrice);
    final totalPaidUsd = _salePayments.fold<double>(0, (sum, payment) {
      if (payment.currencyCode == 'USD') {
        return sum + payment.amount;
      } else if (payment.currencyCode == 'BRL') {
        return sum + payment.amountInUsd;
      }
      return sum;
    });
    final remainingUsd = totalSaleUsd - totalPaidUsd;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Alerta de finalização
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _successGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _successGreen.withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle, color: _successGreen, size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🎉 Venda Pronta para Finalização!',
                        style: TextStyle(
                          color: _successGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Revise todas as informações antes de confirmar a criação da venda.',
                        style: TextStyle(
                          color: _successGreen,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Resumo do cliente
          if (_selectedContact != null) ...[
            _buildReviewCard(
              'Cliente',
              Icons.person,
              _primaryBlue,
              [
                'Nome: ${_selectedContact!.name}',
                if (_selectedContact!.email != null)
                  'Email: ${_selectedContact!.email}',
                if (_selectedContact!.phone != null)
                  'Telefone: ${_selectedContact!.phone}',
              ],
            ),
            const SizedBox(height: 16),
          ],

          // Resumo dos itens
          if (_saleItems.isNotEmpty) ...[
            _buildReviewCard(
              'Itens da Venda (${_saleItems.length})',
              Icons.shopping_cart,
              _accentPurple,
              _saleItems.map((item) {
                final name =
                    item.service?.name ?? item.product?.name ?? 'Item sem nome';
                return '$name - ${item.quantity}x US\$ ${item.unitPrice.toStringAsFixed(2)} = US\$ ${item.totalPrice.toStringAsFixed(2)}';
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],

          // Resumo dos pagamentos
          if (_salePayments.isNotEmpty) ...[
            _buildReviewCard(
              'Pagamentos (${_salePayments.length})',
              Icons.payment,
              _warningOrange,
              _salePayments.map((payment) {
                final type =
                    payment.isAdvancePayment ? 'Adiantamento' : 'Pagamento';
                final rate = ' (Cotação: R\$ ${(1.0 / payment.exchangeRateToUsd).toStringAsFixed(2)}/USD)';
                return '$type: ${payment.amountFormatted} via ${payment.paymentMethodName}$rate';
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],

          // Resumo financeiro final
          _buildReviewCard(
            'Resumo Financeiro',
            Icons.account_balance_wallet,
            remainingUsd > 0.01 ? _errorRed : _successGreen,
            [
              'Total da Venda: US\$ ${totalSaleUsd.toStringAsFixed(2)}',
              'Total Pago: US\$ ${totalPaidUsd.toStringAsFixed(2)}',
              'Saldo Pendente: US\$ ${remainingUsd.toStringAsFixed(2)}',
              if (remainingUsd > 0.01)
                '⚠️ Venda com saldo pendente - cliente deve pagar o restante'
              else
                '✅ Venda totalmente paga',
            ],
          ),

          const SizedBox(height: 24),

          // Status da venda
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  (remainingUsd > 0.01 ? _warningOrange : _successGreen)
                      .withValues(alpha: 0.1),
                  (remainingUsd > 0.01 ? _warningOrange : _successGreen)
                      .withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: (remainingUsd > 0.01 ? _warningOrange : _successGreen)
                    .withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  remainingUsd > 0.01 ? Icons.schedule : Icons.check_circle,
                  color: remainingUsd > 0.01 ? _warningOrange : _successGreen,
                  size: 48,
                ),
                const SizedBox(height: 12),
                Text(
                  remainingUsd > 0.01
                      ? 'Venda Parcialmente Paga'
                      : 'Venda Totalmente Paga',
                  style: TextStyle(
                    color: remainingUsd > 0.01 ? _warningOrange : _successGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  remainingUsd > 0.01
                      ? 'Esta venda será criada com status "Aguardando Pagamento". O cliente deve quitar o saldo pendente.'
                      : 'Esta venda será criada com status "Paga". Todos os valores foram quitados.',
                  style: TextStyle(
                    color: remainingUsd > 0.01 ? _warningOrange : _successGreen,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(
      String title, IconData icon, Color color, List<String> items) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),

          // Conteúdo
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: items
                  .map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          'â€¢ $item',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Exchange Rate Card
          _buildExchangeRateCard(),

          const SizedBox(height: 16),

          // Resumo da Venda
          _buildSaleSummaryCard(),

          const SizedBox(height: 16),

          // Actions Card
          _buildActionsCard(),
        ],
      ),
    );
  }

  Widget _buildExchangeRateCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _primaryBlue.withValues(alpha: 0.1),
              _secondaryBlue.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.currency_exchange,
                  color: _primaryBlue,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'Câmbio USD/BRL',
                  style: TextStyle(
                    color: _primaryBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            ExchangeRateDisplay(),
          ],
        ),
      ),
    );
  }

  Widget _buildSaleSummaryCard() {
    final totalAmountUsd =
        _saleItems.fold<double>(0, (sum, item) => sum + item.totalPrice);
    final exchangeRate = ref.watch(tourismDollarRateProvider);
    final totalAmountBrl = totalAmountUsd * exchangeRate;
    final brlFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _accentPurple.withValues(alpha: 0.1),
              _accentPurple.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.receipt_long,
                  color: _accentPurple,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'Resumo da Venda',
                  style: TextStyle(
                    color: _accentPurple,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Métricas
            _buildSummaryMetric(
                'Itens', '${_saleItems.length}', Icons.inventory),
            _buildSummaryMetric(
                'Pagamentos', '${_salePayments.length}', Icons.payment),
            _buildSummaryMetric(
                'Total (USD)',
                'US\$ ${totalAmountUsd.toStringAsFixed(2)}',
                Icons.attach_money),
            _buildSummaryMetric('Total (BRL)', brlFormat.format(totalAmountBrl),
                Icons.attach_money),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryMetric(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _successGreen.withValues(alpha: 0.1),
              _successGreen.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.settings,
                  color: _successGreen,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'Ações Rápidas',
                  style: TextStyle(
                    color: _successGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Botões de ação
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveDraft,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _neutralGray,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(_isSaving ? 'Salvando...' : 'Salvar Rascunho'),
              ),
            ),

            const SizedBox(height: 8),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _clearForm,
                style: OutlinedButton.styleFrom(
                  foregroundColor: _errorRed,
                  side: const BorderSide(color: _errorRed),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.clear),
                label: const Text('Limpar Tudo'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          // Botão Voltar
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _previousStep,
                style: OutlinedButton.styleFrom(
                  foregroundColor: _primaryBlue,
                  side: const BorderSide(color: _primaryBlue),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Voltar'),
              ),
            ),

          if (_currentStep > 0) const SizedBox(width: 16),

          // Botão Próximo/Finalizar
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isCurrentStepValid() ? _nextStep : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _getStepColor(),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: Icon(
                _currentStep == _stepTitles.length - 1
                    ? Icons.check
                    : Icons.arrow_forward,
              ),
              label: Text(
                _currentStep == _stepTitles.length - 1
                    ? 'Finalizar Venda'
                    : 'Próximo',
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isCurrentStepValid() {
    switch (_currentStep) {
      case 0:
        return _selectedContact != null;
      case 1:
        return _saleItems.isNotEmpty;
      case 2:
        return _salePayments.isNotEmpty;
      case 3:
        return true;
      default:
        return false;
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _stepAnimationController.reset();
      _stepAnimationController.forward();
    }
  }

  void _nextStep() {
    if (_currentStep < _stepTitles.length - 1) {
      setState(() {
        _currentStep++;
      });
      _stepAnimationController.reset();
      _stepAnimationController.forward();
    } else {
      _finalizeSale();
    }
  }

  Future<void> _finalizeSale() async {
    setState(() => _isSaving = true);

    try {
      final supabase = Supabase.instance.client;
      final authState = ref.read(authProvider);
      final currentUser = ref.read(currentUserProvider);

      dynamic userId;
      if (currentUser != null && authState.isAuthenticated) {
        userId = currentUser.id;
      } else {
        // Usuário padrão para desenvolvimento
        userId = '550e8400-e29b-41d4-a716-446655440101';
        print('Usando usuário padrão para desenvolvimento: $userId');
      }

      // 1. Calcular valores totais
      final totalAmountUsd =
          _saleItems.fold<double>(0, (sum, item) => sum + item.totalPrice);
      final currentExchangeRate = ref.read(tourismDollarRateProvider);
      final totalAmountBrl = totalAmountUsd * currentExchangeRate;
      final totalPaid = _salePayments.fold<double>(
          0.0, (sum, payment) => sum + (payment.amountInUsd ?? 0.0));

      // 2. Determinar status de pagamento
      String paymentStatus;
      String saleStatus;
      if (totalPaid >= totalAmountUsd) {
        paymentStatus = 'paid';
        saleStatus = 'completed';
      } else if (totalPaid > 0) {
        paymentStatus = 'partial';
        saleStatus = 'pending';
      } else {
        paymentStatus = 'pending';
        saleStatus = 'pending';
      }

      // 3. Criar a venda principal
      final saleData = {
        'customer_id': _selectedContact!.id,
        'user_id': userId,
        'currency_id': 1, // USD
        'exchange_rate_to_usd': 1.0 / currentExchangeRate,
        'total_amount': totalAmountUsd,
        'total_amount_brl': totalAmountBrl,
        'total_amount_usd': totalAmountUsd,
        'payment_status': paymentStatus,
        'status': saleStatus,
        'notes': null,
        'due_date': null,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      };

      final saleResponse =
          await supabase.from('sale').insert(saleData).select().single();

      final saleId = saleResponse['id'] as int;

      // 4. Criar os itens da venda
      for (final item in _saleItems) {
        final itemData = {
          'sales_id': saleId,
          'service_id': item.service?.id,
          'product_id': item.product?.productId,
          'quantity': item.quantity,
          'pax': item.pax,
          'unit_price_at_sale': item.unitPrice,
          'discount_percentage': item.discount,
          'discount_amount': item.discountAmount,
          'surcharge_percentage': item.surcharge,
          'surcharge_amount': item.surchargeAmount,
          'tax_percentage': item.tax,
          'tax_amount': item.taxAmount,
          'subtotal': item.subtotal,
          'item_total': item.totalPrice,
          'currency_id': 1, // USD
          'exchange_rate_to_usd': 1.0 / currentExchangeRate,
          'unit_price_in_brl': item.unitPrice * currentExchangeRate,
          'unit_price_in_usd': item.unitPrice,
          'item_total_in_brl': item.totalPrice * currentExchangeRate,
          'item_total_in_usd': item.totalPrice,
        };

        await supabase.from('sale_item').insert(itemData);
      }

      // 5. Criar os pagamentos da venda
      for (final payment in _salePayments) {
        final paymentData = {
          'sales_id': saleId,
          'payment_method_id': _getPaymentMethodId(
              payment.paymentMethodName), // Mapear nome para ID
          'amount': payment.amount,
          'currency_id':
              payment.currencyCode == 'USD' ? 1 : 2, // USD = 1, BRL = 2
          'payment_date': payment.paymentDate.toIso8601String(),
          'transaction_id': payment.transactionId,
          'is_advance_payment': payment.isAdvancePayment,
          'exchange_rate_to_usd': payment.exchangeRateToUsd,
          'amount_in_brl': payment.amountInBrl,
          'amount_in_usd': payment.amountInUsd,
        };

        await supabase.from('sale_payment').insert(paymentData);
      }

      // 6. Atualizar provider de vendas
      ref.read(salesProvider.notifier).fetchSalesForUser();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Venda criada com sucesso!'),
            backgroundColor: _successGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );

        // Navegar para a página de vendas no dashboard
        ref.read(dashboardPageProvider.notifier).state = DashboardPage.sales;
      }
    } catch (e) {
      print('Erro ao salvar venda: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar venda: $e'),
            backgroundColor: _errorRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _saveDraft() async {
    setState(() => _isSaving = true);

    try {
      // Implementar salvamento de rascunho
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Rascunho salvo!'),
            backgroundColor: _successGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar rascunho: $e'),
            backgroundColor: _errorRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _clearForm() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpar Formulário'),
        content: const Text('Tem certeza que deseja limpar todos os dados?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _currentStep = 0;
                _selectedContact = null;
                _saleItems.clear();
                _salePayments.clear();
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _errorRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Limpar'),
          ),
        ],
      ),
    );
  }

  // Widget para exibir itens contratados com opções de CRUD
  Widget _buildContractedItemsSection() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _primaryBlue.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Header expansível
          InkWell(
            onTap: () {
              setState(() {
                _showContractedItems = !_showContractedItems;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    _showContractedItems
                        ? Icons.expand_less
                        : Icons.expand_more,
                    color: _primaryBlue,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Itens Contratados (${_saleItems.length})',
                    style: const TextStyle(
                      color: _primaryBlue,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _primaryBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Total: ${_formatCurrency(_calculateTotal())}',
                      style: const TextStyle(
                        color: _primaryBlue,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Lista de itens (expandível)
          if (_showContractedItems) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: _saleItems.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;

                  return _buildContractedItemTile(index, item);
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  // Widget para cada item contratado
  Widget _buildContractedItemTile(int index, SaleItemData item) {
    final isService = item.service != null;
    final itemName = isService
        ? item.service!.name ?? 'Nome não informado'
        : item.product?.name ?? 'Nome não informado';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  itemName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildDetailRow('Qnt:', '${item.quantity}'),
                    const SizedBox(width: 8),
                    _buildDetailRow('Pax:', '${item.pax}'),
                    const SizedBox(width: 8),
                    _buildDetailRow('Preço:', _formatCurrency(item.unitPrice)),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatCurrency(item.totalPrice),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: _primaryBlue,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () => _editContractedItem(index),
                    icon: const Icon(Icons.edit, size: 16),
                    tooltip: 'Editar item',
                    color: _primaryBlue,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _duplicateContractedItem(index),
                    icon: const Icon(Icons.copy, size: 16),
                    tooltip: 'Duplicar item',
                    color: _secondaryBlue,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _removeContractedItem(index),
                    icon: const Icon(Icons.delete, size: 16),
                    tooltip: 'Remover item',
                    color: _errorRed,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Widget auxiliar para detalhes
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 11,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // Métodos para CRUD dos itens contratados
  void _editContractedItem(int index) {
    print('DEBUG: Editando item contratado #$index');
    // TODO: Implementar edição do item
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Editando item #$index'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _duplicateContractedItem(int index) {
    print('DEBUG: Duplicando item contratado #$index');
    final item = _saleItems[index];
    final newItem = SaleItemData(
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

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Item duplicado com sucesso!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _removeContractedItem(int index) {
    print('DEBUG: Removendo item contratado #$index');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Remoção'),
        content: const Text('Tem certeza que deseja remover este item?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _saleItems.removeAt(index);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Item removido com sucesso!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Remover'),
          ),
        ],
      ),
    );
  }

  // Método auxiliar para calcular total
  double _calculateTotal() {
    return _saleItems.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  // Método auxiliar para formatar moeda
  String _formatCurrency(double amount) {
    if (_selectedCurrency?.currencyCode == 'BRL') {
      return 'R\$ ${amount.toStringAsFixed(2)}';
    } else {
      return 'US\$ ${amount.toStringAsFixed(2)}';
    }
  }

  void _showAddPaymentModal() async {
    // Criar um objeto Sale temporário para o modal
    final totalAmount =
        _saleItems.fold<double>(0, (sum, item) => sum + item.totalPrice);
    final tempSale = Sale(
      id: 0, // ID temporário
      contactId: _selectedContact?.id ?? 0,
      contactName: _selectedContact?.name ?? '',
      userId: '1', // ID do usuário atual
      userName: 'Usuário Atual', // Nome do usuário
      totalAmount: totalAmount,
      currencyId: 2, // USD
      currencyCode: 'USD',
      totalAmountBrl: totalAmount * 5.0, // Taxa de câmbio exemplo
      totalAmountUsd: totalAmount,
      totalPaid: 0.0,
      totalPaidBrl: 0.0,
      totalPaidUsd: 0.0,
      remainingAmount: totalAmount,
      remainingAmountBrl: totalAmount * 5.0,
      remainingAmountUsd: totalAmount,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      items: [], // Itens serão calculados pelo modal
      payments: [], // Lista vazia temporária
    );

    final result = await showDialog<SalePaymentData>(
      context: context,
      builder: (context) => AddPaymentModal(
        sale: tempSale,
      ),
    );

    if (result != null) {
      setState(() {
        _salePayments.add(result);
      });
    }
  }

  // Função para mapear nome do método de pagamento para ID
  int _getPaymentMethodId(String methodName) {
    switch (methodName) {
      case 'PIX':
        return 1;
      case 'Cartão de Crédito':
        return 2;
      case 'Transferência Bancária':
        return 3;
      case 'Dinheiro':
        return 4;
      case 'Zelle':
        return 5;
      default:
        print(
            'AVISO: Método de pagamento desconhecido: $methodName. Usando PIX como padrão.');
        return 1; // PIX como padrão
    }
  }
}

// Modal AddPaymentModal agora é importado de ../widgets/add_payment_modal.dart

// Dialog para seleção de contatos
class _ContactSelectorDialog extends ConsumerStatefulWidget {
  final Function(Contact) onContactSelected;

  const _ContactSelectorDialog({
    required this.onContactSelected,
  });

  @override
  ConsumerState<_ContactSelectorDialog> createState() =>
      _ContactSelectorDialogState();
}

class _ContactSelectorDialogState
    extends ConsumerState<_ContactSelectorDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<Contact> _contacts = [];
  List<Contact> _filteredContacts = [];
  bool _isLoading = true;
  String _searchQuery = '';

  // Cores B2B
  static const Color _primaryBlue = Color(0xFF1565C0);
  static const Color _secondaryBlue = Color(0xFF42A5F5);
  static const Color _successGreen = Color(0xFF43A047);

  @override
  void initState() {
    super.initState();
    _loadContacts();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _filterContacts();
    });
  }

  void _filterContacts() {
    if (_searchQuery.isEmpty) {
      _filteredContacts = List.from(_contacts);
    } else {
      _filteredContacts = _contacts.where((contact) {
        final name = contact.name?.toLowerCase() ?? '';
        final email = contact.email?.toLowerCase() ?? '';
        final phone = contact.phone?.toLowerCase() ?? '';
        return name.contains(_searchQuery) ||
            email.contains(_searchQuery) ||
            phone.contains(_searchQuery);
      }).toList();
    }
  }

  Future<void> _loadContacts() async {
    setState(() => _isLoading = true);

    try {
      // Usar o FutureProvider para buscar contatos ativos
      final contactsList = await ref.read(contactsProvider(true).future);

      _contacts = contactsList
          .where((contact) => contact.name != null && contact.name!.isNotEmpty)
          .toList();

      _filterContacts();
    } catch (e) {
      print('Erro ao carregar contatos via provider: $e');
      // Fallback: tentar buscar diretamente do Supabase
      await _loadContactsFromSupabase();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadContactsFromSupabase() async {
    try {
      final response = await Supabase.instance.client
          .from('contacts')
          .select()
          .eq('is_active', true)
          .not('name', 'is', null)
          .order('name')
          .order('id', ascending: false).limit(100);

      _contacts =
          response.map<Contact>((item) => Contact.fromJson(item)).toList();
      _filterContacts();
    } catch (e) {
      print('Erro ao buscar contatos do Supabase: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar contatos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: 500,
        height: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(
                  Icons.person_search,
                  color: _primaryBlue,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Selecionar Cliente',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: _primaryBlue,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Search Field
            Container(
              decoration: BoxDecoration(
                color: _primaryBlue.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _primaryBlue.withValues(alpha: 0.2)),
              ),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Buscar por nome, email ou telefone...',
                  prefixIcon: Icon(Icons.search, color: _primaryBlue),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Results Count
            if (!_isLoading) ...[
              Text(
                '\${_filteredContacts.length} contatos encontrados',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Contacts List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredContacts.isEmpty
                      ? _buildEmptyState()
                      : _buildContactsList(),
            ),

            // Footer
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey[600],
                      side: BorderSide(color: Colors.grey[300]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _createNewContact,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _successGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Novo Cliente'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _searchQuery.isEmpty ? Icons.person_off : Icons.search_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty
                ? 'Nenhum contato encontrado'
                : 'Nenhum resultado para "\$_searchQuery"',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty
                ? 'Clique em "Novo Cliente" para adicionar'
                : 'Tente buscar com outros termos',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactsList() {
    return ListView.separated(
      itemCount: _filteredContacts.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final contact = _filteredContacts[index];
        return _buildContactTile(contact);
      },
    );
  }

  Widget _buildContactTile(Contact contact) {
    return InkWell(
      onTap: () {
        widget.onContactSelected(contact);
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _secondaryBlue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: _secondaryBlue.withValues(alpha: 0.3),
                ),
              ),
              child: Center(
                child: Text(
                  contact.name?.isNotEmpty == true
                      ? contact.name![0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: _secondaryBlue,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Contact Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contact.name ?? 'Nome não informado',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (contact.email != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      contact.email!,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                  if (contact.phone != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      contact.phone!,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Arrow Icon
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  void _createNewContact() {
    Navigator.pop(context);
    // TODO: Implementar navegação para tela de criação de contato
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidade de novo cliente em desenvolvimento'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
