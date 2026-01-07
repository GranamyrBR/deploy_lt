/// Utilitários para flags de países e códigos ISO
class FlagUtils {
  /// Mapa de países para códigos ISO (para flagcdn.com)
  static const Map<String, String> _countryToIsoCode = {
    'Brasil': 'br',
    'Estados Unidos': 'us',
    'Reino Unido': 'gb',
    'França': 'fr',
    'Espanha': 'es',
    'Alemanha': 'de',
    'Itália': 'it',
    'Portugal': 'pt',
    'Japão': 'jp',
    'China': 'cn',
    'Rússia': 'ru',
    'Argentina': 'ar',
    'Chile': 'cl',
    'Uruguai': 'uy',
    'Paraguai': 'py',
    'Bolívia': 'bo',
    'Peru': 'pe',
    'Colômbia': 'co',
    'Venezuela': 've',
    'Equador': 'ec',
    'México': 'mx',
    'Canadá': 'ca',
    'Austrália': 'au',
    'Nova Zelândia': 'nz',
    'África do Sul': 'za',
    'Índia': 'in',
    'Coreia do Sul': 'kr',
    'Tailândia': 'th',
    'Singapura': 'sg',
    'Malásia': 'my',
    'Indonésia': 'id',
    'Filipinas': 'ph',
    'Vietnã': 'vn',
    'Holanda': 'nl',
    'Bélgica': 'be',
    'Suíça': 'ch',
    'Áustria': 'at',
    'Suécia': 'se',
    'Noruega': 'no',
    'Dinamarca': 'dk',
    'Finlândia': 'fi',
    'Polônia': 'pl',
    'República Tcheca': 'cz',
    'Hungria': 'hu',
    'Grécia': 'gr',
    'Turquia': 'tr',
    'Israel': 'il',
    'Emirados Árabes Unidos': 'ae',
    'Arábia Saudita': 'sa',
    'Egito': 'eg',
    'Marrocos': 'ma',
    'Nigéria': 'ng',
    'Quênia': 'ke',
    'Gana': 'gh',
  };

  /// Mapa de códigos DDI para códigos ISO
  static const Map<String, String> _ddiToIsoCode = {
    '55': 'br',   // Brasil
    '1': 'us',    // Estados Unidos/Canadá
    '44': 'gb',   // Reino Unido
    '33': 'fr',   // França
    '34': 'es',   // Espanha
    '49': 'de',   // Alemanha
    '39': 'it',   // Itália
    '351': 'pt',  // Portugal
    '81': 'jp',   // Japão
    '86': 'cn',   // China
    '7': 'ru',    // Rússia
    '54': 'ar',   // Argentina
    '56': 'cl',   // Chile
    '598': 'uy',  // Uruguai
    '595': 'py',  // Paraguai
    '591': 'bo',  // Bolívia
    '51': 'pe',   // Peru
    '57': 'co',   // Colômbia
    '58': 've',   // Venezuela
    '593': 'ec',  // Equador
    '52': 'mx',   // México
    '61': 'au',   // Austrália
    '64': 'nz',   // Nova Zelândia
    '27': 'za',   // África do Sul
    '91': 'in',   // Índia
    '82': 'kr',   // Coreia do Sul
    '66': 'th',   // Tailândia
    '65': 'sg',   // Singapura
    '60': 'my',   // Malásia
    '62': 'id',   // Indonésia
    '63': 'ph',   // Filipinas
    '84': 'vn',   // Vietnã
    '31': 'nl',   // Holanda
    '32': 'be',   // Bélgica
    '41': 'ch',   // Suíça
    '43': 'at',   // Áustria
    '46': 'se',   // Suécia
    '47': 'no',   // Noruega
    '45': 'dk',   // Dinamarca
    '358': 'fi',  // Finlândia
    '48': 'pl',   // Polônia
    '420': 'cz',  // República Tcheca
    '36': 'hu',   // Hungria
    '30': 'gr',   // Grécia
    '90': 'tr',   // Turquia
    '972': 'il',  // Israel
    '971': 'ae',  // Emirados Árabes Unidos
    '966': 'sa',  // Arábia Saudita
    '20': 'eg',   // Egito
    '212': 'ma',  // Marrocos
    '234': 'ng',  // Nigéria
    '254': 'ke',  // Quênia
    '233': 'gh',  // Gana
  };

