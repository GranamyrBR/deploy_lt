import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/base_screen_layout.dart';
import '../widgets/standard_search_bar.dart';
import '../widgets/car_photos_widget.dart';



// Função para obter a imagem padrão baseada no modelo do carro
String getDefaultCarImage(String? model, [List<String>? fotosDisponiveis]) {
  if (model == null) return 'assets/medias/SUBURBAN-PREMIER-1.jpg';
  
  final modelLower = model.toLowerCase();
  
  // Se temos lista de fotos disponíveis, procura por correspondência
  if (fotosDisponiveis != null && fotosDisponiveis.isNotEmpty) {
    // Procura por foto que contenha o nome do modelo
    for (String foto in fotosDisponiveis) {
      final fotoLower = foto.toLowerCase();
      if (fotoLower.contains(modelLower)) {
        return foto;
      }
    }
    
    // Procura por palavras-chave específicas
    if (modelLower.contains('tahoe')) {
      final tahoePhoto = fotosDisponiveis.firstWhere(
        (foto) => foto.toLowerCase().contains('tahoe'),
        orElse: () => '',
      );
      if (tahoePhoto.isNotEmpty) return tahoePhoto;
    }
    
    if (modelLower.contains('suburban')) {
      final suburbanPhoto = fotosDisponiveis.firstWhere(
        (foto) => foto.toLowerCase().contains('suburban'),
        orElse: () => '',
      );
      if (suburbanPhoto.isNotEmpty) return suburbanPhoto;
    }
    
    // Retorna a primeira foto disponível se nenhuma correspondência for encontrada
    return fotosDisponiveis.first;
  }
  
  // Fallback para lógica estática
  if (modelLower.contains('tahoe')) {
    return 'assets/medias/TAHOE-1.jpg';
  } else if (modelLower.contains('suburban')) {
    return 'assets/medias/SUBURBAN-PREMIER-1.jpg';
  }
  
  // Imagem padrão para outros modelos
  return 'assets/medias/SUBURBAN-PREMIER-1.jpg';
}

class CarsScreen extends ConsumerStatefulWidget {
  const CarsScreen({super.key});

  @override
  ConsumerState<CarsScreen> createState() => _CarsScreenState();
}

class _CarsScreenState extends ConsumerState<CarsScreen> {
  final _client = Supabase.instance.client;
  final ScrollController _horizontalScrollController = ScrollController();

  List<Map<String, dynamic>> _cars = [];
  bool _isLoading = false;
  bool _visualizarComoCartao = false;
  String _searchTerm = '';


  @override
  void initState() {
    super.initState();
    _carregarFotosIniciais();
    _fetchCars();
  }
  
  // Carrega as fotos disponíveis na inicialização
  Future<void> _carregarFotosIniciais() async {

  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    super.dispose();
  }

