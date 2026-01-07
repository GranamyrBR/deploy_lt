import 'package:flutter/material.dart';

class SourceColors {
  static const Map<String, Color> sourceColors = {
    // Origens reais do banco de dados
    'Whatsapp': Color(0xFF25D366),
    'Instagram': Color(0xFFE4405F),
    'Facebook': Color(0xFF1877F2),
    'Google': Color(0xFF4285F4),
    'Site': Color(0xFF2196F3),
    'Indicação': Color(0xFF4CAF50),
    'Email': Color(0xFF9C27B0),
    'Agência': Color(0xFF795548),
    'Antigo': Color(0xFF607D8B),
    'Dani': Color(0xFFE91E63),
    'DDMO': Color(0xFF3F51B5),
    'Leco': Color(0xFFFF5722),
    'Parceiro': Color(0xFF009688),
    'Definir': Color(0xFFFFC107),
    'Não rastreada': Color(0xFF9E9E9E),
    'Fez Contato': Color(0xFF8BC34A),
    
    // Origens adicionais para compatibilidade
    'WhatsApp': Color(0xFF25D366),
    'Telefone': Color(0xFFFF9800),
    'LinkedIn': Color(0xFF0077B5),
    'Twitter': Color(0xFF1DA1F2),
    'YouTube': Color(0xFFFF0000),
    'TikTok': Color(0xFF000000),
    'Pinterest': Color(0xFFE60023),
    'Snapchat': Color(0xFFFFFC00),
    'Telegram': Color(0xFF0088CC),
    'Discord': Color(0xFF5865F2),
    'Reddit': Color(0xFFFF4500),
    'Twitch': Color(0xFF9146FF),
    'Tumblr': Color(0xFF36465D),
  };

  /// Retorna a cor para uma origem específica
  static Color getSourceColor(String? sourceName) {
    if (sourceName == null) return Colors.grey;
    
    // Busca exata primeiro
    if (sourceColors.containsKey(sourceName)) {
      return sourceColors[sourceName]!;
    }
    
    // Busca por similaridade (case insensitive)
    final normalizedSourceName = sourceName.toLowerCase();
    for (final entry in sourceColors.entries) {
      if (entry.key.toLowerCase() == normalizedSourceName) {
        return entry.value;
      }
    }
    
    // Se não encontrar, retorna uma cor baseada no hash do nome
    return _generateColorFromString(sourceName);
  }

  /// Gera uma cor baseada no hash da string
  static Color _generateColorFromString(String text) {
    int hash = 0;
    for (int i = 0; i < text.length; i++) {
      hash = text.codeUnitAt(i) + ((hash << 5) - hash);
    }
    
    // Converter hash para HSL e depois para RGB
    final hue = (hash.abs() % 360).toDouble();
    const saturation = 0.7;
    const lightness = 0.5;
    
    return HSLColor.fromAHSL(1.0, hue, saturation, lightness).toColor();
  }

  /// Retorna uma lista de todas as cores disponíveis
  static List<Color> getAllColors() {
    return sourceColors.values.toList();
  }

  /// Retorna uma lista de todas as origens disponíveis
  static List<String> getAllSourceNames() {
    return sourceColors.keys.toList();
  }
}
