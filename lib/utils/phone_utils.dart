/// Utilitários para formatação e detecção de país/estado a partir de números de telefone
class PhoneUtils {
  /// Detecta o país a partir do número de telefone
  static String? getCountryFromPhone(String phone) {
    if (phone.isEmpty) return null;
    
    final digits = phone.replaceAll(RegExp(r'[^\d+]'), '');
    
    // Verificar códigos de país explícitos
    if (digits.startsWith('+55')) {
      return 'Brasil';
    } else if (digits.startsWith('+1') && digits.length == 12) {
      return 'Estados Unidos';
    } else if (digits.startsWith('+351')) {
      return 'Portugal';
    } else if (digits.startsWith('+34')) {
      return 'Espanha';
    } else if (digits.startsWith('+33')) {
      return 'França';
    } else if (digits.startsWith('+49')) {
      return 'Alemanha';
    } else if (digits.startsWith('+44')) {
      return 'Reino Unido';
    } else if (digits.startsWith('+39')) {
      return 'Itália';
    }
    
    // Para números sem + explícito, analisar o padrão
    // Telefones americanos: 11 dígitos começando com 1
    if (digits.startsWith('1') && digits.length == 11) {
      final areaCode = digits.substring(1, 4);
      // Lista de area codes americanos válidos (principais)
      final validUSAreaCodes = [
        '201','202','203','205','206','207','208','209','210','212','213','214','215','216','217','218','219',
        '224','225','228','229','231','234','239','240','248','251','252','253','254','256','260','262','267',
        '269','270','276','281','301','302','303','304','305','307','308','309','310','312','313','314','315',
        '316','317','318','319','320','321','323','325','330','331','334','336','337','339','347','351','352',
        '360','361','364','380','385','386','401','402','404','405','406','407','408','409','410','412','413',
        '414','415','417','419','423','424','425','430','432','434','435','440','442','443','458','469','470',
        '475','478','479','480','484','501','502','503','504','505','507','508','509','510','512','513','515',
        '516','517','518','520','530','540','541','551','559','561','562','563','564','567','570','571','573',
        '574','575','580','585','586','601','602','603','605','606','607','608','609','610','612','614','615',
        '616','617','618','619','620','623','626','628','629','630','631','636','641','646','650','651','657',
        '660','661','662','667','669','678','681','682','701','702','703','704','706','707','708','712','713',
        '714','715','716','717','718','719','720','724','725','727','731','732','734','737','740','747','754',
        '757','760','762','763','765','770','772','773','774','775','781','785','786','787','801','802','803',
        '804','805','806','808','810','812','813','814','815','816','817','818','828','830','831','832','843',
        '845','847','848','850','856','857','858','859','860','862','863','864','865','870','872','878','901',
        '903','904','906','907','908','909','910','912','913','914','915','916','917','918','919','920','925',
        '928','929','931','934','936','937','940','941','947','949','951','952','954','956','959','970','971',
        '972','973','978','979','980','984','985','989'
      ];
      
      if (validUSAreaCodes.contains(areaCode)) {
        return 'Estados Unidos';
      }
    }
    
    // Telefones brasileiros: 12-13 dígitos começando com 55
    if (digits.startsWith('55') && (digits.length == 12 || digits.length == 13)) {
      return 'Brasil';
    }
    
    // Se não conseguir detectar, assume Brasil como padrão
    return 'Brasil';
  }
  
  /// Detecta o estado brasileiro a partir do número de telefone
  static String? getStateFromPhone(String phone) {
    if (phone.isEmpty) return null;
    
    final country = getCountryFromPhone(phone);
    if (country != 'Brasil') return null;
    
    final digits = phone.replaceAll(RegExp(r'[^\d]'), '');
    String cleanPhone = digits;
    
    // Remove código do país se presente
    if (cleanPhone.startsWith('55') && cleanPhone.length >= 12) {
      cleanPhone = cleanPhone.substring(2);
    }
    
    // Extrai código de área (primeiros 2 dígitos)
    if (cleanPhone.length < 2) return null;
    final areaCode = cleanPhone.substring(0, 2);
    
    // Mapeia código de área para estado
    switch (areaCode) {
      case '11':
      case '12':
      case '13':
      case '14':
      case '15':
      case '16':
      case '17':
      case '18':
      case '19':
        return 'SP';
      case '21':
      case '22':
      case '24':
        return 'RJ';
      case '27':
      case '28':
        return 'ES';
      case '31':
      case '32':
      case '33':
      case '34':
      case '35':
      case '37':
      case '38':
        return 'MG';
      case '41':
      case '42':
      case '43':
      case '44':
      case '45':
      case '46':
        return 'PR';
      case '47':
      case '48':
      case '49':
        return 'SC';
      case '51':
      case '53':
      case '54':
      case '55':
        return 'RS';
      case '61':
        return 'DF';
      case '62':
      case '64':
        return 'GO';
      case '63':
        return 'TO';
      case '65':
      case '66':
        return 'MT';
      case '67':
        return 'MS';
      case '68':
        return 'AC';
      case '69':
        return 'RO';
      case '71':
      case '73':
      case '74':
      case '75':
      case '77':
        return 'BA';
      case '79':
        return 'SE';
      case '81':
      case '87':
        return 'PE';
      case '82':
        return 'AL';
      case '83':
        return 'PB';
      case '84':
        return 'RN';
      case '85':
      case '88':
        return 'CE';
      case '86':
      case '89':
        return 'PI';
      case '91':
      case '93':
      case '94':
        return 'PA';
      case '92':
      case '97':
        return 'AM';
      case '95':
        return 'RR';
      case '96':
        return 'AP';
      case '98':
      case '99':
        return 'MA';
      default:
        return null;
    }
  }
  
