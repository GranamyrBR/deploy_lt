import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/accessibility_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/lead_tintim.dart';
import '../models/contact.dart';
import '../services/contacts_service.dart';
import 'create_quotation_with_whatsapp_dialog.dart';

class WhatsAppMessagesModal extends ConsumerStatefulWidget {
  final Contact contact;

  const WhatsAppMessagesModal({
    super.key,
    required this.contact,
  });

  @override
  ConsumerState<WhatsAppMessagesModal> createState() =>
      _WhatsAppMessagesModalState();
}

class _WhatsAppMessagesModalState extends ConsumerState<WhatsAppMessagesModal> {
  bool get isHighContrast => ref.watch(accessibilityProvider);
  SupabaseClient get _supabase => Supabase.instance.client;
  final ContactsService _contactsService = ContactsService();
  List<LeadTintim> _messages = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Mapa para armazenar o tipo de usuário selecionado para cada mensagem
  Map<int, UserType> _messageUserTypes = {};

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessageUserTypes() async {
    try {
      print('🔄 Carregando user_types das mensagens...');

      // Busca user_types individuais para cada telefone das mensagens
      for (int i = 0; i < _messages.length; i++) {
        final message = _messages[i];
        final phone = message.phone;

        if (phone != null && phone.isNotEmpty) {
          try {
            final response = await _supabase
                .from('contact')
                .select('user_type')
                .eq('phone', phone)
                .maybeSingle();

            if (response != null) {
              final userTypeString = response['user_type'] as String?;
              if (userTypeString != null) {
                try {
                  final userType = UserType.values.firstWhere(
                    (e) => e.name == userTypeString,
                    orElse: () => UserType.normal,
                  );
                  _messageUserTypes[i] = userType;
                  print('✅ User_type carregado para $phone: ${userType.name}');
                } catch (e) {
                  print('❌ Erro ao converter user_type para $phone: $e');
                  _messageUserTypes[i] = UserType.normal;
                }
              } else {
                _messageUserTypes[i] = UserType.normal;
              }
            } else {
              _messageUserTypes[i] = UserType.normal;
            }
          } catch (e) {
            print('❌ Erro ao buscar user_type para $phone: $e');
            _messageUserTypes[i] = UserType.normal;
          }
        } else {
          _messageUserTypes[i] = UserType.normal;
        }
      }

      if (mounted) {
        setState(() {});
      }

      print(
          '✅ User_types das mensagens carregados: ${_messageUserTypes.length}');
    } catch (e) {
      print('❌ Erro ao carregar user_types das mensagens: $e');
    }
  }

  Future<void> _loadMessages() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final phone = widget.contact.phone ?? '';
      print('=== WHATSAPP MODAL DEBUG ===');
      print('Contact ID: ${widget.contact.id}');
      print('Contact Name: ${widget.contact.name}');
      print('Contact Phone (original): "${widget.contact.phone}"');
      print('Phone variable: "$phone"');
      print('Phone isEmpty: ${phone.isEmpty}');
      print('Phone length: ${phone.length}');
      print('Contact completo: ${widget.contact.toString()}');

      // Buscar mensagens do contato na tabela leadstintim
      late final List<dynamic> response;

      if (phone.isEmpty) {
        print('❌ Telefone vazio, buscando todos os leads');
        response = await _supabase
            .from('leadstintim')
            .select('*')
            .order('id', ascending: false)
            .order('id', ascending: false).limit(100); // Limitar para performance
      } else {
        // Buscar por telefone específico, tentando diferentes formatos
        final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
        print('📱 Telefone original: "$phone"');
        print('📱 Telefone limpo: "$cleanPhone"');
        print('🔍 Executando consulta SQL...');

        try {
          response = await _supabase
              .from('leadstintim')
              .select('*')
              .or('phone.eq.$phone,phone.eq.$cleanPhone,phone.like.%$cleanPhone%')
              .order('datelast', ascending: false)
              .order('id', ascending: false);

          print('✅ Consulta executada com sucesso!');
        } catch (sqlError) {
          print('❌ Erro na consulta SQL: $sqlError');
          rethrow;
        }
      }

