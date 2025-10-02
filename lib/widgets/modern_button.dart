import 'package:flutter/material.dart';
import '../constants/app_theme.dart';

enum ModernButtonType { primary, secondary, outline, text, danger }

enum ModernButtonSize { small, medium, large }

class ModernButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final ModernButtonType type;
  final ModernButtonSize size;
  final IconData? icon;
  final bool isLoading;
  final bool isDisabled;
  final EdgeInsetsGeometry? padding;
  final double? width;

  const ModernButton({
    super.key,
    required this.text,
    this.onPressed,
    this.type = ModernButtonType.primary,
    this.size = ModernButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.isDisabled = false,
    this.padding,
    this.width,
  });

  @override
  State<ModernButton> createState() => _ModernButtonState();
}

class _ModernButtonState extends State<ModernButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AppTheme.animationFast,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: AppTheme.animationCurve,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (!widget.isDisabled && widget.onPressed != null) {
      setState(() => _isPressed = true);
      _animationController.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (_isPressed) {
      setState(() => _isPressed = false);
      _animationController.reverse();
    }
  }

  void _handleTapCancel() {
    if (_isPressed) {
      setState(() => _isPressed = false);
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: _buildButton(),
          );
        },
      ),
    );
  }

  Widget _buildButton() {
    final isEnabled = !widget.isDisabled && widget.onPressed != null;

    return AnimatedContainer(
      duration: AppTheme.animationMedium,
      curve: AppTheme.animationCurve,
      width: widget.width,
      padding: widget.padding ?? _getPadding(),
      decoration: BoxDecoration(
        color: _getBackgroundColor(isEnabled),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: _getBorder(isEnabled),
        boxShadow: _getBoxShadow(isEnabled),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEnabled ? widget.onPressed : null,
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          child: Container(
            constraints: BoxConstraints(minHeight: _getMinHeight()),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.isLoading)
                  Container(
                    margin: const EdgeInsets.only(right: AppTheme.spacingS),
                    child: SizedBox(
                      width: _getIconSize(),
                      height: _getIconSize(),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getTextColor(isEnabled),
                        ),
                      ),
                    ),
                  )
                else if (widget.icon != null)
                  Container(
                    margin: const EdgeInsets.only(right: AppTheme.spacingS),
                    child: Icon(
                      widget.icon,
                      size: _getIconSize(),
                      color: _getTextColor(isEnabled),
                    ),
                  ),
                Text(
                  widget.text,
                  style: _getTextStyle(isEnabled),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  EdgeInsetsGeometry _getPadding() {
    switch (widget.size) {
      case ModernButtonSize.small:
        return const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingM,
          vertical: AppTheme.spacingS,
        );
      case ModernButtonSize.medium:
        return const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingL,
          vertical: AppTheme.spacingM,
        );
      case ModernButtonSize.large:
        return const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingXL,
          vertical: AppTheme.spacingL,
        );
    }
  }

  double _getMinHeight() {
    switch (widget.size) {
      case ModernButtonSize.small:
        return 36;
      case ModernButtonSize.medium:
        return 48; // Accessibility minimum
      case ModernButtonSize.large:
        return 56;
    }
  }

  double _getIconSize() {
    switch (widget.size) {
      case ModernButtonSize.small:
        return 16;
      case ModernButtonSize.medium:
        return 20;
      case ModernButtonSize.large:
        return 24;
    }
  }

  Color _getBackgroundColor(bool isEnabled) {
    if (!isEnabled) {
      return AppTheme.surfaceContainerHigh;
    }

    switch (widget.type) {
      case ModernButtonType.primary:
        return _isPressed
            ? AppTheme.primaryMedicalDark
            : AppTheme.primaryMedical;
      case ModernButtonType.secondary:
        return _isPressed
            ? AppTheme.surfaceContainerHigh
            : AppTheme.surfaceContainer;
      case ModernButtonType.outline:
      case ModernButtonType.text:
        return _isPressed
            ? AppTheme.primaryMedical.withValues(alpha: 0.08)
            : Colors.transparent;
      case ModernButtonType.danger:
        return _isPressed
            ? AppTheme.error.withValues(alpha: 0.9)
            : AppTheme.error;
    }
  }

  Color _getTextColor(bool isEnabled) {
    if (!isEnabled) {
      return AppTheme.textDisabled;
    }

    switch (widget.type) {
      case ModernButtonType.primary:
        return Colors.white;
      case ModernButtonType.secondary:
        return AppTheme.textPrimaryDark;
      case ModernButtonType.outline:
      case ModernButtonType.text:
        return AppTheme.primaryMedical;
      case ModernButtonType.danger:
        return Colors.white;
    }
  }

  TextStyle _getTextStyle(bool isEnabled) {
    TextStyle baseStyle;
    switch (widget.size) {
      case ModernButtonSize.small:
        baseStyle = AppTheme.labelMedium;
        break;
      case ModernButtonSize.medium:
        baseStyle = AppTheme.labelLarge;
        break;
      case ModernButtonSize.large:
        baseStyle = AppTheme.labelLarge.copyWith(fontSize: 16);
        break;
    }

    return baseStyle.copyWith(
      color: _getTextColor(isEnabled),
      fontWeight: FontWeight.w600,
    );
  }

  Border? _getBorder(bool isEnabled) {
    if (widget.type == ModernButtonType.outline) {
      return Border.all(
        color:
            isEnabled
                ? (_isPressed
                    ? AppTheme.primaryMedicalDark
                    : AppTheme.primaryMedical)
                : AppTheme.borderSubtle,
        width: 1.5,
      );
    }
    return null;
  }

  List<BoxShadow>? _getBoxShadow(bool isEnabled) {
    if (!isEnabled || widget.type == ModernButtonType.text) {
      return null;
    }

    if (widget.type == ModernButtonType.primary && isEnabled) {
      return [
        BoxShadow(
          color: AppTheme.primaryMedical.withValues(alpha: 0.25),
          offset: const Offset(0, 4),
          blurRadius: 12,
          spreadRadius: 0,
        ),
      ];
    }

    return AppTheme.elevationSoft;
  }
}
