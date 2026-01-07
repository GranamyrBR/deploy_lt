import 'package:flutter/material.dart';

mixin SmartSearchMixin {
  /// Busca inteligente que prioriza diferentes campos baseado no tipo de dados
  bool smartSearch(Map<String, dynamic> item, String searchTerm, {
    required String nameField,
    String? phoneField,
    String? emailField,
    String? cityField,
    String? additionalFields,
  }) {
    if (searchTerm.isEmpty) return true;
    
    final termo = searchTerm.toLowerCase();
    
    // Campos básicos
    final nome = (item[nameField] ?? '').toString().toLowerCase();
    final telefone = phoneField != null ? (item[phoneField] ?? '').toString().replaceAll(RegExp(r'\D'), '') : '';
    final email = emailField != null ? (item[emailField] ?? '').toString().toLowerCase() : '';
    final cidade = cityField != null ? (item[cityField] ?? '').toString().toLowerCase() : '';
    
    // Busca inteligente com prioridades
    final nomeWords = nome.split(' ');
    final telefoneClean = telefone.replaceAll(RegExp(r'\D'), '');
    
    // Prioridade 1: Nome (incluindo palavras que começam com o termo)
    final nomeMatch = nome.contains(termo) || nomeWords.any((word) => word.startsWith(termo));
    
    // Prioridade 2: Telefone (busca exata)
    final telefoneMatch = telefoneClean.contains(termo);
    
    // Prioridade 3: Cidade (palavras que começam com o termo)
    final cidadeWords = cidade.split(' ');
    final cidadeMatch = cidade.contains(termo) || cidadeWords.any((word) => word.startsWith(termo));
    
    // Prioridade 4: Email (apenas se o termo for >= 3 caracteres para evitar matches acidentais)
    final emailMatch = termo.length >= 3 && email.contains(termo);
    
    // Campos adicionais (se especificados)
    bool additionalMatch = false;
    if (additionalFields != null) {
      final additionalValue = (item[additionalFields] ?? '').toString().toLowerCase();
      additionalMatch = additionalValue.contains(termo);
    }
    
    final matches = nomeMatch || telefoneMatch || cidadeMatch || emailMatch || additionalMatch;
    
    // Adicionar informação sobre onde foi encontrado o match
    if (matches) {
      item['_matchType'] = nomeMatch ? 'nome' : 
                          telefoneMatch ? 'telefone' : 
                          cidadeMatch ? 'cidade' : 
                          emailMatch ? 'email' : 
                          additionalMatch ? 'outro' : 'outro';
    }
    
    return matches;
  }
  
  /// Remove duplicatas baseado em um campo específico
  List<Map<String, dynamic>> removeDuplicates(List<Map<String, dynamic>> items, String idField) {
    final Map<dynamic, Map<String, dynamic>> uniqueItems = {};
    for (final item in items) {
      final id = item[idField];
      if (!uniqueItems.containsKey(id)) {
        uniqueItems[id] = item;
      }
    }
    return uniqueItems.values.toList();
  }
  
  /// Retorna a cor para o tipo de match
  Color getMatchTypeColor(String? matchType) {
    switch (matchType) {
      case 'nome': return Colors.blue;
      case 'telefone': return Colors.green;
      case 'cidade': return Colors.orange;
      case 'email': return Colors.purple;
      default: return Colors.grey;
    }
  }
  
  /// Retorna o texto para o tipo de match
  String getMatchTypeText(String? matchType) {
    switch (matchType) {
      case 'nome': return 'NOME';
      case 'telefone': return 'TEL';
      case 'cidade': return 'CID';
      case 'email': return 'EMAIL';
      default: return 'OUTRO';
    }
  }
  
  /// Widget para mostrar o indicador de match
  Widget buildMatchIndicator(String? matchType, String searchTerm) {
    if (searchTerm.isEmpty || matchType == null) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: getMatchTypeColor(matchType).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        getMatchTypeText(matchType),
        style: TextStyle(
          fontSize: 9,
          color: getMatchTypeColor(matchType),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
} 
