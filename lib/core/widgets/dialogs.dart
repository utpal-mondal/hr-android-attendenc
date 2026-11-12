import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'app_button.dart';

void showAppSnack(BuildContext context, String message, {bool error = false}) {
  final m = ScaffoldMessenger.of(context);
  m.hideCurrentSnackBar();
  m.showSnackBar(SnackBar(
    content: Row(children: [
      Icon(error ? Icons.error_outline : Icons.check_circle_outline, color: Colors.white, size: 20),
      const SizedBox(width: 10),
      Expanded(child: Text(message)),
    ]),
    backgroundColor: error ? AppColors.danger : AppColors.navy,
  ));
}

Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      content: Text(message, style: const TextStyle(color: AppColors.textSecondary)),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        AppButton(label: cancelLabel, type: AppButtonType.secondary, compact: true, onPressed: () => Navigator.pop(ctx, false)),
        AppButton(
            label: confirmLabel,
            type: destructive ? AppButtonType.destructive : AppButtonType.primary,
            compact: true,
            onPressed: () => Navigator.pop(ctx, true)),
      ],
    ),
  );
  return result ?? false;
}

Future<void> showSuccessDialog(BuildContext context, {required String title, required String message, String buttonLabel = 'Done'}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.6, end: 1),
            duration: const Duration(milliseconds: 450),
            curve: Curves.elasticOut,
            builder: (context, v, child) => Transform.scale(scale: v, child: child),
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(color: AppColors.success.withValues(alpha:0.12), shape: BoxShape.circle),
              child: const Icon(Icons.check_rounded, color: AppColors.success, size: 44),
            ),
          ),
          const SizedBox(height: 18),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 20),
          AppButton(label: buttonLabel, expand: true, onPressed: () => Navigator.pop(ctx)),
        ],
      ),
    ),
  );
}

/// Simulated GPS / geofence verification (documentation: no real GPS in the demo).
Future<bool> runLocationVerification(BuildContext context, {String office = 'Kolkata HQ'}) async {
  final ok = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _VerifyDialog(office: office),
  );
  return ok ?? false;
}

class _VerifyDialog extends StatefulWidget {
  const _VerifyDialog({required this.office});
  final String office;

  @override
  State<_VerifyDialog> createState() => _VerifyDialogState();
}

class _VerifyDialogState extends State<_VerifyDialog> {
  int _step = 0;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() => _step = 1);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => _step = 2);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final labels = ['Checking GPS signal...', 'Matching office geofence...', 'Verified - within 38 m of ${widget.office}'];
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          SizedBox(
            width: 64,
            height: 64,
            child: _step < 2
                ? const CircularProgressIndicator(strokeWidth: 4)
                : Container(
                    decoration: BoxDecoration(color: AppColors.success.withValues(alpha:0.12), shape: BoxShape.circle),
                    child: const Icon(Icons.location_on, color: AppColors.success, size: 34),
                  ),
          ),
          const SizedBox(height: 20),
          const Text('Verifying location', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Text(labels[_step], key: ValueKey(_step), textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// Modal sheet with consistent styling.
Future<T?> showAppSheet<T>(BuildContext context, {required WidgetBuilder builder}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    constraints: const BoxConstraints(maxWidth: 640),
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: SafeArea(top: false, child: builder(ctx)),
    ),
  );
}
