import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../models/quotation_tag.dart';
import '../screens/quotation_tags_management_screen.dart';

/// Dialog para criar ou editar uma tag
class TagCreateEditDialog extends ConsumerStatefulWidget {
  final QuotationTag? tag; // Null = criar nova, não null = editar

  const TagCreateEditDialog({Key? key, this.tag}) : super(key: key);

  @override
  ConsumerState<TagCreateEditDialog> createState() => _TagCreateEditDialogState();
}

class _TagCreateEditDialogState extends ConsumerState<TagCreateEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late Color _selectedColor;
  String? _selectedIcon;
  bool _isActive = true;
  bool _isLoading = false;

  // Ícones disponíveis
  final List<Map<String, dynamic>> _availableIcons = [
    {'name': 'star', 'icon': Icons.star, 'label': 'Estrela'},
    {'name': 'priority_high', 'icon': Icons.priority_high, 'label': 'Prioridade'},
    {'name': 'groups', 'icon': Icons.groups, 'label': 'Grupos'},
    {'name': 'public', 'icon': Icons.public, 'label': 'Internacional'},
    {'name': 'business', 'icon': Icons.business, 'label': 'Negócios'},
    {'name': 'celebration', 'icon': Icons.celebration, 'label': 'Celebração'},
    {'name': 'repeat', 'icon': Icons.repeat, 'label': 'Repetir'},
    {'name': 'discount', 'icon': Icons.discount, 'label': 'Desconto'},
    {'name': 'label', 'icon': Icons.label, 'label': 'Label'},
    {'name': 'verified', 'icon': Icons.verified, 'label': 'Verificado'},
    {'name': 'trending_up', 'icon': Icons.trending_up, 'label': 'Tendência'},
    {'name': 'favorite', 'icon': Icons.favorite, 'label': 'Favorito'},
    {'name': 'flag', 'icon': Icons.flag, 'label': 'Bandeira'},
    {'name': 'bookmark', 'icon': Icons.bookmark, 'label': 'Marcador'},
    {'name': 'lightbulb', 'icon': Icons.lightbulb, 'label': 'Ideia'},
    {'name': 'workspace_premium', 'icon': Icons.workspace_premium, 'label': 'Premium'},
  ];

  bool get isEditMode => widget.tag != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.tag?.name ?? '');
    _descriptionController = TextEditingController(text: widget.tag?.description ?? '');
    _selectedColor = widget.tag != null ? _parseColor(widget.tag!.color) : Colors.blue;
    _selectedIcon = widget.tag?.icon;
    _isActive = widget.tag?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        constraints: const BoxConstraints(maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _selectedColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  if (_selectedIcon != null)
                    Icon(
                      _getIconData(_selectedIcon!),
                      color: Colors.white,
                      size: 28,
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isEditMode ? 'Editar Tag' : 'Nova Tag',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nome
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nome da Tag *',
                          hintText: 'Ex: VIP, Urgente, Especial',
                          prefixIcon: Icon(Icons.label),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Nome é obrigatório';
                          }
                          if (value.trim().length < 2) {
                            return 'Nome deve ter pelo menos 2 caracteres';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Descrição
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Descrição (opcional)',
                          hintText: 'Descreva quando usar esta tag',
                          prefixIcon: Icon(Icons.description),
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),

                      const SizedBox(height: 20),

                      // Cor
                      const Text(
                        'Cor da Tag',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildColorPicker(),

                      const SizedBox(height: 20),

                      // Ícone
                      const Text(
                        'Ícone (opcional)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildIconPicker(),

                      const SizedBox(height: 20),

                      // Status (apenas no modo edição)
                      if (isEditMode) ...[
                        SwitchListTile(
                          title: const Text('Tag Ativa'),
                          subtitle: const Text('Tags inativas não aparecem para seleção'),
                          value: _isActive,
                          onChanged: (value) {
                            setState(() {
                              _isActive = value;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Preview
                      const Text(
                        'Pré-visualização',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildPreview(),
                    ],
                  ),
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.dark 
                    ? Colors.grey[850] 
                    : Colors.grey[100],
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveTag,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedColor,
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(isEditMode ? 'Salvar' : 'Criar'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorPicker() {
    return InkWell(
      onTap: _showColorPickerDialog,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _selectedColor,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: _selectedColor.withOpacity(0.5),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _colorToHex(_selectedColor),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            const Icon(Icons.edit, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildIconPicker() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _availableIcons.map((iconData) {
        final isSelected = _selectedIcon == iconData['name'];
        return InkWell(
          onTap: () {
            setState(() {
              _selectedIcon = _selectedIcon == iconData['name'] ? null : iconData['name'];
            });
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: isSelected ? _selectedColor : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? _selectedColor : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  iconData['icon'],
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                  size: 24,
                ),
                const SizedBox(height: 2),
                Text(
                  iconData['label'],
                  style: TextStyle(
                    fontSize: 8,
                    color: isSelected ? Colors.white : Colors.grey.shade700,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPreview() {
    final tagName = _nameController.text.trim().isEmpty ? 'Nome da Tag' : _nameController.text;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Como vai aparecer:',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _selectedColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: _selectedColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_selectedIcon != null) ...[
                  Icon(_getIconData(_selectedIcon!), color: Colors.white, size: 18),
                  const SizedBox(width: 6),
                ],
                Text(
                  tagName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showColorPickerDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Escolher Cor'),
        content: SingleChildScrollView(
          child: BlockPicker(
            pickerColor: _selectedColor,
            onColorChanged: (color) {
              setState(() {
                _selectedColor = color;
              });
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveTag() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final provider = ref.read(quotationTagProvider);
      final hexColor = _colorToHex(_selectedColor);

      TagOperationResult result;

      if (isEditMode) {
        // Editar
        result = await provider.updateTag(
          tagId: widget.tag!.id,
          name: _nameController.text.trim(),
          color: hexColor,
          description: _descriptionController.text.trim().isEmpty 
              ? null 
              : _descriptionController.text.trim(),
          icon: _selectedIcon,
          isActive: _isActive,
        );
      } else {
        // Criar
        result = await provider.createTag(
          name: _nameController.text.trim(),
          color: hexColor,
          description: _descriptionController.text.trim().isEmpty 
              ? null 
              : _descriptionController.text.trim(),
          icon: _selectedIcon,
          createdBy: 'user', // TODO: pegar do auth
        );
      }

      if (mounted) {
        if (result.success) {
          Navigator.pop(context, result.tag);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Color _parseColor(String hexColor) {
    try {
      return Color(int.parse(hexColor.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.blue;
    }
  }

  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }

  IconData _getIconData(String iconName) {
    final icon = _availableIcons.firstWhere(
      (i) => i['name'] == iconName,
      orElse: () => {'icon': Icons.label},
    );
    return icon['icon'] as IconData;
  }
}