  /// Formata o número de telefone baseado no país
  static String formatPhone(String phone) {
    if (phone.isEmpty) return phone;
    
    final digits = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final country = getCountryFromPhone(phone);
    
    switch (country) {
      case 'Brasil':
        return _formatBrazilianPhone(digits);
      case 'Estados Unidos':
        return _formatAmericanPhone(digits);
      case 'Portugal':
        return _formatPortuguesePhone(digits);
      case 'Espanha':
        return _formatSpanishPhone(digits);
      case 'França':
        return _formatFrenchPhone(digits);
      case 'Alemanha':
        return _formatGermanPhone(digits);
      case 'Reino Unido':
        return _formatUKPhone(digits);
      case 'Itália':
        return _formatItalianPhone(digits);
      default:
        return phone;
    }
  }
  
  static String _formatBrazilianPhone(String digits) {
    if (digits.startsWith('+55')) {
      if (digits.length == 13) {
        return '+55 (${digits.substring(3, 5)}) ${digits.substring(5, 10)}-${digits.substring(10)}';
      } else if (digits.length == 12) {
        return '+55 (${digits.substring(3, 5)}) ${digits.substring(5, 9)}-${digits.substring(9)}';
      }
    } else if (digits.startsWith('55') && (digits.length == 12 || digits.length == 13)) {
      if (digits.length == 13) {
        return '+55 (${digits.substring(2, 4)}) ${digits.substring(4, 9)}-${digits.substring(9)}';
      } else {
        return '+55 (${digits.substring(2, 4)}) ${digits.substring(4, 8)}-${digits.substring(8)}';
      }
    }
    return digits;
  }
  
  static String _formatAmericanPhone(String digits) {
    if (digits.startsWith('+1') && digits.length == 12) {
      return '+1 (${digits.substring(2, 5)}) ${digits.substring(5, 8)}-${digits.substring(8)}';
    } else if (digits.startsWith('1') && digits.length == 11) {
      return '+1 (${digits.substring(1, 4)}) ${digits.substring(4, 7)}-${digits.substring(7)}';
    }
    return digits;
  }
  
  static String _formatPortuguesePhone(String digits) {
    String cleanPhone = digits;
    if (cleanPhone.startsWith('+351')) {
      cleanPhone = cleanPhone.substring(4);
    } else if (cleanPhone.startsWith('351')) {
      cleanPhone = cleanPhone.substring(3);
    }
    
    if (cleanPhone.length == 9) {
      return '+351 ${cleanPhone.substring(0, 3)} ${cleanPhone.substring(3, 6)} ${cleanPhone.substring(6)}';
    }
    return digits;
  }
  
  static String _formatSpanishPhone(String digits) {
    String cleanPhone = digits;
    if (cleanPhone.startsWith('+34')) {
      cleanPhone = cleanPhone.substring(3);
    } else if (cleanPhone.startsWith('34')) {
      cleanPhone = cleanPhone.substring(2);
    }
    
    if (cleanPhone.length == 9) {
      return '+34 ${cleanPhone.substring(0, 3)} ${cleanPhone.substring(3, 6)} ${cleanPhone.substring(6)}';
    }
    return digits;
  }
  
  static String _formatFrenchPhone(String digits) {
    String cleanPhone = digits;
    if (cleanPhone.startsWith('+33')) {
      cleanPhone = cleanPhone.substring(3);
    } else if (cleanPhone.startsWith('33')) {
      cleanPhone = cleanPhone.substring(2);
    }
    
    if (cleanPhone.length == 9) {
      return '+33 ${cleanPhone.substring(0, 1)} ${cleanPhone.substring(1, 3)} ${cleanPhone.substring(3, 5)} ${cleanPhone.substring(5, 7)} ${cleanPhone.substring(7)}';
    }
    return digits;
  }
  
  static String _formatGermanPhone(String digits) {
    String cleanPhone = digits;
    if (cleanPhone.startsWith('+49')) {
      cleanPhone = cleanPhone.substring(3);
    } else if (cleanPhone.startsWith('49')) {
      cleanPhone = cleanPhone.substring(2);
    }
    
    if (cleanPhone.length >= 10) {
      return '+49 ${cleanPhone.substring(0, 3)} ${cleanPhone.substring(3)}';
    }
    return digits;
  }
  
  static String _formatUKPhone(String digits) {
    String cleanPhone = digits;
    if (cleanPhone.startsWith('+44')) {
      cleanPhone = cleanPhone.substring(3);
    } else if (cleanPhone.startsWith('44')) {
      cleanPhone = cleanPhone.substring(2);
    }
    
    if (cleanPhone.length == 10) {
      return '+44 ${cleanPhone.substring(0, 4)} ${cleanPhone.substring(4, 7)} ${cleanPhone.substring(7)}';
    }
    return digits;
  }
  
  static String _formatItalianPhone(String digits) {
    String cleanPhone = digits;
    if (cleanPhone.startsWith('+39')) {
      cleanPhone = cleanPhone.substring(3);
    } else if (cleanPhone.startsWith('39')) {
      cleanPhone = cleanPhone.substring(2);
    }
    
    if (cleanPhone.length == 10) {
      return '+39 ${cleanPhone.substring(0, 3)} ${cleanPhone.substring(3, 6)} ${cleanPhone.substring(6)}';
    }
    return digits;
  }
}