  /// Emojis de bandeiras para países
  static const Map<String, String> _countryFlags = {
    'Brasil': '🇧🇷',
    'Estados Unidos': '🇺🇸',
    'Reino Unido': '🇬🇧',
    'França': '🇫🇷',
    'Espanha': '🇪🇸',
    'Alemanha': '🇩🇪',
    'Itália': '🇮🇹',
    'Portugal': '🇵🇹',
    'Japão': '🇯🇵',
    'China': '🇨🇳',
    'Rússia': '🇷🇺',
    'Argentina': '🇦🇷',
    'Chile': '🇨🇱',
    'Uruguai': '🇺🇾',
    'Paraguai': '🇵🇾',
    'Bolívia': '🇧🇴',
    'Peru': '🇵🇪',
    'Colômbia': '🇨🇴',
    'Venezuela': '🇻🇪',
    'Equador': '🇪🇨',
    'México': '🇲🇽',
    'Canadá': '🇨🇦',
    'Austrália': '🇦🇺',
    'Nova Zelândia': '🇳🇿',
    'África do Sul': '🇿🇦',
    'Índia': '🇮🇳',
    'Coreia do Sul': '🇰🇷',
    'Tailândia': '🇹🇭',
    'Singapura': '🇸🇬',
    'Malásia': '🇲🇾',
    'Indonésia': '🇮🇩',
    'Filipinas': '🇵🇭',
    'Vietnã': '🇻🇳',
    'Holanda': '🇳🇱',
    'Bélgica': '🇧🇪',
    'Suíça': '🇨🇭',
    'Áustria': '🇦🇹',
    'Suécia': '🇸🇪',
    'Noruega': '🇳🇴',
    'Dinamarca': '🇩🇰',
    'Finlândia': '🇫🇮',
    'Polônia': '🇵🇱',
    'República Tcheca': '🇨🇿',
    'Hungria': '🇭🇺',
    'Grécia': '🇬🇷',
    'Turquia': '🇹🇷',
    'Israel': '🇮🇱',
    'Emirados Árabes Unidos': '🇦🇪',
    'Arábia Saudita': '🇸🇦',
    'Egito': '🇪🇬',
    'Marrocos': '🇲🇦',
    'Nigéria': '🇳🇬',
    'Quênia': '🇰🇪',
    'Gana': '🇬🇭',
  };

  /// Obtém o código ISO do país a partir do nome
  static String? getCountryIsoCode(String countryName) {
    return _countryToIsoCode[countryName];
  }

  /// Obtém o código ISO do país a partir do número de telefone
  static String? getCountryIsoCodeFromPhone(String phone) {
    if (phone.isEmpty) return null;
    
    final digits = phone.replaceAll(RegExp(r'[^\d+]'), '');
    
    // Verificar códigos de país com + explícito
    if (digits.startsWith('+')) {
      final match = RegExp(r'^\+(\d{1,4})').firstMatch(digits);
      if (match != null) {
        final ddi = match.group(1)!;
        return _ddiToIsoCode[ddi];
      }
    }
    
    // Verificar códigos sem + (casos específicos)
    // Estados Unidos/Canadá: 11 dígitos começando com 1
    if (digits.startsWith('1') && digits.length == 11) {
      return 'us';
    }
    
    // Brasil: 12-13 dígitos começando com 55
    if (digits.startsWith('55') && (digits.length == 12 || digits.length == 13)) {
      return 'br';
    }
    
    // Outros países - tentar extrair DDI
    final match = RegExp(r'^(\d{1,4})').firstMatch(digits);
    if (match != null) {
      final ddi = match.group(1)!;
      return _ddiToIsoCode[ddi];
    }
    
    return null;
  }

  /// Obtém a emoji da bandeira do país
  static String getCountryFlag(String countryName) {
    return _countryFlags[countryName] ?? '🌍';
  }

  /// Obtém a URL da bandeira do flagcdn.com
  static String getFlagUrl(String? isoCode, {int width = 24, int height = 18}) {
    if (isoCode == null) return '';
    return 'https://flagcdn.com/${width}x${height}/$isoCode.png';
  }

  /// Obtém a URL da bandeira SVG do flagcdn.com
  static String getFlagSvgUrl(String? isoCode) {
    if (isoCode == null) return '';
    return 'https://flagcdn.com/$isoCode.svg';
  }

  /// Obtém o nome do país a partir do código ISO
  static String getCountryNameFromIsoCode(String isoCode) {
    for (final entry in _countryToIsoCode.entries) {
      if (entry.value == isoCode) {
        return entry.key;
      }
    }
    return 'Outros';
  }

  /// Lista todos os países disponíveis
  static List<String> getAllCountries() {
    return _countryToIsoCode.keys.toList()..sort();
  }

  /// Lista todos os códigos ISO disponíveis
  static List<String> getAllIsoCodes() {
    return _countryToIsoCode.values.toList()..sort();
  }

  /// Verifica se um país é suportado
  static bool isCountrySupported(String countryName) {
    return _countryToIsoCode.containsKey(countryName);
  }

  /// Verifica se um código ISO é suportado
  static bool isIsoCodeSupported(String isoCode) {
    return _countryToIsoCode.containsValue(isoCode);
  }
}