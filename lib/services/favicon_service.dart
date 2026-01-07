import 'package:flutter/material.dart';

class FaviconService {
  // Mapeamento de códigos de companhia para nomes de arquivo (sem fundo)
  static const Map<String, String> _airlineFaviconMap = {
    // Companhias americanas
    'AA': 'sem_fundo_aa.png',
    'DL': 'sem_fundo_delta.png',
    'UA': 'sem_fundo_united.png',
    
    // Companhias latino-americanas
    'LA': 'sem_fundo_latam.png',
    'AV': 'sem_fundo_avianca.png',
    'G3': 'sem_fundo_gol.png',
  };

  // Widget para exibir favicon da companhia
  Widget buildAirlineFavicon(String airlineCode, {double size = 32}) {
    final fileName = _airlineFaviconMap[airlineCode.toUpperCase()];
    
    // Todos os favicons terão o mesmo tamanho (300% maior)
    double adjustedSize = size * 4.0;
    
    if (fileName == null) {
      // Fallback para ícone genérico se não encontrar favicon
      return Container(
        width: adjustedSize,
        height: adjustedSize,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(
          Icons.flight,
          size: adjustedSize * 0.6,
          color: Colors.grey[600],
        ),
      );
    }

    // Usar Image.asset para PNG com fit: BoxFit.contain para evitar fundo quadriculado
    return Container(
      width: adjustedSize,
      height: adjustedSize,
      child: Image.asset(
        'assets/favicons/$fileName',
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: adjustedSize,
            height: adjustedSize,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              Icons.flight,
              size: adjustedSize * 0.6,
              color: Colors.grey[600],
            ),
          );
        },
      ),
    );
  }

  // Verificar se um favicon existe
  bool faviconExists(String airlineCode) {
    final fileName = _airlineFaviconMap[airlineCode.toUpperCase()];
    return fileName != null;
  }

  // Listar todos os favicons disponíveis
  List<String> listAvailableFavicons() {
    return _airlineFaviconMap.values.toList()..sort();
  }
} 