  Future<void> _refreshCars() async {
    print('🔄 Forçando atualização da lista de carros...');
    await _fetchCars();
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _fetchCars() async {
    print('🔄 Iniciando _fetchCars...');
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Buscar todos os carros
      final carsResponse = await _client
          .from('car')
          .select('*')
          .order('make', ascending: true);
      
      // Buscar relacionamentos driver_car ativos
      final driverCarResponse = await _client
          .from('driver_car')
          .select('''
            car_id,
            driver:driver_id(
              id,
              name,
              email,
              phone
            )
          ''')
          .eq('is_active', true);
      
      // Criar mapa de carros para motoristas
      final Map<int, List<Map<String, dynamic>>> carDriversMap = {};
      for (final relation in driverCarResponse) {
        final carId = relation['car_id'] as int;
        final driver = relation['driver'] as Map<String, dynamic>;
        
        if (!carDriversMap.containsKey(carId)) {
          carDriversMap[carId] = [];
        }
        carDriversMap[carId]!.add(driver);
      }
      
      // Combinar dados dos carros com motoristas
      final List<Map<String, dynamic>> carsWithDrivers = [];
      for (final car in carsResponse) {
        final carData = Map<String, dynamic>.from(car);
        final carId = car['id'] as int;
        
        if (carDriversMap.containsKey(carId)) {
          carData['drivers'] = carDriversMap[carId];
          // Para compatibilidade com o código existente, usar o primeiro motorista
          carData['driver'] = carDriversMap[carId]!.first;
        } else {
          carData['drivers'] = <Map<String, dynamic>>[];
          carData['driver'] = null;
        }
        
        carsWithDrivers.add(carData);
      }
      
      print('✅ Dados recebidos: ${carsWithDrivers.length} carros');
      
      setState(() {
        _cars = carsWithDrivers;
        _isLoading = false;
      });
      
      print('✅ Lista atualizada com ${_cars.length} carros');
      
    } catch (e) {
      print('❌ Erro ao buscar carros: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar carros: $e')),
        );
      }
    }
  }

  Future<void> _adicionarCarro(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    String? make, model, licensePlate, color;
    int? year, capacity;
    bool hasWifi = false;
    bool isSubmitting = false;



    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, modalSetState) => AlertDialog(
            backgroundColor: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF2A2D3E)
                : const Color(0xFFE8F2FF),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              'Novo Carro',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            content: SizedBox(
              width: 500,
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Primeira linha: Marca e Modelo
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              decoration: _buildModernInputDecoration('Marca *'),
                              validator: (v) => v == null || v.isEmpty ? 'Informe a marca' : null,
                              onSaved: (v) => make = v,
                              onChanged: (value) {
                                make = value;
                                modalSetState(() {});
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              decoration: _buildModernInputDecoration('Modelo *'),
                              validator: (v) => v == null || v.isEmpty ? 'Informe o modelo' : null,
                              onSaved: (v) => model = v,
                              onChanged: (value) {
                                model = value;
                                modalSetState(() {});
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Segunda linha: Ano e Placa
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              decoration: _buildModernInputDecoration('Ano *'),
                              keyboardType: TextInputType.number,
                              validator: (v) => v == null || v.isEmpty ? 'Informe o ano' : null,
                              onSaved: (v) => year = int.tryParse(v ?? ''),
                              onChanged: (value) {
                                year = int.tryParse(value);
                                modalSetState(() {});
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              decoration: _buildModernInputDecoration('Placa *'),
                              validator: (v) => v == null || v.isEmpty ? 'Informe a placa' : null,
                              onSaved: (v) => licensePlate = v,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Terceira linha: Cor e Capacidade
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              decoration: _buildModernInputDecoration('Cor'),
                              onSaved: (v) => color = v,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              decoration: _buildModernInputDecoration('Capacidade'),
                              keyboardType: TextInputType.number,
                              onSaved: (v) => capacity = int.tryParse(v ?? ''),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Checkbox WiFi
                      CheckboxListTile(
                        title: const Text('Possui WiFi'),
                        value: hasWifi,
                        onChanged: (value) {
                          modalSetState(() {
                            hasWifi = value ?? false;
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                      const SizedBox(height: 16),
                      // Widget de fotos do carro
                      CarPhotosWidget(
                        onPhotoSelected: (photoUrl) {
                          // Callback para quando uma foto for selecionada
                          print('Foto selecionada: $photoUrl');
                        },
                      ),
                      const SizedBox(height: 16),

                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: isSubmitting ? null : () async {
                  if (formKey.currentState!.validate()) {
                    formKey.currentState!.save();
                    
                    modalSetState(() {
                      isSubmitting = true;
                    });

                    try {
                      await _client.from('car').insert({
                        'make': make,
                        'model': model,
                        'year': year,
                        'license_plate': licensePlate,
                        'color': color,
                        'capacity': capacity,
                        'has_wifi': hasWifi,
                        'photo_url': '',
                      });

                      Navigator.of(context).pop();
                      _fetchCars();
                      
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Carro adicionado com sucesso!')),
                        );
                      }
                    } catch (e) {
                      modalSetState(() {
                        isSubmitting = false;
                      });
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Erro ao adicionar carro: $e')),
                        );
                      }
                    }
                  }
                },
                child: isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Adicionar'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _editarCarro(Map<String, dynamic> car) async {
    final formKey = GlobalKey<FormState>();
    String? make = car['make'], model = car['model'], licensePlate = car['license_plate'], color = car['color'];
    int? year = car['year'], capacity = car['capacity'];
    bool hasWifi = car['has_wifi'] == true;
    bool isSubmitting = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, modalSetState) => AlertDialog(
            backgroundColor: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF2A2D3E)
                : const Color(0xFFE8F2FF),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              'Editar Carro',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            content: SizedBox(
              width: 500,
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Primeira linha: Marca e Modelo
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: make,
                              decoration: _buildModernInputDecoration('Marca *'),
                              validator: (v) => v == null || v.isEmpty ? 'Informe a marca' : null,
                              onSaved: (v) => make = v,
                              onChanged: (value) {
                                make = value;
                                modalSetState(() {});
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              initialValue: model,
                              decoration: _buildModernInputDecoration('Modelo *'),
                              validator: (v) => v == null || v.isEmpty ? 'Informe o modelo' : null,
                              onSaved: (v) => model = v,
                              onChanged: (value) {
                                model = value;
                                modalSetState(() {});
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Segunda linha: Ano e Placa
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: year?.toString(),
                              decoration: _buildModernInputDecoration('Ano *'),
                              keyboardType: TextInputType.number,
                              validator: (v) => v == null || v.isEmpty ? 'Informe o ano' : null,
                              onSaved: (v) => year = int.tryParse(v ?? ''),
                              onChanged: (value) {
                                year = int.tryParse(value);
                                modalSetState(() {});
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              initialValue: licensePlate,
                              decoration: _buildModernInputDecoration('Placa *'),
                              validator: (v) => v == null || v.isEmpty ? 'Informe a placa' : null,
                              onSaved: (v) => licensePlate = v,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Terceira linha: Cor e Capacidade
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: color,
                              decoration: _buildModernInputDecoration('Cor'),
                              onSaved: (v) => color = v,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              initialValue: capacity?.toString(),
                              decoration: _buildModernInputDecoration('Capacidade'),
                              keyboardType: TextInputType.number,
                              onSaved: (v) => capacity = int.tryParse(v ?? ''),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Checkbox WiFi
                      CheckboxListTile(
                        title: const Text('Possui WiFi'),
                        value: hasWifi,
                        onChanged: (value) {
                          modalSetState(() {
                            hasWifi = value ?? false;
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                      const SizedBox(height: 16),
                      // Widget de fotos
                      CarPhotosWidget(
                        onPhotoSelected: (photoUrl) {
                          print('Foto selecionada para edição: $photoUrl');
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: isSubmitting ? null : () async {
                  if (formKey.currentState!.validate()) {
                    formKey.currentState!.save();
                    modalSetState(() {
                      isSubmitting = true;
                    });
                    try {
                      await _client.from('car').update({
                        'make': make,
                        'model': model,
                        'year': year,
                        'license_plate': licensePlate,
                        'color': color,
                        'capacity': capacity,
                        'has_wifi': hasWifi,
                        'photo_url': '',
                      }).eq('id', car['id']);
                      Navigator.of(context).pop();
                      _fetchCars();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Carro atualizado com sucesso!')),
                        );
                      }
                    } catch (e) {
                      modalSetState(() {
                        isSubmitting = false;
                      });
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Erro ao atualizar carro: $e')),
                        );
                      }
                    }
                  }
                },
                child: isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Salvar'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _excluirCarro(Map<String, dynamic> car) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text('Tem certeza que deseja excluir o carro ${car['make']} ${car['model']} (${car['license_plate']})?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _client.from('car').delete().eq('id', car['id']);
                Navigator.of(context).pop();
                _fetchCars();
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Carro excluído com sucesso!')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro ao excluir carro: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  InputDecoration _buildModernInputDecoration(String label, {String? hintText, String? suffixText}) {
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      suffixText: suffixText,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      filled: true,
      fillColor: Theme.of(context).colorScheme.surface,
    );
  }

  Widget _buildSpreadsheetView(List<Map<String, dynamic>> cars) {
    final screenWidth = MediaQuery.of(context).size.width;
    final availableWidth = screenWidth - 32;
    
    final columns = [
      {'key': 'make', 'label': 'Marca', 'width': availableWidth * 0.15},
      {'key': 'model', 'label': 'Modelo', 'width': availableWidth * 0.15},
      {'key': 'year', 'label': 'Ano', 'width': availableWidth * 0.08},
      {'key': 'license_plate', 'label': 'Placa', 'width': availableWidth * 0.12},
      {'key': 'color', 'label': 'Cor', 'width': availableWidth * 0.10},
      {'key': 'capacity', 'label': 'Capacidade', 'width': availableWidth * 0.10},
      {'key': 'has_wifi', 'label': 'WiFi', 'width': availableWidth * 0.08},
      {'key': 'driver', 'label': 'Motorista', 'width': availableWidth * 0.12},
      {'key': 'actions', 'label': 'Ações', 'width': availableWidth * 0.10},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.directions_car, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Carros',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const Spacer(),
                Text(
                  '${cars.length} carros',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: Scrollbar(
              thumbVisibility: true,
              trackVisibility: true,
              thickness: 8,
              radius: const Radius.circular(4),
              controller: _horizontalScrollController,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                controller: _horizontalScrollController,
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: Column(
                    children: [
                      // Cabeçalho
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.2),
                          border: Border(
                            bottom: BorderSide(
                              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                              width: 2,
                            ),
                          ),
                        ),
                        child: Row(
                          children: columns.map((column) {
                            return Container(
                              width: column['width'] as double,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                              decoration: BoxDecoration(
                                border: Border(
                                  right: BorderSide(
                                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: Text(
                                column['label'] as String,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      // Dados
                      ...cars.asMap().entries.map((entry) {
                        final index = entry.key;
                        final car = entry.value;
                        
                        return Container(
                          decoration: BoxDecoration(
                            color: index.isEven 
                                ? Theme.of(context).colorScheme.surface
                                : Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
                            border: Border(
                              bottom: BorderSide(
                                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
                                width: 1,
                              ),
                            ),
                          ),
                          child: Row(
                            children: columns.map((column) {
                              final key = column['key'] as String;
                              final width = column['width'] as double;
                              
                              if (key == 'actions') {
                                return Container(
                                  width: width,
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, size: 18),
                                        onPressed: () => _editarCarro(car),
                                        tooltip: 'Editar',
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                                        onPressed: () => _excluirCarro(car),
                                        tooltip: 'Excluir',
                                      ),
                                    ],
                                  ),
                                );
                              }
                              
                              String displayValue = '';
                              if (key == 'driver') {
                                final drivers = car['drivers'] as List<Map<String, dynamic>>? ?? [];
                                if (drivers.isNotEmpty) {
                                  // Exibir todos os motoristas separados por vírgula
                                  displayValue = drivers.map((d) => d['name'] as String).join(', ');
                                } else {
                                  displayValue = 'Não atribuído';
                                }
                              } else if (key == 'has_wifi') {
                                displayValue = car[key] == true ? 'Sim' : 'Não';
                              } else {
                                displayValue = car[key]?.toString() ?? '';
                              }
                              
                              return Container(
                                width: width,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                decoration: BoxDecoration(
                                  border: Border(
                                    right: BorderSide(
                                      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                                      width: 1,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  displayValue,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardView(List<Map<String, dynamic>> cars) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calcular número de colunas baseado na largura disponível
        int crossAxisCount = 3;
        double childAspectRatio = 1.4;
        
        if (constraints.maxWidth < 800) {
          crossAxisCount = 2;
          childAspectRatio = 1.5;
        } else if (constraints.maxWidth < 1200) {
          crossAxisCount = 3;
          childAspectRatio = 1.4;
        } else {
          crossAxisCount = 4;
          childAspectRatio = 1.3;
        }
        
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: childAspectRatio,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: cars.length,
          itemBuilder: (context, index) {
            final car = cars[index];
            final hasPhoto = car['photo_url'] != null;
            
            return Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              clipBehavior: Clip.hardEdge, // Força o clipping
              child: LayoutBuilder(
                builder: (context, cardConstraints) {
                  // Usar foto padrão se não houver photo_url ou se estiver vazio
                  final photoUrl = car['photo_url']?.toString().trim();
                  final hasValidPhoto = photoUrl != null && photoUrl.isNotEmpty;
                  final imageToShow = hasValidPhoto ? photoUrl : getDefaultCarImage(car['model']?.toString(), []);
                  
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Foto do carro ou placeholder
                      SizedBox(
                        height: cardConstraints.maxHeight * 0.6, // 60% da altura do card
                        width: double.infinity,
                        child: Image.asset(
                          imageToShow,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Theme.of(context).colorScheme.surfaceContainerHighest,
                              child: const Center(
                                child: Icon(Icons.directions_car, size: 40),
                              ),
                            );
                          },
                        ),
                      ),
                      // Informações do carro
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${car['make']} ${car['model']}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 1),
                              Text(
                                '${car['year']} • ${car['license_plate']}',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                  fontSize: 10,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const Spacer(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  if (car['has_wifi'] == true)
                                    Icon(
                                      Icons.wifi, 
                                      size: 12, 
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  const Spacer(),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      InkWell(
                                        onTap: () => _editarCarro(car),
                                        child: Container(
                                          padding: const EdgeInsets.all(2),
                                          child: const Icon(Icons.edit, size: 12),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      InkWell(
                                        onTap: () => _excluirCarro(car),
                                        child: Container(
                                          padding: const EdgeInsets.all(2),
                                          child: const Icon(Icons.delete, size: 12, color: Colors.red),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredCars = _cars.where((car) {
      if (_searchTerm.isEmpty) return true;
      final searchLower = _searchTerm.toLowerCase();
      return car['make']?.toString().toLowerCase().contains(searchLower) == true ||
             car['model']?.toString().toLowerCase().contains(searchLower) == true ||
             car['license_plate']?.toString().toLowerCase().contains(searchLower) == true ||
             car['color']?.toString().toLowerCase().contains(searchLower) == true;
    }).toList();

    return BaseScreenLayout(
      title: 'Carros',
      actions: [
        IconButton(
          icon: Icon(_visualizarComoCartao ? Icons.table_chart : Icons.grid_view),
          onPressed: () {
            setState(() {
              _visualizarComoCartao = !_visualizarComoCartao;
            });
          },
          tooltip: _visualizarComoCartao ? 'Visualizar como tabela' : 'Visualizar como cartões',
        ),
        ElevatedButton.icon(
          onPressed: () => _adicionarCarro(context),
          icon: const Icon(Icons.add),
          label: const Text('Novo Carro'),
        ),
      ],
      child: Column(
        children: [
          StandardSearchBar(
            controller: TextEditingController(text: _searchTerm),
            onChanged: (value) {
              setState(() {
                _searchTerm = value;
              });
            },
            hintText: 'Buscar carros...',
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _refreshCars,
                    child: _visualizarComoCartao
                        ? _buildCardView(filteredCars)
                        : _buildSpreadsheetView(filteredCars),
                  ),
          ),
        ],
      ),
    );
  }
}
