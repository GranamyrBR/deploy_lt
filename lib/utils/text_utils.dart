/// Utility functions for text manipulation
class TextUtils {
  /// Remove accents and special characters from text for PDF compatibility
  /// with default fonts (Helvetica) that don't support Unicode
  static String removeAccents(String text) {
    const withAccents = 'ÀÁÂÃÄÅàáâãäåÒÓÔÕÕÖØòóôõöøÈÉÊËèéêëðÇçÐÌÍÎÏìíîïÙÚÛÜùúûüÑñŠšŸÿýŽž';
    const withoutAccents = 'AAAAAAaaaaaaOOOOOOOooooooEEEEeeeeeCcDIIIIiiiiUUUUuuuuNnSsYyyZz';
    
    var result = text;
    for (var i = 0; i < withAccents.length; i++) {
      result = result.replaceAll(withAccents[i], withoutAccents[i]);
    }
    
    // Replace other special characters
    result = result
        .replaceAll('ß', 'ss')
        .replaceAll('Þ', 'TH')
        .replaceAll('þ', 'th')
        .replaceAll('Ð', 'D')
        .replaceAll('ð', 'd')
        .replaceAll('Æ', 'AE')
        .replaceAll('æ', 'ae')
        .replaceAll('Œ', 'OE')
        .replaceAll('œ', 'oe');
    
    return result;
  }

  /// Convert currency symbol to ASCII-safe text
  static String safeCurrencySymbol(String currency) {
    switch (currency.toUpperCase()) {
      case 'BRL':
        return 'R\$ '; // Keep for display but avoid in PDF
      case 'USD':
        return '\$ ';
      case 'EUR':
        return 'EUR ';
      case 'GBP':
        return 'GBP ';
      default:
        return '${currency.toUpperCase()} ';
    }
  }
  
  /// Get ASCII-safe currency symbol for PDF
  static String pdfSafeCurrencySymbol(String currency) {
    switch (currency.toUpperCase()) {
      case 'BRL':
        return 'BRL ';
      case 'USD':
        return 'USD ';
      case 'EUR':
        return 'EUR ';
      case 'GBP':
        return 'GBP ';
      default:
        return '${currency.toUpperCase()} ';
    }
  }

  /// Format text for PDF by removing accents and special chars
  static String formatForPdf(String text) {
    return removeAccents(text);
  }

  /// Safe truncate text to a maximum length
  static String truncate(String text, int maxLength, {String ellipsis = '...'}) {
    if (text.length <= maxLength) return text;
    return text.substring(0, maxLength - ellipsis.length) + ellipsis;
  }

  /// Capitalize first letter of each word
  static String titleCase(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  /// Clean phone number to only digits
  static String cleanPhone(String phone) {
    return phone.replaceAll(RegExp(r'[^\d+]'), '');
  }

  /// Format phone number for display
  static String formatPhone(String phone) {
    final cleaned = cleanPhone(phone);
    if (cleaned.startsWith('+55')) {
      // Brazilian format: +55 (11) 98765-4321
      if (cleaned.length >= 13) {
        return '+55 (${cleaned.substring(3, 5)}) ${cleaned.substring(5, 10)}-${cleaned.substring(10)}';
      }
    }
    return phone;
  }
}


