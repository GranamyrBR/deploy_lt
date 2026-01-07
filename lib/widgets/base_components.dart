import 'package:flutter/material.dart';
import '../design/design_tokens.dart';

// Card base moderno
class ModernCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double? elevation;
  final double? borderRadius;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  final bool isInteractive;

  const ModernCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.elevation,
    this.borderRadius,
    this.backgroundColor,
    this.onTap,
    this.isInteractive = false,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      margin: margin ?? EdgeInsets.zero,
      decoration: BoxDecoration(
        color: backgroundColor ?? Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(borderRadius ?? DesignTokens.radius16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: elevation ?? 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius ?? DesignTokens.radius16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(borderRadius ?? DesignTokens.radius16),
            child: Padding(
              padding: padding ?? const EdgeInsets.all(DesignTokens.spacing24),
              child: child,
            ),
          ),
        ),
      ),
    );

    if (isInteractive && onTap != null) {
      return card;
    } else {
      return Container(
        margin: margin ?? EdgeInsets.zero,
        decoration: BoxDecoration(
          color: backgroundColor ?? Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(borderRadius ?? DesignTokens.radius16),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.08),
              blurRadius: elevation ?? 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(DesignTokens.spacing24),
          child: child,
        ),
      );
    }
  }
}

// Botão moderno
class ModernButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final ButtonSize size;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;

  const ModernButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = ButtonVariant.primary,
    this.size = ButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final buttonStyle = _getButtonStyle(context);
    final buttonSize = _getButtonSize();

    Widget button = ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: buttonStyle,
      child: SizedBox(
        height: buttonSize,
        child: Center(
          child: isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      variant == ButtonVariant.primary
                          ? Colors.white
                          : Theme.of(context).colorScheme.primary,
                    ),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: _getIconSize()),
                      const SizedBox(width: DesignTokens.spacing8),
                    ],
                    Text(
                      text,
                      style: _getTextStyle(context),
                    ),
                  ],
                ),
        ),
      ),
    );

    if (isFullWidth) {
      button = SizedBox(width: double.infinity, child: button);
    }

    return button;
  }

  ButtonStyle _getButtonStyle(BuildContext context) {
    switch (variant) {
      case ButtonVariant.primary:
        return ElevatedButton.styleFrom(
          backgroundColor: DesignTokens.primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radius12),
          ),
          padding: _getButtonPadding(),
        );
      case ButtonVariant.secondary:
        return ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: DesignTokens.primaryBlue,
          elevation: 0,
          shadowColor: Colors.transparent,
          side: BorderSide(color: DesignTokens.primaryBlue),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radius12),
          ),
          padding: _getButtonPadding(),
        );
      case ButtonVariant.ghost:
        return ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: DesignTokens.primaryBlue,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radius12),
          ),
          padding: _getButtonPadding(),
        );
    }
  }

  double _getButtonSize() {
    switch (size) {
      case ButtonSize.small:
        return DesignTokens.buttonHeightSm;
      case ButtonSize.medium:
        return DesignTokens.buttonHeightMd;
      case ButtonSize.large:
        return DesignTokens.buttonHeightLg;
      case ButtonSize.xlarge:
        return DesignTokens.buttonHeightXl;
    }
  }

  EdgeInsets _getButtonPadding() {
    switch (size) {
      case ButtonSize.small:
        return DesignTokens.buttonPaddingSm;
      case ButtonSize.medium:
        return DesignTokens.buttonPaddingMd;
      case ButtonSize.large:
        return DesignTokens.buttonPaddingLg;
      case ButtonSize.xlarge:
        return DesignTokens.buttonPaddingXl;
    }
  }

  double _getIconSize() {
    switch (size) {
      case ButtonSize.small:
        return DesignTokens.iconSizeSm;
      case ButtonSize.medium:
        return DesignTokens.iconSizeMd;
      case ButtonSize.large:
        return DesignTokens.iconSizeLg;
      case ButtonSize.xlarge:
        return DesignTokens.iconSizeXl;
    }
  }

  TextStyle _getTextStyle(BuildContext context) {
    switch (size) {
      case ButtonSize.small:
        return DesignTokens.labelMedium.copyWith(
          color: variant == ButtonVariant.primary ? Colors.white : DesignTokens.primaryBlue,
        );
      case ButtonSize.medium:
        return DesignTokens.labelLarge.copyWith(
          color: variant == ButtonVariant.primary ? Colors.white : DesignTokens.primaryBlue,
        );
      case ButtonSize.large:
        return DesignTokens.titleMedium.copyWith(
          color: variant == ButtonVariant.primary ? Colors.white : DesignTokens.primaryBlue,
        );
      case ButtonSize.xlarge:
        return DesignTokens.titleLarge.copyWith(
          color: variant == ButtonVariant.primary ? Colors.white : DesignTokens.primaryBlue,
        );
    }
  }
}

