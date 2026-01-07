import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/sale.dart';
import '../providers/exchange_rate_provider.dart';
import 'exchange_rate_display.dart';

// Classe para retornar os dados do pagamento
class SalePaymentData {
  final String paymentMethodName;
  final double amount;
  final String currencyCode;
  final DateTime paymentDate;
  final String? transactionId;
  final bool isAdvancePayment;
  final double exchangeRateToUsd;
  final double amountInBrl;
  final double amountInUsd;

  SalePaymentData({
    required this.paymentMethodName,
    required this.amount,
    required this.currencyCode,
    required this.paymentDate,
    this.transactionId,
    required this.isAdvancePayment,
    required this.exchangeRateToUsd,
    required this.amountInBrl,
    required this.amountInUsd,
  });

  // Métodos formatadores
  String get amountFormatted {
    final format = NumberFormat.currency(
      locale: currencyCode == 'USD' ? 'en_US' : 'pt_BR',
      symbol: currencyCode == 'USD' ? r'$' : 'R\$',
      decimalDigits: 2,
    );
    return format.format(amount);
  }

  String get paymentDateFormatted {
    return DateFormat('dd/MM/yyyy').format(paymentDate);
  }

  String get dualCurrencyDisplay {
    final brlFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$', decimalDigits: 2);
    final usdFormat = NumberFormat.currency(locale: 'en_US', symbol: r'$', decimalDigits: 2);
    
    if (currencyCode == 'BRL') {
      return '$amountFormatted (${usdFormat.format(amountInUsd)})';
    } else {
      return '$amountFormatted (${brlFormat.format(amountInBrl)})';
    }
    return amountFormatted;
  }
}

class AddPaymentModal extends ConsumerStatefulWidget {
  final Sale sale;

