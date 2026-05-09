import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// Primary CTA: gradient burgundy with subtle press shrink + haptic.
class PrimaryButton extends StatefulWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expanded = true,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expanded;
  final bool loading;

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  bool _pressed = false;

  void _setPressed(bool v) {
    if (_pressed == v) return;
    setState(() => _pressed = v);
    if (v) HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final disabled = widget.onPressed == null || widget.loading;

    final base = Container(
      height: 54,
      width: widget.expanded ? double.infinity : null,
      padding: const EdgeInsets.symmetric(horizontal: 26),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: disabled
              ? [
                  palette.inkMuted.withValues(alpha: 0.28),
                  palette.inkMuted.withValues(alpha: 0.36),
                ]
              : [
                  palette.burgundy,
                  AppColors.burgundyDeep,
                ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: disabled
            ? null
            : [
                BoxShadow(
                  color: AppColors.burgundyDeep.withValues(
                    alpha: _pressed ? 0.12 : 0.22,
                  ),
                  blurRadius: _pressed ? 8 : 18,
                  offset: Offset(0, _pressed ? 2 : 8),
                ),
              ],
      ),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.loading)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: AppColors.page,
                ),
              )
            else ...[
              if (widget.icon != null) ...[
                Icon(widget.icon, color: AppColors.page, size: 18),
                const SizedBox(width: 12),
              ],
              Text(
                widget.label,
                style: AppTypography.button(color: AppColors.page),
              ),
            ],
          ],
        ),
      ),
    );

    return GestureDetector(
      onTapDown: disabled ? null : (_) => _setPressed(true),
      onTapUp: disabled ? null : (_) => _setPressed(false),
      onTapCancel: disabled ? null : () => _setPressed(false),
      onTap: disabled ? null : widget.onPressed,
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        child: base,
      ),
    );
  }
}

/// Secondary, outlined version for ghost actions.
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expanded = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final btn = OutlinedButton(
      onPressed: onPressed == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              onPressed!();
            },
      style: OutlinedButton.styleFrom(
        foregroundColor: palette.ink,
        side: BorderSide(color: palette.divider, width: 1.2),
        backgroundColor: palette.page,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        minimumSize: const Size.fromHeight(54),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        textStyle: AppTypography.button(),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18),
            const SizedBox(width: 12),
          ],
          Text(label),
        ],
      ),
    );
    return expanded ? SizedBox(width: double.infinity, child: btn) : btn;
  }
}
