import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CarPhotosWidget extends StatefulWidget {
  final Function(String?) onPhotoSelected;
  final String? selectedPhotoUrl;
  final bool showSelectionIndicator;
  final double height;
  final double itemWidth;
  final EdgeInsets margin;

  const CarPhotosWidget({
    super.key,
    required this.onPhotoSelected,
    this.selectedPhotoUrl,
    this.showSelectionIndicator = true,
    this.height = 120,
    this.itemWidth = 120,
    this.margin = const EdgeInsets.only(right: 8),
  });

  @override
  State<CarPhotosWidget> createState() => _CarPhotosWidgetState();
}

class _CarPhotosWidgetState extends State<CarPhotosWidget> {
  List<String> _availablePhotos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    try {
      final photos = await _carregarFotosDoAssets();
      setState(() {
        _availablePhotos = photos;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Erro ao carregar fotos: $e');
      setState(() {
        _availablePhotos = _getFotosEstaticas();
        _isLoading = false;
      });
    }
  }

  // Função para carregar fotos dinamicamente do diretório assets
  Future<List<String>> _carregarFotosDoAssets() async {
    try {
      print('🔄 Iniciando carregamento dinâmico de fotos...');
      print('📱 Tipo de plataforma: Web');
      
      // Carrega o manifesto de assets
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);
      
      print('📋 Manifesto carregado com ${manifestMap.keys.length} assets');
      
      // Lista de extensões de imagem suportadas
      final extensoesImagem = ['.jpg', '.jpeg', '.png', '.webp', '.gif', '.bmp'];
      
      // Filtra apenas os assets que estão no diretório assets/medias e são imagens
      List<String> fotosEncontradas = manifestMap.keys
          .where((String key) {
            final isInMediasDir = key.startsWith('assets/medias/');
            final isImage = extensoesImagem.any((ext) => key.toLowerCase().endsWith(ext));
            return isInMediasDir && isImage;
          })
          .toList();
      
      // Ordena alfabeticamente para consistência
      fotosEncontradas.sort();
      
      print('🔍 Fotos encontradas dinamicamente: ${fotosEncontradas.length}');
      for (var foto in fotosEncontradas) {
        print('  ✅ $foto');
      }
      
      if (fotosEncontradas.isEmpty) {
        print('⚠️ Nenhuma foto encontrada dinamicamente, usando fallback estático');
        return _getFotosEstaticas();
      }
      
      return fotosEncontradas;
    } catch (e) {
      print('❌ Erro ao carregar fotos dinamicamente: $e');
      print('🔄 Usando fallback estático');
      return _getFotosEstaticas();
    }
  }

  // Função de fallback com lista estática
  List<String> _getFotosEstaticas() {
    return [
      'assets/medias/SUBURBAN-PREMIER-1.jpg',
      'assets/medias/SUBURBAN-PREMIER-2.jpg',
      'assets/medias/SUBURBAN-PREMIER-3.jpg', 
      'assets/medias/SUBURBAN-PREMIER-4.jpg',
      'assets/medias/TAHOE-1.jpg',
      'assets/medias/TAHOE-2.jpg',
      'assets/medias/Cadillac_Escalade1.jpg',
      'assets/medias/YUKON-1.jpg',
      'assets/medias/SILVERADO-1.jpg',
      'assets/medias/CAMARO-1.jpg',
      'assets/medias/CORVETTE-1.jpg',
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SizedBox(
        height: widget.height,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_availablePhotos.isEmpty) {
      return SizedBox(
        height: widget.height,
        child: Center(
          child: Text(
            'Nenhuma foto disponível',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fotos disponíveis:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: widget.height,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _availablePhotos.length,
            itemBuilder: (context, index) {
              final photoUrl = _availablePhotos[index];
              final isSelected = widget.selectedPhotoUrl == photoUrl;
              
              return GestureDetector(
                onTap: () {
                  widget.onPhotoSelected(isSelected ? null : photoUrl);
                },
                child: Container(
                  width: widget.itemWidth,
                  margin: widget.margin,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isSelected && widget.showSelectionIndicator
                          ? Theme.of(context).colorScheme.primary 
                          : Theme.of(context).colorScheme.outline,
                      width: isSelected && widget.showSelectionIndicator ? 3 : 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: Image.asset(
                      photoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          child: const Icon(Icons.error),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (widget.selectedPhotoUrl != null && widget.showSelectionIndicator) ...[
          const SizedBox(height: 8),
          Text(
            'Foto selecionada ✓',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ],
    );
  }
}