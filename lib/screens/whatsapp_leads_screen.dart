import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lecotour_dashboard/models/lead_tintim.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/lead_tintim_provider.dart';
import '../widgets/base_screen_layout.dart';
import '../widgets/standard_search_bar.dart';
import '../utils/smart_search_mixin.dart';
import '../utils/flag_utils.dart';
import '../services/contacts_service.dart';
import '../models/contact.dart';
import '../services/response_time_calculator.dart';
import '../widgets/response_time_badge.dart';
import '../widgets/response_time_kpi_card.dart';



class WhatsAppLeadsScreen extends ConsumerStatefulWidget {
  const WhatsAppLeadsScreen({super.key});

  @override
  ConsumerState<WhatsAppLeadsScreen> createState() =>
      _WhatsAppLeadsScreenState();
}

class _WhatsAppLeadsScreenState extends ConsumerState<WhatsAppLeadsScreen> with SmartSearchMixin {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = '';
  final ContactsService _contactsService = ContactsService();

  // Map para rastrear tipos de usuário dos leads
  final Map<String, UserType> _leadUserTypes = {};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    print('🚀 WhatsAppLeadsScreen initState - iniciando carregamento de user_types');
    _loadLeadUserTypes();
  }

  Future<void> _loadLeadUserTypes() async {
    try {
      print('🔄 Carregando user_types dos leads...');
      
      // Busca todos os contatos com user_type
      final response = await Supabase.instance.client
          .from('contact')
          .select('phone, user_type')
          .not('phone', 'is', null)
          .not('user_type', 'is', null);
      
      for (final contactData in response) {
        final phone = contactData['phone'] as String?;
        final userTypeString = contactData['user_type'] as String?;
        
        if (phone != null && userTypeString != null) {
          try {
            final userType = UserType.values.firstWhere(
              (e) => e.name == userTypeString,
              orElse: () => UserType.normal,
            );
            _leadUserTypes[phone] = userType;
          } catch (e) {
            _leadUserTypes[phone] = UserType.normal;
          }
        }
      }

      // Complementa com user_type direto dos leads (se coluna existir)
      final leadMap = await _contactsService.fetchLeadUserTypesFromLeadstintim();
      for (final entry in leadMap.entries) {
        _leadUserTypes.putIfAbsent(entry.key, () => entry.value);
      }
      
      if (mounted) {
        setState(() {});
      }
      
      print('✅ User_types dos leads carregados: ${_leadUserTypes.length}');
    } catch (e) {
      print('❌ Erro ao carregar user_types dos leads: $e');
    }
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'Data N/A';
    // Converter de UTC para horário brasileiro usando timezone dinâmico
    // Considera automaticamente horário de verão (UTC-2) e padrão (UTC-3)
    final brazilTime = dateTime.toLocal();
    return DateFormat('dd/MM/yy HH:mm').format(brazilTime);
  }

  // Funções auxiliares para cores e tipos de usuário
  Color _getCircleColor(UserType userType) {
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
        return Theme.of(context).colorScheme.primary.withValues(alpha: 0.2);
    }
  }

  Color _getBorderColor(UserType userType) {
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
        return Theme.of(context).colorScheme.primary.withValues(alpha: 0.7);
    }
  }

  Color _getTextColor(UserType userType) {
    return userType == UserType.normal 
        ? Theme.of(context).colorScheme.primary
        : Colors.white;
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

  String _getInitial(String? name) {
    if (name == null || name.isEmpty) return '?';
    return name[0].toUpperCase();
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

  String _formatPhone(String phone) {
    print('Formatando telefone: $phone'); // Debug
    final digits = phone.replaceAll(RegExp(r'[^\d+]'), '');
    print('Dígitos extraídos: $digits'); // Debug
    
    if (digits.startsWith('+55')) {
      // Brasil com +: +55 (11) 99999-9999 ou +55 (11) 9999-9999
      if (digits.length == 13) {
        final formatted = '+55 (${digits.substring(3, 5)}) ${digits.substring(5, 10)}-${digits.substring(10)}';
        print('Brasil +55 13 dígitos: $formatted'); // Debug
        return formatted;
      } else if (digits.length == 12) {
        final formatted = '+55 (${digits.substring(3, 5)}) ${digits.substring(5, 9)}-${digits.substring(9)}';
        print('Brasil +55 12 dígitos: $formatted'); // Debug
        return formatted;
      }
    } else if (digits.startsWith('55') && digits.length == 13) {
      // Brasil sem +: 55 (11) 99999-9999
      final formatted = '+55 (${digits.substring(2, 4)}) ${digits.substring(4, 9)}-${digits.substring(9)}';
      print('Brasil 55 13 dígitos: $formatted'); // Debug
      return formatted;
    } else if (digits.startsWith('55') && digits.length == 12) {
      // Brasil sem +: 55 (11) 9999-9999
      final formatted = '+55 (${digits.substring(2, 4)}) ${digits.substring(4, 8)}-${digits.substring(8)}';
      print('Brasil 55 12 dígitos: $formatted'); // Debug
      return formatted;
    } else if (digits.startsWith('+1') && digits.length == 12) {
      // EUA: +1 (555) 123-4567 (10 dígitos após o +1)
      final formatted = '+1 (${digits.substring(2, 5)}) ${digits.substring(5, 8)}-${digits.substring(8)}';
      print('EUA: $formatted'); // Debug
      return formatted;
    } else if (digits.startsWith('1') && digits.length == 11) {
      // EUA sem o +: 1 (555) 123-4567 (10 dígitos após o 1)
      final formatted = '1 (${digits.substring(1, 4)}) ${digits.substring(4, 7)}-${digits.substring(7)}';
      print('EUA sem +: $formatted'); // Debug
      return formatted;
    } else if (digits.length == 11) {
      // Brasil sem DDI: (11) 99999-9999
      final formatted = '(${digits.substring(0, 2)}) ${digits.substring(2, 7)}-${digits.substring(7)}';
      print('Brasil 11 dígitos sem DDI: $formatted'); // Debug
      return formatted;
    } else if (digits.length == 10) {
      // Brasil sem DDI: (11) 9999-9999
      final formatted = '(${digits.substring(0, 2)}) ${digits.substring(2, 6)}-${digits.substring(6)}';
      print('Brasil 10 dígitos sem DDI: $formatted'); // Debug
      return formatted;
    } else if (digits.startsWith('351') && digits.length == 12) {
      // Portugal sem +: +351 963 788 149
      final formatted = '+351 ${digits.substring(3, 6)} ${digits.substring(6, 9)} ${digits.substring(9)}';
      print('Portugal 351 12 dígitos: $formatted'); // Debug
      return formatted;
    } else if (digits.startsWith('+351') && digits.length == 13) {
      // Portugal com +: +351 963 788 149
      final formatted = '+351 ${digits.substring(4, 7)} ${digits.substring(7, 10)} ${digits.substring(10)}';
      print('Portugal +351 13 dígitos: $formatted'); // Debug
      return formatted;
    }
    // Para outros casos, retorna o número original
    print('Formato não reconhecido, retornando original: $phone'); // Debug
    return phone;
  }

  // Função para extrair o código ISO do país a partir do DDI do telefone
  String? _getCountryCodeFromPhone(dynamic phone) {
    return FlagUtils.getCountryIsoCodeFromPhone(phone?.toString() ?? '');
  }

  String? _resolveIsoFromPhoneAndCountry(dynamic phone, String? country) {
    return _getCountryCodeFromPhone(phone) ??
        (country != null ? FlagUtils.getCountryIsoCode(country) : null);
  }



  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // REMOVIDO: Lógica de scroll infinito não é mais necessária
    // pois agora carregamos TODOS os leads de uma vez
    // Mantendo a função para evitar erros, mas sem funcionalidade
  }

  @override
  Widget build(BuildContext context) {
    final leadsState = ref.watch(leadTintimProvider);
    final groupedLeads = leadsState.groupedLeads;
    final filteredGroupedLeads = _getFilteredGroupedLeads(groupedLeads);

    return BaseScreenLayout(
      title: 'Leads do WhatsApp',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () {
            ref.read(leadTintimProvider.notifier).fetchInitialLeads();
          },
          tooltip: 'Atualizar leads',
        ),
      ],
      searchBar: StandardSearchBar(
        controller: _searchController,
        hintText: 'Buscar por nome, telefone, mensagem...',
        onChanged: (value) {
          setState(() {
            _searchTerm = value;
          });
        },
        onClear: () {
          setState(() {
            _searchTerm = '';
          });
        },
      ),
      child: _buildBody(context, leadsState, filteredGroupedLeads),
    );
  }

  Widget _buildBody(BuildContext context, GroupedLeadsState leadsState,
      Map<String, List<LeadTintim>> groupedLeads) {
    if (groupedLeads.isEmpty &&
        !leadsState.isLoadingMore &&
        !leadsState.hasMore) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchTerm.isNotEmpty ? Icons.search_off : Icons.phone_android,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              _searchTerm.isNotEmpty 
                ? 'Nenhum lead encontrado para "$_searchTerm"'
                : 'Nenhum lead com telefone válido encontrado.',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            if (_searchTerm.isNotEmpty) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchTerm = '';
                  });
                },
                child: const Text('Limpar busca'),
              ),
            ],
          ],
        ),
      );
    }

    if (groupedLeads.isEmpty && leadsState.isLoadingMore) {
      return const Center(child: CircularProgressIndicator());
    }

    if (leadsState.errorMessage != null && groupedLeads.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Erro: ${leadsState.errorMessage}'),
            ElevatedButton(
              onPressed: () =>
                  ref.read(leadTintimProvider.notifier).fetchInitialLeads(),
              child: const Text('Tentar Novamente'),
            )
          ],
        ),
      );
    }

    final phoneNumbers = groupedLeads.keys.toList();
    // Ordena os grupos de telefone pela data da última mensagem do grupo (mais recente primeiro)
    // Simplificado: Assumindo que os leads dentro de cada grupo já estão ordenados pelo provider,
    // e `groupedLeads[key]!.first.datelast` representa a data mais recente do grupo.
    phoneNumbers.sort((a, b) {
      final lastA = groupedLeads[a]?.first.datelast;
      final lastB = groupedLeads[b]?.first.datelast;

      if (lastA == null && lastB == null) return 0;
      if (lastA == null) {
        return 1; // Coloca grupos sem data (ou com datas nulas) por último
      }
      if (lastB == null) {
        return -1; // Coloca grupos sem data (ou com datas nulas) por último
      }
      return lastB
          .compareTo(lastA); // Ordena do mais recente para o mais antigo
    });

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16.0),
      itemCount: phoneNumbers.length +
          (_searchTerm.isNotEmpty ? 1 : 0) + // Indicador de busca
          _calculateExtraItemCount(leadsState, groupedLeads.isNotEmpty),
      itemBuilder: (context, index) {
        // Adicionar indicador de busca no topo
        if (index == 0 && _searchTerm.isNotEmpty) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${phoneNumbers.length} resultado${phoneNumbers.length != 1 ? 's' : ''} encontrado${phoneNumbers.length != 1 ? 's' : ''} para "$_searchTerm"',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchTerm = '';
                    });
                  },
                  child: Text(
                    'Limpar',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        // Ajustar índice para considerar o indicador de busca
        final actualIndex = _searchTerm.isNotEmpty ? index - 1 : index;
        
        if (actualIndex < phoneNumbers.length) {
          final phoneNumber = phoneNumbers[actualIndex];
          final leadsFromPhone = groupedLeads[phoneNumber]!;
          final LeadTintim firstLeadInGroup = leadsFromPhone.first;
          final contactName = firstLeadInGroup.name ?? 'Desconhecido';

          final bool hasPurchase =
              leadsFromPhone.any((lead) => lead.status == LeadStatus.converted);

          return Card(
            margin: const EdgeInsets.only(bottom: 16.0),
            elevation: 2,
            color: hasPurchase
                ? Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF1B3A2E) // Verde escuro para dark mode
                    : const Color(0xFFE8F5E8) // Verde claro para light mode
                : Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF2A2D3E) // Azul escuro para dark mode
                    : const Color(0xFFE8F2FF), // Azul mais suave para light mode
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ExpansionTile(
              key: PageStorageKey(
                  phoneNumber), // Para manter o estado de expansão
              leading: InkWell(
                onTap: () async {
                  final currentType = _leadUserTypes[phoneNumber] ?? UserType.normal;
                  UserType newType;
                  
                  // Alterna entre os tipos: normal -> driver -> employee -> agency -> normal
                  switch (currentType) {
                    case UserType.normal:
                      newType = UserType.driver;
                      print('Lead $phoneNumber alterado para MOTORISTA');
                      break;
                    case UserType.driver:
                      newType = UserType.employee;
                      print('Lead $phoneNumber alterado para COLABORADOR');
                      break;
                    case UserType.employee:
                      newType = UserType.agency;
                      print('Lead $phoneNumber alterado para AGÊNCIA');
                      break;
                    case UserType.agency:
                      newType = UserType.normal;
                      print('Lead $phoneNumber alterado para NORMAL');
                      break;
                  }
                  
                  // Atualiza localmente primeiro
                  setState(() {
                    _leadUserTypes[phoneNumber] = newType;
                  });
                  
                  try {
                    await _contactsService.setContactUserTypeByPhone(phoneNumber, newType, name: contactName);
                    print('✅ UserType do lead $phoneNumber persistido no banco como $newType');
                  } catch (e) {
                    print('❌ Erro ao persistir UserType do lead $phoneNumber: $e');
                    // Reverte a mudança local em caso de erro
                    setState(() {
                      _leadUserTypes[phoneNumber] = currentType;
                    });
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Erro ao salvar tipo de usuário: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: hasPurchase 
                        ? (Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF2E7D32).withValues(alpha: 0.3)
                            : const Color(0xFF4CAF50).withValues(alpha: 0.2))
                        : _getCircleColor(_leadUserTypes[phoneNumber] ?? UserType.normal),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: hasPurchase
                          ? (Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF4CAF50)
                              : const Color(0xFF2E7D32))
                          : _getBorderColor(_leadUserTypes[phoneNumber] ?? UserType.normal),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: hasPurchase
                        ? Icon(
                            Icons.check_circle,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFF4CAF50)
                                : const Color(0xFF2E7D32),
                            size: 20,
                          )
                        : Text(
                            _getInitial(contactName),
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: _getTextColor(_leadUserTypes[phoneNumber] ?? UserType.normal),
                            ),
                          ),
                  ),
                ),
              ),
              title: Row(
                children: [
                  if (_resolveIsoFromPhoneAndCountry(phoneNumber, leadsFromPhone.isNotEmpty ? leadsFromPhone.first.country : null) != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Image.network(
                        FlagUtils.getFlagUrl(_resolveIsoFromPhoneAndCountry(phoneNumber, leadsFromPhone.isNotEmpty ? leadsFromPhone.first.country : null)!, width: 24, height: 18),
                        width: 24,
                        height: 18,
                        errorBuilder: (context, error, stackTrace) => const SizedBox(width: 24, height: 18),
                      ),
                    ),
                  Expanded(
                    child: Text(
                      '$contactName | ${_formatPhone(phoneNumber)}',
                      style: (Theme.of(context).textTheme.titleMedium ??
                              const TextStyle())
                          .copyWith(
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Inter',
                            fontSize: 18,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  // Indicador do tipo de usuário
                  if ((_leadUserTypes[phoneNumber] ?? UserType.normal) != UserType.normal)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      margin: const EdgeInsets.only(left: 8),
                      decoration: BoxDecoration(
                        color: _getUserTypeColor(_leadUserTypes[phoneNumber] ?? UserType.normal),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getUserTypeLabel(_leadUserTypes[phoneNumber] ?? UserType.normal),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
              subtitle: Text(
                '${leadsFromPhone.length} mensagens | Última: ${_formatDateTime(leadsFromPhone.first.datelast)}',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: Colors.orange[700], // Cor laranja como solicitado
                ),
              ),
              children: [
                // Card de KPIs de tempo de resposta
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ResponseTimeKPICard(
                    metrics: ResponseTimeCalculator.calculateMetrics(leadsFromPhone),
                  ),
                ),
                // Mensagens
                for (int i = 0; i < leadsFromPhone.length; i++)
                  _buildChatBubble(context, leadsFromPhone[i], i, leadsFromPhone),
              ],
            ),
          );
        } else if (index == phoneNumbers.length) {
          // Este é o item no final da lista, pode ser o loader ou o erro/retry
          if (leadsState.isLoadingMore) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 20.0),
              child: Center(child: CircularProgressIndicator()),
            );
          } else if (leadsState.errorMessage != null &&
              groupedLeads.isNotEmpty &&
              leadsState.hasMore) {
            // Mostra erro e botão de tentar novamente se não estiver carregando,
            // houver um erro, a lista não estiver vazia e houver potencial para mais leads.
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Erro ao carregar mais: ${leadsState.errorMessage}'),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => ref
                          .read(leadTintimProvider.notifier)
                          .fetchInitialLeads(),
                      child: const Text('Tentar Novamente'),
                    ),
                  ],
                ),
              ),
            );
          }
        }
        return const SizedBox.shrink(); // Should not happen
      },
    );
  }

  Widget _buildChatBubble(BuildContext context, LeadTintim lead, int index, List<LeadTintim> leadsFromPhone) {
    // 🎯 USAR O CAMPO REAL from_me DO BANCO DE DADOS
    final bool isFromMe = lead.fromMe ?? false; // true = atendente, false = cliente
    
    // Calcular tempo de resposta se for mensagem do atendente
    Duration? responseTime;
    if (isFromMe && index > 0) {
      // Procurar última mensagem do cliente antes desta
      for (int i = index - 1; i >= 0; i--) {
        final previousLead = leadsFromPhone[i];
        if (previousLead.fromMe == false) {
          // Encontrou mensagem do cliente
          final customerTime = previousLead.datelast ?? previousLead.createdAt;
          final agentTime = lead.datelast ?? lead.createdAt;
          if (customerTime != null && agentTime != null) {
            responseTime = agentTime.difference(customerTime);
            if (responseTime.inSeconds < 0) responseTime = null; // Ignora se negativo
          }
          break;
        }
      }
    }
    
    // Cores do WhatsApp
    const whatsappGreen = Color(0xFF25D366); // Verde principal do WhatsApp
    const whatsappLightGreen = Color(0xFFDCF8C6); // Verde claro para mensagens do cliente
    const whatsappDarkGreen = Color(0xFF005C4B); // Verde escuro para mensagens do atendente
    const whatsappGray = Color(0xFFFFFFFF); // Branco para mensagens do cliente (light mode)
    const whatsappDarkGray = Color(0xFF1F2C34); // Cinza escuro (dark mode)
    
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    final bubbleColor = isFromMe
        ? (isDarkMode ? whatsappDarkGreen : whatsappLightGreen) // Atendente (verde)
        : (isDarkMode ? whatsappDarkGray : whatsappGray); // Cliente (branco/cinza)
    
    final textColor = isFromMe
        ? (isDarkMode ? Colors.white : Colors.black87) // Atendente
        : (isDarkMode ? Colors.white : Colors.black87); // Cliente
    
    final align = isFromMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final radius = isFromMe
        ? const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(4),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          );
    
    return Padding(
      padding: EdgeInsets.only(
        left: isFromMe ? 60 : 8,
        right: isFromMe ? 8 : 60,
        top: 4,
        bottom: 4,
      ),
      child: Row(
        mainAxisAlignment:
            isFromMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: radius,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: align,
                children: [
                  // Indicador de quem enviou
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isFromMe ? Icons.person : Icons.person_outline,
                        size: 12,
                        color: textColor.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isFromMe ? 'Atendente' : 'Cliente',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: textColor.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lead.message ?? 'Mensagem vazia',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatDateTime(lead.datelast),
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: textColor.withValues(alpha: 0.6),
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
                      // Badge de tempo de resposta para mensagens do atendente
                      if (isFromMe && responseTime != null) ...[
                        const SizedBox(width: 8),
                        ResponseTimeBadge(
                          responseTime: responseTime,
                          compact: true,
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

  Map<String, List<LeadTintim>> _getFilteredGroupedLeads(Map<String, List<LeadTintim>> groupedLeads) {
    if (_searchTerm.isEmpty) {
      return groupedLeads;
    }

    final filteredMap = <String, List<LeadTintim>>{};

    for (final entry in groupedLeads.entries) {
      final phoneNumber = entry.key;
      final leads = entry.value;

      // Verifica se algum lead do grupo corresponde à busca
      bool shouldInclude = false;

      for (final lead in leads) {
        // Converter LeadTintim para Map para usar o mixin
        final leadMap = {
          'id': lead.id,
          'name': lead.name,
          'phone': phoneNumber,
          'message': lead.message,
          'status': _leadStatusToString(lead.status),
        };
        
        if (smartSearch(
          leadMap, 
          _searchTerm,
          nameField: 'name',
          phoneField: 'phone',
          additionalFields: 'message',
        )) {
          shouldInclude = true;
          break;
        }
      }

      if (shouldInclude) {
        filteredMap[phoneNumber] = leads;
      }
    }

    return filteredMap;
  }
}

int _calculateExtraItemCount(
    GroupedLeadsState leadsState, bool hasGroupedLeads) {
  final bool showErrorItem = leadsState.errorMessage != null &&
      hasGroupedLeads && // Only show error if there are existing items
      !leadsState.isLoadingMore && // Don't show error if currently loading more
      leadsState.hasMore; // Only show error if there's potential to load more

  if (leadsState.isLoadingMore || showErrorItem) {
    return 1;
  }
  return 0;
}
