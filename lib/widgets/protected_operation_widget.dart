import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

class ProtectedOperationWidget extends ConsumerWidget {
  final String operation;
  final Widget child;
  final Widget? fallback;

  const ProtectedOperationWidget({
    super.key,
    required this.operation,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canExecute = ref.watch(canExecuteCriticalDBOperationProvider(operation));
    final isDBA = ref.watch(isDBAProvider);

    if (canExecute || isDBA) {
      return child;
    }

    return fallback ?? const SizedBox.shrink();
  }
}

class ProtectedButton extends ConsumerWidget {
  final String operation;
  final VoidCallback? onPressed;
  final Widget child;
  final ButtonStyle? style;
  final bool? isDisabled;

  const ProtectedButton({
    super.key,
    required this.operation,
    this.onPressed,
    required this.child,
    this.style,
    this.isDisabled,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canExecute = ref.watch(canExecuteCriticalDBOperationProvider(operation));
    final isDBA = ref.watch(isDBAProvider);

    if (!canExecute && !isDBA) {
      return const SizedBox.shrink();
    }

    return ElevatedButton(
      onPressed: (isDisabled == true) ? null : onPressed,
      style: style,
      child: child,
    );
  }
}

class ProtectedIconButton extends ConsumerWidget {
  final String operation;
  final VoidCallback? onPressed;
  final Widget icon;
  final String? tooltip;
  final Color? color;

  const ProtectedIconButton({
    super.key,
    required this.operation,
    this.onPressed,
    required this.icon,
    this.tooltip,
    this.color,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canExecute = ref.watch(canExecuteCriticalDBOperationProvider(operation));
    final isDBA = ref.watch(isDBAProvider);

    if (!canExecute && !isDBA) {
      return const SizedBox.shrink();
    }

    return IconButton(
      onPressed: onPressed,
      icon: icon,
      tooltip: tooltip,
      color: color,
    );
  }
}

mixin ProtectedOperationMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  bool canExecuteOperation(String operation) {
    return ref.read(canExecuteCriticalDBOperationProvider(operation));
  }

  bool get isDBA => ref.read(isDBAProvider);
} 
