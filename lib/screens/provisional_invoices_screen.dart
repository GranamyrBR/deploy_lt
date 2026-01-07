import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/provisional_invoice.dart';
import '../providers/sales_provider.dart';
import '../models/currency.dart';
import '../widgets/base_screen_layout.dart';
import '../services/invoices_service.dart';
import '../models/provisional_invoice_item.dart';

class ProvisionalInvoicesScreen extends ConsumerWidget {
  const ProvisionalInvoicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoiceAsync = ref.watch(filteredInvoicesProvider);
    final currencyAsync = ref.watch(currenciesProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final created = await showDialog<bool>(
            context: context,
            builder: (ctx) => const _CreateProvisionalInvoiceDialog(),
          );
          if (created == true) {
            // Atualiza lista
            ref.refresh(filteredInvoicesProvider);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Fatura provisória criada')),
            );
          }
        },
        child: const Icon(Icons.add),
      ),
      body: BaseScreenLayout(
        title: 'Faturas Provisórias',
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt),
            onPressed: () => _showFilters(context, ref),
          ),
        ],
        child: invoiceAsync.when(
          data: (invoice) => currencyAsync.when(
            data: (currency) => _buildInvoicesList(context, invoice, currency),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Erro ao carregar moedas: $e')),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Erro ao carregar faturas: $e')),
        ),
      ),
    );
  }

  void _showFilters(BuildContext context, WidgetRef ref) {
    // TODO: implementar filtros de faturas
    showDialog(
      context: context,
      builder: (context) => const AlertDialog(
        title: Text('Filtros'),
        content: Text('Filtros de faturas em desenvolvimento.'),
      ),
    );
  }

  Widget _buildInvoicesList(BuildContext context, List<ProvisionalInvoice> invoice, List<Currency> currency) {
    if (invoice.isEmpty) {
      return const Center(child: Text('Nenhuma fatura provisória encontrada.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: invoice.length,
      itemBuilder: (context, index) {
        final selectedInvoice = invoice[index];
        final selectedCurrency = currency.firstWhere(
          (c) => c.currencyCode == selectedInvoice.currencyCode,
          orElse: () => Currency(
            currencyId: 0,
            currencyCode: selectedInvoice.currencyCode,
            currencyName: selectedInvoice.currencyCode,
            exchangeRateToUsd: selectedInvoice.exchangeRateToUsd ?? 0.0, // Sem fallback - cotação deve ser definida manualmente
          ),
        );
        return ProvisionalInvoiceCard(invoice: selectedInvoice, currency: selectedCurrency);
      },
    );
  }
}

class ProvisionalInvoiceCard extends StatelessWidget {
  final ProvisionalInvoice invoice;
  final Currency currency;
  const ProvisionalInvoiceCard({super.key, required this.invoice, required this.currency});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Fatura #${invoice.invoiceNumber}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Chip(
                  label: Text(invoice.statusDisplay),
                  backgroundColor: invoice.statusColor,
                  labelStyle: const TextStyle(color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Conta: ${invoice.accountName}'),
            Text('Data de emissão: ${invoice.issueDateFormatted}'),
            if (invoice.dueDateFormatted != null)
              Text('Vencimento: ${invoice.dueDateFormatted}'),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Valor: ',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(invoice.dualCurrencyDisplay),
              ],
            ),
            Text('Moeda: ${invoice.currencyCode}'),
            if (invoice.exchangeRateToUsd != null)
              Text('Cotação do dia: R\$ ${(1.0 / invoice.exchangeRateToUsd!).toStringAsFixed(2)}/USD'),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.visibility),
                  onPressed: () {
                    // TODO: abrir detalhe da fatura
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    // TODO: editar fatura
                  },
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.receipt_long, size: 16),
                  label: const Text('Gerar Fatura'),
                  onPressed: () async {
                    final service = InvoicesService();
                    try {
                      final result = await service.createFinalInvoiceFromProvisional(invoice);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Fatura final gerada')), 
                        );
                        _showInvoicePreview(context, result);
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Erro ao gerar fatura: $e')),
                        );
                      }
                    }
                  },
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.email, size: 16),
                  label: const Text('Enviar'),
                  onPressed: () {
                    _showInvoicePreview(context, {
                      'invoice_number': invoice.invoiceNumber,
                      'total_amount': invoice.totalAmount,
                      'issued_date': invoice.issueDate,
                      'due_date': invoice.dueDate,
                      'account_name': invoice.accountName,
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showInvoicePreview(BuildContext context, Map<String, dynamic> inv) {
    showDialog(
      context: context,
      builder: (context) {
        return _InvoicePreviewDialog(invoice: invoice, currency: currency, inv: inv);
      },
    );
  }
}

class _InvoicePreviewDialog extends StatefulWidget {
  final ProvisionalInvoice invoice;
  final Currency currency;
  final Map<String, dynamic> inv;
  const _InvoicePreviewDialog({required this.invoice, required this.currency, required this.inv});
  @override
  State<_InvoicePreviewDialog> createState() => _InvoicePreviewDialogState();
}

class _InvoicePreviewDialogState extends State<_InvoicePreviewDialog> {
  final _service = InvoicesService();
  List<ProvisionalInvoiceItem> _items = [];
  bool _loading = true;
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _subjectController = TextEditingController(text: 'Fatura ${DateTime.now().year}');

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    try {
      final items = await _service.getProvisionalInvoiceItems(widget.invoice.id);
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Image.asset('web/icons/lecotour.png', width: 28, height: 28, errorBuilder: (_, __, ___) => const SizedBox()),
          const SizedBox(width: 8),
          Expanded(child: Text('Fatura ${widget.inv['invoice_number'] ?? widget.invoice.invoiceNumber}')),
        ],
      ),
      content: SizedBox(
        width: 720,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Conta: ${widget.inv['account_name'] ?? widget.invoice.accountName}', style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text('Emitida em: ${widget.inv['issued_date'] ?? widget.invoice.issueDateFormatted}'),
                    if (widget.inv['due_date'] != null || widget.invoice.dueDateFormatted != null)
                      Text('Vencimento: ${widget.inv['due_date'] ?? widget.invoice.dueDateFormatted}'),
                    const SizedBox(height: 12),
                    Text('Valor: ${widget.invoice.dualCurrencyDisplay}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('Moeda: ${widget.currency.currencyCode}'),
                    const SizedBox(height: 16),
                    const Text('Itens', style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Table(
                      columnWidths: const {
                        0: FlexColumnWidth(3),
                        1: FlexColumnWidth(1),
                        2: FlexColumnWidth(2),
                        3: FlexColumnWidth(2),
                      },
                      children: [
                        const TableRow(children: [
                          Padding(padding: EdgeInsets.all(6), child: Text('Descrição', style: TextStyle(fontWeight: FontWeight.w600))),
                          Padding(padding: EdgeInsets.all(6), child: Text('Qtd', style: TextStyle(fontWeight: FontWeight.w600))),
                          Padding(padding: EdgeInsets.all(6), child: Text('Unitário', style: TextStyle(fontWeight: FontWeight.w600))),
                          Padding(padding: EdgeInsets.all(6), child: Text('Total', style: TextStyle(fontWeight: FontWeight.w600))),
                        ]),
                        ..._items.map((it) => TableRow(children: [
                          Padding(padding: const EdgeInsets.all(6), child: Text(it.serviceName)),
                          Padding(padding: const EdgeInsets.all(6), child: Text('${it.quantity}')),
                          Padding(padding: const EdgeInsets.all(6), child: Text(it.unitPriceFormatted)),
                          Padding(padding: const EdgeInsets.all(6), child: Text(it.dualCurrencyDisplay)),
                        ])).toList(),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('Enviar por email', style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(child: TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email do destinatário'))),
                      const SizedBox(width: 8),
                      Expanded(child: TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Nome do destinatário'))),
                    ]),
                    const SizedBox(height: 8),
                    TextField(controller: _subjectController, decoration: const InputDecoration(labelText: 'Assunto')),
                  ],
                ),
              ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fechar')),
        ElevatedButton.icon(
          onPressed: () async {
            await _service.sendProvisionalInvoiceReminder(
              provisionalInvoiceId: widget.invoice.id,
              toEmail: _emailController.text.trim(),
              toName: _nameController.text.trim(),
              subject: _subjectController.text.trim(),
              message: 'Fatura ${widget.invoice.invoiceNumber} no valor de ${widget.invoice.dualCurrencyDisplay}',
            );
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registro de envio criado')));
            }
          },
          icon: const Icon(Icons.email, size: 16),
          label: const Text('Enviar por email'),
        ),
        ElevatedButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Use Ctrl+P para imprimir/Salvar PDF')));
          },
          icon: const Icon(Icons.print, size: 16),
          label: const Text('Imprimir/Salvar PDF'),
        ),
      ],
    );
  }
}
class _CreateProvisionalInvoiceDialog extends StatefulWidget {
  const _CreateProvisionalInvoiceDialog();
  @override
  State<_CreateProvisionalInvoiceDialog> createState() => _CreateProvisionalInvoiceDialogState();
}