  const AddPaymentModal({
    required this.sale,
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState<AddPaymentModal> createState() => _AddPaymentModalState();
}

class _AddPaymentModalState extends ConsumerState<AddPaymentModal> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _transactionIdController = TextEditingController();

  static const Color _primaryBlue = Color(0xFF1565C0);
  static const Color _warningOrange = Color(0xFFFF9800);
  static const Color _successGreen = Color(0xFF43A047);
  static const Color _errorRed = Color(0xFFE53935);

  String _selectedPaymentMethod = 'PIX';
  String _selectedCurrency = 'BRL';
  bool _isAdvancePayment = false;
  DateTime _selectedDate = DateTime.now();
  double? _exchangeRateSnapshot;
  bool _isCalculating = false;

  final List<String> _paymentMethods = [
    'PIX', 'Cartão de Crédito', 'Transferência Bancária', 'Dinheiro', 'Zelle'
  ];

  @override
  void initState() {
    super.initState();
    _captureExchangeRate();
    _isAdvancePayment = widget.sale.remainingAmountUsd > 0;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _transactionIdController.dispose();
    super.dispose();
  }

  void _captureExchangeRate() {
    final currentRate = ref.read(tourismDollarRateProvider);
    setState(() {
      _exchangeRateSnapshot = currentRate;
    });
  }

  @override
  Widget build(BuildContext context) {
    final remainingUsd = widget.sale.remainingAmountUsd;
    // Usar a taxa de câmbio manual atual em vez do snapshot
    final exchangeRate = ref.watch(manualExchangeRateProvider);
    final brlFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.payment, color: _warningOrange, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Registrar Pagamento para Venda #${widget.sale.id}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: _warningOrange,
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
              _buildSaleSummary(remainingUsd, exchangeRate),
              const SizedBox(height: 20),
              if (remainingUsd > 0.01) ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _fillRemainingAmount(remainingUsd, exchangeRate),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _warningOrange,
                      side: BorderSide(color: _warningOrange),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.auto_fix_high, size: 16),
                    label: Text(
                      'Pagar Valor Restante (${_selectedCurrency == 'BRL' ? brlFormat.format(remainingUsd * exchangeRate) : 'US\$ ${remainingUsd.toStringAsFixed(2)}'})',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
              // Seção de Câmbio
              _buildExchangeRateSection(),
              const SizedBox(height: 8),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value: _selectedPaymentMethod,
                        decoration: _buildInputDecoration('Método de Pagamento'),
                        items: _paymentMethods.map((method) => 
                          DropdownMenuItem(value: method, child: Text(method))
                        ).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedPaymentMethod = value!;
                          });
                        },
                        validator: (value) => value == null ? 'Selecione um método' : null,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedCurrency,
                              decoration: _buildInputDecoration('Moeda'),
                              items: const [
                                DropdownMenuItem(value: 'BRL', child: Text('BRL - Real')),
                                DropdownMenuItem(value: 'USD', child: Text('USD - Dólar')),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedCurrency = value!;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Row(
                              children: [
                                Checkbox(
                                  value: _isAdvancePayment,
                                  onChanged: (value) {
                                    setState(() {
                                      _isAdvancePayment = value ?? false;
                                    });
                                  },
                                ),
                                const Text('Adiantamento'),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _amountController,
                        decoration: _buildInputDecoration('Valor ($_selectedCurrency)'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                          final currentExchangeRate = ref.read(manualExchangeRateProvider);
                          return _validatePaymentAmount(value, remainingUsd, currentExchangeRate);
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _transactionIdController,
                        decoration: _buildInputDecoration('ID da Transação (opcional)'),
                        maxLength: 50,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey[600],
                        side: BorderSide(color: Colors.grey[300]!),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _addPayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _successGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Adicionar Pagamento'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSaleSummary(double remainingUsd, double exchangeRate) {
    final brlFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _primaryBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _primaryBlue.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumo da Venda',
            style: TextStyle(
              color: _primaryBlue,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total da Venda:'),
              Text(
                'US\$ ${widget.sale.totalAmountUsd.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Pago:'),
              Text(
                'US\$ ${widget.sale.totalPaidUsd.toStringAsFixed(2)}',
                style: TextStyle(color: _successGreen, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Saldo Pendente:'),
              Text(
                'US\$ ${remainingUsd.toStringAsFixed(2)}',
                style: TextStyle(
                  color: remainingUsd > 0 ? _errorRed : _successGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Em Reais:'),
              Text(
                brlFormat.format(remainingUsd * exchangeRate),
                style: TextStyle(
                  color: remainingUsd > 0 ? _errorRed : _successGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: _primaryBlue),
      ),
    );
  }

  Widget _buildExchangeRateSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.currency_exchange,
                color: Colors.blue[600],
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                'Cotação do Dólar',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const ExchangeRateDisplay(),
        ],
      ),
    );
  }

  String? _validatePaymentAmount(String? value, double remainingUsd, double exchangeRate) {
    if (value == null || value.isEmpty) {
      return 'Digite o valor';
    }
    
    final amount = double.tryParse(value);
    if (amount == null || amount <= 0) {
      return 'Digite um valor válido';
    }
    
    final amountInUsd = _selectedCurrency == 'BRL' ? amount / exchangeRate : amount;
    
    if (amountInUsd > remainingUsd + 0.01) { // +0.01 para tolerância de arredondamento
      return 'Valor excede o saldo pendente (US\$ ${remainingUsd.toStringAsFixed(2)})';
    }
    
    return null;
  }

  void _fillRemainingAmount(double remainingUsd, double exchangeRate) {
    // Usar a taxa de câmbio manual atual
    final currentExchangeRate = ref.read(manualExchangeRateProvider);
    final amount = _selectedCurrency == 'BRL' 
        ? remainingUsd * currentExchangeRate 
        : remainingUsd;
    
    setState(() {
      _amountController.text = amount.toStringAsFixed(2);
      _isAdvancePayment = false;
    });
  }

  void _addPayment() {
    if (!_formKey.currentState!.validate()) return;
    
    final amount = double.parse(_amountController.text);
    // Usar a taxa de câmbio manual definida pela atendente
    final exchangeRate = ref.read(manualExchangeRateProvider);
    
    double amountInBrl;
    double amountInUsd;
    
    if (_selectedCurrency == 'BRL') {
      amountInBrl = amount;
      amountInUsd = amount / exchangeRate;
    } else {
      amountInUsd = amount;
      amountInBrl = amount * exchangeRate;
    }
    
    // CORREÇÃO CRÍTICA: exchangeRateToUsd deve ser a taxa para converter para USD
    // Se pagamento em BRL: exchangeRateToUsd = 1/exchangeRate (ex: 1/5.50 = 0.1818)
    // Se pagamento em USD: exchangeRateToUsd = 1.0 (não há conversão)
    final exchangeRateToUsd = _selectedCurrency == 'BRL' ? 1.0 / exchangeRate : 1.0;
    
    final paymentData = SalePaymentData(
      paymentMethodName: _selectedPaymentMethod,
      amount: amount,
      currencyCode: _selectedCurrency,
      paymentDate: _selectedDate,
      transactionId: _transactionIdController.text.isNotEmpty 
          ? _transactionIdController.text 
          : null,
      isAdvancePayment: _isAdvancePayment,
      exchangeRateToUsd: exchangeRateToUsd,
      amountInBrl: amountInBrl,
      amountInUsd: amountInUsd,
    );
    
    Navigator.pop(context, paymentData);
  }
}