      print(
          '📊 Resposta da consulta: ${response.length} registros encontrados');
      if (response.isNotEmpty) {
        print('📋 Primeiro registro encontrado:');
        final first = response.first;
        print('  - ID: ${first['id']}');
        print('  - Nome: ${first['name']}');
        print('  - Telefone: ${first['phone']}');
        print('  - Status: ${first['status']}');
      } else {
        print('❌ Nenhum registro encontrado!');
        if (phone.isNotEmpty) {
          print('🔍 Tentando consulta de debug...');

          // Consulta de debug para verificar se existem registros com telefones similares
          final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
          if (cleanPhone.length >= 8) {
            final debugResponse = await _supabase
                .from('leadstintim')
                .select('id, name, phone')
                .like(
                    'phone', '%${cleanPhone.substring(cleanPhone.length - 8)}%')
                .order('id', ascending: false)
                .order('id', ascending: false).limit(5);

            print(
                '🔍 Debug - registros com últimos 8 dígitos: ${debugResponse.length}');
            for (var record in debugResponse) {
              print('  - ${record['name']}: ${record['phone']}');
            }
          }
        }
      }

      print('🔄 Convertendo dados para objetos LeadTintim...');
      try {
        final List<LeadTintim> messages = (response as List)
            .map((json) => LeadTintim.fromJson(json))
            .toList();
        print('✅ Conversão bem-sucedida: ${messages.length} mensagens');

        setState(() {
          _messages = messages;
          _isLoading = false;
        });

        print(
            '✅ Estado atualizado - Mensagens carregadas: ${_messages.length}');

        // Carrega os user_types após carregar as mensagens
        _loadMessageUserTypes();
      } catch (conversionError) {
        print('❌ Erro na conversão dos dados: $conversionError');
        print(
            '📋 Dados brutos do primeiro registro: ${response.isNotEmpty ? response.first : "Nenhum registro"}');
        setState(() {
          _messages = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Erro geral ao carregar mensagens: $e');
      setState(() {
        _errorMessage = 'Erro ao carregar mensagens: $e';
        _isLoading = false;
      });
    }
  }

  String formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';
    // Converte UTC para horário local
    final localDateTime = dateTime.toLocal();
    return '${localDateTime.day.toString().padLeft(2, '0')}/${localDateTime.month.toString().padLeft(2, '0')}/${localDateTime.year} ${localDateTime.hour.toString().padLeft(2, '0')}:${localDateTime.minute.toString().padLeft(2, '0')}';
  }

  // Métodos auxiliares para gerenciar tipos de usuário
  String _getInitial(String? name) {
    if (name == null || name.isEmpty) return '?';
    return name.substring(0, 1).toUpperCase();
  }