class _CreateProvisionalInvoiceDialogState extends State<_CreateProvisionalInvoiceDialog> {
  final _service = InvoicesService();
  final _formKey = GlobalKey<FormState>();
  final _totalController = TextEditingController();
  final _netController = TextEditingController();
  DateTime _issueDate = DateTime.now();
  DateTime? _dueDate;
  int? _accountId;
  int? _currencyId;
  String _invoiceNumber = '';
  bool _loading = true;
  List<Map<String, dynamic>> _accounts = [];
  List<Map<String, dynamic>> _currencies = [];

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      final inv = await _service.generateInvoiceNumber();
      final accounts = await _service.getAccountsSimple();
      final currencies = await _service.getCurrenciesSimple();
      setState(() {
        _invoiceNumber = inv;
        _accounts = accounts;
        _currencies = currencies;
        _loading = false;
      });
    } catch (e) {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nova Fatura Provisória'),
      content: SizedBox(
        width: 600,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(children: [
                      Expanded(child: TextFormField(
                        initialValue: _invoiceNumber,
                        readOnly: true,
                        decoration: const InputDecoration(labelText: 'Número da Fatura'),
                      )),
                    ]),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      value: _accountId,
                      items: _accounts.map((a) => DropdownMenuItem<int>(
                        value: a['id'] as int,
                        child: Text(a['name'] as String),
                      )).toList(),
                      onChanged: (v) => setState(() { _accountId = v; }),
                      decoration: const InputDecoration(labelText: 'Conta'),
                      validator: (v) => v == null ? 'Selecione a conta' : null,
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      value: _currencyId,
                      items: _currencies.map((c) => DropdownMenuItem<int>(
                        value: c['currency_id'] as int,
                        child: Text('${c['currency_code']} - ${c['currency_name']}'),
                      )).toList(),
                      onChanged: (v) => setState(() { _currencyId = v; }),
                      decoration: const InputDecoration(labelText: 'Moeda'),
                      validator: (v) => v == null ? 'Selecione a moeda' : null,
                    ),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(child: TextFormField(
                        controller: _totalController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Valor Total'),
                        validator: (v) => (v == null || v.isEmpty) ? 'Informe o valor' : null,
                      )),
                      const SizedBox(width: 8),
                      Expanded(child: TextFormField(
                        controller: _netController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Valor Líquido'),
                        validator: (v) => (v == null || v.isEmpty) ? 'Informe o valor' : null,
                      )),
                    ]),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(child: _DateField(
                        label: 'Emissão',
                        date: _issueDate,
                        onPick: (d) => setState(() { _issueDate = d; }),
                      )),
                      const SizedBox(width: 8),
                      Expanded(child: _DateField(
                        label: 'Vencimento',
                        date: _dueDate,
                        onPick: (d) => setState(() { _dueDate = d; }),
                      )),
                    ]),
                  ],
                ),
              ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
        ElevatedButton.icon(
          onPressed: _loading ? null : () async {
            if (!_formKey.currentState!.validate()) return;
            try {
              final total = double.parse(_totalController.text.replaceAll(',', '.'));
              final net = double.parse(_netController.text.replaceAll(',', '.'));
              final data = {
                'account_id': _accountId,
                'invoice_number': _invoiceNumber,
                'issue_date': _issueDate.toIso8601String(),
                'due_date': _dueDate?.toIso8601String(),
                'total_amount': total,
                'net_amount': net,
                'currency_id': _currencyId,
                'status': 'Pending',
              };
              await _service.createProvisionalInvoice(data);
              if (mounted) Navigator.pop(context, true);
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
              }
            }
          },
          icon: const Icon(Icons.save, size: 16),
          label: const Text('Criar'),
        ),
      ],
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? date;
  final Function(DateTime) onPick;
  const _DateField({required this.label, required this.date, required this.onPick});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final now = DateTime.now();
        final initial = date ?? now;
        final picked = await showDatePicker(
          context: context,
          initialDate: initial,
          firstDate: DateTime(now.year - 1),
          lastDate: DateTime(now.year + 2),
        );
        if (picked != null) onPick(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: Text(date != null ? '${date!.year}-${date!.month.toString().padLeft(2, '0')}-${date!.day.toString().padLeft(2, '0')}' : 'Selecionar'),
      ),
    );
  }
}
