import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Widget de autocomplete usando Nominatim (OpenStreetMap) - 100% GRATUITO
/// Sem API Key, sem custos, sem limites rígidos
class NominatimAddressField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final IconData? prefixIcon;

  const NominatimAddressField({
    super.key,
    required this.controller,
    required this.labelText,
    this.hintText,
    this.prefixIcon,
  });

  @override
  State<NominatimAddressField> createState() => _NominatimAddressFieldState();
}

class _NominatimAddressFieldState extends State<NominatimAddressField> {
  static const String _baseUrl = 'https://nominatim.openstreetmap.org';
  
  // Cache e rate limiting
  final Map<String, List<NominatimPlace>> _cache = {};
  DateTime? _lastCallTime;

  Future<List<NominatimPlace>> _searchPlaces(String query) async {
    if (query.length < 3) return [];

    // Rate limiting: 1 req/seg (respeitar política do Nominatim)
    final now = DateTime.now();
    if (_lastCallTime != null && now.difference(_lastCallTime!).inMilliseconds < 1000) {
      await Future<void>.delayed(Duration(milliseconds: 1000 - now.difference(_lastCallTime!).inMilliseconds));
    }
    _lastCallTime = DateTime.now();

    // Verificar cache
    if (_cache.containsKey(query)) {
      return _cache[query]!;
    }

    try {
      final uri = Uri.parse('$_baseUrl/search').replace(
        queryParameters: {
          'q': query,
          'format': 'json',
          'addressdetails': '1',
          'limit': '50',
          'accept-language': 'pt-BR',
          'dedupe': '0',
          'countrycodes': 'us', // 🇺🇸 Limita busca apenas aos Estados Unidos
        },
      );

      debugPrint('🔍 Nominatim: Buscando "$query"');
      debugPrint('🌐 URL: ${uri.toString()}');
      
      final response = await http.get(
        uri,
        headers: {
          'User-Agent': 'LecotourDashboard/1.0', // Obrigatório pela política do Nominatim
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        
        debugPrint('📊 API retornou ${data.length} resultados');
        
        final places = data.map((item) {
          return NominatimPlace(
            displayName: item['display_name'] ?? '',
            name: item['name'] ?? item['display_name'] ?? '',
            address: item['address'] ?? {},
            latitude: double.tryParse(item['lat'] ?? '0') ?? 0.0,
            longitude: double.tryParse(item['lon'] ?? '0') ?? 0.0,
            type: item['type'] ?? '',
            placeClass: item['class'] ?? '',
          );
        }).toList();

        _cache[query] = places;
        
        debugPrint('✅ Processados ${places.length} locais');
        debugPrint('📋 TODOS os resultados:');
        for (var i = 0; i < places.length; i++) {
          final p = places[i];
          debugPrint('  ${i + 1}. 📍 ${p.name} (${p.type}/${p.placeClass})');
          debugPrint('     ${p.shortAddress}');
        }
        
        return places;
      } else {
        debugPrint('❌ HTTP ${response.statusCode}: ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('❌ Erro: $e');
      return [];
    }
  }

  String _getIcon(NominatimPlace place) {
    if (place.type == 'hotel' || place.placeClass == 'tourism') return '🏨';
    if (place.type == 'airport' || place.placeClass == 'aeroway') return '✈️';
    if (place.type == 'restaurant' || place.placeClass == 'amenity') return '🍽️';
    if (place.placeClass == 'building') return '🏢';
    return '📍';
  }

  @override
  Widget build(BuildContext context) {
    return Autocomplete<NominatimPlace>(
      initialValue: TextEditingValue(text: widget.controller.text),
      displayStringForOption: (NominatimPlace place) => place.displayName,
      optionsBuilder: (TextEditingValue textEditingValue) async {
        if (textEditingValue.text.length < 3) {
          return const Iterable<NominatimPlace>.empty();
        }
        return await _searchPlaces(textEditingValue.text);
      },
      optionsViewBuilder: (
        BuildContext context,
        AutocompleteOnSelected<NominatimPlace> onSelected,
        Iterable<NominatimPlace> options,
      ) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: 400,
                maxWidth: MediaQuery.of(context).size.width * 0.85,
              ),
              child: options.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 12),
                          Text('Buscando endereços...'),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shrinkWrap: true,
                      itemCount: options.length,
                      itemBuilder: (BuildContext context, int index) {
                        final place = options.elementAt(index);
                        
                        return InkWell(
                          onTap: () => onSelected(place),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: Colors.grey[200]!),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[50],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _getIcon(place),
                                    style: const TextStyle(fontSize: 20),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        place.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        place.shortAddress,
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
                                Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[400]),
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
      onSelected: (NominatimPlace place) {
        widget.controller.text = place.displayName;
        
        debugPrint('✅ Selecionado: ${place.name}');
        debugPrint('📍 Coords: ${place.latitude}, ${place.longitude}');
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    place.name,
                    maxLines: 1,
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
        // Sincronizar controllers
        textEditingController.text = widget.controller.text;
        textEditingController.addListener(() {
          widget.controller.text = textEditingController.text;
        });

        return TextFormField(
          controller: textEditingController,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: widget.labelText,
            hintText: widget.hintText ?? 'Digite para buscar hotéis e endereços',
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
          ),
        );
      },
    );
  }
}

class NominatimPlace {
  final String displayName;
  final String name;
  final Map<String, dynamic> address;
  final double latitude;
  final double longitude;
  final String type;
  final String placeClass;

  NominatimPlace({
    required this.displayName,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.type,
    required this.placeClass,
  });

  String get shortAddress {
    final parts = displayName.split(',');
    if (parts.length > 1) {
      return parts.sublist(1).join(',').trim();
    }
    return displayName;
  }

  bool get isHotel => type == 'hotel' || placeClass == 'tourism';
  bool get isAirport => type == 'airport' || placeClass == 'aeroway';
}