enum ButtonVariant { primary, secondary, ghost }
enum ButtonSize { small, medium, large, xlarge }

// Input field moderno
class ModernTextField extends StatelessWidget {
  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final int? maxLines;
  final int? maxLength;
  final bool enabled;

  const ModernTextField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.onChanged,
    this.maxLines = 1,
    this.maxLength,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: DesignTokens.labelMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: DesignTokens.spacing8),
        ],
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: validator,
          onChanged: onChanged,
          maxLines: maxLines,
          maxLength: maxLength,
          enabled: enabled,
          style: DesignTokens.bodyMedium.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: DesignTokens.bodyMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: enabled 
                ? Theme.of(context).colorScheme.surface
                : Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radius12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radius12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radius12),
              borderSide: BorderSide(
                color: DesignTokens.primaryBlue,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radius12),
              borderSide: BorderSide(
                color: DesignTokens.error,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radius12),
              borderSide: BorderSide(
                color: DesignTokens.error,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.spacing16,
              vertical: DesignTokens.spacing12,
            ),
          ),
        ),
      ],
    );
  }
}

// Badge moderno
class ModernBadge extends StatelessWidget {
  final String text;
  final BadgeVariant variant;
  final BadgeSize size;

  const ModernBadge({
    super.key,
    required this.text,
    this.variant = BadgeVariant.primary,
    this.size = BadgeSize.medium,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: _getPadding(),
      decoration: BoxDecoration(
        color: _getBackgroundColor(context),
        borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
      ),
      child: Text(
        text,
        style: _getTextStyle(context),
      ),
    );
  }

  EdgeInsets _getPadding() {
    switch (size) {
      case BadgeSize.small:
        return const EdgeInsets.symmetric(
          horizontal: DesignTokens.spacing8,
          vertical: DesignTokens.spacing4,
        );
      case BadgeSize.medium:
        return const EdgeInsets.symmetric(
          horizontal: DesignTokens.spacing12,
          vertical: DesignTokens.spacing6,
        );
      case BadgeSize.large:
        return const EdgeInsets.symmetric(
          horizontal: DesignTokens.spacing16,
          vertical: DesignTokens.spacing8,
        );
    }
  }

  Color _getBackgroundColor(BuildContext context) {
    switch (variant) {
      case BadgeVariant.primary:
        return DesignTokens.primaryBlue.withValues(alpha: 0.1);
      case BadgeVariant.success:
        return DesignTokens.success.withValues(alpha: 0.1);
      case BadgeVariant.warning:
        return DesignTokens.warning.withValues(alpha: 0.1);
      case BadgeVariant.error:
        return DesignTokens.error.withValues(alpha: 0.1);
      case BadgeVariant.info:
        return DesignTokens.info.withValues(alpha: 0.1);
    }
  }

  TextStyle _getTextStyle(BuildContext context) {
    final fontSize = size == BadgeSize.small ? 10.0 : 12.0;
    final fontWeight = FontWeight.w600;

    switch (variant) {
      case BadgeVariant.primary:
        return TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: DesignTokens.primaryBlue,
        );
      case BadgeVariant.success:
        return TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: DesignTokens.success,
        );
      case BadgeVariant.warning:
        return TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: DesignTokens.warning,
        );
      case BadgeVariant.error:
        return TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: DesignTokens.error,
        );
      case BadgeVariant.info:
        return TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: DesignTokens.info,
        );
    }
  }
}

enum BadgeVariant { primary, success, warning, error, info }
enum BadgeSize { small, medium, large }

// Loading spinner moderno
class ModernLoadingSpinner extends StatelessWidget {
  final double size;
  final Color? color;
  final String? message;

  const ModernLoadingSpinner({
    super.key,
    this.size = 40,
    this.color,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(
              color ?? DesignTokens.primaryBlue,
            ),
          ),
        ),
        if (message != null) ...[
          const SizedBox(height: DesignTokens.spacing16),
          Text(
            message!,
            style: DesignTokens.bodyMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

// Empty state moderno
class ModernEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? description;
  final String? actionText;
  final VoidCallback? onAction;

  const ModernEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.description,
    this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spacing32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(DesignTokens.spacing24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                shape: BoxShape.circle,
                boxShadow: DesignTokens.shadowSm,
              ),
              child: Icon(
                icon,
                size: DesignTokens.iconSize2xl,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: DesignTokens.spacing24),
            Text(
              title,
              style: DesignTokens.headlineSmall.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            if (description != null) ...[
              const SizedBox(height: DesignTokens.spacing8),
              Text(
                description!,
                style: DesignTokens.bodyMedium.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: DesignTokens.spacing24),
              ModernButton(
                text: actionText!,
                onPressed: onAction,
                variant: ButtonVariant.primary,
                size: ButtonSize.medium,
              ),
            ],
          ],
        ),
      ),
    );
  }
} 
