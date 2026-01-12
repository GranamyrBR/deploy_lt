import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/enhanced_quotation_model.dart';
import '../services/pdf_generator_simple.dart';
import '../services/quotation_email_service.dart';
import '../services/quotation_whatsapp_service.dart';
import '../services/quotation_service.dart';
import 'quotation_status_manager.dart';

class QuotationManagementDialog extends ConsumerStatefulWidget {
  final Quotation quotation;
  final VoidCallback? onQuotationUpdated;

  const QuotationManagementDialog({
    super.key,
    required this.quotation,
    this.onQuotationUpdated,
  });

  @override
  ConsumerState<QuotationManagementDialog> createState() => _QuotationManagementDialogState();
}

class _QuotationManagementDialogState extends ConsumerState<QuotationManagementDialog> 
    with SingleTickerProviderStateMixin {
  bool _isGeneratingPdf = false;
  bool _isSendingEmail = false;
  bool _isSendingWhatsApp = false;
  bool _isSaving = false;
  String? _pdfFilePath;
  late List<QuotationItem> _items;
  late QuotationService _quotationService;
  late TabController _tabController;
  
  // Global key for safe scaffold context access
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.quotation.items);
    _quotationService = QuotationService();
    _tabController = TabController(length: 2, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Quotation get _currentQuotation => widget.quotation.copyWith(
    items: _items,
    subtotal: _calculateSubtotal(),
    total: _calculateTotal(),
  );

  double _calculateSubtotal() {
    return _items.fold<double>(0, (sum, item) => sum + item.value);
  }

  double _calculateTotal() {
    final subtotal = _calculateSubtotal();
    final discount = widget.quotation.discountAmount;
    final tax = widget.quotation.taxAmount;
    return subtotal - discount + tax;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Use a full-screen dialog with Scaffold to provide proper context for SnackBars
    return Dialog(
      child: ScaffoldMessenger(
        key: _scaffoldMessengerKey,
        child: Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                Icon(Icons.description, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Gerenciar Cotação'),
                      Text(
                        widget.quotation.quotationNumber,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              if (_isSaving)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else
                IconButton(
                  icon: const Icon(Icons.save),
                  tooltip: 'Salvar Cotacao',
                  onPressed: _saveQuotation,
                ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          body: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
              maxWidth: 700,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quotation Summary
                  _buildQuotationSummary(context),
                  const SizedBox(height: 24),
                  
                  // Items Section (Services & Products)
                  _buildItemsSection(context),
                  const SizedBox(height: 24),
                  
                  // PDF Generation Section
                  _buildPdfSection(context),
                  const SizedBox(height: 16),
                  
                  // Email Sending Section
                  _buildEmailSection(context),
                  const SizedBox(height: 16),
                  
                  // WhatsApp Sending Section
                  _buildWhatsAppSection(context),
                  const SizedBox(height: 16),
                  
                  // Status Section
                  _buildStatusSection(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuotationSummary(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Resumo da Cotação',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Client Information
            _buildInfoRow('Cliente:', widget.quotation.clientName),
            _buildInfoRow('Email:', widget.quotation.clientEmail),
            if (widget.quotation.clientPhone != null)
              _buildInfoRow('Telefone:', widget.quotation.clientPhone!),
            
            const SizedBox(height: 12),
            
            // Trip Information
            _buildInfoRow('Tipo:', widget.quotation.typeDisplayName),
            _buildInfoRow('Data:', '${widget.quotation.travelDate.day}/${widget.quotation.travelDate.month}/${widget.quotation.travelDate.year}'),
            _buildInfoRow('Passageiros:', widget.quotation.passengerCount.toString()),
            _buildInfoRow('Status:', widget.quotation.statusDisplayName),
            
            const SizedBox(height: 12),
            
            // Financial Summary (ATUALIZADO DINAMICAMENTE)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  _buildInfoRow('Subtotal:', _currentQuotation.formattedSubtotal),
                  if (_currentQuotation.taxAmount > 0)
                    _buildInfoRow('Taxas:', _currentQuotation.formattedTax),
                  if (_currentQuotation.discountAmount > 0)
                    _buildInfoRow('Desconto:', '-${_currentQuotation.formattedDiscount}'),
                  Divider(color: theme.colorScheme.outline),
                  _buildInfoRow('TOTAL:', _currentQuotation.formattedTotal, isTotal: true),
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Items Count
            _buildInfoRow('Itens:', '${_items.length} serviços/produtos'),
            
            if (widget.quotation.agency != null) ...[
              const SizedBox(height: 12),
              _buildInfoRow('Agência:', widget.quotation.agency!.name),
              if (widget.quotation.agencyCommissionRate != null)
                _buildInfoRow('Comissão:', '${widget.quotation.agencyCommissionRate}%'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildItemsSection(BuildContext context) {
    final theme = Theme.of(context);
    final total = _items.fold<double>(0, (sum, item) => sum + item.value);
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.shopping_cart, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Serviços e Produtos',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Adicionados na tela anterior',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Lista de items
            if (_items.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                ),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.warning_amber_rounded, size: 48, color: Colors.orange),
                      const SizedBox(height: 8),
                      Text(
                        '⚠️ Nenhum serviço ou produto foi adicionado',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Volte para a tela anterior e adicione itens',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Column(
                children: [
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      final unitPrice = item.value / item.quantity;
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              // Quantidade editável
                              SizedBox(
                                width: 80,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Qtd',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: theme.colorScheme.outline,
                                      ),
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.remove_circle_outline, size: 20),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          onPressed: item.quantity > 1
                                              ? () => _updateItemQuantity(index, item.quantity - 1)
                                              : null,
                                        ),
                                        Container(
                                          width: 30,
                                          alignment: Alignment.center,
                                          child: Text(
                                            '${item.quantity}',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.add_circle_outline, size: 20),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          onPressed: () => _updateItemQuantity(index, item.quantity + 1),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              
                              const SizedBox(width: 12),
                              
                              // Descrição e valores
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.description,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Valor unitario: USD ${unitPrice.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: theme.colorScheme.outline,
                                      ),
                                    ),
                                    Text(
                                      'Total: USD ${item.value.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Botão remover
                              IconButton(
                                icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
                                tooltip: 'Remover item',
                                onPressed: () => _removeItem(index),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'TOTAL:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'USD ${total.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // Método removido: usuário adiciona itens na tela anterior
  // Future<void> _addServicesProducts() - não mais necessário

  void _updateItemQuantity(int index, int newQuantity) {
    if (newQuantity < 1) return;
    
    setState(() {
      final item = _items[index];
      final unitPrice = item.value / item.quantity;
      final newValue = unitPrice * newQuantity;
      
      _items[index] = item.copyWith(
        quantity: newQuantity,
        value: newValue,
      );
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
    _showSafeSnackBar(
      message: 'Item removido',
      backgroundColor: Colors.orange,
    );
  }

  Future<void> _saveQuotation() async {
    if (!mounted) return;
    
    // Apenas datas são obrigatórias (validação removida de itens)
    
    setState(() {
      _isSaving = true;
    });

    try {
      print('=== SALVANDO COTACAO NO DB ===');
      print('Numero: ${_currentQuotation.quotationNumber}');
      print('Cliente: ${_currentQuotation.clientName}');
      print('Items: ${_items.length}');
      print('Total: ${_currentQuotation.total}');
      
      // Salvar cotação no banco de dados Supabase
      final result = await _quotationService.saveQuotation(_currentQuotation);
      
      print('=== RESULTADO ===');
      print('Success: ${result.success}');
      print('ID: ${result.id}');
      print('Error: ${result.errorMessage}');
      
      if (mounted) {
        if (result.success) {
          _showSafeSnackBar(
            message: '✅ Cotacao ${_currentQuotation.quotationNumber} salva! ID: ${result.id}',
            backgroundColor: Colors.green,
          );
          
          // Notificar parent que cotação foi atualizada
          widget.onQuotationUpdated?.call();
          
          // Fechar dialog após 1 segundo
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) Navigator.of(context).pop();
          });
        } else {
          _showSafeSnackBar(
            message: '❌ Erro: ${result.errorMessage ?? "Erro desconhecido"}',
            backgroundColor: Colors.red,
          );
        }
      }
    } catch (e) {
      print('=== ERRO CRITICO ===');
      print('Erro: $e');
      
      if (mounted) {
        _showSafeSnackBar(
          message: '❌ Erro ao salvar: $e',
          backgroundColor: Colors.red,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Widget _buildPdfSection(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.picture_as_pdf, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Documento PDF',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (_pdfFilePath != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'PDF Gerado com Sucesso',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Pronto para envio',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isGeneratingPdf ? null : _generatePdf,
                  icon: _isGeneratingPdf 
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.picture_as_pdf),
                  label: Text(_isGeneratingPdf ? 'Gerando PDF...' : 'Gerar PDF'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmailSection(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.email, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Envio por Email',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Client Email
            if (widget.quotation.clientContact?.canReceiveEmails ?? false) ...[
              _buildEmailRecipientButton(
                context,
                'Enviar para Cliente',
                widget.quotation.clientEmail,
                Icons.person,
                () => _sendEmailToClient(),
              ),
              const SizedBox(height: 8),
            ],
            
            // Agency Email
            if (widget.quotation.agency?.email != null) ...[
              _buildEmailRecipientButton(
                context,
                'Enviar para Agência',
                widget.quotation.agency!.email!,
                Icons.business,
                () => _sendEmailToAgency(),
              ),
              const SizedBox(height: 8),
            ],
            
            // Custom Email
            _buildEmailRecipientButton(
              context,
              'Enviar para Outro Email',
              'Personalizar destinatário',
              Icons.edit,
              () => _sendEmailToCustom(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWhatsAppSection(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.chat, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Envio por WhatsApp',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Client WhatsApp
            if (widget.quotation.clientContact?.canReceiveWhatsApp ?? false) ...[
              _buildWhatsAppRecipientButton(
                context,
                'Enviar para Cliente',
                widget.quotation.clientContact!.whatsapp!,
                Icons.person,
                () => _sendWhatsAppToClient(),
              ),
              const SizedBox(height: 8),
            ],
            
            // Custom WhatsApp
            _buildWhatsAppRecipientButton(
              context,
              'Enviar para Outro Número',
              'Personalizar número',
              Icons.edit,
              () => _sendWhatsAppToCustom(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSection(BuildContext context) {
    return QuotationStatusManager(
      currentStatus: widget.quotation.status,
      onStatusChanged: _updateQuotationStatus,
      enabled: !_isSaving,
    );
  }

  /// Atualiza o status da cotação
  Future<void> _updateQuotationStatus(QuotationStatus newStatus) async {
    setState(() {
      _isSaving = true;
    });

    try {
      // Cria cotação atualizada com novo status e datas correspondentes
      final DateTime now = DateTime.now();
      Quotation updatedQuotation = _currentQuotation.copyWith(
        status: newStatus,
      );

      // Atualiza as datas conforme o status
      switch (newStatus) {
        case QuotationStatus.sent:
          updatedQuotation = updatedQuotation.copyWith(sentDate: now);
          break;
        case QuotationStatus.viewed:
          updatedQuotation = updatedQuotation.copyWith(viewedDate: now);
          break;
        case QuotationStatus.accepted:
          updatedQuotation = updatedQuotation.copyWith(acceptedDate: now);
          break;
        case QuotationStatus.rejected:
          updatedQuotation = updatedQuotation.copyWith(rejectedDate: now);
          break;
        case QuotationStatus.expired:
          // Status expirado - não atualiza datas
          break;
        case QuotationStatus.cancelled:
          // Status cancelado - não atualiza datas
          break;
        case QuotationStatus.draft:
          // Limpa as datas se voltar para rascunho
          updatedQuotation = updatedQuotation.copyWith(
            sentDate: null,
            viewedDate: null,
            acceptedDate: null,
            rejectedDate: null,
          );
          break;
      }

      // Salva no banco
      await _quotationService.saveQuotation(updatedQuotation);

      if (mounted) {
        _scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('Status atualizado para: ${_getStatusDisplayName(newStatus)}'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        // Chama callback se existir
        if (widget.onQuotationUpdated != null) {
          widget.onQuotationUpdated!();
        }

        // Fecha o dialog após salvar
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        _scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  String _getStatusDisplayName(QuotationStatus status) {
    switch (status) {
      case QuotationStatus.draft:
        return 'Rascunho';
      case QuotationStatus.sent:
        return 'Enviado';
      case QuotationStatus.viewed:
        return 'Visualizado';
      case QuotationStatus.accepted:
        return 'Aceito';
      case QuotationStatus.rejected:
        return 'Rejeitado';
      case QuotationStatus.expired:
        return 'Expirado';
      case QuotationStatus.cancelled:
        return 'Cancelado';
    }
  }

  Widget _buildInfoRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailRecipientButton(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _isSendingEmail ? null : onPressed,
        icon: _isSendingEmail
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(icon, size: 20),
        label: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _buildWhatsAppRecipientButton(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _isSendingWhatsApp ? null : onPressed,
        icon: _isSendingWhatsApp
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(icon, size: 20, color: Colors.green),
        label: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.green,
          side: BorderSide(color: Colors.green.withValues(alpha: 0.3)),
        ),
      ),
    );
  }

  // Safe snackbar method to avoid widget lifecycle issues
  void _showSafeSnackBar({
    required String message,
    required Color backgroundColor,
  }) {
    // Use Timer to defer the operation and ensure widget is still mounted
    Timer(const Duration(milliseconds: 100), () {
      if (mounted) {
        try {
          // Use the scaffold messenger key for safe context access
          if (_scaffoldMessengerKey.currentState != null) {
            _scaffoldMessengerKey.currentState!.showSnackBar(
              SnackBar(
                content: Text(message),
                backgroundColor: backgroundColor,
                duration: const Duration(seconds: 3),
              ),
            );
          } else {
            debugPrint('ScaffoldMessenger key not available, skipping snackbar');
          }
        } catch (e) {
          debugPrint('Could not show snackbar: $e');
        }
      } else {
        debugPrint('Widget no longer mounted, skipping snackbar');
      }
    });
  }

  // Action methods
  Future<void> _generatePdf() async {
    if (!mounted) return;
    
    setState(() {
      _isGeneratingPdf = true;
    });

    try {
      final pdfFile = await PdfGeneratorSimple.generatePdf(_currentQuotation);
      
      // Safely update state and show feedback
      if (mounted) {
        setState(() {
          _pdfFilePath = pdfFile.path;
        });
        
        // Use a safer approach for showing snackbar
        _showSafeSnackBar(
          message: 'PDF gerado com sucesso!',
          backgroundColor: Colors.green,
        );
      }
    } catch (e) {
      if (mounted) {
        _showSafeSnackBar(
          message: 'Erro ao gerar PDF: $e',
          backgroundColor: Colors.red,
        );
      }
    } finally {
      // Always reset the loading state if widget is still mounted
      if (mounted) {
        setState(() {
          _isGeneratingPdf = false;
        });
      }
    }
  }

  Future<void> _sendEmailToClient() async {
    await _sendEmail(() => QuotationEmailService.sendQuotationToClient(
      quotation: _currentQuotation,
    ));
  }

  Future<void> _sendEmailToAgency() async {
    await _sendEmail(() => QuotationEmailService.sendQuotationToAgency(
      quotation: _currentQuotation,
    ));
  }

  Future<void> _sendEmailToCustom() async {
    final emailController = TextEditingController();
    final nameController = TextEditingController();
    final messageController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enviar Email Personalizado'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email do Destinatário *',
                  hintText: 'email@exemplo.com',
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome do Destinatário',
                  hintText: 'Nome completo',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: messageController,
                decoration: const InputDecoration(
                  labelText: 'Mensagem Adicional',
                  hintText: 'Mensagem personalizada...',
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (emailController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Por favor, insira o email do destinatário')),
                );
                return;
              }
              Navigator.of(context).pop(true);
            },
            child: const Text('Enviar'),
          ),
        ],
      ),
    );

    if (result == true) {
      await _sendEmail(() => QuotationEmailService.sendQuotationCopy(
        quotation: _currentQuotation,
        copyEmail: emailController.text.trim(),
        copyName: nameController.text.trim().isEmpty ? null : nameController.text.trim(),
        additionalMessage: messageController.text.trim().isEmpty ? null : messageController.text.trim(),
      ));
    }
  }

  Future<void> _sendEmail(Future<bool> Function() emailFunction) async {
    setState(() {
      _isSendingEmail = true;
    });

    try {
      final success = await emailFunction();
      
      if (mounted) {
        if (success) {
          _showSafeSnackBar(
            message: 'Email enviado com sucesso!',
            backgroundColor: Colors.green,
          );
          
          // Update quotation status
          widget.onQuotationUpdated?.call();
        } else {
          _showSafeSnackBar(
            message: 'Erro ao enviar email. Verifique se o aplicativo de email está configurado.',
            backgroundColor: Colors.orange,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _showSafeSnackBar(
          message: 'Erro ao enviar email: $e',
          backgroundColor: Colors.red,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSendingEmail = false;
        });
      }
    }
  }

  Future<void> _sendWhatsAppToClient() async {
    await _sendWhatsApp(() => QuotationWhatsAppService.sendQuotationToClient(
      quotation: widget.quotation,
    ));
  }

  Future<void> _sendWhatsAppToCustom() async {
    final phoneController = TextEditingController();
    final nameController = TextEditingController();
    final messageController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enviar WhatsApp Personalizado'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Número de WhatsApp *',
                  hintText: '+55 11 91234-5678',
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome do Destinatário',
                  hintText: 'Nome completo',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: messageController,
                decoration: const InputDecoration(
                  labelText: 'Mensagem Adicional',
                  hintText: 'Mensagem personalizada...',
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (phoneController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Por favor, insira o número de WhatsApp')),
                );
                return;
              }
              Navigator.of(context).pop(true);
            },
            child: const Text('Enviar'),
          ),
        ],
      ),
    );

    if (result == true) {
      await _sendWhatsApp(() => QuotationWhatsAppService.sendQuotationCopy(
        quotation: widget.quotation,
        phoneNumber: phoneController.text.trim(),
        recipientName: nameController.text.trim().isEmpty ? null : nameController.text.trim(),
        additionalMessage: messageController.text.trim().isEmpty ? null : messageController.text.trim(),
      ));
    }
  }

  Future<void> _sendWhatsApp(Future<bool> Function() whatsappFunction) async {
    setState(() {
      _isSendingWhatsApp = true;
    });

    try {
      final success = await whatsappFunction();
      
      if (mounted) {
        if (success) {
          _showSafeSnackBar(
            message: 'WhatsApp aberto com sucesso!',
            backgroundColor: Colors.green,
          );
        } else {
          _showSafeSnackBar(
            message: 'Erro ao abrir WhatsApp. Verifique se o aplicativo está instalado.',
            backgroundColor: Colors.orange,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _showSafeSnackBar(
          message: 'Erro ao enviar WhatsApp: $e',
          backgroundColor: Colors.red,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSendingWhatsApp = false;
        });
      }
    }
  }
}