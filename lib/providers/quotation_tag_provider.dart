import 'package:flutter/material.dart';
import '../models/quotation_tag.dart';
import '../services/quotation_tag_service.dart';

/// Provider para gerenciar estado das tags
class QuotationTagProvider extends ChangeNotifier {
  final QuotationTagService _service = QuotationTagService();
  
  List<QuotationTag> _tags = [];
  bool _isLoading = false;
  String? _error;
  
  // Cache de tags por cotação
  final Map<int, List<QuotationTag>> _tagsByQuotation = {};

  // Getters
  List<QuotationTag> get tags => _tags;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  List<QuotationTag> get systemTags => _tags.where((t) => t.isSystem).toList();
  List<QuotationTag> get customTags => _tags.where((t) => !t.isSystem).toList();
  List<QuotationTag> get activeTags => _tags.where((t) => t.isActive).toList();

  /// Carregar todas as tags
  Future<void> loadTags({bool activeOnly = true}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _tags = await _service.getTags(activeOnly: activeOnly);
      _error = null;
    } catch (e) {
      _error = 'Erro ao carregar tags: $e';
      print(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Buscar tags de uma cotação
  Future<List<QuotationTag>> getTagsByQuotationId(int quotationId, {bool forceRefresh = false}) async {
    // Usar cache se disponível
    if (!forceRefresh && _tagsByQuotation.containsKey(quotationId)) {
      return _tagsByQuotation[quotationId]!;
    }

    try {
      final tags = await _service.getTagsByQuotationId(quotationId);
      _tagsByQuotation[quotationId] = tags;
      return tags;
    } catch (e) {
      print('Erro ao buscar tags da cotação: $e');
      return [];
    }
  }

  /// Criar nova tag
  Future<TagOperationResult> createTag({
    required String name,
    required String color,
    String? description,
    String? icon,
    required String createdBy,
  }) async {
    final request = CreateTagRequest(
      name: name,
      color: color,
      description: description,
      icon: icon,
      createdBy: createdBy,
    );

    final result = await _service.createTag(request);

    if (result.success) {
      // Recarregar tags
      await loadTags();
    }

    return result;
  }

  /// Atualizar tag
  Future<TagOperationResult> updateTag({
    required int tagId,
    String? name,
    String? color,
    String? description,
    String? icon,
    bool? isActive,
  }) async {
    final result = await _service.updateTag(
      tagId: tagId,
      name: name,
      color: color,
      description: description,
      icon: icon,
      isActive: isActive,
    );

    if (result.success) {
      await loadTags();
    }

    return result;
  }

  /// Deletar tag
  Future<TagOperationResult> deleteTag(int tagId) async {
    final result = await _service.deleteTag(tagId);

    if (result.success) {
      _tags.removeWhere((t) => t.id == tagId);
      notifyListeners();
    }

    return result;
  }

  /// Atribuir tag a cotação
  Future<TagOperationResult> assignTag({
    required int quotationId,
    required int tagId,
    String assignedBy = 'system',
  }) async {
    final result = await _service.assignTagToQuotation(
      quotationId: quotationId,
      tagId: tagId,
      assignedBy: assignedBy,
    );

    if (result.success) {
      // Limpar cache
      _tagsByQuotation.remove(quotationId);
    }

    return result;
  }

  /// Remover tag de cotação
  Future<TagOperationResult> removeTag({
    required int quotationId,
    required int tagId,
  }) async {
    final result = await _service.removeTagFromQuotation(
      quotationId: quotationId,
      tagId: tagId,
    );

    if (result.success) {
      // Limpar cache
      _tagsByQuotation.remove(quotationId);
    }

    return result;
  }

  /// Atualizar todas as tags de uma cotação
  Future<bool> updateQuotationTags({
    required int quotationId,
    required List<int> tagIds,
    String assignedBy = 'system',
  }) async {
    final success = await _service.updateQuotationTags(
      quotationId: quotationId,
      tagIds: tagIds,
      assignedBy: assignedBy,
    );

    if (success) {
      // Limpar cache
      _tagsByQuotation.remove(quotationId);
    }

    return success;
  }

  /// Buscar tag por ID
  QuotationTag? getTagById(int id) {
    try {
      return _tags.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Limpar cache de uma cotação
  void clearQuotationCache(int quotationId) {
    _tagsByQuotation.remove(quotationId);
  }

  /// Limpar todo o cache
  void clearAllCache() {
    _tagsByQuotation.clear();
  }
}
