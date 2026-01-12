import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Modal mini para registrar datas de viagem rapidamente
/// Usado para leads que ainda não fecharam cotação completa
class QuickDatesDialog extends StatefulWidget {
  final String contactName;
  final String contactPhone;
  final int contactId;
  final DateTime? initialDepartureDate;
  final DateTime? initialReturnDate;

  const QuickDatesDialog({
    super.key,
    required this.contactName,
    required this.contactPhone,
    required this.contactId,
    this.initialDepartureDate,
    this.initialReturnDate,
  });

  @override
  State<QuickDatesDialog> createState() => _QuickDatesDialogState();
}

class _QuickDatesDialogState extends State<QuickDatesDialog> {
  DateTime? _departureDate;
  DateTime? _returnDate;
  final _notesController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _departureDate = widget.initialDepartureDate;
    _returnDate = widget.initialReturnDate;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDepartureDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _departureDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
      locale: const Locale('pt', 'BR'),
      helpText: 'Selecione a data de ida',
      cancelText: 'Cancelar',
      confirmText: 'OK',
    );

    if (date != null) {
      setState(() {
        _departureDate = date;
        // Se data de volta for antes da ida, limpar
        if (_returnDate != null && _returnDate!.isBefore(date)) {
          _returnDate = null;
        }
      });
    }
  }

  Future<void> _selectReturnDate() async {
    final initialDate = _returnDate ?? 
        (_departureDate?.add(const Duration(days: 7)) ?? DateTime.now());
    
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: _departureDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
      locale: const Locale('pt', 'BR'),
      helpText: 'Selecione a data de volta',
      cancelText: 'Cancelar',
      confirmText: 'OK',
    );

    if (date != null) {
      setState(() {
        _returnDate = date;
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Selecionar';
    return DateFormat('dd/MM/yyyy', 'pt_BR').format(date);
  }

  int? _getDaysUntilTrip() {
    if (_departureDate == null) return null;
    return _departureDate!.difference(DateTime.now()).inDays;
  }

  Future<void> _save() async {
    if (_departureDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione pelo menos a data de ida'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    // Retornar os dados para serem salvos
    Navigator.of(context).pop({
      'departure_date': _departureDate,
      'return_date': _returnDate,
      'notes': _notesController.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final daysUntilTrip = _getDaysUntilTrip();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 450,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.calendar_month,
                    color: Colors.blue.shade700,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Datas de Viagem',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.contactName,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  tooltip: 'Fechar',
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Data de Ida
            InkWell(
              onTap: _selectDepartureDate,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _departureDate != null 
                        ? Colors.blue.shade300 
                        : Colors.grey.shade300,
                    width: _departureDate != null ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  color: _departureDate != null 
                      ? Colors.blue.shade50 
                      : Colors.grey.shade50,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.flight_takeoff,
                      color: _departureDate != null 
                          ? Colors.blue.shade700 
                          : Colors.grey.shade600,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Data de Ida',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatDate(_departureDate),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: _departureDate != null 
                                  ? Colors.blue.shade700 
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (daysUntilTrip != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: daysUntilTrip <= 7
                              ? Colors.red.shade100
                              : daysUntilTrip <= 30
                                  ? Colors.orange.shade100
                                  : Colors.green.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'em $daysUntilTrip dias',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: daysUntilTrip <= 7
                                ? Colors.red.shade700
                                : daysUntilTrip <= 30
                                    ? Colors.orange.shade700
                                    : Colors.green.shade700,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Data de Volta
            InkWell(
              onTap: _selectReturnDate,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _returnDate != null 
                        ? Colors.green.shade300 
                        : Colors.grey.shade300,
                    width: _returnDate != null ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  color: _returnDate != null 
                      ? Colors.green.shade50 
                      : Colors.grey.shade50,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.flight_land,
                      color: _returnDate != null 
                          ? Colors.green.shade700 
                          : Colors.grey.shade600,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Data de Volta (opcional)',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatDate(_returnDate),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: _returnDate != null 
                                  ? Colors.green.shade700 
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_departureDate != null && _returnDate != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_returnDate!.difference(_departureDate!).inDays} dias',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Notas rápidas
            TextField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: 'Observações (opcional)',
                hintText: 'Ex: Cliente quer Nova York, ainda pesquisando preços...',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.note_alt_outlined),
                helperText: 'Anotações rápidas sobre o lead',
              ),
              maxLines: 2,
              maxLength: 200,
            ),

            const SizedBox(height: 24),

            // Botões
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _save,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check),
                    label: Text(_isSaving ? 'Salvando...' : 'Salvar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
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
}