  Color _getCircleColor(UserType userType, bool isConversion) {
    if (isConversion) {
      return Colors.green;
    }

    switch (userType) {
      case UserType.driver:
        return Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF6B46C1) // Roxo
            : const Color(0xFF8B5CF6);
      case UserType.employee:
        return Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF059669) // Verde
            : const Color(0xFF10B981);
      case UserType.agency:
        return Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1976D2) // Azul escuro
            : const Color(0xFF2196F3);
      case UserType.normal:
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  Color _getBorderColor(UserType userType, bool isConversion) {
    if (isConversion) {
      return Colors.green.shade700;
    }

    switch (userType) {
      case UserType.driver:
        return Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF7C3AED)
            : const Color(0xFF6D28D9);
      case UserType.employee:
        return Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF047857)
            : const Color(0xFF065F46);
      case UserType.agency:
        return Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF0D47A1)
            : const Color(0xFF1976D2);
      case UserType.normal:
      default:
        return Theme.of(context).colorScheme.primary.withOpacity(0.7);
    }
  }

  Color _getTextColor(UserType userType, bool isConversion) {
    return Colors.white;
  }

  Color _getUserTypeColor(UserType userType) {
    switch (userType) {
      case UserType.driver:
        return const Color(0xFF8B5CF6); // Roxo
      case UserType.employee:
        return const Color(0xFF10B981); // Verde
      case UserType.agency:
        return const Color(0xFF2196F3); // Azul
      case UserType.normal:
        return Colors.grey;
    }
  }

  String _getUserTypeLabel(UserType userType) {
    switch (userType) {
      case UserType.driver:
        return 'MOTORISTA';
      case UserType.employee:
        return 'COLABORADOR';
      case UserType.agency:
        return 'AGÊNCIA';
      case UserType.normal:
        return '';
    }
  }

  String _leadStatusToString(LeadStatus? status) {
    if (status == null) return 'N/A';
    switch (status) {
      case LeadStatus.newLead:
        return 'Novo Lead';
      case LeadStatus.contacted:
        return 'Fez Contato';
      case LeadStatus.converted:
        return 'Comprou';
      case LeadStatus.unknown:
        return 'Desconhecido';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isHighContrast = ref.watch(accessibilityProvider);
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
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
                    color: const Color(0xFF25D366),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.chat_bubble,
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
                        'Mensagens do WhatsApp',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isHighContrast ? Colors.black : null,
                                ),
                      ),
                      Text(
                        widget.contact.name ?? 'Contato sem nome',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: isHighContrast
                                  ? Colors.black
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.7),
                            ),
                      ),
                    ],
                  ),
                ),
                // Botão Criar Cotação - PROFISSIONAL COM FORMULÁRIO!
                ElevatedButton.icon(
                onPressed: _messages.isEmpty
                    ? null
                    : () async {
                        // Fecha modal atual e abre modal de criação com WhatsApp
                        Navigator.of(context).pop();
                        
                        await showDialog<void>(
                          context: context,
                          builder: (context) => CreateQuotationWithWhatsAppDialog(
                            initialContact: widget.contact,
                            whatsappMessages: _messages,
                          ),
                        );
                      },
                  icon: const Icon(Icons.article_outlined, size: 20),
                  label: const Text('Criar Cotação'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                ),
                const SizedBox(width: 12),
                const Text('Alto Contraste', style: TextStyle(fontSize: 12)),
                Switch(
                  value: isHighContrast,
                  onChanged: (_) =>
                      ref.read(accessibilityProvider.notifier).toggle(),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Conteúdo principal
            Expanded(
              child: _isLoading
                  ? _buildLoadingState()
                  : _errorMessage != null
                      ? _buildErrorState()
                      : _messages.isEmpty
                          ? _buildEmptyState()
                          : _buildMessagesContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Carregando mensagens...'),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadMessages,
            child: const Text('Tentar Novamente'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhuma mensagem encontrada',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Este contato ainda não possui mensagens do WhatsApp.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesContent() {
    return Column(
      children: [
        // Estatísticas
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isHighContrast
                ? Colors.black
                : Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '${_messages.length}',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isHighContrast
                                    ? Colors.white
                                    : Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer,
                              ),
                    ),
                    Text(
                      'Total de Mensagens',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isHighContrast
                                ? Colors.white70
                                : Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer,
                          ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '${_messages.where((m) => m.status == LeadStatus.converted).length}',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isHighContrast
                                    ? Colors.white
                                    : Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer,
                              ),
                    ),
                    Text(
                      'Conversões',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isHighContrast
                                ? Colors.white70
                                : Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer,
                          ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      _messages.isNotEmpty
                          ? formatDateTime(_messages.first.datelast)
                          : 'N/A',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isHighContrast
                                ? Colors.white
                                : Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer,
                          ),
                    ),
                    Text(
                      'Última Mensagem',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isHighContrast
                                ? Colors.white70
                                : Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Lista de mensagens
        Expanded(
          child: ListView.builder(
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final message = _messages[index];
              return _buildMessageCard(message, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMessageCard(LeadTintim message, int index) {
    final bool isConversion = message.status == LeadStatus.converted;
    final UserType userType = _messageUserTypes[index] ?? UserType.normal;
    final bool isFromMe = message.fromMe ?? false; // true = atendente, false = cliente
    final isHighContrast = ref.watch(accessibilityProvider);

    // Cores para chat style
    final Color clientBubbleColor = isHighContrast
        ? Colors.grey[900]!
        : (Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1F2C34) // Cinza escuro para dark mode
            : const Color(0xFFFFFFFF)); // Branco para light mode

    final Color attendantBubbleColor = isHighContrast
        ? Colors.black
        : (Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF005C4B) // Verde WhatsApp escuro
            : const Color(0xFFDCF8C6)); // Verde claro WhatsApp

    return Padding(
      padding: EdgeInsets.only(
        bottom: 8,
        left: isFromMe ? 60 : 8, // Atendente mais à direita
        right: isFromMe ? 8 : 60, // Cliente mais à esquerda
      ),
      child: Row(
        mainAxisAlignment:
            isFromMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar do cliente (à esquerda)
          if (!isFromMe) ...[
            _buildAvatar(message, userType, isConversion),
            const SizedBox(width: 8),
          ],

          // Bubble da mensagem
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isFromMe ? attendantBubbleColor : clientBubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(isFromMe ? 12 : 4),
                  topRight: Radius.circular(isFromMe ? 4 : 12),
                  bottomLeft: const Radius.circular(12),
                  bottomRight: const Radius.circular(12),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cabeçalho com nome e badges
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isFromMe ? 'Atendente' : (message.name ?? 'Cliente'),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isHighContrast
                                  ? Colors.white
                                  : (isFromMe
                                      ? (Theme.of(context).brightness == Brightness.dark
                                          ? Colors.white
                                          : const Color(0xFF075E54))
                                      : Theme.of(context).colorScheme.primary),
                            ),
                      ),
                      const SizedBox(width: 8),
                      // Badge de status
                      if (isConversion)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'CONVERTEU',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      // Badge de tipo de usuário
                      if (userType != UserType.normal && !isFromMe)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          margin: const EdgeInsets.only(left: 4),
                          decoration: BoxDecoration(
                            color: _getUserTypeColor(userType),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _getUserTypeLabel(userType),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Conteúdo da mensagem
                  if (message.message != null && message.message!.isNotEmpty)
                    Text(
                      message.message!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: isHighContrast
                                ? Colors.white
                                : (isFromMe && Theme.of(context).brightness == Brightness.light
                                    ? Colors.black87
                                    : null),
                          ),
                    ),

                  // Informações de venda (apenas mensagem, sem valor)
                  if (message.salemessage != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        message.salemessage!,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.green[800]),
                      ),
                    ),
                  ],

                  // Rodapé com hora
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        formatDateTime(message.datelast),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontSize: 10,
                              color: isHighContrast
                                  ? Colors.white60
                                  : (isFromMe
                                      ? Colors.black54
                                      : Colors.grey[600]),
                            ),
                      ),
                      if (isFromMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.done_all,
                          size: 14,
                          color: Colors.blue[300],
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Avatar do atendente (à direita)
          if (isFromMe) ...[
            const SizedBox(width: 8),
            _buildAvatar(message, userType, isConversion),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar(LeadTintim message, UserType userType, bool isConversion) {
    return InkWell(
      onTap: message.fromMe ?? false
          ? null
          : () async {
              // Apenas permite trocar tipo para mensagens de clientes
              final currentType = userType;
              UserType newType;

              switch (currentType) {
                case UserType.normal:
                  newType = UserType.driver;
                  break;
                case UserType.driver:
                  newType = UserType.employee;
                  break;
                case UserType.employee:
                  newType = UserType.agency;
                  break;
                case UserType.agency:
                  newType = UserType.normal;
                  break;
              }

              setState(() {
                final index = _messages.indexOf(message);
                _messageUserTypes[index] = newType;
              });

              try {
                final phone = message.phone;
                if (phone != null && phone.isNotEmpty) {
                  final contact =
                      await _contactsService.getContactByPhone(phone);
                  if (contact != null) {
                    await _contactsService.updateContactUserType(
                        contact.id, newType);
                  }
                }
              } catch (e) {
                print('❌ Erro ao persistir UserType: $e');
              }
            },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _getCircleColor(userType, isConversion),
          shape: BoxShape.circle,
          border: Border.all(
            color: _getBorderColor(userType, isConversion),
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            message.fromMe ?? false ? 'A' : _getInitial(message.name),
            style: TextStyle(
              color: _getTextColor(userType, isConversion),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
