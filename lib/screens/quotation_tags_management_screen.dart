import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/quotation_tag.dart';
import '../providers/quotation_tag_provider.dart';
import '../widgets/tag_create_edit_dialog.dart';
import '../widgets/standard_app_header.dart';

final quotationTagProvider = ChangeNotifierProvider((ref) => QuotationTagProvider());

/// Tela de gerenciamento de tags
class QuotationTagsManagementScreen extends ConsumerStatefulWidget {
  const QuotationTagsManagementScreen({super.key});

  @override
  ConsumerState<QuotationTagsManagementScreen> createState() => _QuotationTagsManagementScreenState();
}

class _QuotationTagsManagementScreenState extends ConsumerState<QuotationTagsManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(quotationTagProvider).loadTags(activeOnly: false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(quotationTagProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      body: Column(
        children: [
          // 🆕 Header padronizado
          StandardAppHeader(
            title: 'Gerenciar Tags',
            subtitle: 'Organização e Categorização de Cotações',
            icon: Icons.label,
            isDark: isDark,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: () => ref.read(quotationTagProvider).loadTags(activeOnly: false),
                tooltip: 'Atualizar',
              ),
            ],
          ),
          
          Expanded(
            child: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.error != null
              ? _buildErrorState(provider.error!)
              : _buildContent(provider, isDark),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateTagDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Nova Tag'),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(error),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => ref.read(quotationTagProvider).loadTags(activeOnly: false),
            child: const Text('Tentar Novamente'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(QuotationTagProvider provider, bool isDark) {
    final systemTags = provider.systemTags;
    final customTags = provider.customTags;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Estatísticas
          _buildStatsCards(provider, isDark),
          
          const SizedBox(height: 24),
          
          // Tags do Sistema
          if (systemTags.isNotEmpty) ...[
            _buildSectionHeader('Tags do Sistema', isDark, systemTags.length),
            const SizedBox(height: 12),
            _buildTagsList(systemTags, isDark, isSystem: true),
            const SizedBox(height: 24),
          ],
          
          // Tags Customizadas
          _buildSectionHeader('Tags Personalizadas', isDark, customTags.length),
          const SizedBox(height: 12),
          customTags.isEmpty
              ? _buildEmptyCustomTags(isDark)
              : _buildTagsList(customTags, isDark, isSystem: false),
        ],
      ),
    );
  }

  Widget _buildStatsCards(QuotationTagProvider provider, bool isDark) {
    final totalTags = provider.tags.length;
    final activeTags = provider.activeTags.length;
    final totalUsage = provider.tags.fold<int>(0, (sum, tag) => sum + (tag.usageCount ?? 0));

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.label,
            title: 'Total de Tags',
            value: totalTags.toString(),
            color: Colors.blue,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.check_circle,
            title: 'Ativas',
            value: activeTags.toString(),
            color: Colors.green,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.trending_up,
            title: 'Usos Totais',
            value: totalUsage.toString(),
            color: Colors.purple,
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark, int count) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            count.toString(),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTagsList(List<QuotationTag> tags, bool isDark, {required bool isSystem}) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tags.length,
      itemBuilder: (context, index) {
        return _buildTagCard(tags[index], isDark, isSystem: isSystem);
      },
    );
  }

  Widget _buildTagCard(QuotationTag tag, bool isDark, {required bool isSystem}) {
    final color = _parseColor(tag.color);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color, width: 2),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            tag.icon != null ? _getIconData(tag.icon!) : Icons.label,
            color: color,
            size: 24,
          ),
        ),
        title: Row(
          children: [
            Text(
              tag.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            if (!tag.isActive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'INATIVA',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (isSystem)
              Container(
                margin: const EdgeInsets.only(left: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'SISTEMA',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (tag.description != null) ...[
              const SizedBox(height: 4),
              Text(tag.description!),
            ],
            const SizedBox(height: 4),
            Text(
              'Usado ${tag.usageCount ?? 0} vezes',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Botão Editar
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showEditTagDialog(context, tag),
              tooltip: 'Editar',
            ),
            // Botão Deletar (apenas para tags customizadas)
            if (!isSystem)
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _confirmDeleteTag(tag),
                tooltip: 'Deletar',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCustomTags(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 2,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.label_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Nenhuma tag personalizada',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Crie tags personalizadas para organizar suas cotações',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? Colors.grey[500] : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateTagDialog(BuildContext context) async {
    final result = await showDialog<QuotationTag>(
      context: context,
      builder: (context) => const TagCreateEditDialog(),
    );

    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tag "${result.name}" criada com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _showEditTagDialog(BuildContext context, QuotationTag tag) async {
    final result = await showDialog<QuotationTag>(
      context: context,
      builder: (context) => TagCreateEditDialog(tag: tag),
    );

    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tag "${result.name}" atualizada com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _confirmDeleteTag(QuotationTag tag) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deletar Tag'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tem certeza que deseja deletar a tag "${tag.name}"?'),
            if ((tag.usageCount ?? 0) > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Esta tag está sendo usada em ${tag.usageCount} cotações. Ela será removida de todas.',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => _deleteTag(tag),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Deletar'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTag(QuotationTag tag) async {
    Navigator.pop(context); // Fechar dialog

    final result = await ref.read(quotationTagProvider).deleteTag(tag.id);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: result.success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Color _parseColor(String hexColor) {
    try {
      return Color(int.parse(hexColor.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.blue;
    }
  }

  IconData _getIconData(String iconName) {
    final iconMap = {
      'star': Icons.star,
      'priority_high': Icons.priority_high,
      'groups': Icons.groups,
      'public': Icons.public,
      'business': Icons.business,
      'celebration': Icons.celebration,
      'repeat': Icons.repeat,
      'discount': Icons.discount,
    };
    return iconMap[iconName] ?? Icons.label;
  }
}
