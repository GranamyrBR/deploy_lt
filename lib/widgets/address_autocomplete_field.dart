import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_keys.dart';

/// Widget de autocomplete de endereços usando Google Geocoding API (GRATUITA)
/// Limite: 2.500 requisições/dia grátis
class AddressAutocompleteField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final IconData? prefixIcon;
  final void Function(AddressSuggestion)? onAddressSelected;
  final String? Function(String?)? validator;
  final bool enabled;

  const AddressAutocompleteField({
    Key? key,
    required this.controller,
    required this.labelText,
    this.hintText,
    this.prefixIcon,
    this.onAddressSelected,
    this.validator,
    this.enabled = true,
  }) : super(key: key);

  @override
  State<AddressAutocompleteField> createState() => _AddressAutocompleteFieldState();
}

class _AddressAutocompleteFieldState extends State<AddressAutocompleteField> {
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api';
  
  // API Key com fallback (carregada uma vez)
  late final String _apiKey;
  
  @override
  void initState() {
    super.initState();
    // Carregar API Key uma vez na inicialização
    try {
      _apiKey = ApiKeys.googleMapsApiKey;
    } catch (e) {
      // Usar chave padrão se dotenv não estiver carregado
      _apiKey = 'AIzaSyAKhlxvUnKDY853Y3-mpWIk66Moh-aCpQM';
    }
  }
  
  // Cache para evitar chamadas repetidas
  final Map<String, List<AddressSuggestion>> _cache = {};
  DateTime? _lastCallTime;

  Future<List<AddressSuggestion>> _getAddressSuggestions(String query) async {
    if (_apiKey.isEmpty || query.length < 3) {
      return [];
    }

    // Rate limiting: mínimo 300ms entre chamadas
    final now = DateTime.now();
    if (_lastCallTime != null && now.difference(_lastCallTime!).inMilliseconds < 300) {
      await Future.delayed(const Duration(milliseconds: 300), () {});
    }
    _lastCallTime = DateTime.now();

    // Verificar cache
    if (_cache.containsKey(query)) {
      return _cache[query]!;
    }

    try {
      // Usar Geocoding API para buscar endereços
      final uri = Uri.parse('$_baseUrl/geocode/json').replace(
        queryParameters: {
          'address': query,
          'key': _apiKey,
          'language': 'pt-BR',
        },
      );

      debugPrint('🔍 Buscando: $query');
      debugPrint('🌐 URL: ${uri.toString()}');
      
      final response = await http.get(uri);
      
      debugPrint('📡 Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        debugPrint('📊 API Status: ${data['status']}');
        debugPrint('📋 Resultados: ${data['results']?.length ?? 0}');
        
        if (data['status'] == 'OK' && data['results'] != null) {
          final suggestions = (data['results'] as List<dynamic>)
              .take(5) // Limitar a 5 resultados
              .map((result) {
                final location = result['geometry']['location'];
                return AddressSuggestion(
                  formattedAddress: result['formatted_address'],
                  placeId: result['place_id'],
                  latitude: location['lat'].toDouble(),
                  longitude: location['lng'].toDouble(),
                  types: List<String>.from(result['types'] ?? []),
                );
              })
              .toList();

          // Salvar no cache
          _cache[query] = suggestions;
          
          debugPrint('✅ Encontrados ${suggestions.length} endereços');
          for (var s in suggestions) {
            debugPrint('  📍 ${s.shortAddress}');
          }
          return suggestions;
        } else {
          debugPrint('❌ API Status: ${data['status']}');
          if (data['error_message'] != null) {
            debugPrint('❌ Erro: ${data['error_message']}');
          }
        }
      } else {
        debugPrint('❌ HTTP Error: ${response.statusCode}');
        debugPrint('❌ Body: ${response.body}');
      }
      
      return [];
    } catch (e) {
      debugPrint('❌ Erro ao buscar endereços: $e');
      return [];
    }
  }

  String _getAddressIcon(List<String> types) {
    if (types.contains('lodging') || types.contains('hotel')) return '🏨';
    if (types.contains('airport')) return '✈️';
    if (types.contains('restaurant')) return '🍽️';
    if (types.contains('point_of_interest')) return '📍';
    if (types.contains('establishment')) return '🏢';
    return '📍';
  }

  @override
  Widget build(BuildContext context) {
    return Autocomplete<AddressSuggestion>(
      initialValue: TextEditingValue(text: widget.controller.text),
      displayStringForOption: (AddressSuggestion suggestion) => suggestion.formattedAddress,
      optionsBuilder: (TextEditingValue textEditingValue) async {
        if (textEditingValue.text.length < 3) {
          return const Iterable<AddressSuggestion>.empty();
        }
        return await _getAddressSuggestions(textEditingValue.text);
      },
      optionsViewBuilder: (
        BuildContext context,
        AutocompleteOnSelected<AddressSuggestion> onSelected,
        Iterable<AddressSuggestion> options,
      ) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: 300,
                maxWidth: MediaQuery.of(context).size.width - 48,
              ),
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (BuildContext context, int index) {
                  final suggestion = options.elementAt(index);
                  return InkWell(
                    onTap: () => onSelected(suggestion),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Text(
                            _getAddressIcon(suggestion.types),
                            style: const TextStyle(fontSize: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  suggestion.shortAddress,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  suggestion.formattedAddress,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right, size: 16, color: Colors.grey[400]),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
      onSelected: (AddressSuggestion suggestion) {
        widget.controller.text = suggestion.formattedAddress;
        
        if (widget.onAddressSelected != null) {
          widget.onAddressSelected!(suggestion);
        }
        
        // Mostrar feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Endereço selecionado: ${suggestion.shortAddress}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      },
      fieldViewBuilder: (
        BuildContext context,
        TextEditingController textEditingController,
        FocusNode focusNode,
        VoidCallback onFieldSubmitted,
      ) {
        // Sincronizar o controller externo com o interno
        textEditingController.text = widget.controller.text;
        textEditingController.addListener(() {
          widget.controller.text = textEditingController.text;
        });

        return TextFormField(
          controller: textEditingController,
          focusNode: focusNode,
          enabled: widget.enabled,
          decoration: InputDecoration(
            labelText: widget.labelText,
            hintText: widget.hintText ?? 'Digite para buscar...',
            prefixIcon: widget.prefixIcon != null ? Icon(widget.prefixIcon) : null,
            suffixIcon: textEditingController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      textEditingController.clear();
                      widget.controller.clear();
                    },
                  )
                : const Icon(Icons.search),
            helperText: 'Digite ao menos 3 caracteres',
            helperMaxLines: 1,
          ),
          validator: widget.validator,
        );
      },
    );
  }
}

class AddressSuggestion {
  final String formattedAddress;
  final String placeId;
  final double latitude;
  final double longitude;
  final List<String> types;

  AddressSuggestion({
    required this.formattedAddress,
    required this.placeId,
    required this.latitude,
    required this.longitude,
    required this.types,
  });

  String get shortAddress {
    // Pegar a primeira parte do endereço (antes da primeira vírgula)
    final parts = formattedAddress.split(',');
    return parts.isNotEmpty ? parts[0].trim() : formattedAddress;
  }

  bool get isHotel => types.contains('lodging') || types.contains('hotel');
  bool get isAirport => types.contains('airport');
  bool get isRestaurant => types.contains('restaurant');
}
