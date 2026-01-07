import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/quotation_tag.dart';

/// Service para gerenciar tags de cotações
class QuotationTagService {
  final SupabaseClient _client = Supabase.instance.client;

  // =====================================================
  // CREATE
  // =====================================================

  /// Criar nova tag
  Future<TagOperationResult> createTag(CreateTagRequest request) async {
    try {
      final result = await _client.rpc('create_quotation_tag', params: request.toJson());
      
      if (result is List && result.isNotEmpty) {
        final data = result.first as Map<String, dynamic>;
        return TagOperationResult.fromJson(data);
      }
      
      return TagOperationResult(
        success: false,
        message: 'Erro ao criar tag',
      );
    } catch (e) {
      print('Erro ao criar tag: $e');
      return TagOperationResult(
        success: false,
        message: 'Erro: $e',
      );
    }
  }

  // =====================================================
  // READ
  // =====================================================

  /// Listar todas as tags
  Future<List<QuotationTag>> getTags({bool activeOnly = true}) async {
    try {
      final result = await _client.rpc('get_quotation_tags', params: {
        'p_active_only': activeOnly,
      });
      
      if (result is List) {
        return result.map((e) => QuotationTag.fromJson(e as Map<String, dynamic>)).toList();
      }
      
      return [];
    } catch (e) {
      print('Erro ao buscar tags: $e');
      return [];
    }
  }

  /// Buscar tags de uma cotação específica
  Future<List<QuotationTag>> getTagsByQuotationId(int quotationId) async {
    try {
      final result = await _client.rpc('get_quotation_tags_by_quotation_id', params: {
        'p_quotation_id': quotationId,
      });
      
      if (result is List) {
        return result.map((e) => QuotationTag.fromJson(e as Map<String, dynamic>)).toList();
      }
      
      return [];
    } catch (e) {
      print('Erro ao buscar tags da cotação: $e');
      return [];
    }
  }

  /// Buscar estatísticas de uso das tags
  Future<List<Map<String, dynamic>>> getTagStats() async {
    try {
      final result = await _client.from('quotation_tag_stats').select();
      return (result as List).map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      print('Erro ao buscar estatísticas: $e');
      return [];
    }
  }

  // =====================================================
  // UPDATE
  // =====================================================

  /// Atualizar tag
  Future<TagOperationResult> updateTag({
    required int tagId,
    String? name,
    String? color,
    String? description,
    String? icon,
    bool? isActive,
  }) async {
    try {
      final result = await _client.rpc('update_quotation_tag', params: {
        'p_tag_id': tagId,
        'p_name': name,
        'p_color': color,
        'p_description': description,
        'p_icon': icon,
        'p_is_active': isActive,
      });
      
      if (result is List && result.isNotEmpty) {
        final data = result.first as Map<String, dynamic>;
        return TagOperationResult(
          success: data['success'] as bool? ?? false,
          message: data['message'] as String? ?? '',
        );
      }
      
      return TagOperationResult(
        success: false,
        message: 'Erro ao atualizar tag',
      );
    } catch (e) {
      print('Erro ao atualizar tag: $e');
      return TagOperationResult(
        success: false,
        message: 'Erro: $e',
      );
    }
  }

  // =====================================================
  // DELETE
  // =====================================================

  /// Deletar tag
  Future<TagOperationResult> deleteTag(int tagId) async {
    try {
      final result = await _client.rpc('delete_quotation_tag', params: {
        'p_tag_id': tagId,
      });
      
      if (result is List && result.isNotEmpty) {
        final data = result.first as Map<String, dynamic>;
        return TagOperationResult(
          success: data['success'] as bool? ?? false,
          message: data['message'] as String? ?? '',
        );
      }
      
      return TagOperationResult(
        success: false,
        message: 'Erro ao deletar tag',
      );
    } catch (e) {
      print('Erro ao deletar tag: $e');
      return TagOperationResult(
        success: false,
        message: 'Erro: $e',
      );
    }
  }

  // =====================================================
  // ASSIGN / REMOVE
  // =====================================================

  /// Atribuir tag a uma cotação
  Future<TagOperationResult> assignTagToQuotation({
    required int quotationId,
    required int tagId,
    String assignedBy = 'system',
  }) async {
    try {
      final result = await _client.rpc('assign_tag_to_quotation', params: {
        'p_quotation_id': quotationId,
        'p_tag_id': tagId,
        'p_assigned_by': assignedBy,
      });
      
      if (result is List && result.isNotEmpty) {
        final data = result.first as Map<String, dynamic>;
        return TagOperationResult(
          success: data['success'] as bool? ?? false,
          message: data['message'] as String? ?? '',
        );
      }
      
      return TagOperationResult(
        success: false,
        message: 'Erro ao atribuir tag',
      );
    } catch (e) {
      print('Erro ao atribuir tag: $e');
      return TagOperationResult(
        success: false,
        message: 'Erro: $e',
      );
    }
  }

  /// Remover tag de uma cotação
  Future<TagOperationResult> removeTagFromQuotation({
    required int quotationId,
    required int tagId,
  }) async {
    try {
      final result = await _client.rpc('remove_tag_from_quotation', params: {
        'p_quotation_id': quotationId,
        'p_tag_id': tagId,
      });
      
      if (result is List && result.isNotEmpty) {
        final data = result.first as Map<String, dynamic>;
        return TagOperationResult(
          success: data['success'] as bool? ?? false,
          message: data['message'] as String? ?? '',
        );
      }
      
      return TagOperationResult(
        success: false,
        message: 'Erro ao remover tag',
      );
    } catch (e) {
      print('Erro ao remover tag: $e');
      return TagOperationResult(
        success: false,
        message: 'Erro: $e',
      );
    }
  }

  /// Atualizar todas as tags de uma cotação (substitui as existentes)
  Future<bool> updateQuotationTags({
    required int quotationId,
    required List<int> tagIds,
    String assignedBy = 'system',
  }) async {
    try {
      // 1. Buscar tags atuais
      final currentTags = await getTagsByQuotationId(quotationId);
      final currentTagIds = currentTags.map((t) => t.id).toSet();
      final newTagIds = tagIds.toSet();
      
      // 2. Tags para adicionar (não existem atualmente)
      final toAdd = newTagIds.difference(currentTagIds);
      
      // 3. Tags para remover (existem mas não estão na nova lista)
      final toRemove = currentTagIds.difference(newTagIds);
      
      // 4. Adicionar novas tags
      for (final tagId in toAdd) {
        await assignTagToQuotation(
          quotationId: quotationId,
          tagId: tagId,
          assignedBy: assignedBy,
        );
      }
      
      // 5. Remover tags antigas
      for (final tagId in toRemove) {
        await removeTagFromQuotation(
          quotationId: quotationId,
          tagId: tagId,
        );
      }
      
      return true;
    } catch (e) {
      print('Erro ao atualizar tags da cotação: $e');
      return false;
    }
  }
}
