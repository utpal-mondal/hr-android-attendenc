import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum AppButtonType { primary, secondary, destructive, text }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.type = AppButtonType.primary,
    this.loading = false,
    this.expand = false,
    this.compact = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppButtonType type;
  final bool loading;
  final bool expand;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final fg = switch (type) {
      AppButtonType.primary => Colors.white,
      AppButtonType.destructive => Colors.white,
      AppButtonType.secondary => AppColors.navy,
      AppButtonType.text => AppColors.teal,
    };
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (loading)
          SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: fg))
        else if (icon != null)
          Icon(icon, size: 18),
        if (loading || icon != null) const SizedBox(width: 8),
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis, maxLines: 1, style: const TextStyle(fontWeight: FontWeight.w600))),
      ],
    );
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(10));
    final size = Size(0, compact ? 40 : 48);
    final pad = EdgeInsets.symmetric(horizontal: compact ? 14 : 20);
    final handler = loading ? null : onPressed;

    Widget button;
    switch (type) {
      case AppButtonType.primary:
        button = FilledButton(
          onPressed: handler,
          style: FilledButton.styleFrom(backgroundColor: AppColors.navy, foregroundColor: Colors.white, minimumSize: size, padding: pad, shape: shape),
          child: content,
        );
      case AppButtonType.destructive:
        button = FilledButton(
          onPressed: handler,
          style: FilledButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white, minimumSize: size, padding: pad, shape: shape),
          child: content,
        );
      case AppButtonType.secondary:
        button = OutlinedButton(
          onPressed: handler,
          style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.navy, minimumSize: size, padding: pad, shape: shape, side: const BorderSide(color: AppColors.border), backgroundColor: Colors.white),
          child: content,
        );
      case AppButtonType.text:
        button = TextButton(
          onPressed: handler,
          style: TextButton.styleFrom(foregroundColor: AppColors.teal, minimumSize: Size(0, compact ? 36 : 44), padding: pad, shape: shape),
          child: content,
        );
    }
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}
