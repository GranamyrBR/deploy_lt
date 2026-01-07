import 'package:flutter/material.dart';
import '../models/quotation_tag.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

/// Widget para selecionar tags para uma cotação
class QuotationTagSelector extends StatefulWidget {
  final List<QuotationTag> availableTags;
  final List<int> selectedTagIds;
  final Function(List<int>) onTagsChanged;
  final bool allowCreateNew;

  const QuotationTagSelector({
    Key? key,
    required this.availableTags,
    required this.selectedTagIds,
    required this.onTagsChanged,
    this.allowCreateNew = false,
  }) : super(key: key);

  @override
  State<QuotationTagSelector> createState() => _QuotationTagSelectorState();
}

class _QuotationTagSelectorState extends State<QuotationTagSelector> {
  late List<int> _selectedIds;

  @override
  void initState() {
    super.initState();
    _selectedIds = List.from(widget.selectedTagIds);
  }

  void _toggleTag(int tagId) {
    setState(() {
      if (_selectedIds.contains(tagId)) {
        _selectedIds.remove(tagId);
      } else {
        _selectedIds.add(tagId);
      }
    });
    widget.onTagsChanged(_selectedIds);
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...widget.availableTags.map((tag) => _buildTagChip(tag)),
        if (widget.allowCreateNew) _buildAddButton(),
      ],
    );
  }

  Widget _buildTagChip(QuotationTag tag) {
    final isSelected = _selectedIds.contains(tag.id);
    final color = _parseColor(tag.color);

    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (tag.icon != null) ...[
            Icon(
              _getIconData(tag.icon!),
              size: 16,
              color: isSelected ? Colors.white : color,
            ),
            const SizedBox(width: 4),
          ],
          Text(tag.name),
        ],
      ),
      selected: isSelected,
      onSelected: (_) => _toggleTag(tag.id),
      backgroundColor: color.withOpacity(0.1),
      selectedColor: color,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : color,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(color: color, width: 1.5),
    );
  }

  Widget _buildAddButton() {
    return ActionChip(
      label: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.add, size: 16),
          SizedBox(width: 4),
          Text('Nova Tag'),
        ],
      ),
      onPressed: () {
        // TODO: Abrir dialog para criar nova tag
      },
    );
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
      'vip': Icons.workspace_premium,
      'urgent': Icons.warning_amber,
      'label': Icons.label,
    };
    return iconMap[iconName] ?? Icons.label;
  }
}

/// Widget para exibir tags de forma compacta
class QuotationTagDisplay extends StatelessWidget {
  final List<QuotationTag> tags;
  final int maxVisible;
  final double size;

  const QuotationTagDisplay({
    Key? key,
    required this.tags,
    this.maxVisible = 3,
    this.size = 24,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) return const SizedBox.shrink();

    final visibleTags = tags.take(maxVisible).toList();
    final remainingCount = tags.length - maxVisible;

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        ...visibleTags.map((tag) => _buildTagBadge(tag)),
        if (remainingCount > 0) _buildMoreBadge(remainingCount),
      ],
    );
  }

  Widget _buildTagBadge(QuotationTag tag) {
    final color = _parseColor(tag.color);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: size * 0.4, vertical: size * 0.2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size * 0.4),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (tag.icon != null) ...[
            Icon(
              _getIconData(tag.icon!),
              size: size * 0.6,
              color: Colors.white,
            ),
            SizedBox(width: size * 0.15),
          ],
          Text(
            tag.name,
            style: TextStyle(
              color: Colors.white,
              fontSize: size * 0.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoreBadge(int count) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: size * 0.4, vertical: size * 0.2),
      decoration: BoxDecoration(
        color: Colors.grey.shade400,
        borderRadius: BorderRadius.circular(size * 0.4),
      ),
      child: Text(
        '+$count',
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.5,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
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
      'vip': Icons.workspace_premium,
      'urgent': Icons.warning_amber,
      'label': Icons.label,
    };
    return iconMap[iconName] ?? Icons.label;
  }
}
