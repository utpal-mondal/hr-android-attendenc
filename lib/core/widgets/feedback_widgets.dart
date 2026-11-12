import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'app_button.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.title, this.message, this.icon = Icons.inbox_outlined, this.actionLabel, this.onAction});
  final String title;
  final String? message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(color: AppColors.teal.withValues(alpha:0.10), shape: BoxShape.circle),
              child: Icon(icon, size: 34, color: AppColors.teal),
            ),
            const SizedBox(height: 16),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            if (message != null) ...[
              const SizedBox(height: 6),
              Text(message!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13.5)),
            ],
            if (actionLabel != null) ...[
              const SizedBox(height: 16),
              AppButton(label: actionLabel!, onPressed: onAction, compact: true),
            ],
          ],
        ),
      ),
    );
  }
}

class ErrorState extends StatelessWidget {
  const ErrorState({super.key, this.message = 'Something went wrong.', this.onRetry});
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(color: AppColors.danger.withValues(alpha:0.10), shape: BoxShape.circle),
              child: const Icon(Icons.cloud_off_outlined, size: 34, color: AppColors.danger),
            ),
            const SizedBox(height: 16),
            const Text('Unable to load', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13.5)),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              AppButton(label: 'Retry', icon: Icons.refresh, onPressed: onRetry, compact: true),
            ],
          ],
        ),
      ),
    );
  }
}

enum ShimmerLayout { list, dashboard }

class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform(this.slidePercent);
  final double slidePercent;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slidePercent, 0.0, 0.0);
  }
}

/// Shimmer skeleton used instead of plain spinners (documentation section 4).
class LoadingShimmer extends StatefulWidget {
  const LoadingShimmer({super.key, this.layout = ShimmerLayout.dashboard, this.itemCount = 6});
  final ShimmerLayout layout;
  final int itemCount;

  @override
  State<LoadingShimmer> createState() => _LoadingShimmerState();
}

class _LoadingShimmerState extends State<LoadingShimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Widget _box({double? width, double height = 14, double radius = 8}) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(color: const Color(0xFFE4E7EC), borderRadius: BorderRadius.circular(radius)),
      );

  Widget _row() => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
        child: Row(
          children: [
            Container(width: 44, height: 44, decoration: const BoxDecoration(color: Color(0xFFE4E7EC), shape: BoxShape.circle)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [_box(height: 14), const SizedBox(height: 8), _box(width: 140, height: 11)],
              ),
            ),
            const SizedBox(width: 12),
            _box(width: 60, height: 22, radius: 12),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final Widget skeleton;
    if (widget.layout == ShimmerLayout.list) {
      skeleton = Column(children: [for (var i = 0; i < widget.itemCount; i++) Padding(padding: const EdgeInsets.only(bottom: 12), child: _row())]);
    } else {
      skeleton = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 170, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16))),
          const SizedBox(height: 16),
          Row(children: [
            for (var i = 0; i < 2; i++) ...[
              Expanded(child: Container(height: 82, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)))),
              if (i == 0) const SizedBox(width: 12),
            ]
          ]),
          const SizedBox(height: 12),
          Row(children: [
            for (var i = 0; i < 2; i++) ...[
              Expanded(child: Container(height: 82, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)))),
              if (i == 0) const SizedBox(width: 12),
            ]
          ]),
          const SizedBox(height: 20),
          _row(),
          const SizedBox(height: 12),
          _row(),
          const SizedBox(height: 12),
          _row(),
        ],
      );
    }
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) => LinearGradient(
            colors: const [Color(0xFFE9ECF0), Color(0xFFF8F9FB), Color(0xFFE9ECF0)],
            stops: const [0.1, 0.3, 0.5],
            begin: const Alignment(-1.0, -0.3),
            end: const Alignment(1.0, 0.3),
            tileMode: TileMode.clamp,
            transform: _SlidingGradientTransform(_c.value * 2 - 1),
          ).createShader(bounds),
          child: child,
        );
      },
      child: skeleton,
    );
  }
}
