import 'package:flutter/material.dart';

class StandardSearchBar extends StatefulWidget {
  final TextEditingController? controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;

  const StandardSearchBar({
    Key? key,
    this.controller,
    this.hintText = 'Buscar...',
    this.onChanged,
    this.onClear,
  }) : super(key: key);

  @override
  State<StandardSearchBar> createState() => _StandardSearchBarState();
}

class _StandardSearchBarState extends State<StandardSearchBar> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasText = _controller.text.isNotEmpty;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      child: Material(
        elevation: 3,
        borderRadius: BorderRadius.circular(32),
        child: TextField(
          controller: _controller,
          onChanged: (value) {
            widget.onChanged?.call(value);
          },
          decoration: InputDecoration(
            hintText: widget.hintText,
            prefixIcon: const Icon(Icons.search, color: Colors.grey),
            suffixIcon: hasText && widget.onClear != null
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey),
                    onPressed: () {
                      _controller.clear();
                      widget.onClear?.call();
                    },
                  )
                : null,
            border: InputBorder.none,
            filled: true,
            fillColor: theme.colorScheme.surface,
            contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
          ),
          style: theme.textTheme.bodyMedium,
        ),
      ),
    );
  }
} 
