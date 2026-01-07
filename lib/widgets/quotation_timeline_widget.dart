import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class QuotationTimelineWidget extends StatefulWidget {
  final int quotationId;

  const QuotationTimelineWidget({
    super.key,
    required this.quotationId,
  });

  @override
  State<QuotationTimelineWidget> createState() => _QuotationTimelineWidgetState();
}

class _QuotationTimelineWidgetState extends State<QuotationTimelineWidget> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _timeline = [];
  bool _isLoading = true;
  final _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTimeline();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadTimeline() async {
    setState(() => _isLoading = true);
    
    try {
      final result = await _supabase.rpc<List<dynamic>>(
        'get_quotation_timeline',
        params: {'p_quotation_id': widget.quotationId},
      );
      
      if (mounted) {
        setState(() {
          _timeline = (result).map((e) => Map<String, dynamic>.from(e)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Erro ao carregar timeline: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _addNote(String note) async {
    if (note.trim().isEmpty) return;

    try {
      await _supabase.rpc('add_quotation_timeline_event', params: {
        'p_quotation_id': widget.quotationId,
        'p_event_type': 'note',
        'p_title': 'Nota adicionada',
        'p_description': note,
        'p_created_by': _supabase.auth.currentUser?.email ?? 'system',
      });

      _noteController.clear();
      await _loadTimeline();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nota adicionada com sucesso!')),
        );
      }
    } catch (e) {
      print('Erro ao adicionar nota: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao adicionar nota: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _addFollowUpReminder() async {
    final now = DateTime.now();
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now.add(const Duration(hours: 1))),
    );
    
    if (selectedTime == null) return;
    
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    
    if (selectedDate == null) return;
    
    final followUpDateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    try {
      // Atualizar a cotação com a data do follow-up
      await _supabase
          .from('quotation')
          .update({
            'follow_up_date': followUpDateTime.toIso8601String(),
            'follow_up_count': (_timeline.where((e) => e['event_type'] == 'follow_up').length + 1),
          })
          .eq('id', widget.quotationId);

      // Adicionar evento na timeline
      await _supabase.rpc('add_quotation_timeline_event', params: {
        'p_quotation_id': widget.quotationId,
        'p_event_type': 'follow_up',
        'p_title': 'Follow-up agendado',
        'p_description': 'Follow-up agendado para ${DateFormat('dd/MM/yyyy HH:mm').format(followUpDateTime)}',
        'p_created_by': _supabase.auth.currentUser?.email ?? 'system',
      });

      await _loadTimeline();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Follow-up agendado para ${DateFormat('dd/MM/yyyy HH:mm').format(followUpDateTime)}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Erro ao agendar follow-up: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao agendar: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header com botões de ação
        Row(
          children: [
            const Text(
              'Timeline & Follow-ups',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.alarm_add),
              onPressed: _addFollowUpReminder,
              tooltip: 'Agendar Follow-up',
              color: Colors.blue,
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadTimeline,
              tooltip: 'Atualizar',
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Campo para adicionar nota rápida
        TextField(
          controller: _noteController,
          decoration: InputDecoration(
            hintText: 'Adicionar nota...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            suffixIcon: IconButton(
              icon: const Icon(Icons.send),
              onPressed: () => _addNote(_noteController.text),
            ),
          ),
          maxLines: 2,
          onSubmitted: _addNote,
        ),
        
        const SizedBox(height: 16),
        
        // Timeline
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _timeline.isEmpty
                  ? const Center(
                      child: Text(
                        'Nenhum evento registrado',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _timeline.length,
                      itemBuilder: (context, index) {
                        final event = _timeline[index];
                        return _buildTimelineItem(event, index == _timeline.length - 1);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildTimelineItem(Map<String, dynamic> event, bool isLast) {
    final eventType = event['event_type'] ?? '';
    final title = event['title'] ?? '';
    final description = event['description'];
    final createdBy = event['created_by'];
    final createdAt = DateTime.parse(event['created_at']);
    
    final icon = _getEventIcon(eventType);
    final color = _getEventColor(eventType);
    
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator
          Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 2),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: Colors.grey.shade300,
                  ),
                ),
            ],
          ),
          
          const SizedBox(width: 16),
          
          // Event content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  if (description != null && description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 12, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('dd/MM/yyyy HH:mm').format(createdAt),
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 11,
                        ),
                      ),
                      if (createdBy != null) ...[
                        const SizedBox(width: 12),
                        Icon(Icons.person, size: 12, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          createdBy,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getEventIcon(String eventType) {
    switch (eventType) {
      case 'created':
        return Icons.add_circle;
      case 'sent':
        return Icons.send;
      case 'viewed':
        return Icons.visibility;
      case 'follow_up':
        return Icons.alarm;
      case 'status_change':
        return Icons.swap_horiz;
      case 'note':
        return Icons.note;
      case 'email':
        return Icons.email;
      case 'whatsapp':
        return Icons.chat;
      case 'call':
        return Icons.phone;
      default:
        return Icons.event;
    }
  }

  Color _getEventColor(String eventType) {
    switch (eventType) {
      case 'created':
        return Colors.blue;
      case 'sent':
        return Colors.green;
      case 'viewed':
        return Colors.purple;
      case 'follow_up':
        return Colors.orange;
      case 'status_change':
        return Colors.indigo;
      case 'note':
        return Colors.grey;
      case 'email':
        return Colors.teal;
      case 'whatsapp':
        return const Color(0xFF25D366);
      case 'call':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}


